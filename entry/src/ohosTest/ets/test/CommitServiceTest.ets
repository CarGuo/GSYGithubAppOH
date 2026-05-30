import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
  TokenStorage,
  LoginExpiredBus,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS, NETWORK_ERROR } from '../../../main/ets/net/NetworkCode';
import { Address } from '../../../main/ets/net/Address';
import {
  CommitService,
  CommitServiceResult,
  COMMIT_DIFF_ACCEPT,
  CommitCacheDao,
} from '../../../main/ets/service/CommitService';
import {
  CommitDetail,
  PushDetailStore,
} from '../../../main/ets/store/PushDetailStore';
import {
  CodeService,
  CodeServiceResult,
} from '../../../main/ets/service/CodeService';
import { CodeDetailStore } from '../../../main/ets/store/CodeDetailStore';
import { ReadResult } from '../../../main/ets/dao/DaoBase';

class CapturedRequest {
  url: string = '';
  method: string = '';
  acceptHeader: string = '';
}

class FakeHttpProvider implements HttpProvider {
  nextStatus: number = SUCCESS;
  nextBody: string = '';
  callCount: number = 0;
  captured: CapturedRequest = new CapturedRequest();
  capturedAll: CapturedRequest[] = [];
  responses: RawResponse[] = [];

  pushResponse(status: number, body: string): void {
    this.responses.push(new RawResponse(status, body, {}));
  }

  async request(url: string,
                method: string,
                headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    this.captured.url = url;
    this.captured.method = method;
    const accept: string | undefined = headers['Accept'];
    this.captured.acceptHeader = accept !== undefined ? accept : '';
    const cap: CapturedRequest = new CapturedRequest();
    cap.url = url;
    cap.method = method;
    cap.acceptHeader = this.captured.acceptHeader;
    this.capturedAll.push(cap);
    if (this.responses.length > 0) {
      const head: RawResponse | undefined = this.responses.shift();
      return head as RawResponse;
    }
    return new RawResponse(this.nextStatus, this.nextBody, {});
  }
}

class FakeTokenStorage implements TokenStorage {
  value: string | null = null;

  async load(): Promise<string | null> {
    return this.value;
  }

  async save(token: string): Promise<void> {
    this.value = token;
  }

  async clear(): Promise<void> {
    this.value = null;
  }
}

class FakeCommitCacheDao implements CommitCacheDao {
  data: string = '';
  saveCount: number = 0;
  readCount: number = 0;
  savedFullName: string = '';
  savedSha: string = '';

  async saveCommitInfoDetail(fullName: string, sha: string, jsonString: string): Promise<number> {
    this.saveCount = this.saveCount + 1;
    this.savedFullName = fullName;
    this.savedSha = sha;
    this.data = jsonString;
    return this.saveCount;
  }

  async readCommitInfoDetail(_fullName: string, _sha: string): Promise<ReadResult> {
    this.readCount = this.readCount + 1;
    if (this.data.length === 0) {
      return { result: false, data: '', updateAt: 0 } as ReadResult;
    }
    return { result: true, data: this.data, updateAt: 1 } as ReadResult;
  }
}

const FULL_NAME: string = 'CarGuo/GSYGithubApp';
const OWNER: string = 'CarGuo';
const REPO_NAME: string = 'GSYGithubApp';
const SHA: string = 'abc1234567890';
const BRANCH: string = 'master';
const PATH: string = 'README.md';
const CODE_PATH: string = 'entry/src/main/ets/pages/HomePage.ets';

function buildCommitDetailBody(): string {
  return '{"sha":"' + SHA + '",' +
    '"html_url":"https://github.com/' + FULL_NAME + '/commit/' + SHA + '",' +
    '"commit":{' +
      '"message":"unit test commit",' +
      '"author":{"name":"AuthorName","email":"author@example.com","date":"2024-01-02T03:04:05Z"},' +
      '"committer":{"name":"CommitterName","email":"committer@example.com","date":"2024-01-02T03:04:05Z"}' +
    '},' +
    '"author":{"login":"AuthorLogin","avatar_url":"","html_url":""},' +
    '"committer":{"login":"CommitterLogin","avatar_url":"","html_url":""},' +
    '"files":[{"filename":"README.md","status":"modified","additions":5,"deletions":1,' +
      '"changes":6,"blob_url":"","raw_url":"","patch":"@@ patch @@","sha":"sha-readme"}],' +
    '"stats":{"additions":5,"deletions":1,"total":6}' +
  '}';
}

export default function CommitServiceTest(): void {
  describe('CommitServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let pushStore: PushDetailStore;
    let commitService: CommitService;
    let commitCacheDao: FakeCommitCacheDao;
    let codeStore: CodeDetailStore;
    let codeService: CodeService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      pushStore = new PushDetailStore();
      commitCacheDao = new FakeCommitCacheDao();
      commitService = new CommitService(pushStore, commitCacheDao);
      codeStore = new CodeDetailStore();
      codeService = new CodeService(codeStore);

      HttpManager.setMockProvider(provider);
      HttpManager.setTokenStorage(storage);
      HttpManager.setTimeout(15000);
      HttpManager.setAuthorization(null);
      LoginExpiredBus.clear();
    });

    afterEach((): void => {
      HttpManager.setMockProvider(null);
      LoginExpiredBus.clear();
    });

    it('getCommitDetail_uses_commit_url_and_updates_store', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = buildCommitDetailBody();

      const res: CommitServiceResult<CommitDetail> =
        await commitService.getCommitDetail(FULL_NAME, SHA);

      expect(provider.captured.url).assertEqual(Address.getCommitDetail(OWNER, REPO_NAME, SHA));
      expect(provider.captured.method).assertEqual('GET');
      expect(res.result).assertTrue();
      expect(pushStore.commit !== null).assertTrue();
      expect(pushStore.files.length).assertEqual(1);
      expect(pushStore.files[0].filename).assertEqual('README.md');
      expect(commitCacheDao.saveCount).assertEqual(1);
      expect(commitCacheDao.savedFullName).assertEqual(FULL_NAME);
      expect(commitCacheDao.savedSha).assertEqual(SHA);
    });

    it('getCommitDetail_emits_cache_first_then_network_updates_cache', 0, async (): Promise<void> => {
      commitCacheDao.data = buildCommitDetailBody().replace('unit test commit', 'cached commit');
      provider.nextStatus = SUCCESS;
      provider.nextBody = buildCommitDetailBody();

      const res: CommitServiceResult<CommitDetail> =
        await commitService.getCommitDetail(FULL_NAME, SHA);

      expect(provider.callCount).assertEqual(1);
      expect(res.result).assertTrue();
      expect(res.fromCache).assertFalse();
      expect(pushStore.commit !== null).assertTrue();
      expect((pushStore.commit as CommitDetail).commit.message).assertEqual('unit test commit');
      expect(commitCacheDao.readCount).assertEqual(1);
      expect(commitCacheDao.saveCount).assertEqual(1);
    });

    it('getCommitDetail_falls_back_to_cached_commit_when_network_fails', 0, async (): Promise<void> => {
      commitCacheDao.data = buildCommitDetailBody().replace('unit test commit', 'cached commit');
      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: CommitServiceResult<CommitDetail> =
        await commitService.getCommitDetail(FULL_NAME, SHA);

      expect(provider.callCount).assertEqual(1);
      expect(res.result).assertTrue();
      expect(res.fromCache).assertTrue();
      expect(pushStore.error.length).assertEqual(0);
      expect(pushStore.commit !== null).assertTrue();
      expect((pushStore.commit as CommitDetail).commit.message).assertEqual('cached commit');
    });

    it('getCommitDetail_invalid_full_name_sets_error', 0, async (): Promise<void> => {
      const res: CommitServiceResult<CommitDetail> =
        await commitService.getCommitDetail('', SHA);
      expect(res.result).assertFalse();
      expect(pushStore.error.length > 0).assertTrue();
    });

    it('getCommitDetail_failure_sets_error', 0, async (): Promise<void> => {
      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: CommitServiceResult<CommitDetail> =
        await commitService.getCommitDetail(FULL_NAME, SHA);

      expect(res.result).assertFalse();
      expect(pushStore.error.length > 0).assertTrue();
    });

    it('getCommitDiff_uses_diff_accept_header', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = 'diff --git a/x b/x\n';

      const res: CommitServiceResult<string> =
        await commitService.getCommitDiff(FULL_NAME, SHA);

      expect(provider.captured.url).assertEqual(Address.getCommitDiff(OWNER, REPO_NAME, SHA));
      expect(provider.captured.method).assertEqual('GET');
      expect(provider.captured.acceptHeader).assertEqual(COMMIT_DIFF_ACCEPT);
      expect(res.result).assertTrue();
      expect(res.data !== null).assertTrue();
      expect((res.data as string).indexOf('diff --git') >= 0).assertTrue();
    });

    it('getCommitDiff_invalid_param_returns_false', 0, async (): Promise<void> => {
      const res: CommitServiceResult<string> = await commitService.getCommitDiff('', '');
      expect(res.result).assertFalse();
    });

    it('Address_getRawFile_uses_raw_host_with_branch_and_path', 0, (): void => {
      const url: string = Address.getRawFile(OWNER, REPO_NAME, BRANCH, PATH);
      expect(url.indexOf('https://github.com/') === 0).assertTrue();
      expect(url.indexOf('/raw/' + BRANCH + '/' + PATH) >= 0).assertTrue();
    });

    it('Address_getCommitDetail_and_getCommitDiff_share_url_pattern', 0, (): void => {
      const detailUrl: string = Address.getCommitDetail(OWNER, REPO_NAME, SHA);
      const diffUrl: string = Address.getCommitDiff(OWNER, REPO_NAME, SHA);
      expect(detailUrl.indexOf('/commits/' + SHA) >= 0).assertTrue();
      expect(diffUrl.indexOf('/commits/' + SHA) >= 0).assertTrue();
    });

    it('Address_getReposCommitsPaged_adds_branch_sha_query', 0, (): void => {
      const url: string = Address.getReposCommitsPaged(OWNER, REPO_NAME, 1, 30, 'feature/a b');
      expect(url.indexOf('/commits?page=1&per_page=30') >= 0).assertTrue();
      expect(url.indexOf('&sha=feature%2Fa%20b') >= 0).assertTrue();
    });

    it('CodeService_getRawContent_succeeds_via_github_html_contents_api', 0, async (): Promise<void> => {
      provider.pushResponse(SUCCESS, '<h1>Hello</h1><p>print("hi")</p>');

      const res: CodeServiceResult<string> =
        await codeService.getRawContent(FULL_NAME, BRANCH, PATH);

      expect(res.result).assertTrue();
      expect(provider.capturedAll[0].url)
        .assertEqual(Address.getReposFileDir(OWNER, REPO_NAME, PATH, BRANCH));
      expect(provider.capturedAll[0].method).assertEqual('GET');
      expect(provider.capturedAll[0].acceptHeader).assertEqual('application/vnd.github.html');
      expect(codeStore.content.length > 0).assertTrue();
      expect(codeStore.htmlContent.length > 0).assertTrue();
      expect(codeStore.path).assertEqual(PATH);
    });

    it('CodeService_getRawContent_falls_back_to_contents_api_when_html_and_raw_fail', 0,
      async (): Promise<void> => {
        provider.pushResponse(404, '');
        provider.pushResponse(404, '');
        provider.pushResponse(SUCCESS, JSON.stringify({
          'content': 'IyBIZWxsbwo=',
          'encoding': 'base64',
          'path': PATH,
          'name': PATH,
        }));

        const res: CodeServiceResult<string> =
          await codeService.getRawContent(FULL_NAME, BRANCH, CODE_PATH);

        expect(res.result).assertTrue();
        expect(provider.callCount).assertEqual(3);
        expect(provider.capturedAll[0].url)
          .assertEqual(Address.getReposFileDir(OWNER, REPO_NAME, CODE_PATH, BRANCH));
        expect(provider.capturedAll[1].url)
          .assertEqual(Address.getRawFile(OWNER, REPO_NAME, BRANCH, CODE_PATH));
        expect(provider.capturedAll[2].url)
          .assertEqual(Address.getReposFileDir(OWNER, REPO_NAME, CODE_PATH, BRANCH));
        expect(codeStore.content.indexOf('Hello') >= 0).assertTrue();
        expect(codeStore.htmlContent.length > 0).assertTrue();
      });

    it('CodeService_getRawContent_markdown_does_not_fallback_to_raw_source', 0,
      async (): Promise<void> => {
        provider.pushResponse(404, '');
        provider.pushResponse(SUCCESS, '# Hello');

        const res: CodeServiceResult<string> =
          await codeService.getRawContent(FULL_NAME, BRANCH, PATH);

        expect(res.result).assertFalse();
        expect(provider.callCount).assertEqual(1);
        expect(provider.capturedAll[0].acceptHeader).assertEqual('application/vnd.github.html');
        expect(codeStore.content.length).assertEqual(0);
        expect(codeStore.error.length > 0).assertTrue();
      });

    it('CodeService_getCommitFile_loads_patch_from_commit_sha_like_compose', 0,
      async (): Promise<void> => {
        provider.pushResponse(SUCCESS, buildCommitDetailBody());

        const res: CodeServiceResult<string> =
          await codeService.getCommitFile(FULL_NAME, SHA, PATH);

        expect(res.result).assertTrue();
        expect(provider.callCount).assertEqual(1);
        expect(provider.captured.url).assertEqual(Address.getCommitDetail(OWNER, REPO_NAME, SHA));
        expect(provider.captured.method).assertEqual('GET');
        expect(codeStore.path).assertEqual(PATH);
        expect(codeStore.content).assertEqual('@@ patch @@');
        expect(codeStore.htmlContent.indexOf('@@ patch @@') >= 0).assertTrue();
      });

    it('CodeService_getCommitFile_missing_file_sets_error', 0,
      async (): Promise<void> => {
        provider.pushResponse(SUCCESS, buildCommitDetailBody());

        const res: CodeServiceResult<string> =
          await codeService.getCommitFile(FULL_NAME, SHA, 'missing.txt');

        expect(res.result).assertFalse();
        expect(codeStore.error).assertEqual('File not found in commit');
      });

    it('CodeService_getRawContent_invalid_full_name_returns_false', 0,
      async (): Promise<void> => {
        const res: CodeServiceResult<string> =
          await codeService.getRawContent('', BRANCH, PATH);
        expect(res.result).assertFalse();
        expect(codeStore.error.length > 0).assertTrue();
      });

    it('CodeService_getRawContent_failure_sets_error', 0, async (): Promise<void> => {
      provider.pushResponse(NETWORK_ERROR, '');
      provider.pushResponse(NETWORK_ERROR, '');

      const res: CodeServiceResult<string> =
        await codeService.getRawContent(FULL_NAME, BRANCH, PATH);

      expect(res.result).assertFalse();
      expect(codeStore.error.length > 0).assertTrue();
    });

    it('CodeService_guessLangByPath_returns_markdown_for_md', 0, (): void => {
      expect(CodeService.guessLangByPath('README.md')).assertEqual('markdown');
      expect(CodeService.guessLangByPath('a/b.markdown')).assertEqual('markdown');
    });

    it('CodeService_guessLangByPath_returns_typescript_for_ts_and_ets', 0, (): void => {
      expect(CodeService.guessLangByPath('a/b.ts')).assertEqual('typescript');
      expect(CodeService.guessLangByPath('a/b.ets')).assertEqual('typescript');
    });

    it('CodeService_decodeBase64_decodes_utf8', 0, (): void => {
      const decoded: string = CodeService.decodeBase64('IyBIZWxsbwo=');
      expect(decoded.indexOf('Hello') >= 0).assertTrue();
    });

    it('PushDetailStore_setCommit_copies_files', 0, (): void => {
      const store: PushDetailStore = new PushDetailStore();
      const detail: CommitDetail = {
        'sha': SHA,
        'html_url': '',
        'commit': {
          'message': 'm',
          'author': { 'name': 'a', 'email': 'a@a', 'date': 'd' },
          'committer': { 'name': 'c', 'email': 'c@c', 'date': 'd' },
        },
        'author': null,
        'committer': null,
        'files': [
          {
            'filename': 'x',
            'status': 'modified',
            'additions': 1,
            'deletions': 1,
            'changes': 2,
            'blob_url': '',
            'raw_url': '',
            'patch': '',
            'sha': 'sx',
          },
        ],
        'stats': { 'additions': 1, 'deletions': 1, 'total': 2 },
      } as CommitDetail;
      store.setCommit(detail);
      expect(store.files.length).assertEqual(1);
      expect(store.commit !== null).assertTrue();
      expect(store.loading).assertFalse();
    });

    it('CodeDetailStore_setContent_clears_loading_and_error', 0, (): void => {
      const store: CodeDetailStore = new CodeDetailStore();
      store.startLoading();
      store.setError('e');
      store.setContent('raw', '<html></html>');
      expect(store.content).assertEqual('raw');
      expect(store.htmlContent).assertEqual('<html></html>');
      expect(store.loading).assertFalse();
      expect(store.error.length).assertEqual(0);
    });
  });
}
