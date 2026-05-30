import HttpManager from '../net/HttpManager';
import { Address } from '../net/Address';
import { HttpResult } from '../net/Result';
import { UNAUTHORIZED } from '../net/NetworkCode';
import { DynamicDao } from '../dao/DynamicDao';
import { ReadResult } from '../dao/DaoBase';
import { DynamicEvent, DynamicStore } from '../store/DynamicStore';

export class FetchReceivedResult {
  result: boolean;
  code: number;
  data: DynamicEvent[];
  fromCache: boolean;
  msg: string;

  constructor(result: boolean, code: number, data: DynamicEvent[], fromCache: boolean, msg: string) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.fromCache = fromCache;
    this.msg = msg;
  }
}

export class DynamicService {
  private store: DynamicStore;
  private dao: DynamicDao;
  private pageSize: number;

  constructor(store: DynamicStore, dao?: DynamicDao, pageSize?: number) {
    this.store = store;
    this.dao = dao !== undefined ? dao : new DynamicDao();
    this.pageSize = pageSize !== undefined && pageSize > 0 ? pageSize : Address.getReceivedEventPageSize();
  }

  getStore(): DynamicStore {
    return this.store;
  }

  getPageSize(): number {
    return this.pageSize;
  }

  async fetchReceivedEvents(user: string, page: number): Promise<FetchReceivedResult> {
    if (!user || user.length === 0) {
      const empty: FetchReceivedResult = new FetchReceivedResult(false, 0, [], false, 'empty user');
      this.store.setError(empty.msg);
      return empty;
    }

    const finalPage: number = page > 0 ? page : 1;
    let cached: DynamicEvent[] = [];
    if (finalPage === 1) {
      cached = await this.readCache(user);
      if (cached.length > 0) {
        this.store.applyCachedFallback(cached);
      }
    }
    this.store.startLoading();

    const url: string = Address.getReceivedEvent(user, finalPage, this.pageSize);
    const httpResult: HttpResult<DynamicEvent[]> = await HttpManager.getFetch<DynamicEvent[]>(url);

    if (httpResult.result && httpResult.data !== null) {
      const events: DynamicEvent[] = httpResult.data as DynamicEvent[];
      if (finalPage === 1) {
        try {
          await this.dao.saveReceivedEvent(user, JSON.stringify(events));
        } catch (_e) {
        }
        this.store.applyRefresh(events, this.pageSize);
      } else {
        this.store.applyAppend(events, finalPage, this.pageSize);
      }
      return new FetchReceivedResult(true, httpResult.code, events, false, '');
    }

    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new FetchReceivedResult(false, UNAUTHORIZED, [], false, msg);
    }

    if (finalPage === 1) {
      if (cached.length > 0) {
        this.store.applyCachedFallback(cached);
        return new FetchReceivedResult(true, httpResult.code, cached, true,
          httpResult.msg !== null ? httpResult.msg : '');
      }
    }

    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new FetchReceivedResult(false, httpResult.code, [], false, failMsg);
  }

  /**
   * 拉取指定用户自身行为事件，对齐 RN 端
   * [store/actions/event.js](../../../../../../../reactnative/GSYGithubApp/app/store/actions/event.js)
   * `getEvent(page, login)` 走 `GET /users/:login/events`，被 BasePersonPage（MyPage / UserDetail）使用。
   * 与 fetchReceivedEvents 共用同一份 DynamicStore 视图模型，调用方决定切换。
   */
  async fetchUserEvents(user: string, page: number): Promise<FetchReceivedResult> {
    if (!user || user.length === 0) {
      const empty: FetchReceivedResult = new FetchReceivedResult(false, 0, [], false, 'empty user');
      this.store.setError(empty.msg);
      return empty;
    }

    const finalPage: number = page > 0 ? page : 1;
    let cached: DynamicEvent[] = [];
    if (finalPage === 1) {
      cached = await this.readUserEventCache(user);
      if (cached.length > 0) {
        this.store.applyCachedFallback(cached);
      }
    }
    this.store.startLoading();

    const url: string = Address.getUserEvent(user, finalPage, this.pageSize);
    const httpResult: HttpResult<DynamicEvent[]> = await HttpManager.getFetch<DynamicEvent[]>(url);

    if (httpResult.result && httpResult.data !== null) {
      const events: DynamicEvent[] = httpResult.data as DynamicEvent[];
      if (finalPage === 1) {
        try {
          await this.dao.saveUserEvent(user, JSON.stringify(events));
        } catch (_e) {
        }
        this.store.applyRefresh(events, this.pageSize);
      } else {
        this.store.applyAppend(events, finalPage, this.pageSize);
      }
      return new FetchReceivedResult(true, httpResult.code, events, false, '');
    }

    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new FetchReceivedResult(false, UNAUTHORIZED, [], false, msg);
    }

    if (finalPage === 1) {
      if (cached.length > 0) {
        this.store.applyCachedFallback(cached);
        return new FetchReceivedResult(true, httpResult.code, cached, true,
          httpResult.msg !== null ? httpResult.msg : '');
      }
    }

    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new FetchReceivedResult(false, httpResult.code, [], false, failMsg);
  }

  private async readUserEventCache(user: string): Promise<DynamicEvent[]> {
    try {
      const cache: ReadResult = await this.dao.readUserEvent(user);
      if (!cache.result || cache.data.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      if (Array.isArray(parsed)) {
        return parsed as DynamicEvent[];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }

  private async readCache(user: string): Promise<DynamicEvent[]> {
    try {
      const cache: ReadResult = await this.dao.readReceivedEvent(user);
      if (!cache.result || cache.data.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      if (Array.isArray(parsed)) {
        return parsed as DynamicEvent[];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }
}
