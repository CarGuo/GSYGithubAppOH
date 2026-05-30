import HttpManager from '../net/HttpManager';
import { Address } from '../net/Address';
import { HttpResult } from '../net/Result';
import { UNAUTHORIZED } from '../net/NetworkCode';
import { RecommendRepo, RecommendSearchResponse } from '../store/RecommendStore';
import {
  SearchStore,
  SearchTab,
  SEARCH_TAB_REPO,
  SEARCH_TAB_USER,
  SEARCH_TAB_ISSUE,
  SearchUserItem,
  SearchUserSearchResponse,
  SearchIssueItem,
  SearchIssueSearchResponse,
} from '../store/SearchStore';

export class SearchRepoResult {
  result: boolean;
  code: number;
  data: RecommendRepo[];
  msg: string;
  fromCache: boolean;

  constructor(result: boolean, code: number, data: RecommendRepo[], msg: string, fromCache: boolean = false) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.msg = msg;
    this.fromCache = fromCache;
  }
}

export class SearchUserResult {
  result: boolean;
  code: number;
  data: SearchUserItem[];
  msg: string;
  fromCache: boolean;

  constructor(result: boolean, code: number, data: SearchUserItem[], msg: string, fromCache: boolean = false) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.msg = msg;
    this.fromCache = fromCache;
  }
}

export class SearchIssueResult {
  result: boolean;
  code: number;
  data: SearchIssueItem[];
  msg: string;
  fromCache: boolean;

  constructor(result: boolean, code: number, data: SearchIssueItem[], msg: string, fromCache: boolean = false) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.msg = msg;
    this.fromCache = fromCache;
  }
}

export class SearchService {
  private store: SearchStore;
  private pageSize: number;

  constructor(store: SearchStore, pageSize?: number) {
    this.store = store;
    this.pageSize = pageSize !== undefined && pageSize > 0
      ? pageSize
      : Address.getSearchReposPageSize();
  }

  getStore(): SearchStore {
    return this.store;
  }

  getPageSize(): number {
    return this.pageSize;
  }

  getCurrentTab(): SearchTab {
    return this.store.tab;
  }

  async searchRepo(q: string,
                   sort: string | null,
                   page: number): Promise<SearchRepoResult> {
    const finalPage: number = page > 0 ? page : 1;
    this.store.startLoading();
    const url: string = Address.getSearchRepos(q, sort, finalPage, this.pageSize);
    const httpResult: HttpResult<RecommendSearchResponse> =
      await HttpManager.getFetch<RecommendSearchResponse>(url);

    if (httpResult.result && httpResult.data !== null) {
      const payload: RecommendSearchResponse = httpResult.data as RecommendSearchResponse;
      const items: RecommendRepo[] = payload.items !== undefined && payload.items !== null
        ? payload.items
        : [];
      if (finalPage === 1) {
        this.store.applyReposRefresh(items, this.pageSize);
      } else {
        this.store.applyReposAppend(items, finalPage, this.pageSize);
      }
      return new SearchRepoResult(true, httpResult.code, items, '');
    }

    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new SearchRepoResult(false, UNAUTHORIZED, [], msg);
    }

    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new SearchRepoResult(false, httpResult.code, [], failMsg);
  }

  async searchUser(q: string,
                   sort: string | null,
                   page: number): Promise<SearchUserResult> {
    const finalPage: number = page > 0 ? page : 1;
    this.store.startLoading();
    const url: string = Address.getSearchUsers(q, sort, finalPage, this.pageSize);
    const httpResult: HttpResult<SearchUserSearchResponse> =
      await HttpManager.getFetch<SearchUserSearchResponse>(url);

    if (httpResult.result && httpResult.data !== null) {
      const payload: SearchUserSearchResponse = httpResult.data as SearchUserSearchResponse;
      const items: SearchUserItem[] = payload.items !== undefined && payload.items !== null
        ? payload.items
        : [];
      if (finalPage === 1) {
        this.store.applyUsersRefresh(items, this.pageSize);
      } else {
        this.store.applyUsersAppend(items, finalPage, this.pageSize);
      }
      return new SearchUserResult(true, httpResult.code, items, '');
    }

    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new SearchUserResult(false, UNAUTHORIZED, [], msg);
    }

    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new SearchUserResult(false, httpResult.code, [], failMsg);
  }

  async searchIssue(q: string,
                    sort: string | null,
                    page: number): Promise<SearchIssueResult> {
    const finalPage: number = page > 0 ? page : 1;
    this.store.startLoading();
    const url: string = Address.getSearchIssues(q, sort, finalPage, this.pageSize);
    const httpResult: HttpResult<SearchIssueSearchResponse> =
      await HttpManager.getFetch<SearchIssueSearchResponse>(url);

    if (httpResult.result && httpResult.data !== null) {
      const payload: SearchIssueSearchResponse = httpResult.data as SearchIssueSearchResponse;
      const items: SearchIssueItem[] = payload.items !== undefined && payload.items !== null
        ? payload.items
        : [];
      if (finalPage === 1) {
        this.store.applyIssuesRefresh(items, this.pageSize);
      } else {
        this.store.applyIssuesAppend(items, finalPage, this.pageSize);
      }
      return new SearchIssueResult(true, httpResult.code, items, '');
    }

    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new SearchIssueResult(false, UNAUTHORIZED, [], msg);
    }

    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new SearchIssueResult(false, httpResult.code, [], failMsg);
  }

  async searchByTab(tab: SearchTab,
                    q: string,
                    sort: string | null,
                    page: number): Promise<boolean> {
    if (tab === SEARCH_TAB_REPO) {
      const r: SearchRepoResult = await this.searchRepo(q, sort, page);
      return r.result;
    }
    if (tab === SEARCH_TAB_USER) {
      const r: SearchUserResult = await this.searchUser(q, sort, page);
      return r.result;
    }
    if (tab === SEARCH_TAB_ISSUE) {
      const r: SearchIssueResult = await this.searchIssue(q, sort, page);
      return r.result;
    }
    return false;
  }
}
