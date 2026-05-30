import HttpManager from '../net/HttpManager';
import { Address } from '../net/Address';
import { HttpResult } from '../net/Result';
import { UNAUTHORIZED } from '../net/NetworkCode';
import {
  NotifyFilter,
  NotifyStore,
  NotifyThread,
  NOTIFY_FILTER_ALL,
  NOTIFY_FILTER_PARTICIPATING,
  NOTIFY_FILTER_UNREAD,
} from '../store/NotifyStore';

const STATUS_NO_CONTENT: number = 204;
const STATUS_RESET_CONTENT: number = 205;

export class NotifyFilterParam {
  all: boolean;
  participating: boolean;

  constructor(all: boolean, participating: boolean) {
    this.all = all;
    this.participating = participating;
  }
}

export function resolveFilterParam(filter: NotifyFilter): NotifyFilterParam {
  if (filter === NOTIFY_FILTER_ALL) {
    return new NotifyFilterParam(true, false);
  }
  if (filter === NOTIFY_FILTER_PARTICIPATING) {
    return new NotifyFilterParam(false, true);
  }
  return new NotifyFilterParam(false, false);
}

export class FetchNotifyResult {
  result: boolean;
  code: number;
  data: NotifyThread[];
  msg: string;
  fromCache: boolean;

  constructor(result: boolean, code: number, data: NotifyThread[], msg: string, fromCache: boolean = false) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.msg = msg;
    this.fromCache = fromCache;
  }
}

export class MarkNotifyResult {
  result: boolean;
  code: number;
  msg: string;
  fromCache: boolean;

  constructor(result: boolean, code: number, msg: string, fromCache: boolean = false) {
    this.result = result;
    this.code = code;
    this.msg = msg;
    this.fromCache = fromCache;
  }
}

export class NotifyService {
  private store: NotifyStore;
  private pageSize: number;

  constructor(store: NotifyStore, pageSize?: number) {
    this.store = store;
    this.pageSize = pageSize !== undefined && pageSize > 0
      ? pageSize : Address.getNotificationPageSize();
  }

  getStore(): NotifyStore {
    return this.store;
  }

  getPageSize(): number {
    return this.pageSize;
  }

  static resolveFilter(filter: NotifyFilter): NotifyFilterParam {
    return resolveFilterParam(filter);
  }

  buildUrl(filter: NotifyFilter, page: number): string {
    const param: NotifyFilterParam = resolveFilterParam(filter);
    const finalPage: number = page > 0 ? page : 1;
    return Address.getNotifications(param.all, param.participating, finalPage, this.pageSize);
  }

  async getNotifications(filter: NotifyFilter, page: number): Promise<FetchNotifyResult> {
    const finalPage: number = page > 0 ? page : 1;
    if (this.store.filter !== filter) {
      this.store.setFilter(filter);
    }
    this.store.startLoading();

    const url: string = this.buildUrl(filter, finalPage);
    const httpResult: HttpResult<NotifyThread[]> = await HttpManager.getFetch<NotifyThread[]>(url);

    if (httpResult.result && httpResult.data !== null) {
      const threads: NotifyThread[] = httpResult.data as NotifyThread[];
      if (finalPage === 1) {
        this.store.applyRefresh(threads, this.pageSize);
      } else {
        this.store.applyAppend(threads, finalPage, this.pageSize);
      }
      return new FetchNotifyResult(true, httpResult.code, threads, '');
    }

    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new FetchNotifyResult(false, UNAUTHORIZED, [], msg);
    }

    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new FetchNotifyResult(false, httpResult.code, [], failMsg);
  }

  async markAsRead(threadId: string): Promise<MarkNotifyResult> {
    if (!threadId || threadId.length === 0) {
      return new MarkNotifyResult(false, 0, 'empty threadId');
    }
    const url: string = Address.markNotificationsThread(threadId);
    const httpResult: HttpResult<Object> = await HttpManager.netFetch<Object>(url, 'PATCH', null, false, null);
    if (httpResult.result
      || httpResult.code === STATUS_NO_CONTENT
      || httpResult.code === STATUS_RESET_CONTENT) {
      this.store.markThreadRead(threadId);
      return new MarkNotifyResult(true, httpResult.code, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      return new MarkNotifyResult(false, UNAUTHORIZED, msg);
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'mark thread failed';
    return new MarkNotifyResult(false, httpResult.code, failMsg);
  }

  async markAllAsRead(repoFullName?: string): Promise<MarkNotifyResult> {
    const hasRepo: boolean = repoFullName !== undefined
      && repoFullName !== null
      && repoFullName.length > 0;
    const url: string = hasRepo
      ? Address.markRepoNotifications(repoFullName as string)
      : Address.setAllNotificationAsRead();
    const httpResult: HttpResult<Object> = await HttpManager.netFetch<Object>(url, 'PUT', null, false, null);
    if (httpResult.result
      || httpResult.code === STATUS_NO_CONTENT
      || httpResult.code === STATUS_RESET_CONTENT) {
      this.store.markAllRead();
      return new MarkNotifyResult(true, httpResult.code, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      return new MarkNotifyResult(false, UNAUTHORIZED, msg);
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'mark all failed';
    return new MarkNotifyResult(false, httpResult.code, failMsg);
  }
}

export const NOTIFY_FILTER_UNREAD_EXPORT: NotifyFilter = NOTIFY_FILTER_UNREAD;
