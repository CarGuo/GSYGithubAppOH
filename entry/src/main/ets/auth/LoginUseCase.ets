/**
 * LoginUseCase —— 登录流程编排，对齐 RN 端
 * [store/actions/login.js](../../../../../../../reactnative/GSYGithubApp/app/store/actions/login.js)：
 *
 *  - loginWithBasicAuth(user, pwd)        : 走旧版 `POST /authorizations`（Basic Auth），
 *                                            201 时 HttpManager 已自动把 `token xxx` 持久化。
 *  - loginWithPersonalAccessToken(token)  : 直接拼 `token xxx`，写 Preferences + HttpManager 内存，
 *                                            再调 `GET /user` 校验 token，401 失败则回滚清理。
 *  - exchangeOAuthCode(code)              : 走 `https://github.com/login/oauth/access_token`
 *                                            兑换 access_token，写 Preferences 后调 `/user` 拉用户。
 *  - logout()                             : 清 HttpManager / Preferences / AppStorage / UserDao，
 *                                            发 EVENT_USER_LOGGED_OUT。
 *
 * 与 RN 不同：
 *  - 通过 [AuthStore](../store/AuthStore.ets) 维护 UI 状态（loading / error / userInfo / authed），
 *    替代 RN 端 redux dispatch。
 *  - 成功登录后落库走 [UserDao](../dao/UserDao.ets) 的 `UserInfo` 表，等价 RN 端
 *    `UserDao.saveUserInfoLocale`。
 *  - HTTP 失败码统一用 [HttpResult](../net/Result.ets) 返回，不再 throw。
 */

import { HttpManager } from '../net/HttpManager';
import { HttpResult } from '../net/Result';
import { Address, HOST_WEB } from '../net/Address';
import { CREATED, SUCCESS, UNAUTHORIZED } from '../net/NetworkCode';
import {
  Preferences,
  KEY_USER_TOKEN,
  KEY_USER_INFO,
  KEY_USER_BASIC,
  KEY_USER_NAME,
  KEY_USER_PASSWORD,
} from '../dao/db/Preferences';
import { UserDao, USER_TABLE_INFO } from '../dao/UserDao';
import { EventBus, EVENT_USER_LOGGED_IN, EVENT_USER_LOGGED_OUT } from '../utils/EventBus';
import { AuthStore, AuthUserInfo, GlobalAuthStore } from '../store/AuthStore';

export type LoginOutcome = HttpResult<AuthUserInfo>;

export interface PreferencesLike {
  putString(key: string, value: string): Promise<void>;
  remove(key: string): Promise<void>;
}

export class OAuthClientConfig {
  clientId: string;
  clientSecret: string;
  redirectUri: string;

  constructor(clientId: string, clientSecret: string, redirectUri: string = 'gsygithubapp://authed') {
    this.clientId = clientId;
    this.clientSecret = clientSecret;
    this.redirectUri = redirectUri;
  }
}

const OAUTH_TOKEN_URL: string = `${HOST_WEB}login/oauth/access_token`;

export class LoginUseCase {
  private store: AuthStore;
  private userDao: UserDao | null;
  private prefs: PreferencesLike;
  private oauth: OAuthClientConfig | null;

  constructor(store: AuthStore = GlobalAuthStore,
              userDao: UserDao | null = null,
              prefs: PreferencesLike | null = null,
              oauth: OAuthClientConfig | null = null) {
    this.store = store;
    this.userDao = userDao;
    this.prefs = prefs !== null ? prefs : (Preferences as PreferencesLike);
    this.oauth = oauth;
  }

  setOAuthConfig(oauth: OAuthClientConfig): void {
    this.oauth = oauth;
  }

  async loginWithBasicAuth(user: string, pwd: string): Promise<LoginOutcome> {
    const userName: string = (user ? user : '').trim();
    const password: string = pwd ? pwd : '';
    if (userName.length === 0 || password.length === 0) {
      return this.failOutcome(UNAUTHORIZED, '用户名或密码为空');
    }

    this.store.setLoading(true);
    await HttpManager.clearAuthorization();

    const basic: string = `Basic ${LoginUseCase.toBase64(`${userName}:${password}`)}`;
    HttpManager.setAuthorization(basic);

    const body: Record<string, Object> = {
      'scopes': ['user', 'repo', 'gist', 'notifications'],
      'note': 'GSYGithubAppOH',
      'client_id': '',
      'client_secret': '',
    };
    const res: HttpResult<Object> = await HttpManager.netFetch<Object>(
      Address.getAuthorization(), 'POST', body, true, null);

    if (res.code === CREATED || res.code === SUCCESS) {
      await this.persistBasicCache(userName, password, basic);
      const tokenInMemory: string | null = HttpManager.getAuthorizationInMemory();
      if (tokenInMemory && tokenInMemory.length > 0) {
        await this.prefs.putString(KEY_USER_TOKEN, tokenInMemory);
      }
      return await this.fetchUserAndCommit(tokenInMemory ? tokenInMemory : basic);
    }

    await this.rollbackOnFailure();
    const msg: string = res.msg ? res.msg : '登录失败';
    return this.failOutcome(res.code, msg);
  }

  async loginWithPersonalAccessToken(token: string): Promise<LoginOutcome> {
    const raw: string = (token ? token : '').trim();
    if (raw.length === 0) {
      return this.failOutcome(UNAUTHORIZED, 'token 为空');
    }
    const bare: string = raw.toLowerCase().indexOf('token ') === 0 ? raw.substring(6).trim() : raw;
    const authorization: string = `token ${bare}`;

    this.store.setLoading(true);
    await HttpManager.clearAuthorization();
    HttpManager.setAuthorization(authorization);
    await this.prefs.putString(KEY_USER_TOKEN, authorization);

    return await this.fetchUserAndCommit(authorization);
  }

  async exchangeOAuthCode(code: string): Promise<LoginOutcome> {
    const c: string = (code ? code : '').trim();
    if (c.length === 0) {
      return this.failOutcome(UNAUTHORIZED, 'OAuth code 为空');
    }
    if (this.oauth === null) {
      return this.failOutcome(UNAUTHORIZED, 'OAuth 未配置 client');
    }
    const cfg: OAuthClientConfig = this.oauth as OAuthClientConfig;

    this.store.setLoading(true);
    await HttpManager.clearAuthorization();

    const url: string =
      `${OAUTH_TOKEN_URL}?client_id=${cfg.clientId}&client_secret=${cfg.clientSecret}&code=${c}`;
    const res: HttpResult<Object> = await HttpManager.netFetch<Object>(url, 'GET', null, false, null);

    if (!res.result) {
      await this.rollbackOnFailure();
      const msg: string = res.msg ? res.msg : 'OAuth 兑换失败';
      return this.failOutcome(res.code, msg);
    }

    const accessToken: string = LoginUseCase.parseAccessToken(res.data);
    if (accessToken.length === 0) {
      await this.rollbackOnFailure();
      return this.failOutcome(UNAUTHORIZED, 'OAuth 未返回 access_token');
    }
    const authorization: string = `token ${accessToken}`;
    HttpManager.setAuthorization(authorization);
    await this.prefs.putString(KEY_USER_TOKEN, authorization);

    return await this.fetchUserAndCommit(authorization);
  }

  async logout(): Promise<void> {
    await HttpManager.clearAuthorization();
    await this.removePrefSafe(KEY_USER_TOKEN);
    await this.removePrefSafe(KEY_USER_INFO);
    await this.removePrefSafe(KEY_USER_BASIC);
    await this.removePrefSafe(KEY_USER_NAME);
    await this.removePrefSafe(KEY_USER_PASSWORD);

    if (this.userDao !== null) {
      try {
        await (this.userDao as UserDao).clear();
      } catch (_e) {
      }
    }

    this.store.clear();
    EventBus.emit(EVENT_USER_LOGGED_OUT, null);
  }

  private async fetchUserAndCommit(authorization: string): Promise<LoginOutcome> {
    const res: HttpResult<Object> = await HttpManager.netFetch<Object>(
      Address.getMyUserInfo(), 'GET', null, false, null);

    if (!res.result || res.data === null) {
      await this.rollbackOnFailure();
      const code: number = res.code === SUCCESS ? UNAUTHORIZED : res.code;
      const msg: string = res.msg ? res.msg : '登录校验失败';
      return this.failOutcome(code, msg);
    }

    const jsonString: string = JSON.stringify(res.data);
    const user: AuthUserInfo | null = AuthUserInfo.fromJson(jsonString);
    if (user === null || user.login.length === 0) {
      await this.rollbackOnFailure();
      return this.failOutcome(UNAUTHORIZED, '用户信息解析失败');
    }

    if (this.userDao !== null) {
      try {
        await (this.userDao as UserDao).save(USER_TABLE_INFO, user.login, jsonString);
      } catch (_e) {
      }
    }

    try {
      await this.prefs.putString(KEY_USER_INFO, jsonString);
    } catch (_e) {
    }

    this.store.setUser(authorization, user);
    EventBus.emit(EVENT_USER_LOGGED_IN, user);
    return HttpResult.ok<AuthUserInfo>(SUCCESS, user, res.headers);
  }

  private async rollbackOnFailure(): Promise<void> {
    await HttpManager.clearAuthorization();
    await this.removePrefSafe(KEY_USER_TOKEN);
    this.store.clear();
  }

  private async persistBasicCache(userName: string, password: string, basic: string): Promise<void> {
    await this.prefs.putString(KEY_USER_NAME, userName);
    await this.prefs.putString(KEY_USER_PASSWORD, password);
    await this.prefs.putString(KEY_USER_BASIC, basic);
  }

  private async removePrefSafe(key: string): Promise<void> {
    try {
      await this.prefs.remove(key);
    } catch (_e) {
    }
  }

  private failOutcome(code: number, msg: string): LoginOutcome {
    this.store.setError(msg);
    return HttpResult.fail<AuthUserInfo>(code, msg);
  }

  private static parseAccessToken(data: Object | null): string {
    if (data === null) {
      return '';
    }
    if (typeof data === 'string') {
      return LoginUseCase.parseAccessTokenFromForm(data as string);
    }
    const obj: Record<string, Object> = data as Record<string, Object>;
    const v: Object | undefined = obj['access_token'];
    if (typeof v === 'string' && (v as string).length > 0) {
      return v as string;
    }
    return '';
  }

  private static parseAccessTokenFromForm(body: string): string {
    if (!body || body.length === 0) {
      return '';
    }
    const trimmed: string = body.trim();
    if (trimmed.charAt(0) === '{') {
      try {
        const obj: Record<string, Object> = JSON.parse(trimmed) as Record<string, Object>;
        const v: Object | undefined = obj['access_token'];
        if (typeof v === 'string' && (v as string).length > 0) {
          return v as string;
        }
      } catch (_e) {
      }
    }
    const parts: string[] = trimmed.split('&');
    for (let i = 0; i < parts.length; i++) {
      const kv: string[] = parts[i].split('=');
      if (kv.length === 2 && kv[0] === 'access_token') {
        return decodeURIComponent(kv[1]);
      }
    }
    return '';
  }

  private static toBase64(input: string): string {
    const chars: string =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const bytes: number[] = [];
    for (let i = 0; i < input.length; i++) {
      const c: number = input.charCodeAt(i);
      if (c < 0x80) {
        bytes.push(c);
      } else if (c < 0x800) {
        bytes.push(0xc0 | (c >> 6));
        bytes.push(0x80 | (c & 0x3f));
      } else {
        bytes.push(0xe0 | (c >> 12));
        bytes.push(0x80 | ((c >> 6) & 0x3f));
        bytes.push(0x80 | (c & 0x3f));
      }
    }
    let out: string = '';
    let i: number = 0;
    while (i < bytes.length) {
      const b1: number = bytes[i++];
      const b2: number = i < bytes.length ? bytes[i++] : -1;
      const b3: number = i < bytes.length ? bytes[i++] : -1;
      const c1: number = b1 >> 2;
      const c2: number = ((b1 & 0x03) << 4) | (b2 >= 0 ? (b2 >> 4) : 0);
      const c3: number = b2 >= 0 ? (((b2 & 0x0f) << 2) | (b3 >= 0 ? (b3 >> 6) : 0)) : 64;
      const c4: number = b3 >= 0 ? (b3 & 0x3f) : 64;
      out += chars.charAt(c1) + chars.charAt(c2)
        + (c3 === 64 ? '=' : chars.charAt(c3))
        + (c4 === 64 ? '=' : chars.charAt(c4));
    }
    return out;
  }
}

export const DefaultLoginUseCase: LoginUseCase = new LoginUseCase();
