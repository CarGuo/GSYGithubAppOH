/**
 * MyService —— "我的"页签的数据编排层。
 *
 * 与 RN 端 [store/actions/user.js](../../../../../../../reactnative/GSYGithubApp/app/store/actions/user.js)
 * 中 `getUserInfo()` / `getUserOrgs()` / `getNotifation()` 的语义对齐：
 *
 *  - `refreshMe()` 走 `GET /user`，复用 [HttpManager](../net/HttpManager.ets) 内已注入的
 *    `Authorization`，不再自带 token 字符串拼装。
 *  - `fetchUnRead()` 走 `GET /notifications?all=false&participating=false&page=1` 仅探测是否存在未读，
 *    对齐 RN 端 `userActions.getNotifation(false, false, 0)` 的 unRead 头铃铛逻辑。
 *  - `fetchUserOrgs(login)` 走 `GET /users/:login/orgs`，对齐 RN 端 `_getOrgsList()`。
 *  - `fetchUserStarredCount(login)` 走 `GET /users/:login/starred?page=1&per_page=100`，
 *    与 RN 端 `repositoryActions.getUserRepository100Status` 的 stargazers 累加近似 ——
 *    取首屏 100 个仓库 stargazers_count 之和填到 UserHeadItem 的 beStared 格。
 *  - 失败：401 已由 HttpManager 自行清空 token + 派 LoginExpired，本层只负责把错误回写 MyStore.error；
 *    其他 5xx / 网络错误同样写 error，但不清登录态。
 *
 * 不与 ArkUI 装饰器耦合，便于单测注入 FakeHttpProvider + FakeRdb。
 */

import { HttpManager } from '../net/HttpManager';
import { Address } from '../net/Address';
import { HttpResult } from '../net/Result';
import { NetworkCode, SUCCESS, UNAUTHORIZED } from '../net/NetworkCode';
import { UserDao, USER_TABLE_INFO } from '../dao/UserDao';
import { ReadResult } from '../dao/DaoBase';
import hilog from '@ohos.hilog';
import {
  AuthStore,
  AuthUserInfo,
  GlobalAuthStore,
} from '../store/AuthStore';
import { MyStore, GlobalMyStore } from '../store/MyStore';

export class RefreshMeResult {
  result: boolean;
  code: number;
  data: AuthUserInfo | null;
  msg: string;
  fromCache: boolean;

  constructor(result: boolean, code: number, data: AuthUserInfo | null, msg: string, fromCache: boolean = false) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.msg = msg;
    this.fromCache = fromCache;
  }
}

export interface MyOrgItem {
  id: number;
  login: string;
  avatar_url: string;
}

export class FetchUnReadResult {
  result: boolean;
  unRead: boolean;
  msg: string;

  constructor(result: boolean, unRead: boolean, msg: string) {
    this.result = result;
    this.unRead = unRead;
    this.msg = msg;
  }
}

export class FetchUserOrgsResult {
  result: boolean;
  data: MyOrgItem[];
  msg: string;

  constructor(result: boolean, data: MyOrgItem[], msg: string) {
    this.result = result;
    this.data = data;
    this.msg = msg;
  }
}

export class FetchStarredCountResult {
  result: boolean;
  count: number;
  msg: string;

  constructor(result: boolean, count: number, msg: string) {
    this.result = result;
    this.count = count;
    this.msg = msg;
  }
}

interface StarredRepoLike {
  stargazers_count: number;
  watchers_count: number;
}

function parseLinkLastPage(link: string): number {
  if (!link || link.length === 0) {
    return 0;
  }
  // GitHub Link header 真实格式：
  //   <https://api.github.com/...&page=2>; rel="next", <https://api.github.com/...&page=34>; rel="last"
  // 直接正则抓 rel="last" 那段 url 里的 page=N
  const lastSegMatch: RegExpMatchArray | null = link.match(/<[^>]*[?&]page=(\d+)[^>]*>;\s*rel="last"/);
  if (lastSegMatch !== null && lastSegMatch.length >= 2) {
    const n: number = Number.parseInt(lastSegMatch[1], 10);
    hilog.info(0x0000, 'MyService', 'parseLinkLastPage: rel=last page=%{public}d', n);
    if (!Number.isNaN(n)) {
      return n;
    }
  }
  // 单页（只有 prev 或 first）情况：取整段 link 里出现的最大 page=N
  const allMatches: RegExpMatchArray | null = link.match(/[?&]page=(\d+)/g);
  if (allMatches !== null) {
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
    hilog.info(0x0000, 'MyService', 'parseLinkLastPage: fallback maxN=%{public}d', maxN);
    return maxN;
  }
  hilog.info(0x0000, 'MyService', 'parseLinkLastPage: no match link=%{public}s', link);
  return 0;
}

function readLinkHeader(headers: Object | null): string {
  if (headers === null || headers === undefined) {
    hilog.info(0x0000, 'MyService', 'readLinkHeader: headers null');
    return '';
  }
  const obj: Record<string, Object> = headers as Record<string, Object>;
  const keys: string[] = Object.keys(obj);
  hilog.info(0x0000, 'MyService', 'readLinkHeader: keys=%{public}s', keys.join('|'));
  // GitHub 实测返回的 header key 大小写不固定，做大小写不敏感扫描。
  for (let i = 0; i < keys.length; i++) {
    const k: string = keys[i];
    if (k.toLowerCase() === 'link') {
      const v: Object = obj[k];
      if (typeof v === 'string') {
        const s: string = v as string;
        hilog.info(0x0000, 'MyService', 'readLinkHeader: hit %{public}s len=%{public}d', k, s.length);
        return s;
      }
    }
  }
  hilog.info(0x0000, 'MyService', 'readLinkHeader: no link key found');
  return '';
}

export class MyService {
  private store: MyStore;
  private authStore: AuthStore;
  private userDao: UserDao | null;

  constructor(store: MyStore = GlobalMyStore,
              authStore: AuthStore = GlobalAuthStore,
              userDao: UserDao | null = null) {
    this.store = store;
    this.authStore = authStore;
    this.userDao = userDao;
  }

  getStore(): MyStore {
    return this.store;
  }

  getAuthStore(): AuthStore {
    return this.authStore;
  }

  async refreshMe(): Promise<RefreshMeResult> {
    this.store.startLoading();
    const cachedUser: AuthUserInfo | null = await this.readCachedMe();
    if (cachedUser !== null) {
      this.store.setUser(cachedUser);
      this.authStore.setUser(this.authStore.token, cachedUser);
      this.store.startLoading();
    }

    const url: string = Address.getMyUserInfo();
    const res: HttpResult<Object> = await HttpManager.netFetch<Object>(url, 'GET', null, false, null);

    if (!res.result || res.data === null) {
      const code: number = res.code === SUCCESS ? UNAUTHORIZED : res.code;
      const msg: string = res.msg !== null && res.msg.length > 0
        ? res.msg
        : NetworkCode.handleError(code, null);
      this.store.setError(msg);
      if (code === UNAUTHORIZED) {
        this.authStore.clear();
      }
      if (code !== UNAUTHORIZED && cachedUser !== null) {
        this.store.setUser(cachedUser);
        this.authStore.setUser(this.authStore.token, cachedUser);
        return new RefreshMeResult(true, code, cachedUser, msg, true);
      }
      return new RefreshMeResult(false, code, null, msg);
    }

    const jsonString: string = JSON.stringify(res.data);
    const user: AuthUserInfo | null = AuthUserInfo.fromJson(jsonString);
    if (user === null || user.login.length === 0) {
      const msg: string = '用户信息解析失败';
      this.store.setError(msg);
      return new RefreshMeResult(false, res.code, null, msg);
    }

    if (this.userDao !== null) {
      try {
        await (this.userDao as UserDao).save(USER_TABLE_INFO, user.login, jsonString);
      } catch (_e) {
      }
    }

    const existingToken: string = this.authStore.token;
    this.authStore.setUser(existingToken, user);
    this.store.setUser(user);
    return new RefreshMeResult(true, res.code, user, '');
  }

  private async readCachedMe(): Promise<AuthUserInfo | null> {
    if (this.userDao === null) {
      return null;
    }
    const current: AuthUserInfo | null = this.authStore.userInfo;
    const login: string = current !== null && current.login.length > 0 ? current.login : '';
    if (login.length === 0) {
      return null;
    }
    try {
      const cache: ReadResult = await (this.userDao as UserDao).read(USER_TABLE_INFO, login);
      if (!cache.result || cache.data.length === 0) {
        return null;
      }
      return AuthUserInfo.fromJson(cache.data);
    } catch (_e) {
      return null;
    }
  }

  async fetchUnRead(): Promise<FetchUnReadResult> {
    const url: string = Address.getNotifications(false, false, 1, 1);
    const res: HttpResult<Object[]> = await HttpManager.getFetch<Object[]>(url);
    if (!res.result || res.data === null) {
      return new FetchUnReadResult(false, false,
        res.msg !== null ? res.msg : 'fetch unread failed');
    }
    const list: Object[] = res.data as Object[];
    return new FetchUnReadResult(true, list.length > 0, '');
  }

  async fetchUserOrgs(login: string): Promise<FetchUserOrgsResult> {
    if (!login || login.length === 0) {
      return new FetchUserOrgsResult(false, [], 'empty login');
    }
    const url: string = Address.getUserOrgsPaged(login, 1);
    const res: HttpResult<MyOrgItem[]> = await HttpManager.getFetch<MyOrgItem[]>(url);
    if (!res.result || res.data === null) {
      return new FetchUserOrgsResult(false, [],
        res.msg !== null ? res.msg : 'fetch orgs failed');
    }
    return new FetchUserOrgsResult(true, res.data as MyOrgItem[], '');
  }

  async fetchUserStarredCount(login: string): Promise<FetchStarredCountResult> {
    if (!login || login.length === 0) {
      return new FetchStarredCountResult(false, 0, 'empty login');
    }
    // 对齐 RN 端 userDao.getUserStaredCountNet：starred?per_page=1 + 解析 Link header last 页号
    const url: string = Address.getUserStarred(login, 1, 1, 'updated');
    const res: HttpResult<Object[]> = await HttpManager.getFetch<Object[]>(url);
    if (!res.result) {
      return new FetchStarredCountResult(false, 0,
        res.msg !== null ? res.msg : 'fetch starred failed');
    }
    const link: string = readLinkHeader(res.headers as Object | null);
    if (link.length > 0) {
      const last: number = parseLinkLastPage(link);
      if (last > 0) {
        return new FetchStarredCountResult(true, last, '');
      }
    }
    // 没有 Link header → 用户 starred 列表 <=1 页，返回当前数据 length
    const list: Object[] = (res.data === null ? [] : res.data) as Object[];
    return new FetchStarredCountResult(true, list.length, '');
  }

  async fetchUserBeStaredCount(login: string): Promise<FetchStarredCountResult> {
    if (!login || login.length === 0) {
      return new FetchStarredCountResult(false, 0, 'empty login');
    }
    // 对齐 RN 端 repositoryDao.getUserRepository100StatusDao：拉 100 个仓库累加 watchers_count
    const url: string = Address.getUserRepos(login, 1, 'pushed', 100);
    const res: HttpResult<StarredRepoLike[]> = await HttpManager.getFetch<StarredRepoLike[]>(url);
    if (!res.result || res.data === null) {
      return new FetchStarredCountResult(false, 0,
        res.msg !== null ? res.msg : 'fetch repos failed');
    }
    const list: StarredRepoLike[] = res.data as StarredRepoLike[];
    let total: number = 0;
    for (let i: number = 0; i < list.length; i++) {
      const item: StarredRepoLike = list[i];
      if (item !== null && item !== undefined && typeof item.watchers_count === 'number') {
        total = total + (item.watchers_count as number);
      }
    }
    return new FetchStarredCountResult(true, total, '');
  }
}

export const DefaultMyService: MyService = new MyService();
