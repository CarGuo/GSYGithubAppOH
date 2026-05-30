import HttpManager from '../net/HttpManager';
import { Address } from '../net/Address';
import { HttpResult } from '../net/Result';
import { UNAUTHORIZED } from '../net/NetworkCode';
import { RecommendRepo, RecommendSearchResponse, RecommendStore } from '../store/RecommendStore';

export const RECOMMEND_DEFAULT_QUERY: string = 'stars:>1';
export const RECOMMEND_DEFAULT_SORT: string = 'stars';

export class FetchRecommendResult {
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

export class RecommendService {
  private store: RecommendStore;
  private pageSize: number;
  private query: string;
  private sort: string;

  constructor(store: RecommendStore, pageSize?: number, query?: string, sort?: string) {
    this.store = store;
    this.pageSize = pageSize !== undefined && pageSize > 0 ? pageSize : Address.getSearchReposPageSize();
    this.query = query !== undefined && query.length > 0 ? query : RECOMMEND_DEFAULT_QUERY;
    this.sort = sort !== undefined && sort.length > 0 ? sort : RECOMMEND_DEFAULT_SORT;
  }

  getStore(): RecommendStore {
    return this.store;
  }

  getPageSize(): number {
    return this.pageSize;
  }

  getQuery(): string {
    return this.query;
  }

  getSort(): string {
    return this.sort;
  }

  async fetchRecommend(page: number): Promise<FetchRecommendResult> {
    const finalPage: number = page > 0 ? page : 1;
    this.store.startLoading();

    const url: string = Address.getSearchRepos(this.query, this.sort, finalPage, this.pageSize);
    const httpResult: HttpResult<RecommendSearchResponse> =
      await HttpManager.getFetch<RecommendSearchResponse>(url);

    if (httpResult.result && httpResult.data !== null) {
      const payload: RecommendSearchResponse = httpResult.data as RecommendSearchResponse;
      const items: RecommendRepo[] = payload.items !== undefined && payload.items !== null
        ? payload.items
        : [];
      if (finalPage === 1) {
        this.store.applyRefresh(items, this.pageSize);
      } else {
        this.store.applyAppend(items, finalPage, this.pageSize);
      }
      return new FetchRecommendResult(true, httpResult.code, items, '');
    }

    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new FetchRecommendResult(false, UNAUTHORIZED, [], msg);
    }

    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new FetchRecommendResult(false, httpResult.code, [], failMsg);
  }
}
