import HttpManager from '../net/HttpManager';
import { Address } from '../net/Address';
import { HttpResult } from '../net/Result';
import { UNAUTHORIZED, NETWORK_ERROR } from '../net/NetworkCode';
import { UserDao } from '../dao/UserDao';
import { ReadResult } from '../dao/DaoBase';
import {
  UserDetail,
  UserDetailStore,
  UserRepoItem,
  emptyUserDetail
} from '../store/UserDetailStore';
import { SubUserItem } from './RepositoryService';

const STATUS_NO_CONTENT: number = 204;
const STATUS_NOT_FOUND: number = 404;
const USER_CACHE_KIND_FOLLOWERS: number = 1;
const USER_CACHE_KIND_FOLLOWED: number = 2;

export class FetchSubUserListResult {
  result: boolean;
  code: number;
  data: SubUserItem[];
  fromCache: boolean;
  msg: string;

  constructor(result: boolean, code: number, data: SubUserItem[],
    fromCache: boolean, msg: string) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.fromCache = fromCache;
    this.msg = msg;
  }
}

export class FetchUserResult {
  result: boolean;
  code: number;
  data: UserDetail;
  fromCache: boolean;
  msg: string;

  constructor(result: boolean, code: number, data: UserDetail, fromCache: boolean, msg: string) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.fromCache = fromCache;
    this.msg = msg;
  }
}

export class FetchUserReposResult {
  result: boolean;
  code: number;
  data: UserRepoItem[];
  fromCache: boolean;
  msg: string;

  constructor(result: boolean, code: number, data: UserRepoItem[], fromCache: boolean, msg: string) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.fromCache = fromCache;
    this.msg = msg;
  }
}

export class FetchFollowResult {
  result: boolean;
  code: number;
  followed: boolean;
  msg: string;

  constructor(result: boolean, code: number, followed: boolean, msg: string) {
    this.result = result;
    this.code = code;
    this.followed = followed;
    this.msg = msg;
  }
}

export class FetchStarredCountResult {
  result: boolean;
  code: number;
  count: number;
  msg: string;

  constructor(result: boolean, code: number, count: number, msg: string) {
    this.result = result;
    this.code = code;
    this.count = count;
    this.msg = msg;
  }
}

function parseLinkLastPage(link: string): number {
  if (!link || link.length === 0) {
    return 0;
  }
  const lastSegMatch: RegExpMatchArray | null = link.match(/<[^>]*[?&]page=(\d+)[^>]*>;\s*rel="last"/);
  if (lastSegMatch !== null && lastSegMatch.length >= 2) {
    const n: number = Number.parseInt(lastSegMatch[1], 10);
    return Number.isNaN(n) ? 0 : n;
  }
  const allMatches: RegExpMatchArray | null = link.match(/[?&]page=(\d+)/g);
  if (allMatches === null) {
    return 0;
  }
  let maxN: number = 0;
  for (let i: number = 0; i < allMatches.length; i++) {
    const m: RegExpMatchArray | null = allMatches[i].match(/page=(\d+)/);
    if (m !== null && m.length >= 2) {
      const n: number = Number.parseInt(m[1], 10);
      if (!Number.isNaN(n) && n > maxN) {
        maxN = n;
      }
    }
  }
  return maxN;
}

function readLinkHeader(headers: Object | null): string {
  if (headers === null || headers === undefined) {
    return '';
  }
  const obj: Record<string, Object> = headers as Record<string, Object>;
  const keys: string[] = Object.keys(obj);
  for (let i: number = 0; i < keys.length; i++) {
    const key: string = keys[i];
    if (key.toLowerCase() === 'link') {
      const v: Object = obj[key];
      return typeof v === 'string' ? v as string : '';
    }
  }
  return '';
}

export class UserService {
  private store: UserDetailStore;
  private dao: UserDao;
  private pageSize: number;

  constructor(store: UserDetailStore, dao?: UserDao, pageSize?: number) {
    this.store = store;
    this.dao = dao !== undefined ? dao : new UserDao();
    this.pageSize = pageSize !== undefined && pageSize > 0 ? pageSize : Address.getUserReposPageSize();
  }

  getStore(): UserDetailStore {
    return this.store;
  }

  getPageSize(): number {
    return this.pageSize;
  }

  async getUser(login: string): Promise<FetchUserResult> {
    if (!login || login.length === 0) {
      const empty: FetchUserResult = new FetchUserResult(false, 0, emptyUserDetail(), false, 'empty login');
      this.store.setError(empty.msg);
      return empty;
    }

    const cachedUser: UserDetail | null = await this.readCachedUser(login);
    if (cachedUser !== null) {
      this.store.applyUser(cachedUser);
    }
    this.store.startLoading();
    const url: string = Address.getUserInfo(login);
    const httpResult: HttpResult<UserDetail> = await HttpManager.getFetch<UserDetail>(url);

    if (httpResult.result && httpResult.data !== null) {
      const user: UserDetail = httpResult.data as UserDetail;
      const starredRes: FetchStarredCountResult = await this.getUserStarredCount(login, false);
      const userRecord: Record<string, Object> = user as Object as Record<string, Object>;
      if (starredRes.result) {
        userRecord['starred'] = starredRes.count.toString();
      } else if (cachedUser !== null && cachedUser.starred !== undefined && cachedUser.starred !== null
        && cachedUser.starred.length > 0) {
        userRecord['starred'] = cachedUser.starred;
      } else {
        userRecord['starred'] = '0';
      }
      try {
        await this.dao.saveUserInfo(login, JSON.stringify(user));
      } catch (_e) {
      }
      this.store.applyUser(user);
      this.store.finishLoading();
      return new FetchUserResult(true, httpResult.code, user, false, '');
    }

    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new FetchUserResult(false, UNAUTHORIZED, emptyUserDetail(), false, msg);
    }

    if (cachedUser !== null) {
      this.store.applyUser(cachedUser);
      this.store.finishLoading();
      return new FetchUserResult(true, httpResult.code, cachedUser, true,
        httpResult.msg !== null ? httpResult.msg : '');
    }

    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new FetchUserResult(false, httpResult.code, emptyUserDetail(), false, failMsg);
  }

  async getUserStarredCount(login: string, applyToStore: boolean = true): Promise<FetchStarredCountResult> {
    if (!login || login.length === 0) {
      return new FetchStarredCountResult(false, 0, 0, 'empty login');
    }
    const url: string = Address.getUserStarred(login, 1, 1, 'updated');
    const httpResult: HttpResult<Object[]> = await HttpManager.getFetch<Object[]>(url);
    if (!httpResult.result) {
      return new FetchStarredCountResult(false, httpResult.code, 0,
        httpResult.msg !== null ? httpResult.msg : 'fetch starred failed');
    }
    const link: string = readLinkHeader(httpResult.headers as Object | null);
    let count: number = 0;
    if (link.length > 0) {
      count = parseLinkLastPage(link);
    }
    if (count <= 0) {
      const dataObj: Object | null = httpResult.data as Object | null;
      if (Array.isArray(dataObj)) {
        count = (dataObj as Object[]).length;
      }
    }
    if (applyToStore) {
      this.store.applyStarredCount(count);
    }
    return new FetchStarredCountResult(true, httpResult.code, count, '');
  }

  async getUserRepos(login: string, page: number): Promise<FetchUserReposResult> {
    if (!login || login.length === 0) {
      const empty: FetchUserReposResult = new FetchUserReposResult(false, 0, [], false, 'empty login');
      this.store.setError(empty.msg);
      return empty;
    }

    const finalPage: number = page > 0 ? page : 1;
    this.store.startLoading();

    const url: string = Address.getUserRepos(login, finalPage, null, this.pageSize);
    const httpResult: HttpResult<UserRepoItem[]> = await HttpManager.getFetch<UserRepoItem[]>(url);

    if (httpResult.result && httpResult.data !== null) {
      const repos: UserRepoItem[] = httpResult.data as UserRepoItem[];
      if (finalPage === 1) {
        try {
          await this.dao.saveUserRepos(login, JSON.stringify(repos));
        } catch (_e) {
        }
        this.store.applyReposRefresh(repos, this.pageSize);
      } else {
        this.store.applyReposAppend(repos, finalPage, this.pageSize);
      }
      return new FetchUserReposResult(true, httpResult.code, repos, false, '');
    }

    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new FetchUserReposResult(false, UNAUTHORIZED, [], false, msg);
    }

    if (finalPage === 1) {
      const cached: UserRepoItem[] = await this.readCachedRepos(login);
      if (cached.length > 0) {
        this.store.applyReposCachedFallback(cached);
        return new FetchUserReposResult(true, httpResult.code, cached, true,
          httpResult.msg !== null ? httpResult.msg : '');
      }
    }

    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new FetchUserReposResult(false, httpResult.code, [], false, failMsg);
  }

  async getFollowStatus(login: string): Promise<FetchFollowResult> {
    if (!login || login.length === 0) {
      return new FetchFollowResult(false, 0, false, 'empty login');
    }
    const url: string = Address.getFollowStatus(login);
    const httpResult: HttpResult<Object> = await HttpManager.getFetch<Object>(url);
    if (httpResult.result) {
      this.store.applyFollowed(true);
      return new FetchFollowResult(true, httpResult.code, true, '');
    }
    if (httpResult.code === STATUS_NO_CONTENT) {
      this.store.applyFollowed(true);
      return new FetchFollowResult(true, httpResult.code, true, '');
    }
    if (httpResult.code === STATUS_NOT_FOUND) {
      this.store.applyFollowed(false);
      return new FetchFollowResult(true, httpResult.code, false, '');
    }
    const msg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    return new FetchFollowResult(false, httpResult.code, false, msg);
  }

  async follow(login: string): Promise<FetchFollowResult> {
    if (!login || login.length === 0) {
      return new FetchFollowResult(false, 0, false, 'empty login');
    }
    const url: string = Address.setFollow(login);
    const httpResult: HttpResult<Object> = await HttpManager.netFetch<Object>(url, 'PUT', null, false, null);
    if (httpResult.result || httpResult.code === STATUS_NO_CONTENT) {
      this.store.applyFollowed(true);
      return new FetchFollowResult(true, httpResult.code, true, '');
    }
    const msg: string = httpResult.msg !== null ? httpResult.msg : 'follow failed';
    return new FetchFollowResult(false, httpResult.code, this.store.followed, msg);
  }

  async unfollow(login: string): Promise<FetchFollowResult> {
    if (!login || login.length === 0) {
      return new FetchFollowResult(false, 0, false, 'empty login');
    }
    const url: string = Address.setUnfollow(login);
    const httpResult: HttpResult<Object> = await HttpManager.netFetch<Object>(url, 'DELETE', null, false, null);
    if (httpResult.result || httpResult.code === STATUS_NO_CONTENT) {
      this.store.applyFollowed(false);
      return new FetchFollowResult(true, httpResult.code, false, '');
    }
    const msg: string = httpResult.msg !== null ? httpResult.msg : 'unfollow failed';
    return new FetchFollowResult(false, httpResult.code, this.store.followed, msg);
  }

  private async readCachedUser(login: string): Promise<UserDetail | null> {
    try {
      const cache: ReadResult = await this.dao.readUserInfo(login);
      if (!cache.result || cache.data.length === 0) {
        return null;
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      return parsed as UserDetail;
    } catch (_e) {
      return null;
    }
  }

  private async readCachedRepos(login: string): Promise<UserRepoItem[]> {
    try {
      const cache: ReadResult = await this.dao.readUserRepos(login);
      if (!cache.result || cache.data.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      if (Array.isArray(parsed)) {
        return parsed as UserRepoItem[];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }

  async getUserFollowers(login: string, page: number): Promise<FetchSubUserListResult> {
    if (!login || login.length === 0) {
      return new FetchSubUserListResult(false, 0, [], false, 'empty login');
    }
    const finalPage: number = page > 0 ? page : 1;
    const url: string = Address.getUserFollowers(login, finalPage, this.pageSize);
    const httpResult: HttpResult<SubUserItem[]> = await HttpManager.getFetch<SubUserItem[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const list: SubUserItem[] = httpResult.data as SubUserItem[];
      if (finalPage === 1) {
        try {
          await this.dao.saveFollower(login, JSON.stringify(list));
        } catch (_e) {
        }
      }
      return new FetchSubUserListResult(true, httpResult.code, list, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      return new FetchSubUserListResult(false, UNAUTHORIZED, [], false,
        httpResult.msg !== null ? httpResult.msg : 'unauthorized');
    }
    if (finalPage === 1) {
      const cached: SubUserItem[] = await this.readSubUsersCache(USER_CACHE_KIND_FOLLOWERS, login);
      if (cached.length > 0) {
        return new FetchSubUserListResult(true, httpResult.code, cached, true,
          httpResult.msg !== null ? httpResult.msg : '');
      }
    }
    return new FetchSubUserListResult(false, httpResult.code, [], false,
      httpResult.msg !== null ? httpResult.msg : 'network error');
  }

  async getUserFollowed(login: string, page: number): Promise<FetchSubUserListResult> {
    if (!login || login.length === 0) {
      return new FetchSubUserListResult(false, 0, [], false, 'empty login');
    }
    const finalPage: number = page > 0 ? page : 1;
    const url: string = Address.getUserFollowed(login, finalPage, this.pageSize);
    const httpResult: HttpResult<SubUserItem[]> = await HttpManager.getFetch<SubUserItem[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const list: SubUserItem[] = httpResult.data as SubUserItem[];
      if (finalPage === 1) {
        try {
          await this.dao.saveFollowed(login, JSON.stringify(list));
        } catch (_e) {
        }
      }
      return new FetchSubUserListResult(true, httpResult.code, list, false, '');
    }
    if (httpResult.code === UNAUTHORIZED) {
      return new FetchSubUserListResult(false, UNAUTHORIZED, [], false,
        httpResult.msg !== null ? httpResult.msg : 'unauthorized');
    }
    if (finalPage === 1) {
      const cached: SubUserItem[] = await this.readSubUsersCache(USER_CACHE_KIND_FOLLOWED, login);
      if (cached.length > 0) {
        return new FetchSubUserListResult(true, httpResult.code, cached, true,
          httpResult.msg !== null ? httpResult.msg : '');
      }
    }
    return new FetchSubUserListResult(false, httpResult.code, [], false,
      httpResult.msg !== null ? httpResult.msg : 'network error');
  }

  async getOrgMembers(org: string, page: number,
                      onCache?: (items: SubUserItem[]) => void): Promise<FetchSubUserListResult> {
    if (!org || org.length === 0) {
      return new FetchSubUserListResult(false, 0, [], false, 'empty org');
    }
    const finalPage: number = page > 0 ? page : 1;
    let cached: SubUserItem[] = [];
    if (finalPage === 1) {
      cached = await this.readOrgMembersCache(org);
      if (cached.length > 0 && onCache !== undefined) {
        onCache(cached.slice());
      }
    }
    const url: string = Address.getOrgMembers(org, finalPage, this.pageSize);
    const httpResult: HttpResult<SubUserItem[]> = await HttpManager.getFetch<SubUserItem[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const list: SubUserItem[] = httpResult.data as SubUserItem[];
      if (finalPage === 1) {
        try {
          await this.dao.saveOrgMember(org, JSON.stringify(list));
        } catch (_e) {
        }
      }
      return new FetchSubUserListResult(true, httpResult.code, list, false, '');
    }
    if (finalPage === 1 && cached.length > 0) {
      return new FetchSubUserListResult(true, httpResult.code, cached, true,
        httpResult.msg !== null ? httpResult.msg : '');
    }
    return new FetchSubUserListResult(false, httpResult.code, [], false,
      httpResult.msg !== null ? httpResult.msg : 'network error');
  }

  async getUserOrgs(login: string, page: number): Promise<FetchSubUserListResult> {
    if (!login || login.length === 0) {
      return new FetchSubUserListResult(false, 0, [], false, 'empty login');
    }
    const finalPage: number = page > 0 ? page : 1;
    const url: string = Address.getUserOrgsPaged(login, finalPage, this.pageSize);
    const httpResult: HttpResult<SubUserItem[]> = await HttpManager.getFetch<SubUserItem[]>(url);
    if (httpResult.result && httpResult.data !== null) {
      const list: SubUserItem[] = httpResult.data as SubUserItem[];
      return new FetchSubUserListResult(true, httpResult.code, list, false, '');
    }
    return new FetchSubUserListResult(false, httpResult.code, [], false,
      httpResult.msg !== null ? httpResult.msg : 'network error');
  }

  private async readOrgMembersCache(org: string): Promise<SubUserItem[]> {
    try {
      const cache: ReadResult = await this.dao.readOrgMember(org);
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

  private async readSubUsersCache(kind: number, login: string): Promise<SubUserItem[]> {
    try {
      let cache: ReadResult;
      if (kind === USER_CACHE_KIND_FOLLOWERS) {
        cache = await this.dao.readFollower(login);
      } else {
        cache = await this.dao.readFollowed(login);
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

  /**
   * 对齐 Compose UserRepository.updateUserInfo：PATCH /user 更新当前登录用户，
   * 成功后把 GitHub 返回的用户详情写回本地 UserDao 缓存。
   * 注意：本方法不依赖实例 store / dao，因此提供静态版本，便于 PersonInfoPage 直接调用。
   */
  static async updateUser(field: string,
                          value: string,
                          dao: UserDao | null = null): Promise<UpdateUserResult> {
    if (field === undefined || field === null || field.length === 0) {
      return new UpdateUserResult(false, 0, 'empty field');
    }
    const url: string = Address.getMyUserInfo();
    const params: Record<string, Object> = {};
    params[field] = value;
    const httpResult: HttpResult<UserDetail> = await HttpManager.netFetch<UserDetail>(
      url, 'PATCH', params, true, null);
    if (httpResult.result) {
      const updatedUser: UserDetail | null = httpResult.data !== null ? httpResult.data as UserDetail : null;
      if (dao !== null && updatedUser !== null && updatedUser.login !== undefined
        && updatedUser.login !== null && updatedUser.login.length > 0) {
        try {
          await dao.saveUserInfo(updatedUser.login, JSON.stringify(updatedUser));
        } catch (_e) {
        }
      }
      return new UpdateUserResult(true, httpResult.code, '', updatedUser);
    }
    return new UpdateUserResult(false, httpResult.code,
      httpResult.msg !== null ? httpResult.msg : 'network error');
  }
}

export class UpdateUserResult {
  result: boolean;
  code: number;
  msg: string;
  user: UserDetail | null;

  constructor(result: boolean, code: number, msg: string, user: UserDetail | null = null) {
    this.result = result;
    this.code = code;
    this.msg = msg;
    this.user = user;
  }
}
