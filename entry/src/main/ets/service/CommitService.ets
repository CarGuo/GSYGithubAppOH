import HttpManager from '../net/HttpManager';
import { Address } from '../net/Address';
import { HttpHeaders, HttpResult } from '../net/Result';
import { RepositoryDao } from '../dao/RepositoryDao';
import { ReadResult } from '../dao/DaoBase';
import {
  CommitDetail,
  CommitFileItem,
  PushDetailStore,
} from '../store/PushDetailStore';

export class CommitOwnerNamePair {
  owner: string;
  name: string;

  constructor(owner: string, name: string) {
    this.owner = owner;
    this.name = name;
  }

  static parse(fullName: string): CommitOwnerNamePair {
    const safe: string = fullName !== null && fullName !== undefined ? fullName : '';
    const idx: number = safe.indexOf('/');
    if (idx < 0) {
      return new CommitOwnerNamePair(safe, '');
    }
    return new CommitOwnerNamePair(safe.substring(0, idx), safe.substring(idx + 1));
  }
}

export class CommitServiceResult<T> {
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

export const COMMIT_DIFF_ACCEPT: string = 'application/vnd.github.v3.diff';

export interface CommitCacheDao {
  saveCommitInfoDetail(fullName: string, sha: string, jsonString: string): Promise<number>;
  readCommitInfoDetail(fullName: string, sha: string): Promise<ReadResult>;
}

export class CommitService {
  private store: PushDetailStore;
  private dao: CommitCacheDao;

  constructor(store: PushDetailStore, dao?: CommitCacheDao) {
    this.store = store;
    this.dao = dao !== undefined ? dao : new RepositoryDao();
  }

  getStore(): PushDetailStore {
    return this.store;
  }

  async getCommitDetail(fullName: string,
                        sha: string): Promise<CommitServiceResult<CommitDetail>> {
    const owner: CommitOwnerNamePair = CommitOwnerNamePair.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0 || sha === null || sha.length === 0) {
      const msg: string = 'invalid params';
      this.store.setError(msg);
      return new CommitServiceResult<CommitDetail>(false, 0, null, msg);
    }
    let cached: CommitDetail | null = await this.readCommitCache(fullName, sha);
    if (cached !== null) {
      this.store.setCommit(cached);
    }
    this.store.startLoading();
    const url: string = Address.getCommitDetail(owner.owner, owner.name, sha);
    const httpResult: HttpResult<CommitDetail> = await HttpManager.getFetch<CommitDetail>(url);
    if (httpResult.result && httpResult.data !== null) {
      const data: CommitDetail = httpResult.data as CommitDetail;
      try {
        await this.dao.saveCommitInfoDetail(fullName, sha, JSON.stringify(data));
      } catch (_e) {
      }
      this.store.setCommit(data);
      return new CommitServiceResult<CommitDetail>(true, httpResult.code, data, '');
    }
    if (cached !== null) {
      this.store.setCommit(cached);
      return new CommitServiceResult<CommitDetail>(true, httpResult.code, cached,
        httpResult.msg !== null ? httpResult.msg : '', true);
    }
    const msg: string = httpResult.msg !== null && httpResult.msg.length > 0
      ? httpResult.msg : 'network error';
    this.store.setError(msg);
    return new CommitServiceResult<CommitDetail>(false, httpResult.code, null, msg);
  }

  async getCommitDiff(fullName: string,
                      sha: string): Promise<CommitServiceResult<string>> {
    const owner: CommitOwnerNamePair = CommitOwnerNamePair.parse(fullName);
    if (owner.owner.length === 0 || owner.name.length === 0 || sha === null || sha.length === 0) {
      const msg: string = 'invalid params';
      return new CommitServiceResult<string>(false, 0, null, msg);
    }
    const url: string = Address.getCommitDiff(owner.owner, owner.name, sha);
    const headers: HttpHeaders = {};
    headers['Accept'] = COMMIT_DIFF_ACCEPT;
    const httpResult: HttpResult<string> = await HttpManager.getFetch<string>(url, headers);
    if (httpResult.result && httpResult.data !== null) {
      const text: string = httpResult.data as string;
      return new CommitServiceResult<string>(true, httpResult.code, text, '');
    }
    const msg: string = httpResult.msg !== null && httpResult.msg.length > 0
      ? httpResult.msg : 'network error';
    return new CommitServiceResult<string>(false, httpResult.code, null, msg);
  }

  static extractFiles(detail: CommitDetail | null): CommitFileItem[] {
    if (detail === null || detail.files === null || detail.files === undefined) {
      return [];
    }
    return detail.files.slice();
  }

  private async readCommitCache(fullName: string, sha: string): Promise<CommitDetail | null> {
    try {
      const cache: ReadResult = await this.dao.readCommitInfoDetail(fullName, sha);
      if (!cache.result || cache.data.length === 0) {
        return null;
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      return parsed as CommitDetail;
    } catch (_e) {
      return null;
    }
  }
}
