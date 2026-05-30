import HttpManager from '../net/HttpManager';
import { Address } from '../net/Address';
import { HttpResult } from '../net/Result';
import { CodeDetailStore } from '../store/CodeDetailStore';
import { HtmlUtil } from '../utils/HtmlUtil';
import { GSYColor } from '../style/Theme';
import { RepositoryDao } from '../dao/RepositoryDao';
import { ReadResult } from '../dao/DaoBase';
import { HttpHeaders } from '../net/Result';
import { CommitDetail, CommitFileItem } from '../store/PushDetailStore';

export class RepoOwnerNamePair {
  owner: string;
  name: string;

  constructor(owner: string, name: string) {
    this.owner = owner;
    this.name = name;
  }

  static parse(fullName: string): RepoOwnerNamePair {
    const safe: string = fullName !== null && fullName !== undefined ? fullName : '';
    const idx: number = safe.indexOf('/');
    if (idx < 0) {
      return new RepoOwnerNamePair(safe, '');
    }
    return new RepoOwnerNamePair(safe.substring(0, idx), safe.substring(idx + 1));
  }
}

export class CodeServiceResult<T> {
  result: boolean;
  code: number;
  data: T | null;
  msg: string;
  fromCache: boolean;

  constructor(result: boolean, code: number, data: T | null, msg: string, fromCache: boolean = false) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.msg = msg;
    this.fromCache = fromCache;
  }
}

export interface RawContentResponse {
  content: string;
  encoding: string;
  path: string;
  name: string;
}

const MARKDOWN_LANG: string = 'markdown';
const GITHUB_HTML_ACCEPT: string = 'application/vnd.github.html';

export class CodeService {
  private store: CodeDetailStore;
  private dao: RepositoryDao;

  constructor(store: CodeDetailStore, dao?: RepositoryDao) {
    this.store = store;
    this.dao = dao !== undefined ? dao : new RepositoryDao();
  }

  getStore(): CodeDetailStore {
    return this.store;
  }

  static guessLangByPath(path: string): string {
    const safe: string = path !== null && path !== undefined ? path : '';
    const dot: number = safe.lastIndexOf('.');
    if (dot < 0) {
      return 'java';
    }
    const ext: string = safe.substring(dot + 1).toLowerCase();
    if (ext === 'md' || ext === 'markdown') {
      return MARKDOWN_LANG;
    }
    if (ext === 'ts' || ext === 'tsx') {
      return 'typescript';
    }
    if (ext === 'js' || ext === 'jsx') {
      return 'javascript';
    }
    if (ext === 'java') {
      return 'java';
    }
    if (ext === 'kt' || ext === 'kts') {
      return 'kotlin';
    }
    if (ext === 'py') {
      return 'python';
    }
    if (ext === 'go') {
      return 'go';
    }
    if (ext === 'rs') {
      return 'rust';
    }
    if (ext === 'c' || ext === 'h') {
      return 'c';
    }
    if (ext === 'cc' || ext === 'cpp' || ext === 'cxx' || ext === 'hpp') {
      return 'cpp';
    }
    if (ext === 'm' || ext === 'mm') {
      return 'objectivec';
    }
    if (ext === 'swift') {
      return 'swift';
    }
    if (ext === 'php') {
      return 'php';
    }
    if (ext === 'html' || ext === 'htm') {
      return 'html';
    }
    if (ext === 'css' || ext === 'scss' || ext === 'less') {
      return 'css';
    }
    if (ext === 'json') {
      return 'json';
    }
    if (ext === 'xml') {
      return 'xml';
    }
    if (ext === 'yaml' || ext === 'yml') {
      return 'yaml';
    }
    if (ext === 'sh' || ext === 'bash') {
      return 'bash';
    }
    if (ext === 'ets' || ext === 'arkts') {
      return 'typescript';
    }
    return ext.length > 0 ? ext : 'java';
  }

  async getRawContent(fullName: string,
                      branch: string,
                      path: string): Promise<CodeServiceResult<string>> {
    const owner: RepoOwnerNamePair = RepoOwnerNamePair.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      const msg: string = 'invalid fullName';
      this.store.setError(msg);
      return new CodeServiceResult<string>(false, 0, null, msg);
    }
    const safePath: string = path !== null && path !== undefined ? path : '';
    const safeBranch: string = branch !== null && branch !== undefined && branch.length > 0
      ? branch : 'master';
    const isMarkdown: boolean = CodeService.isMarkdownPath(safePath);
    this.store.setPath(safePath);
    let cachedBody: string = '';
    try {
      const cache: ReadResult = await this.dao.readCodeContent(fullName, safeBranch, safePath);
      if (cache.result && cache.data.length > 0) {
        cachedBody = cache.data;
        if (!isMarkdown || CodeService.isLikelyHtml(cachedBody)) {
          this.store.setContent(cachedBody, CodeService.wrapHtml(cachedBody, safePath));
        }
      }
    } catch (_e) {
    }
    this.store.startLoading();

    const htmlHeaders: HttpHeaders = {
      'Accept': GITHUB_HTML_ACCEPT,
    };
    const contentsUrl: string = Address.getReposFileDir(owner.owner, owner.name, safePath, safeBranch);
    const htmlResp: HttpResult<string> = await HttpManager.getFetch<string>(contentsUrl, htmlHeaders);
    if (htmlResp.result && htmlResp.data !== null) {
      const body: string = htmlResp.data as string;
      const html: string = CodeService.wrapHtml(body, safePath);
      try {
        await this.dao.saveCodeContent(fullName, safeBranch, safePath, body);
      } catch (_e) {
      }
      this.store.setContent(body, html);
      return new CodeServiceResult<string>(true, htmlResp.code, html, '');
    }

    // Compose 的文件详情对 Markdown 只走 GitHub 渲染后的 HTML，再交给 WebView。
    // 这里不再把 raw markdown 当兜底渲染，避免 README.md 显示源码文本。
    if (isMarkdown) {
      if (cachedBody.length > 0 && CodeService.isLikelyHtml(cachedBody)) {
        const cachedHtml: string = CodeService.wrapHtml(cachedBody, safePath);
        this.store.setContent(cachedBody, cachedHtml);
        return new CodeServiceResult<string>(true, htmlResp.code, cachedHtml,
          htmlResp.msg !== null ? htmlResp.msg : '', true);
      }
      const markdownMsg: string = htmlResp.msg !== null && htmlResp.msg.length > 0
        ? htmlResp.msg : 'network error';
      this.store.setError(markdownMsg);
      return new CodeServiceResult<string>(false, htmlResp.code, null, markdownMsg);
    }

    const rawUrl: string = Address.getRawFile(owner.owner, owner.name, safeBranch, safePath);
    const rawResp: HttpResult<string> = await HttpManager.getFetch<string>(rawUrl);
    if (rawResp.result && rawResp.data !== null) {
      const text: string = rawResp.data as string;
      const html: string = CodeService.wrapHtml(text, safePath);
      try {
        await this.dao.saveCodeContent(fullName, safeBranch, safePath, text);
      } catch (_e) {
      }
      this.store.setContent(text, html);
      return new CodeServiceResult<string>(true, rawResp.code, html, '');
    }

    const apiResp: HttpResult<RawContentResponse> =
      await HttpManager.getFetch<RawContentResponse>(contentsUrl);
    if (apiResp.result && apiResp.data !== null) {
      const data: RawContentResponse = apiResp.data as RawContentResponse;
      const decoded: string = CodeService.decodeBase64(data.content);
      const html: string = CodeService.wrapHtml(decoded, safePath);
      try {
        await this.dao.saveCodeContent(fullName, safeBranch, safePath, decoded);
      } catch (_e) {
      }
      this.store.setContent(decoded, html);
      return new CodeServiceResult<string>(true, apiResp.code, html, '');
    }

    if (cachedBody.length > 0) {
      this.store.setContent(cachedBody, CodeService.wrapHtml(cachedBody, safePath));
      return new CodeServiceResult<string>(true, apiResp.code, this.store.htmlContent,
        apiResp.msg !== null ? apiResp.msg : '', true);
    }
    const msg: string = apiResp.msg !== null && apiResp.msg.length > 0 ? apiResp.msg
      : (rawResp.msg !== null ? rawResp.msg : 'network error');
    this.store.setError(msg);
    return new CodeServiceResult<string>(false, apiResp.code, null, msg);
  }

  async getCommitFile(fullName: string,
                      sha: string,
                      path: string): Promise<CodeServiceResult<string>> {
    const owner: RepoOwnerNamePair = RepoOwnerNamePair.parse(fullName);
    const safePath: string = path !== null && path !== undefined ? path : '';
    if (owner.owner.length === 0 || owner.name.length === 0
      || sha === null || sha === undefined || sha.length === 0 || safePath.length === 0) {
      const msg: string = 'invalid params';
      this.store.setError(msg);
      return new CodeServiceResult<string>(false, 0, null, msg);
    }
    this.store.setPath(safePath);
    this.store.startLoading();

    const url: string = Address.getCommitDetail(owner.owner, owner.name, sha);
    const httpResult: HttpResult<CommitDetail> = await HttpManager.getFetch<CommitDetail>(url);
    if (httpResult.result && httpResult.data !== null) {
      const detail: CommitDetail = httpResult.data as CommitDetail;
      const files: CommitFileItem[] = detail.files !== null && detail.files !== undefined ? detail.files : [];
      for (let i = 0; i < files.length; i++) {
        const file: CommitFileItem = files[i];
        if (file.filename === safePath) {
          const patch: string = file.patch !== null && file.patch !== undefined ? file.patch : '';
          const html: string = CodeService.wrapHtml(patch, safePath);
          this.store.setContent(patch, html);
          return new CodeServiceResult<string>(true, httpResult.code, html, '');
        }
      }
      const msg: string = 'File not found in commit';
      this.store.setError(msg);
      return new CodeServiceResult<string>(false, httpResult.code, null, msg);
    }
    const msg: string = httpResult.msg !== null && httpResult.msg.length > 0
      ? httpResult.msg : 'network error';
    this.store.setError(msg);
    return new CodeServiceResult<string>(false, httpResult.code, null, msg);
  }

  static wrapHtml(content: string, path: string): string {
    if (content === null || content === undefined) {
      return '';
    }
    const lang: string = CodeService.guessLangByPath(path);
    if (lang === MARKDOWN_LANG) {
      return CodeService.wrapMarkdownHtml(content);
    }
    return HtmlUtil.generateCode2Html(content, GSYColor.webDraculaBackground, lang, true);
  }

  private static isMarkdownPath(path: string): boolean {
    return CodeService.guessLangByPath(path) === MARKDOWN_LANG;
  }

  private static isLikelyHtml(content: string): boolean {
    const safe: string = content !== null && content !== undefined ? content.trim().toLowerCase() : '';
    if (safe.length === 0) {
      return false;
    }
    return safe.indexOf('<html') >= 0
      || safe.indexOf('<body') >= 0
      || safe.indexOf('<article') >= 0
      || safe.indexOf('<div') >= 0
      || safe.indexOf('<h1') >= 0
      || safe.indexOf('<h2') >= 0
      || safe.indexOf('<p') >= 0;
  }

  private static wrapMarkdownHtml(content: string): string {
    if (CodeService.isLikelyHtml(content) && content.toLowerCase().indexOf('<html') >= 0) {
      return content;
    }
    const viewport: string = '<meta name="viewport" content="width=device-width, initial-scale=1.0">';
    const style: string = '<style>'
      + 'body{padding:15px;}'
      + 'img{max-width:100% !important;height:auto !important;}'
      + 'pre{background-color:#f6f8fa;padding:16px;overflow:auto;border-radius:6px;}'
      + '</style>';
    return '<html><head>' + viewport + style + '</head><body>' + content + '</body></html>';
  }

  static decodeBase64(content: string): string {
    if (content === null || content === undefined || content.length === 0) {
      return '';
    }
    try {
      const bytes: Uint8Array = CodeService.decodeBase64Bytes(content);
      return CodeService.decodeUtf8(bytes);
    } catch (_e) {
      return '';
    }
  }

  private static decodeBase64Bytes(content: string): Uint8Array {
    const alphabet: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const out: number[] = [];
    let buffer: number = 0;
    let bits: number = 0;
    for (let i = 0; i < content.length; i++) {
      const ch: string = content.charAt(i);
      if (ch === '=') {
        break;
      }
      const idx: number = alphabet.indexOf(ch);
      if (idx < 0) {
        continue;
      }
      buffer = (buffer << 6) | idx;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        out.push((buffer >> bits) & 0xFF);
      }
    }
    return new Uint8Array(out);
  }

  private static decodeUtf8(bytes: Uint8Array): string {
    let out: string = '';
    let i: number = 0;
    while (i < bytes.length) {
      const b0: number = bytes[i];
      if (b0 < 0x80) {
        out += String.fromCharCode(b0);
        i += 1;
      } else if ((b0 & 0xE0) === 0xC0 && i + 1 < bytes.length) {
        const b1: number = bytes[i + 1];
        out += String.fromCharCode(((b0 & 0x1F) << 6) | (b1 & 0x3F));
        i += 2;
      } else if ((b0 & 0xF0) === 0xE0 && i + 2 < bytes.length) {
        const b1: number = bytes[i + 1];
        const b2: number = bytes[i + 2];
        out += String.fromCharCode(((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F));
        i += 3;
      } else {
        out += '?';
        i += 1;
      }
    }
    return out;
  }
}
