import HttpManager from '../net/HttpManager';
import { Address } from '../net/Address';
import { HttpResult } from '../net/Result';
import { UNAUTHORIZED, NO_CONTENT } from '../net/NetworkCode';
import { IssueDao } from '../dao/IssueDao';
import { ReadResult } from '../dao/DaoBase';
import {
  IssueDetailModel,
  IssueCommentModel,
  IssueDetailStore,
  ISSUE_STATE_OPEN,
  ISSUE_STATE_CLOSED
} from '../store/IssueDetailStore';

export class IssueOwnerName {
  owner: string;
  name: string;

  constructor(owner: string, name: string) {
    this.owner = owner;
    this.name = name;
  }

  static parse(fullName: string): IssueOwnerName {
    const safe: string = fullName !== null && fullName !== undefined ? fullName : '';
    const idx: number = safe.indexOf('/');
    if (idx < 0) {
      return new IssueOwnerName(safe, '');
    }
    const owner: string = safe.substring(0, idx);
    const name: string = safe.substring(idx + 1);
    return new IssueOwnerName(owner, name);
  }
}

export class IssueServiceResult<T> {
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

interface IssueStateBody {
  state: string;
}

interface IssueCommentBody {
  body: string;
}

interface IssueEditBody {
  title: string;
  body: string;
}

export class IssueService {
  private store: IssueDetailStore;
  private dao: IssueDao;
  private pageSize: number;

  constructor(store: IssueDetailStore, dao?: IssueDao, pageSize?: number) {
    this.store = store;
    this.dao = dao !== undefined ? dao : new IssueDao();
    this.pageSize = pageSize !== undefined && pageSize > 0
      ? pageSize : Address.getIssuePageSize();
  }

  getStore(): IssueDetailStore {
    return this.store;
  }

  getPageSize(): number {
    return this.pageSize;
  }

  async getIssue(fullName: string,
                 num: number): Promise<IssueServiceResult<IssueDetailModel>> {
    const owner: IssueOwnerName = IssueOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      const msg: string = 'invalid fullName';
      this.store.setError(msg);
      return new IssueServiceResult<IssueDetailModel>(false, 0, null, false, msg);
    }
    const cachedIssue: IssueDetailModel | null = await this.readIssueCache(fullName, num);
    if (cachedIssue !== null) {
      this.store.setIssue(cachedIssue);
    }
    this.store.startLoading();
    const url: string = Address.getIssue(owner.owner, owner.name, num);
    const httpResult: HttpResult<IssueDetailModel> =
      await HttpManager.getFetch<IssueDetailModel>(url);
    if (httpResult.result && httpResult.data !== null) {
      const detail: IssueDetailModel = httpResult.data as IssueDetailModel;
      try {
        await this.dao.saveIssueDetail(fullName, num, JSON.stringify(detail));
      } catch (_e) {
      }
      this.store.setIssue(detail);
      this.store.finishLoading();
      return new IssueServiceResult<IssueDetailModel>(true, httpResult.code, detail, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new IssueServiceResult<IssueDetailModel>(false, UNAUTHORIZED, null, false, msg);
    }
    if (cachedIssue !== null) {
      this.store.setIssue(cachedIssue);
      this.store.finishLoading();
      return new IssueServiceResult<IssueDetailModel>(true, httpResult.code, cachedIssue, true,
        httpResult.msg !== null ? httpResult.msg : '');
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new IssueServiceResult<IssueDetailModel>(false, httpResult.code, null, false, failMsg);
  }

  async getComments(fullName: string,
                    num: number,
                    page: number): Promise<IssueServiceResult<IssueCommentModel[]>> {
    const owner: IssueOwnerName = IssueOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      const msg: string = 'invalid fullName';
      this.store.setError(msg);
      return new IssueServiceResult<IssueCommentModel[]>(false, 0, [], false, msg);
    }
    const finalPage: number = page > 0 ? page : 1;
    let cachedComments: IssueCommentModel[] = [];
    if (finalPage === 1) {
      cachedComments = await this.readCommentsCache(fullName, num, finalPage);
      if (cachedComments.length > 0) {
        this.store.applyCommentsRefresh(cachedComments, this.pageSize);
      }
    }
    this.store.startLoading();
    const url: string = Address.getIssueComments(owner.owner, owner.name, num,
      finalPage, this.pageSize);
    const httpResult: HttpResult<IssueCommentModel[]> =
      await HttpManager.getFetch<IssueCommentModel[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const items: IssueCommentModel[] = httpResult.data as IssueCommentModel[];
      if (finalPage === 1) {
        try {
          await this.dao.saveIssueComment(fullName, num, finalPage, JSON.stringify(items));
        } catch (_e) {
        }
        this.store.applyCommentsRefresh(items, this.pageSize);
      } else {
        this.store.applyCommentsAppend(items, finalPage, this.pageSize);
      }
      return new IssueServiceResult<IssueCommentModel[]>(true, httpResult.code, items, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new IssueServiceResult<IssueCommentModel[]>(false, UNAUTHORIZED, [], false, msg);
    }
    if (cachedComments.length > 0) {
      this.store.applyCommentsRefresh(cachedComments, this.pageSize);
      return new IssueServiceResult<IssueCommentModel[]>(true, httpResult.code, cachedComments, true,
        httpResult.msg !== null ? httpResult.msg : '');
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new IssueServiceResult<IssueCommentModel[]>(false, httpResult.code, [], false, failMsg);
  }

  async createComment(fullName: string,
                      num: number,
                      body: string): Promise<IssueServiceResult<IssueCommentModel>> {
    const owner: IssueOwnerName = IssueOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new IssueServiceResult<IssueCommentModel>(false, 0, null, false, 'invalid fullName');
    }
    const safeBody: string = body !== null && body !== undefined ? body : '';
    if (safeBody.length === 0) {
      return new IssueServiceResult<IssueCommentModel>(false, 0, null, false, 'empty body');
    }
    const url: string = Address.createIssueComment(owner.owner, owner.name, num);
    const params: IssueCommentBody = { 'body': safeBody };
    const httpResult: HttpResult<IssueCommentModel> =
      await HttpManager.netFetch<IssueCommentModel>(url, 'POST',
        params as Object as Record<string, Object>, true, null);
    if (httpResult.result && httpResult.data !== null) {
      const comment: IssueCommentModel = httpResult.data as IssueCommentModel;
      this.store.appendComment(comment);
      return new IssueServiceResult<IssueCommentModel>(true, httpResult.code, comment, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      return new IssueServiceResult<IssueCommentModel>(false, UNAUTHORIZED, null, false, msg);
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    return new IssueServiceResult<IssueCommentModel>(false, httpResult.code, null, false, failMsg);
  }

  async closeIssue(fullName: string,
                   num: number): Promise<IssueServiceResult<IssueDetailModel>> {
    return this.toggleIssueState(fullName, num, ISSUE_STATE_CLOSED);
  }

  async reopenIssue(fullName: string,
                    num: number): Promise<IssueServiceResult<IssueDetailModel>> {
    return this.toggleIssueState(fullName, num, ISSUE_STATE_OPEN);
  }

  private async toggleIssueState(fullName: string,
                                 num: number,
                                 state: string): Promise<IssueServiceResult<IssueDetailModel>> {
    const owner: IssueOwnerName = IssueOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new IssueServiceResult<IssueDetailModel>(false, 0, null, false, 'invalid fullName');
    }
    const url: string = Address.setIssueState(owner.owner, owner.name, num);
    const params: IssueStateBody = { 'state': state };
    const httpResult: HttpResult<IssueDetailModel> =
      await HttpManager.netFetch<IssueDetailModel>(url, 'PATCH',
        params as Object as Record<string, Object>, true, null);
    if (httpResult.result && httpResult.data !== null) {
      const detail: IssueDetailModel = httpResult.data as IssueDetailModel;
      try {
        await this.dao.saveIssueDetail(fullName, num, JSON.stringify(detail));
      } catch (_e) {
      }
      this.store.setIssue(detail);
      return new IssueServiceResult<IssueDetailModel>(true, httpResult.code, detail, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      return new IssueServiceResult<IssueDetailModel>(false, UNAUTHORIZED, null, false, msg);
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    return new IssueServiceResult<IssueDetailModel>(false, httpResult.code, null, false, failMsg);
  }

  async editIssue(fullName: string,
                  num: number,
                  title: string,
                  body: string): Promise<IssueServiceResult<IssueDetailModel>> {
    const owner: IssueOwnerName = IssueOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new IssueServiceResult<IssueDetailModel>(false, 0, null, false, 'invalid fullName');
    }
    const safeTitle: string = title !== null && title !== undefined ? title : '';
    if (safeTitle.length === 0) {
      return new IssueServiceResult<IssueDetailModel>(false, 0, null, false, 'empty title');
    }
    const safeBody: string = body !== null && body !== undefined ? body : '';
    const url: string = Address.editIssue(owner.owner, owner.name, num);
    const params: IssueEditBody = { 'title': safeTitle, 'body': safeBody };
    const httpResult: HttpResult<IssueDetailModel> =
      await HttpManager.netFetch<IssueDetailModel>(url, 'PATCH',
        params as Object as Record<string, Object>, true, null);
    if (httpResult.result && httpResult.data !== null) {
      const detail: IssueDetailModel = httpResult.data as IssueDetailModel;
      try {
        await this.dao.saveIssueDetail(fullName, num, JSON.stringify(detail));
      } catch (_e) {
      }
      this.store.setIssue(detail);
      return new IssueServiceResult<IssueDetailModel>(true, httpResult.code, detail, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      return new IssueServiceResult<IssueDetailModel>(false, UNAUTHORIZED, null, false, msg);
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    return new IssueServiceResult<IssueDetailModel>(false, httpResult.code, null, false, failMsg);
  }

  async toggleIssueLock(fullName: string,
                        num: number,
                        currentLocked: boolean): Promise<IssueServiceResult<boolean>> {
    const owner: IssueOwnerName = IssueOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new IssueServiceResult<boolean>(false, 0, null, false, 'invalid fullName');
    }
    const url: string = Address.lockIssue(owner.owner, owner.name, num);
    const method: 'PUT' | 'DELETE' = currentLocked ? 'DELETE' : 'PUT';
    const httpResult: HttpResult<Object> =
      await HttpManager.netFetch<Object>(url, method, null, true, null);
    const ok: boolean = httpResult.result || httpResult.code === NO_CONTENT;
    if (ok) {
      const nextLocked: boolean = !currentLocked;
      if (this.store.issue !== null) {
        const current: IssueDetailModel = this.store.issue as IssueDetailModel;
        current.locked = nextLocked;
        this.store.setIssue(current);
        try {
          await this.dao.saveIssueDetail(fullName, num, JSON.stringify(current));
        } catch (_e) {
        }
      }
      return new IssueServiceResult<boolean>(true, httpResult.code, nextLocked, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      return new IssueServiceResult<boolean>(false, UNAUTHORIZED, null, false, msg);
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    return new IssueServiceResult<boolean>(false, httpResult.code, null, false, failMsg);
  }

  async editComment(fullName: string,
                    num: number,
                    commentId: number,
                    body: string,
                    rowIndex: number): Promise<IssueServiceResult<IssueCommentModel>> {
    const owner: IssueOwnerName = IssueOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new IssueServiceResult<IssueCommentModel>(false, 0, null, false, 'invalid fullName');
    }
    const safeBody: string = body !== null && body !== undefined ? body : '';
    if (safeBody.length === 0) {
      return new IssueServiceResult<IssueCommentModel>(false, 0, null, false, 'empty body');
    }
    const url: string = Address.editIssueComment(owner.owner, owner.name, commentId);
    const params: IssueCommentBody = { 'body': safeBody };
    const httpResult: HttpResult<IssueCommentModel> =
      await HttpManager.netFetch<IssueCommentModel>(url, 'PATCH',
        params as Object as Record<string, Object>, true, null);
    if (httpResult.result && httpResult.data !== null) {
      const comment: IssueCommentModel = httpResult.data as IssueCommentModel;
      this.store.replaceCommentAt(rowIndex, comment);
      return new IssueServiceResult<IssueCommentModel>(true, httpResult.code, comment, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      return new IssueServiceResult<IssueCommentModel>(false, UNAUTHORIZED, null, false, msg);
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    return new IssueServiceResult<IssueCommentModel>(false, httpResult.code, null, false, failMsg);
  }

  async deleteComment(fullName: string,
                      num: number,
                      commentId: number,
                      rowIndex: number): Promise<IssueServiceResult<boolean>> {
    const owner: IssueOwnerName = IssueOwnerName.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0) {
      return new IssueServiceResult<boolean>(false, 0, null, false, 'invalid fullName');
    }
    const url: string = Address.editIssueComment(owner.owner, owner.name, commentId);
    const httpResult: HttpResult<Object> =
      await HttpManager.netFetch<Object>(url, 'DELETE', null, true, null);
    const ok: boolean = httpResult.result || httpResult.code === NO_CONTENT;
    if (ok) {
      this.store.removeCommentAt(rowIndex);
      return new IssueServiceResult<boolean>(true, httpResult.code, true, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      return new IssueServiceResult<boolean>(false, UNAUTHORIZED, null, false, msg);
    }
    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    return new IssueServiceResult<boolean>(false, httpResult.code, null, false, failMsg);
  }

  private async readIssueCache(fullName: string, num: number): Promise<IssueDetailModel | null> {
    try {
      const cache: ReadResult = await this.dao.readIssueDetail(fullName, num);
      if (!cache.result || cache.data.length === 0) {
        return null;
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      return parsed as IssueDetailModel;
    } catch (_e) {
      return null;
    }
  }

  private async readCommentsCache(fullName: string, num: number,
    page: number): Promise<IssueCommentModel[]> {
    try {
      const cache: ReadResult = await this.dao.readIssueComment(fullName, num, page);
      if (!cache.result || cache.data.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      if (Array.isArray(parsed)) {
        return parsed as IssueCommentModel[];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }
}
