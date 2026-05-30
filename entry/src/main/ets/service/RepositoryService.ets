import HttpManager from '../net/HttpManager';
import { Address } from '../net/Address';
import { HttpResult, HttpHeaders } from '../net/Result';
import { UNAUTHORIZED } from '../net/NetworkCode';
import { RepositoryDao } from '../dao/RepositoryDao';
import { IssueDao } from '../dao/IssueDao';
import { ReadResult } from '../dao/DaoBase';
import { Logger } from '../ai-debug/Logger';
import {
  RepositoryDetail,
  RepositoryEventItem,
  RepositoryFileItem,
  RepositoryIssueItem,
  RepositoryCommitItem,
  RepositoryPulseData,
  RepositoryDetailStore,
  ISSUE_STATE_ALL
} from '../store/RepositoryDetailStore';
import { HtmlUtil } from '../utils/HtmlUtil';

const NO_CONTENT: number = 204;
const NOT_FOUND_CODE: number = 404;
const REPO_CACHE_KIND_STAR: number = 1;
const REPO_CACHE_KIND_WATCHER: number = 2;
const REPO_CACHE_KIND_FORK: number = 3;

export interface SubUserItem {
  id: number;
  login: string;
  avatar_url: string;
  html_url: string;
}

export interface SubRepositoryItem {
  id: number;
  name: string;
  full_name: string;
  description: string;
  language: string;
  stargazers_count: number;
  forks_count: number;
  watchers_count: number;
  owner_login: string;
  owner_avatar_url?: string;
}

interface RawOwner {
  login?: string;
  avatar_url?: string;
}

interface RawRepo {
  id?: number;
  name?: string;
  full_name?: string;
  description?: string | null;
  language?: string | null;
  stargazers_count?: number;
  forks_count?: number;
  watchers_count?: number;
  owner?: RawOwner;
}

interface RepositoryIssueSearchResponse {
  total_count?: number;
  incomplete_results?: boolean;
  items?: RepositoryIssueItem[];
}

interface RawSearchRepoResponse {
  items?: RawRepo[];
}

export function normalizeRawRepo(raw: RawRepo): SubRepositoryItem {
  const owner: RawOwner = raw.owner !== undefined && raw.owner !== null ? raw.owner : {};
  return {
    id: raw.id !== undefined && raw.id !== null ? raw.id : 0,
    name: raw.name !== undefined && raw.name !== null ? raw.name : '',
    full_name: raw.full_name !== undefined && raw.full_name !== null ? raw.full_name : '',
    description: raw.description !== undefined && raw.description !== null ? raw.description : '',
    language: raw.language !== undefined && raw.language !== null ? raw.language : '',
    stargazers_count: raw.stargazers_count !== undefined && raw.stargazers_count !== null ? raw.stargazers_count : 0,
    forks_count: raw.forks_count !== undefined && raw.forks_count !== null ? raw.forks_count : 0,
    watchers_count: raw.watchers_count !== undefined && raw.watchers_count !== null ? raw.watchers_count : 0,
    owner_login: owner.login !== undefined && owner.login !== null ? owner.login : '',
    owner_avatar_url: owner.avatar_url !== undefined && owner.avatar_url !== null ? owner.avatar_url : '',
  };
}

export class SubListResult<T> {
  result: boolean;
  code: number;
  data: T[];
  fromCache: boolean;
  msg: string;

  constructor(result: boolean, code: number, data: T[], fromCache: boolean, msg: string) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.fromCache = fromCache;
    this.msg = msg;
  }
}

export class RepoOwnerName {
  owner: string;
  name: string;

  constructor(owner: string, name: string) {
    this.owner = owner;
    this.name = name;
  }

  static parse(fullName: string): RepoOwnerName {
    const safe: string = fullName !== null && fullName !== undefined ? fullName : '';
    const idx: number = safe.indexOf('/');
    if (idx < 0) {
      return new RepoOwnerName(safe, '');
    }
    const owner: string = safe.substring(0, idx);
    const name: string = safe.substring(idx + 1);
    return new RepoOwnerName(owner, name);
  }
}

export class RepositoryServiceResult<T> {
  result: boolean;
  code: number;
  data: T | null;
  fromCache: boolean;
  msg: string;

  constructor(result: boolean, code: number, data: T | null, fromCache: boolean, msg: string) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.fromCache = fromCache;
    this.msg = msg;
  }
}

interface ReadmeRaw {
  content: string;
  encoding: string;
}

export class RepositoryService {
  private store: RepositoryDetailStore;
  private dao: RepositoryDao;
  private issueDao: IssueDao;
  private pageSize: number;

  constructor(store: RepositoryDetailStore,
              dao?: RepositoryDao,
              pageSize?: number,
              issueDao?: IssueDao) {
    this.store = store;
    this.dao = dao !== undefined ? dao : new RepositoryDao();
    this.issueDao = issueDao !== undefined ? issueDao : new IssueDao();
    this.pageSize = pageSize !== undefined && pageSize > 0
      ? pageSize : Address.getRepositoryPageSize();
  }

  getStore(): RepositoryDetailStore {
    return this.store;
  }

  getPageSize(): number {
    return this.pageSize;
  }

  async getReposInfo(fullName: string): Promise<RepositoryServiceResult<RepositoryDetail>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      const msg: string = 'invalid fullName';
      this.store.setError(msg);
      return new RepositoryServiceResult<RepositoryDetail>(false, 0, null, false, msg);
    }
    let cachedDetail: RepositoryDetail | null = null;
    try {
      cachedDetail = await this.readDetailCache(fullName);
      if (cachedDetail !== null) {
        this.store.setDetail(RepositoryService.sanitizeDetail(cachedDetail));
      }
    } catch (_e) {
      cachedDetail = null;
    }
    this.store.startLoading();
    const url: string = Address.getReposDetail(owner.owner, owner.name);
    const httpResult: HttpResult<RepositoryDetail> =
      await HttpManager.getFetch<RepositoryDetail>(url);
    if (httpResult.result && httpResult.data !== null) {
      const detail: RepositoryDetail = RepositoryService.sanitizeDetail(httpResult.data as RepositoryDetail);
      try {
        await this.dao.saveDetail(fullName, JSON.stringify(detail));
      } catch (_e) {
      }
      this.store.setDetail(detail);
      this.store.finishLoading();
      return new RepositoryServiceResult<RepositoryDetail>(true, httpResult.code, detail, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new RepositoryServiceResult<RepositoryDetail>(false, UNAUTHORIZED, null, false, msg);
    }
    if (cachedDetail !== null) {
      const safeCached: RepositoryDetail = RepositoryService.sanitizeDetail(cachedDetail);
      this.store.setDetail(safeCached);
      this.store.finishLoading();
      return new RepositoryServiceResult<RepositoryDetail>(true, httpResult.code, safeCached, true,
        httpResult.msg !== null ? httpResult.msg : '');
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new RepositoryServiceResult<RepositoryDetail>(false, httpResult.code, null, false, failMsg);
  }

  async getReadme(fullName: string,
                  branch: string | null = null): Promise<RepositoryServiceResult<string>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      const msg: string = 'invalid fullName';
      this.store.setReadmeError(msg);
      return new RepositoryServiceResult<string>(false, 0, null, false, msg);
    }
    const url: string = Address.getReposReadme(owner.owner, owner.name, branch);
    Logger.i('ReadmeFlow', `getReadme start fullName=${fullName} branch=${branch} url=${url}`);
    let cachedReadme: string | null = null;
    const defaultBranch: string = this.store.detail !== null
      && this.store.detail.default_branch !== null
      && this.store.detail.default_branch !== undefined
      && this.store.detail.default_branch.length > 0
      ? this.store.detail.default_branch : '';
    const isDefaultBranch: boolean = branch === null || branch.length === 0
      || (defaultBranch.length > 0 && branch === defaultBranch);
    if (isDefaultBranch) {
      try {
        cachedReadme = await this.readReadmeCache(fullName);
        if (cachedReadme !== null) {
          this.store.setReadmeHtml(cachedReadme);
          Logger.i('ReadmeFlow', `getReadme cache-first len=${cachedReadme.length}`);
        }
      } catch (_e) {
        cachedReadme = null;
      }
    }
    if (cachedReadme === null) {
      this.store.startReadmeLoading();
    }
    // Compose ReadmeRepository：默认分支先 emit DB cache，再请求 GitHub HTML 刷新并写回 DB；
    // 非默认分支只走网络，避免把其它分支 README 覆盖到默认分支缓存。
    const headers: HttpHeaders = { 'Accept': 'application/vnd.github.html' };
    const httpResult: HttpResult<string> = await HttpManager.getFetch<string>(url, headers);
    Logger.i('ReadmeFlow',
      `getReadme http result=${httpResult.result} code=${httpResult.code}`
        + ` hasData=${httpResult.data !== null} msg=${httpResult.msg}`);
    if (httpResult.result && httpResult.data !== null) {
      const rawHtml: string = httpResult.data as string;
      const html: string = HtmlUtil.generateHtml(rawHtml);
      Logger.i('ReadmeFlow',
        `getReadme rawHtmlLen=${rawHtml.length} wrappedLen=${html.length}`);
      if (isDefaultBranch) {
        try {
          await this.dao.saveReadme(fullName, html);
        } catch (_e) {
        }
      }
      this.store.setReadmeHtml(html);
      Logger.i('ReadmeFlow',
        `getReadme store.readmeHtml updated len=${this.store.readmeHtml.length}`);
      return new RepositoryServiceResult<string>(true, httpResult.code, html, false, '');
    }
    if (cachedReadme !== null) {
      this.store.setReadmeHtml(cachedReadme);
      Logger.i('ReadmeFlow',
        `getReadme fall back to cache len=${cachedReadme.length}`);
      return new RepositoryServiceResult<string>(true, httpResult.code, cachedReadme, true,
        httpResult.msg !== null ? httpResult.msg : '');
    }
    const msg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    Logger.w('ReadmeFlow', `getReadme failed code=${httpResult.code} msg=${msg}`);
    this.store.setReadmeError(msg);
    return new RepositoryServiceResult<string>(false, httpResult.code, null, false, msg);
  }

  async getStarStatus(fullName: string): Promise<RepositoryServiceResult<boolean>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new RepositoryServiceResult<boolean>(false, 0, false, false, 'invalid fullName');
    }
    const starUrl: string = Address.getStar(owner.owner, owner.name);
    const starResp: HttpResult<Object> = await HttpManager.getFetch<Object>(starUrl);
    const isStarred: boolean = starResp.result || starResp.code === NO_CONTENT;
    this.store.setStarred(isStarred);

    const watchUrl: string = Address.getWatch(owner.owner, owner.name);
    const watchResp: HttpResult<Object> = await HttpManager.getFetch<Object>(watchUrl);
    const isWatching: boolean = watchResp.result || watchResp.code === NO_CONTENT;
    this.store.setWatching(isWatching);

    return new RepositoryServiceResult<boolean>(true, starResp.code, isStarred, false, '');
  }

  async star(fullName: string): Promise<RepositoryServiceResult<boolean>> {
    return this.toggleStar(fullName, true);
  }

  async unstar(fullName: string): Promise<RepositoryServiceResult<boolean>> {
    return this.toggleStar(fullName, false);
  }

  async watch(fullName: string): Promise<RepositoryServiceResult<boolean>> {
    return this.toggleWatch(fullName, true);
  }

  async unwatch(fullName: string): Promise<RepositoryServiceResult<boolean>> {
    return this.toggleWatch(fullName, false);
  }

  private async toggleStar(fullName: string,
                           starred: boolean): Promise<RepositoryServiceResult<boolean>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new RepositoryServiceResult<boolean>(false, 0, false, false, 'invalid fullName');
    }
    const url: string = starred ? Address.setStar(owner.owner, owner.name)
      : Address.setUnstar(owner.owner, owner.name);
    const httpResult: HttpResult<Object> = await HttpManager.netFetch<Object>(url,
      starred ? 'PUT' : 'DELETE', null, false, null);
    const ok: boolean = httpResult.result || httpResult.code === NO_CONTENT;
    if (ok) {
      this.store.setStarred(starred);
      return new RepositoryServiceResult<boolean>(true, httpResult.code, starred, false, '');
    }
    const msg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    return new RepositoryServiceResult<boolean>(false, httpResult.code, this.store.starred, false, msg);
  }

  private async toggleWatch(fullName: string,
                            watching: boolean): Promise<RepositoryServiceResult<boolean>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new RepositoryServiceResult<boolean>(false, 0, false, false, 'invalid fullName');
    }
    const url: string = watching ? Address.setWatch(owner.owner, owner.name)
      : Address.setUnwatch(owner.owner, owner.name);
    const httpResult: HttpResult<Object> = await HttpManager.netFetch<Object>(url,
      watching ? 'PUT' : 'DELETE', null, false, null);
    const ok: boolean = httpResult.result || httpResult.code === NO_CONTENT;
    if (ok) {
      this.store.setWatching(watching);
      return new RepositoryServiceResult<boolean>(true, httpResult.code, watching, false, '');
    }
    const msg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    return new RepositoryServiceResult<boolean>(false, httpResult.code, this.store.watching, false, msg);
  }

  async getRepositoryEvents(fullName: string,
                            page: number): Promise<RepositoryServiceResult<RepositoryEventItem[]>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      const msg: string = 'invalid fullName';
      this.store.setError(msg);
      return new RepositoryServiceResult<RepositoryEventItem[]>(false, 0, [], false, msg);
    }
    const finalPage: number = page > 0 ? page : 1;
    let cachedEvents: RepositoryEventItem[] = [];
    if (finalPage === 1) {
      cachedEvents = await this.readEventCache(fullName);
      if (cachedEvents.length > 0) {
        this.store.applyActivityRefresh(cachedEvents, this.pageSize);
      }
    }
    this.store.startLoading();
    const url: string = Address.getRepositoryEvent(owner.owner, owner.name, finalPage, this.pageSize);
    const httpResult: HttpResult<RepositoryEventItem[]> =
      await HttpManager.getFetch<RepositoryEventItem[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const events: RepositoryEventItem[] = httpResult.data as RepositoryEventItem[];
      if (finalPage === 1) {
        try {
          await this.dao.saveEvent(fullName, JSON.stringify(events));
        } catch (_e) {
        }
        this.store.applyActivityRefresh(events, this.pageSize);
      } else {
        this.store.applyActivityAppend(events, finalPage, this.pageSize);
      }
      return new RepositoryServiceResult<RepositoryEventItem[]>(true, httpResult.code, events, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new RepositoryServiceResult<RepositoryEventItem[]>(false, UNAUTHORIZED, [], false, msg);
    }
    if (cachedEvents.length > 0) {
      this.store.applyActivityRefresh(cachedEvents, this.pageSize);
      return new RepositoryServiceResult<RepositoryEventItem[]>(true, httpResult.code, cachedEvents, true,
        httpResult.msg !== null ? httpResult.msg : '');
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new RepositoryServiceResult<RepositoryEventItem[]>(false, httpResult.code, [], false, failMsg);
  }

  async getRepositoryFiles(fullName: string,
                           path: string): Promise<RepositoryServiceResult<RepositoryFileItem[]>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      const msg: string = 'invalid fullName';
      this.store.setError(msg);
      return new RepositoryServiceResult<RepositoryFileItem[]>(false, 0, [], false, msg);
    }
    this.store.startLoading();
    const safePath: string = path !== null && path !== undefined ? path : '';
    const url: string = Address.getReposFileDir(owner.owner, owner.name, safePath, null);
    const httpResult: HttpResult<RepositoryFileItem[]> =
      await HttpManager.getFetch<RepositoryFileItem[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const files: RepositoryFileItem[] = httpResult.data as RepositoryFileItem[];
      this.store.setFiles(files);
      this.store.finishLoading();
      return new RepositoryServiceResult<RepositoryFileItem[]>(true, httpResult.code, files, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new RepositoryServiceResult<RepositoryFileItem[]>(false, UNAUTHORIZED, [], false, msg);
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new RepositoryServiceResult<RepositoryFileItem[]>(false, httpResult.code, [], false, failMsg);
  }

  async getIssues(fullName: string,
                  state: string | null,
                  page: number,
                  query: string = ''): Promise<RepositoryServiceResult<RepositoryIssueItem[]>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      const msg: string = 'invalid fullName';
      this.store.setError(msg);
      return new RepositoryServiceResult<RepositoryIssueItem[]>(false, 0, [], false, msg);
    }
    const finalPage: number = page > 0 ? page : 1;
    const finalState: string = state !== null && state !== undefined && state.length > 0
      ? state : ISSUE_STATE_ALL;
    const finalQuery: string = query !== null && query !== undefined ? query.trim() : '';
    const useSearch: boolean = finalQuery.length > 0;
    const shouldUseCacheFirst: boolean = finalPage === 1 && !useSearch && finalState === ISSUE_STATE_ALL;
    let cachedIssues: RepositoryIssueItem[] = [];
    if (shouldUseCacheFirst) {
      cachedIssues = await this.readIssueCache(fullName, finalState, finalPage);
      if (cachedIssues.length > 0) {
        this.store.applyIssuesRefresh(cachedIssues, this.pageSize);
        this.store.applyIssueRefresh(cachedIssues, this.pageSize);
      }
    }
    this.store.startLoading();
    this.store.startIssueLoading();
    const url: string = useSearch
      ? Address.getRepositoryIssueSearch(fullName, finalState, finalQuery, finalPage, this.pageSize)
      : Address.getReposIssueByFullName(fullName, finalState, finalPage, this.pageSize);
    const httpResult: HttpResult<RepositoryIssueItem[] | RepositoryIssueSearchResponse> =
      await HttpManager.getFetch<RepositoryIssueItem[] | RepositoryIssueSearchResponse>(url);
    if (httpResult.result && httpResult.data !== null) {
      let issues: RepositoryIssueItem[] = [];
      if (useSearch) {
        const payload: RepositoryIssueSearchResponse = httpResult.data as RepositoryIssueSearchResponse;
        issues = payload.items !== undefined && payload.items !== null ? payload.items : [];
      } else {
        issues = httpResult.data as RepositoryIssueItem[];
      }
      if (finalPage === 1 && !useSearch) {
        try {
          await this.dao.saveIssue(fullName, finalState, finalPage, JSON.stringify(issues));
        } catch (_e) {
        }
        try {
          await this.issueDao.saveRepoIssue(fullName, finalState, finalPage, JSON.stringify(issues));
        } catch (_e) {
        }
      }
      if (finalPage === 1) {
        this.store.applyIssuesRefresh(issues, this.pageSize);
        this.store.applyIssueRefresh(issues, this.pageSize);
      } else {
        this.store.applyIssuesAppend(issues, finalPage, this.pageSize);
        this.store.applyIssueAppend(issues, finalPage, this.pageSize);
      }
      return new RepositoryServiceResult<RepositoryIssueItem[]>(true, httpResult.code, issues, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      this.store.finishIssueLoading();
      return new RepositoryServiceResult<RepositoryIssueItem[]>(false, UNAUTHORIZED, [], false, msg);
    }
    if (finalPage === 1 && !useSearch) {
      if (cachedIssues.length === 0) {
        cachedIssues = await this.readIssueCache(fullName, finalState, finalPage);
      }
      if (cachedIssues.length > 0) {
        this.store.applyIssuesRefresh(cachedIssues, this.pageSize);
        this.store.applyIssueRefresh(cachedIssues, this.pageSize);
        return new RepositoryServiceResult<RepositoryIssueItem[]>(true, httpResult.code, cachedIssues, true,
          httpResult.msg !== null ? httpResult.msg : '');
      }
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    this.store.finishIssueLoading();
    return new RepositoryServiceResult<RepositoryIssueItem[]>(false, httpResult.code, [], false, failMsg);
  }

  /**
   * 创建 Issue —— 对齐 RN [issueActions.createIssue](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryIssueListPage.js#L229-L245)
   * POST /repos/{owner}/{repo}/issues  body={title, body}
   * 成功后将新 issue 插到 store.issues 头部，UI 端通过 @ObjectLink 自动刷新。
   */
  async createIssue(fullName: string,
                    title: string,
                    body: string): Promise<RepositoryServiceResult<RepositoryIssueItem | null>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new RepositoryServiceResult<RepositoryIssueItem | null>(false, 0, null, false, 'invalid fullName');
    }
    const trimmedTitle: string = title === null || title === undefined ? '' : title.trim();
    if (trimmedTitle.length === 0) {
      return new RepositoryServiceResult<RepositoryIssueItem | null>(false, 0, null, false, 'title required');
    }
    const url: string = Address.createIssue(owner.owner, owner.name);
    const params: Record<string, Object> = {
      'title': trimmedTitle,
      'body': body === null || body === undefined ? '' : body,
    };
    const httpResult: HttpResult<RepositoryIssueItem> =
      await HttpManager.netFetch<RepositoryIssueItem>(url, 'POST', params, true, null);
    if (httpResult.result && httpResult.data !== null) {
      const created: RepositoryIssueItem = httpResult.data as RepositoryIssueItem;
      const merged: RepositoryIssueItem[] = [created];
      const current: RepositoryIssueItem[] = this.store.issues;
      for (let i: number = 0; i < current.length; i++) {
        merged.push(current[i]);
      }
      this.store.issues = merged;
      this.store.issueList = merged.slice();
      return new RepositoryServiceResult<RepositoryIssueItem | null>(true, httpResult.code, created, false, '');
    }
    const msg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    return new RepositoryServiceResult<RepositoryIssueItem | null>(false, httpResult.code, null, false, msg);
  }

  /**
   * 获取仓库 commits —— 对齐 Compose RepositoryRepository.getRepositoryCommits：
   * 默认分支第一页先读取本地 DB，再请求网络刷新并写回 DB。
   */
  async getRepositoryCommits(fullName: string,
                             page: number): Promise<RepositoryServiceResult<RepositoryCommitItem[]>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new RepositoryServiceResult<RepositoryCommitItem[]>(false, 0, [], false, 'invalid fullName');
    }
    const finalPage: number = page > 0 ? page : 1;
    const defaultBranch: string = this.store.detail !== null
      && this.store.detail.default_branch !== null
      && this.store.detail.default_branch !== undefined
      && this.store.detail.default_branch.length > 0
      ? this.store.detail.default_branch : '';
    const activeBranch: string = this.store.currentBranch.length > 0 ? this.store.currentBranch : defaultBranch;
    const shouldUseCache: boolean = finalPage === 1 && activeBranch.length > 0 && activeBranch === defaultBranch;
    let cachedCommits: RepositoryCommitItem[] = [];
    if (shouldUseCache) {
      cachedCommits = await this.readCommitsCache(fullName, activeBranch, finalPage);
      if (cachedCommits.length > 0) {
        this.store.applyCommitsRefresh(cachedCommits, this.pageSize);
      }
    }
    this.store.startCommitsLoading();
    const url: string = Address.getReposCommitsPaged(owner.owner, owner.name, finalPage, this.pageSize,
      activeBranch.length > 0 ? activeBranch : null);
    const httpResult: HttpResult<RepositoryCommitItem[]> =
      await HttpManager.getFetch<RepositoryCommitItem[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const items: RepositoryCommitItem[] = httpResult.data as RepositoryCommitItem[];
      if (shouldUseCache) {
        try {
          await this.dao.saveCommits(fullName, activeBranch, finalPage, JSON.stringify(items));
        } catch (_e) {
        }
      }
      if (finalPage === 1) {
        this.store.applyCommitsRefresh(items, this.pageSize);
      } else {
        this.store.applyCommitsAppend(items, finalPage, this.pageSize);
      }
      return new RepositoryServiceResult<RepositoryCommitItem[]>(true, httpResult.code, items, false, '');
    }
    if (cachedCommits.length > 0) {
      this.store.applyCommitsRefresh(cachedCommits, this.pageSize);
      return new RepositoryServiceResult<RepositoryCommitItem[]>(true, httpResult.code, cachedCommits, true,
        httpResult.msg !== null ? httpResult.msg : '');
    }
    this.store.finishCommitsLoading();
    const msg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    return new RepositoryServiceResult<RepositoryCommitItem[]>(false, httpResult.code, [], false, msg);
  }

  /**
   * Pulse 简版：RN 端是抓 GitHub Web Pulse 页 HTML 解析，这里改为
   * 用本仓库已有的 detail.open_issues_count 与近 7 天 closed issues 搜索数做近似聚合。
   * 数据准确度低于 RN，但能给「Pulse」tab 提供可视化卡片。
   */
  async buildPulse(fullName: string): Promise<RepositoryServiceResult<RepositoryPulseData>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      const empty: RepositoryPulseData = { weekOpenedCount: 0, weekClosedCount: 0, description: '' };
      return new RepositoryServiceResult<RepositoryPulseData>(false, 0, empty, false, 'invalid fullName');
    }
    let opened: number = 0;
    let closed: number = 0;
    if (this.store.detail !== null) {
      opened = this.store.detail.open_issues_count;
    }
    const sinceDate: Date = new Date();
    sinceDate.setDate(sinceDate.getDate() - 7);
    const sinceISO: string = sinceDate.toISOString().substring(0, 10);
    const closedQ: string =
      `repo:${owner.owner}/${owner.name}+state:closed+closed:>=${sinceISO}&type=Issues`;
    const closedUrl: string = `${Address.repositoryIssueSearch(closedQ)}`;
    const closedRes: HttpResult<Object> = await HttpManager.getFetch<Object>(closedUrl);
    if (closedRes.result && closedRes.data !== null) {
      const raw: Record<string, Object> = closedRes.data as Record<string, Object>;
      const totalRaw: Object | undefined = raw['total_count'];
      if (totalRaw !== undefined && totalRaw !== null) {
        const parsed: number = Number(totalRaw);
        if (!isNaN(parsed)) {
          closed = parsed;
        }
      }
    }
    const detailDesc: string = (this.store.detail !== null
      && this.store.detail.description !== null
      && this.store.detail.description !== undefined)
      ? this.store.detail.description : '';
    const data: RepositoryPulseData = {
      weekOpenedCount: opened,
      weekClosedCount: closed,
      description: detailDesc,
    };
    this.store.setPulse(data);
    return new RepositoryServiceResult<RepositoryPulseData>(true, 200, data, false, '');
  }

  /**
   * fork 仓库：对齐 Compose `RepoDetailInfoViewModel.forkRepo`，直接
   * POST /repos/:owner/:name/forks，202 Accepted 也算成功。
   */
  async forkRepository(fullName: string): Promise<RepositoryServiceResult<boolean>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new RepositoryServiceResult<boolean>(false, 0, false, false, 'invalid fullName');
    }
    const url: string = Address.createFork(owner.owner, owner.name);
    const httpResult: HttpResult<Object> = await HttpManager.netFetch<Object>(
      url, 'POST', null, false, null);
    const ok: boolean = httpResult.result || httpResult.code === 202 || httpResult.code === NO_CONTENT;
    if (ok) {
      return new RepositoryServiceResult<boolean>(true, httpResult.code, true, false, '');
    }
    const msg: string = httpResult.msg !== null && httpResult.msg !== undefined && httpResult.msg.length > 0
      ? httpResult.msg : 'network error';
    return new RepositoryServiceResult<boolean>(false, httpResult.code, false, false, msg);
  }

  /**
   * 拉分支列表 —— 对齐 RN
   * [repository.getBranches](https://github.com/CarGuo/GSYGithubApp/blob/master/app/store/actions/repository.js)。
   */
  async getBranches(fullName: string): Promise<RepositoryServiceResult<string[]>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new RepositoryServiceResult<string[]>(false, 0, [], false, 'invalid fullName');
    }
    const url: string = Address.getBranches(owner.owner, owner.name);
    const httpResult: HttpResult<Object[]> = await HttpManager.getFetch<Object[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const list: Object[] = httpResult.data as Object[];
      const names: string[] = [];
      for (let i = 0; i < list.length; i++) {
        const raw: Record<string, Object> = list[i] as Record<string, Object>;
        const nameRaw: Object | undefined = raw['name'];
        if (nameRaw !== null && nameRaw !== undefined) {
          names.push(String(nameRaw));
        }
      }
      this.store.setBranches(names);
      return new RepositoryServiceResult<string[]>(true, httpResult.code, names, false, '');
    }
    const msg: string = httpResult.msg !== null && httpResult.msg !== undefined && httpResult.msg.length > 0
      ? httpResult.msg : 'network error';
    return new RepositoryServiceResult<string[]>(false, httpResult.code, [], false, msg);
  }

  async getEvents(fullName: string,
                  page: number): Promise<RepositoryServiceResult<RepositoryEventItem[]>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      const msg: string = 'invalid fullName';
      this.store.setError(msg);
      return new RepositoryServiceResult<RepositoryEventItem[]>(false, 0, [], false, msg);
    }
    const finalPage: number = page > 0 ? page : 1;
    let cachedEvents: RepositoryEventItem[] = [];
    if (finalPage === 1) {
      cachedEvents = await this.readEventCache(fullName);
      if (cachedEvents.length > 0) {
        this.store.applyActivityRefresh(cachedEvents, this.pageSize);
        this.store.applyEventRefresh(cachedEvents, this.pageSize);
      }
    }
    this.store.startEventLoading();
    const url: string = Address.getReposEventsByFullName(fullName, finalPage, this.pageSize);
    const httpResult: HttpResult<RepositoryEventItem[]> =
      await HttpManager.getFetch<RepositoryEventItem[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const events: RepositoryEventItem[] = httpResult.data as RepositoryEventItem[];
      if (finalPage === 1) {
        try {
          await this.dao.saveEvent(fullName, JSON.stringify(events));
        } catch (_e) {
        }
        this.store.applyActivityRefresh(events, this.pageSize);
        this.store.applyEventRefresh(events, this.pageSize);
      } else {
        this.store.applyActivityAppend(events, finalPage, this.pageSize);
        this.store.applyEventAppend(events, finalPage, this.pageSize);
      }
      return new RepositoryServiceResult<RepositoryEventItem[]>(true, httpResult.code, events, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      this.store.finishEventLoading();
      return new RepositoryServiceResult<RepositoryEventItem[]>(false, UNAUTHORIZED, [], false, msg);
    }
    if (finalPage === 1) {
      if (cachedEvents.length > 0) {
        this.store.applyActivityRefresh(cachedEvents, this.pageSize);
        this.store.applyEventRefresh(cachedEvents, this.pageSize);
        return new RepositoryServiceResult<RepositoryEventItem[]>(true, httpResult.code, cachedEvents, true,
          httpResult.msg !== null ? httpResult.msg : '');
      }
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    this.store.finishEventLoading();
    return new RepositoryServiceResult<RepositoryEventItem[]>(false, httpResult.code, [], false, failMsg);
  }

  async getFiles(fullName: string,
                 branch: string | null,
                 path: string | null): Promise<RepositoryServiceResult<RepositoryFileItem[]>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      const msg: string = 'invalid fullName';
      this.store.setError(msg);
      return new RepositoryServiceResult<RepositoryFileItem[]>(false, 0, [], false, msg);
    }
    const safePath: string = path !== null && path !== undefined ? path : '';
    const safeBranch: string | null = branch !== null && branch !== undefined && branch.length > 0
      ? branch : null;
    const defaultBranch: string = this.store.detail !== null
      && this.store.detail.default_branch !== null
      && this.store.detail.default_branch !== undefined
      && this.store.detail.default_branch.length > 0
      ? this.store.detail.default_branch : '';
    const activeBranch: string = safeBranch !== null ? safeBranch : defaultBranch;
    const shouldUseCache: boolean = safePath.length === 0
      && activeBranch.length > 0
      && defaultBranch.length > 0
      && activeBranch === defaultBranch;
    const cacheBranch: string = shouldUseCache ? activeBranch : '';
    let cachedFiles: RepositoryFileItem[] = [];
    if (shouldUseCache) {
      cachedFiles = await this.readFileCache(fullName, cacheBranch, safePath);
      if (cachedFiles.length > 0) {
        this.store.setFiles(cachedFiles);
        this.store.applyFileRefresh(cachedFiles);
      }
    }
    this.store.startFileLoading();
    const url: string = Address.getReposFileDir(owner.owner, owner.name, safePath, safeBranch);
    Logger.i('FilesFlow',
      `getFiles start fullName=${fullName} branch=${safeBranch} path=${safePath} cache=${shouldUseCache} url=${url}`);
    const httpResult: HttpResult<RepositoryFileItem[]> =
      await HttpManager.getFetch<RepositoryFileItem[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const files: RepositoryFileItem[] = httpResult.data as RepositoryFileItem[];
      if (shouldUseCache) {
        try {
          await this.dao.saveFile(fullName, cacheBranch, safePath, JSON.stringify(files));
        } catch (_e) {
        }
      }
      this.store.setFiles(files);
      this.store.applyFileRefresh(files);
      return new RepositoryServiceResult<RepositoryFileItem[]>(true, httpResult.code, files, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      this.store.finishFileLoading();
      return new RepositoryServiceResult<RepositoryFileItem[]>(false, UNAUTHORIZED, [], false, msg);
    }
    if (shouldUseCache && cachedFiles.length > 0) {
      this.store.setFiles(cachedFiles);
      this.store.applyFileRefresh(cachedFiles);
      return new RepositoryServiceResult<RepositoryFileItem[]>(true, httpResult.code, cachedFiles, true,
        httpResult.msg !== null ? httpResult.msg : '');
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    this.store.finishFileLoading();
    return new RepositoryServiceResult<RepositoryFileItem[]>(false, httpResult.code, [], false, failMsg);
  }

  private async readDetailCache(fullName: string): Promise<RepositoryDetail | null> {
    try {
      const cache: ReadResult = await this.dao.readDetail(fullName);
      if (!cache.result || cache.data.length === 0) {
        return null;
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      return parsed as RepositoryDetail;
    } catch (_e) {
      return null;
    }
  }

  private async readReadmeCache(fullName: string): Promise<string | null> {
    try {
      const cache: ReadResult = await this.dao.readReadme(fullName);
      if (!cache.result || cache.data.length === 0) {
        return null;
      }
      return cache.data;
    } catch (_e) {
      return null;
    }
  }

  private async readEventCache(fullName: string): Promise<RepositoryEventItem[]> {
    try {
      const cache: ReadResult = await this.dao.readEvent(fullName);
      if (!cache.result || cache.data.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      if (Array.isArray(parsed)) {
        return parsed as RepositoryEventItem[];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }

  private async readFileCache(fullName: string, branch: string, path: string): Promise<RepositoryFileItem[]> {
    try {
      const cache: ReadResult = await this.dao.readFile(fullName, branch, path);
      if (!cache.result || cache.data.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      if (Array.isArray(parsed)) {
        return parsed as RepositoryFileItem[];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }

  private async readIssueCache(fullName: string, state: string,
    page: number): Promise<RepositoryIssueItem[]> {
    try {
      const cache: ReadResult = await this.dao.readIssue(fullName, state, page);
      if (!cache.result || cache.data.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      if (Array.isArray(parsed)) {
        return parsed as RepositoryIssueItem[];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }

  private async readCommitsCache(fullName: string, branch: string,
    page: number): Promise<RepositoryCommitItem[]> {
    try {
      const cache: ReadResult = await this.dao.readCommits(fullName, branch, page);
      if (!cache.result || cache.data.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      if (Array.isArray(parsed)) {
        return parsed as RepositoryCommitItem[];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }

  private static decodeBase64(content: string): string {
    if (content === null || content === undefined || content.length === 0) {
      return '';
    }
    try {
      const bytes: Uint8Array = RepositoryService.decodeBase64Bytes(content);
      return RepositoryService.decodeUtf8(bytes);
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

  private static safeNum(value: number | undefined | null): number {
    if (value === undefined || value === null) {
      return 0;
    }
    const n: number = Number(value);
    if (!Number.isFinite(n)) {
      return 0;
    }
    return n;
  }

  private static safeStr(value: string | undefined | null): string {
    if (value === undefined || value === null) {
      return '';
    }
    return String(value);
  }

  private static sanitizeDetail(raw: RepositoryDetail): RepositoryDetail {
    const safe: RepositoryDetail = raw;
    safe.id = RepositoryService.safeNum(raw.id);
    safe.name = RepositoryService.safeStr(raw.name);
    safe.full_name = RepositoryService.safeStr(raw.full_name);
    safe.description = RepositoryService.safeStr(raw.description);
    safe.default_branch = RepositoryService.safeStr(raw.default_branch);
    safe.html_url = RepositoryService.safeStr(raw.html_url);
    safe.language = RepositoryService.safeStr(raw.language);
    safe.stargazers_count = RepositoryService.safeNum(raw.stargazers_count);
    safe.watchers_count = RepositoryService.safeNum(raw.watchers_count);
    safe.forks_count = RepositoryService.safeNum(raw.forks_count);
    safe.open_issues_count = RepositoryService.safeNum(raw.open_issues_count);
    safe.subscribers_count = RepositoryService.safeNum(raw.subscribers_count);
    safe.size = RepositoryService.safeNum(raw.size);
    return safe;
  }

  async getStars(fullName: string, page: number): Promise<SubListResult<SubUserItem>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new SubListResult<SubUserItem>(false, 0, [], false, 'invalid fullName');
    }
    const finalPage: number = page > 0 ? page : 1;
    const url: string = Address.getRepositoryStars(owner.owner, owner.name, finalPage, this.pageSize);
    const httpResult: HttpResult<SubUserItem[]> = await HttpManager.getFetch<SubUserItem[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const list: SubUserItem[] = httpResult.data as SubUserItem[];
      if (finalPage === 1) {
        try {
          await this.dao.saveStar(fullName, JSON.stringify(list));
        } catch (_e) {
        }
      }
      return new SubListResult<SubUserItem>(true, httpResult.code, list, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      return new SubListResult<SubUserItem>(false, UNAUTHORIZED, [], false,
        httpResult.msg !== null ? httpResult.msg : 'unauthorized');
    }
    if (finalPage === 1) {
      const cached: SubUserItem[] = await this.readUsersCache(REPO_CACHE_KIND_STAR, fullName);
      if (cached.length > 0) {
        return new SubListResult<SubUserItem>(true, httpResult.code, cached, true,
          httpResult.msg !== null ? httpResult.msg : '');
      }
    }
    return new SubListResult<SubUserItem>(false, httpResult.code, [], false,
      httpResult.msg !== null ? httpResult.msg : 'network error');
  }

  async getForks(fullName: string, page: number): Promise<SubListResult<SubRepositoryItem>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new SubListResult<SubRepositoryItem>(false, 0, [], false, 'invalid fullName');
    }
    const finalPage: number = page > 0 ? page : 1;
    const url: string = Address.getRepositoryForks(owner.owner, owner.name, finalPage, this.pageSize);
    const httpResult: HttpResult<RawRepo[]> =
      await HttpManager.getFetch<RawRepo[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const rawList: RawRepo[] = httpResult.data as RawRepo[];
      const list: SubRepositoryItem[] = [];
      for (let i: number = 0; i < rawList.length; i++) {
        list.push(normalizeRawRepo(rawList[i]));
      }
      if (finalPage === 1) {
        try {
          await this.dao.saveFork(fullName, JSON.stringify(list));
        } catch (_e) {
        }
      }
      return new SubListResult<SubRepositoryItem>(true, httpResult.code, list, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      return new SubListResult<SubRepositoryItem>(false, UNAUTHORIZED, [], false,
        httpResult.msg !== null ? httpResult.msg : 'unauthorized');
    }
    if (finalPage === 1) {
      const cached: SubRepositoryItem[] = await this.readReposCache(REPO_CACHE_KIND_FORK, fullName);
      if (cached.length > 0) {
        return new SubListResult<SubRepositoryItem>(true, httpResult.code, cached, true,
          httpResult.msg !== null ? httpResult.msg : '');
      }
    }
    return new SubListResult<SubRepositoryItem>(false, httpResult.code, [], false,
      httpResult.msg !== null ? httpResult.msg : 'network error');
  }

  async getWatchers(fullName: string, page: number): Promise<SubListResult<SubUserItem>> {
    const owner: RepoOwnerName = RepoOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new SubListResult<SubUserItem>(false, 0, [], false, 'invalid fullName');
    }
    const finalPage: number = page > 0 ? page : 1;
    const url: string = Address.getRepositoryWatchers(owner.owner, owner.name, finalPage, this.pageSize);
    const httpResult: HttpResult<SubUserItem[]> = await HttpManager.getFetch<SubUserItem[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const list: SubUserItem[] = httpResult.data as SubUserItem[];
      if (finalPage === 1) {
        try {
          await this.dao.saveWatcher(fullName, JSON.stringify(list));
        } catch (_e) {
        }
      }
      return new SubListResult<SubUserItem>(true, httpResult.code, list, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      return new SubListResult<SubUserItem>(false, UNAUTHORIZED, [], false,
        httpResult.msg !== null ? httpResult.msg : 'unauthorized');
    }
    if (finalPage === 1) {
      const cached: SubUserItem[] = await this.readUsersCache(REPO_CACHE_KIND_WATCHER, fullName);
      if (cached.length > 0) {
        return new SubListResult<SubUserItem>(true, httpResult.code, cached, true,
          httpResult.msg !== null ? httpResult.msg : '');
      }
    }
    return new SubListResult<SubUserItem>(false, httpResult.code, [], false,
      httpResult.msg !== null ? httpResult.msg : 'network error');
  }

  /**
   * 用户 star 的仓库列表 —— 对齐 RN [ListPage.user_star 分支](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ListPage.js#L236-L247)
   * GET /users/:login/starred?sort=updated&page=N&per_page=30
   */
  async getUserStarredRepos(login: string, page: number): Promise<SubListResult<SubRepositoryItem>> {
    if (login.length === 0) {
      return new SubListResult<SubRepositoryItem>(false, 0, [], false, 'invalid login');
    }
    const finalPage: number = page > 0 ? page : 1;
    const url: string = Address.getUserStarred(login, finalPage, this.pageSize);
    const httpResult: HttpResult<RawRepo[]> = await HttpManager.getFetch<RawRepo[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const rawList: RawRepo[] = httpResult.data as RawRepo[];
      const normalized: SubRepositoryItem[] = [];
      for (let i: number = 0; i < rawList.length; i++) {
        normalized.push(normalizeRawRepo(rawList[i]));
      }
      return new SubListResult<SubRepositoryItem>(true, httpResult.code, normalized, false, '');
    }
    return new SubListResult<SubRepositoryItem>(false, httpResult.code, [], false,
      httpResult.msg !== null ? httpResult.msg : 'network error');
  }

  async searchTopicRepos(topic: string, page: number): Promise<SubListResult<SubRepositoryItem>> {
    const safeTopic: string = topic !== null && topic !== undefined ? topic.trim() : '';
    if (safeTopic.length === 0) {
      return new SubListResult<SubRepositoryItem>(false, 0, [], false, 'invalid topic');
    }
    const finalPage: number = page > 0 ? page : 1;
    const url: string = Address.search('topic:' + safeTopic, 'stars', 'desc',
      null, finalPage, this.pageSize);
    const httpResult: HttpResult<RawSearchRepoResponse> =
      await HttpManager.getFetch<RawSearchRepoResponse>(url);
    if (httpResult.result && httpResult.data !== null) {
      const payload: RawSearchRepoResponse = httpResult.data as RawSearchRepoResponse;
      const rawList: RawRepo[] = payload.items !== undefined && payload.items !== null
        ? payload.items
        : [];
      const normalized: SubRepositoryItem[] = [];
      for (let i: number = 0; i < rawList.length; i++) {
        normalized.push(normalizeRawRepo(rawList[i]));
      }
      return new SubListResult<SubRepositoryItem>(true, httpResult.code, normalized, false, '');
    }
    return new SubListResult<SubRepositoryItem>(false, httpResult.code, [], false,
      httpResult.msg !== null ? httpResult.msg : 'network error');
  }

  private async readUsersCache(kind: number, fullName: string): Promise<SubUserItem[]> {
    try {
      let cache: ReadResult;
      if (kind === REPO_CACHE_KIND_STAR) {
        cache = await this.dao.readStar(fullName);
      } else {
        cache = await this.dao.readWatcher(fullName);
      }
      if (!cache.result || cache.data.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      if (Array.isArray(parsed)) {
        return parsed as SubUserItem[];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }

  private async readReposCache(kind: number, fullName: string): Promise<SubRepositoryItem[]> {
    try {
      let cache: ReadResult;
      if (kind === REPO_CACHE_KIND_FORK) {
        cache = await this.dao.readFork(fullName);
      } else {
        return [];
      }
      if (!cache.result || cache.data.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      if (Array.isArray(parsed)) {
        return parsed as SubRepositoryItem[];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }

  static async fetchRepositoryRelease(owner: string,
                                      name: string,
                                      page: number): Promise<FetchReleaseListResult> {
    return RepositoryService.fetchReleaseLike(owner, name, page, true);
  }

  static async fetchRepositoryTag(owner: string,
                                  name: string,
                                  page: number): Promise<FetchReleaseListResult> {
    return RepositoryService.fetchReleaseLike(owner, name, page, false);
  }

  private static async fetchReleaseLike(owner: string,
                                        name: string,
                                        page: number,
                                        isRelease: boolean): Promise<FetchReleaseListResult> {
    if (owner.length === 0 || name.length === 0) {
      return new FetchReleaseListResult(false, 0, [], 'empty owner/name');
    }
    const baseUrl: string = isRelease
      ? Address.getReposRelease(owner, name)
      : Address.getReposTag(owner, name);
    const url: string = baseUrl + Address.getPageParams('?', page);
    const acceptValue: string = 'application/vnd.github.html,application/vnd.github.VERSION.raw';
    const headers: Record<string, string> = {};
    headers['Accept'] = acceptValue;
    const httpResult: HttpResult<Object[]> = await HttpManager.netFetch<Object[]>(
      url, 'GET', null, false, headers);
    if (httpResult.result && httpResult.data !== null) {
      const arr: Object[] = httpResult.data as Object[];
      const list: ReleaseListItem[] = [];
      for (let i: number = 0; i < arr.length; i++) {
        list.push(ReleaseListItem.fromRaw(arr[i]));
      }
      return new FetchReleaseListResult(true, httpResult.code, list, '');
    }
    return new FetchReleaseListResult(false, httpResult.code, [],
      httpResult.msg !== null ? httpResult.msg : 'network error');
  }
}

export class ReleaseListItem {
  id: number = 0;
  name: string = '';
  tagName: string = '';
  publishedAt: string = '';
  bodyHtml: string = '';
  htmlUrl: string = '';
  cloneUrl: string = '';

  static fromRaw(raw: Object): ReleaseListItem {
    const item: ReleaseListItem = new ReleaseListItem();
    const obj: Record<string, Object> = raw as Record<string, Object>;
    const idVal: Object | undefined = obj['id'];
    if (typeof idVal === 'number') {
      item.id = idVal as number;
    }
    const nameVal: Object | undefined = obj['name'];
    if (typeof nameVal === 'string') {
      item.name = nameVal as string;
    }
    const tagVal: Object | undefined = obj['tag_name'];
    if (typeof tagVal === 'string') {
      item.tagName = tagVal as string;
    }
    const pubVal: Object | undefined = obj['published_at'];
    if (typeof pubVal === 'string') {
      item.publishedAt = pubVal as string;
    } else {
      const createdVal: Object | undefined = obj['created_at'];
      if (typeof createdVal === 'string') {
        item.publishedAt = createdVal as string;
      }
    }
    const bodyVal: Object | undefined = obj['body_html'];
    if (typeof bodyVal === 'string') {
      item.bodyHtml = bodyVal as string;
    } else {
      const bodyRaw: Object | undefined = obj['body'];
      if (typeof bodyRaw === 'string') {
        item.bodyHtml = bodyRaw as string;
      }
    }
    const htmlUrlVal: Object | undefined = obj['html_url'];
    if (typeof htmlUrlVal === 'string') {
      item.htmlUrl = htmlUrlVal as string;
    }
    const cloneUrlVal: Object | undefined = obj['clone_url'];
    if (typeof cloneUrlVal === 'string') {
      item.cloneUrl = cloneUrlVal as string;
    }
    return item;
  }

  resolveTitle(): string {
    if (this.name.length > 0) {
      return this.name;
    }
    return this.tagName;
  }
}

export class FetchReleaseListResult {
  result: boolean;
  code: number;
  data: ReleaseListItem[];
  msg: string;

  constructor(result: boolean, code: number, data: ReleaseListItem[], msg: string) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.msg = msg;
  }
}
