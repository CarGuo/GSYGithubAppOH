/**
 * AuthStore —— 全局登录态容器，对齐 RN 端 Redux
 * [store/actions/login.js](../../../../../../../reactnative/GSYGithubApp/app/store/actions/login.js)
 * 与 [store/actions/user.js](../../../../../../../reactnative/GSYGithubApp/app/store/actions/user.js) 的语义：
 *
 * - 字段：authed / loading / error / userInfo / token，对应 RN 端
 *   `LOGIN.IN | LOGIN.CLEAR` + `USER.USER_INFO` 派发后的最终视图模型。
 * - 通过 ArkUI 的 `@Observed` 让该实例可被 `@ObjectLink` / `@Prop` 直接订阅。
 * - 通过 `AppStorage` 镜像同步状态，便于跨页面 / 顶层 Provider 监听
 *   （ArkUI 推荐做法），等价 RN 端 `connect(state => ({state}))`。
 * - 仅承载状态与状态迁移，不直接发起网络请求；具体登录流程在
 *   [LoginUseCase.ets](../auth/LoginUseCase.ets) 中编排。
 */

export const APP_STORAGE_KEY_AUTHED: string = 'auth.authed';
export const APP_STORAGE_KEY_LOADING: string = 'auth.loading';
export const APP_STORAGE_KEY_ERROR: string = 'auth.error';
export const APP_STORAGE_KEY_TOKEN: string = 'auth.token';
export const APP_STORAGE_KEY_USER_LOGIN: string = 'auth.userLogin';
export const APP_STORAGE_KEY_USER_INFO: string = 'auth.userInfo';

export class AuthUserInfo {
  login: string;
  name: string;
  avatarUrl: string;
  htmlUrl: string;
  raw: string;
  bio: string;
  followers: number;
  following: number;
  publicRepos: number;
  company: string;
  location: string;
  blog: string;
  createdAt: string;
  type: string;
  starred: string;

  constructor(login: string = '',
              name: string = '',
              avatarUrl: string = '',
              htmlUrl: string = '',
              raw: string = '',
              bio: string = '',
              followers: number = 0,
              following: number = 0,
              publicRepos: number = 0,
              company: string = '',
              location: string = '',
              blog: string = '',
              createdAt: string = '',
              type: string = '',
              starred: string = '') {
    this.login = login;
    this.name = name;
    this.avatarUrl = avatarUrl;
    this.htmlUrl = htmlUrl;
    this.raw = raw;
    this.bio = bio;
    this.followers = followers;
    this.following = following;
    this.publicRepos = publicRepos;
    this.company = company;
    this.location = location;
    this.blog = blog;
    this.createdAt = createdAt;
    this.type = type;
    this.starred = starred;
  }

  static fromJson(jsonString: string): AuthUserInfo | null {
    if (!jsonString || jsonString.length === 0) {
      return null;
    }
    let parsed: Record<string, Object> | null = null;
    try {
      parsed = JSON.parse(jsonString) as Record<string, Object>;
    } catch (_e) {
      return null;
    }
    if (!parsed) {
      return null;
    }
    const login: string = AuthUserInfo.readString(parsed, 'login');
    const name: string = AuthUserInfo.readString(parsed, 'name');
    const avatarUrl: string = AuthUserInfo.readString(parsed, 'avatar_url');
    const htmlUrl: string = AuthUserInfo.readString(parsed, 'html_url');
    const bio: string = AuthUserInfo.readString(parsed, 'bio');
    const followers: number = AuthUserInfo.readNumber(parsed, 'followers');
    const following: number = AuthUserInfo.readNumber(parsed, 'following');
    const publicRepos: number = AuthUserInfo.readNumber(parsed, 'public_repos');
    const company: string = AuthUserInfo.readString(parsed, 'company');
    const location: string = AuthUserInfo.readString(parsed, 'location');
    const blog: string = AuthUserInfo.readString(parsed, 'blog');
    const createdAt: string = AuthUserInfo.readString(parsed, 'created_at');
    const type: string = AuthUserInfo.readString(parsed, 'type');
    const starred: string = AuthUserInfo.readString(parsed, 'starred');
    return new AuthUserInfo(login, name, avatarUrl, htmlUrl, jsonString,
      bio, followers, following, publicRepos,
      company, location, blog, createdAt, type, starred);
  }

  private static readString(obj: Record<string, Object>, key: string): string {
    const v: Object | undefined = obj[key];
    if (typeof v === 'string') {
      return v as string;
    }
    if (v === null || v === undefined) {
      return '';
    }
    return String(v);
  }

  private static readNumber(obj: Record<string, Object>, key: string): number {
    const v: Object | undefined = obj[key];
    if (typeof v === 'number') {
      return v as number;
    }
    if (typeof v === 'string') {
      const n: number = Number.parseInt(v as string, 10);
      return Number.isNaN(n) ? 0 : n;
    }
    return 0;
  }
}

@Observed
export class AuthStore {
  authed: boolean = false;
  loading: boolean = false;
  error: string = '';
  userInfo: AuthUserInfo | null = null;
  token: string = '';

  private syncEnabled: boolean = true;

  setLoading(loading: boolean): void {
    this.loading = loading;
    if (loading) {
      this.error = '';
      this.writeAppStorage(APP_STORAGE_KEY_ERROR, '');
    }
    this.writeAppStorage(APP_STORAGE_KEY_LOADING, loading);
  }

  setError(message: string): void {
    this.error = message ? message : '';
    this.loading = false;
    this.writeAppStorage(APP_STORAGE_KEY_ERROR, this.error);
    this.writeAppStorage(APP_STORAGE_KEY_LOADING, false);
  }

  setUser(token: string, user: AuthUserInfo | null): void {
    const trimToken: string = token ? token : '';
    this.token = trimToken;
    this.userInfo = user;
    this.authed = trimToken.length > 0 && user !== null;
    this.loading = false;
    this.error = '';
    this.writeAppStorage(APP_STORAGE_KEY_TOKEN, trimToken);
    this.writeAppStorage(APP_STORAGE_KEY_AUTHED, this.authed);
    this.writeAppStorage(APP_STORAGE_KEY_LOADING, false);
    this.writeAppStorage(APP_STORAGE_KEY_ERROR, '');
    this.writeAppStorage(APP_STORAGE_KEY_USER_LOGIN, user ? user.login : '');
    this.writeAppStorage(APP_STORAGE_KEY_USER_INFO, user ? user.raw : '');
  }

  clear(): void {
    this.authed = false;
    this.loading = false;
    this.error = '';
    this.userInfo = null;
    this.token = '';
    this.writeAppStorage(APP_STORAGE_KEY_AUTHED, false);
    this.writeAppStorage(APP_STORAGE_KEY_LOADING, false);
    this.writeAppStorage(APP_STORAGE_KEY_ERROR, '');
    this.writeAppStorage(APP_STORAGE_KEY_TOKEN, '');
    this.writeAppStorage(APP_STORAGE_KEY_USER_LOGIN, '');
    this.writeAppStorage(APP_STORAGE_KEY_USER_INFO, '');
  }

  setAppStorageSyncEnabled(enabled: boolean): void {
    this.syncEnabled = enabled;
  }

  private writeAppStorage(key: string, value: string | boolean): void {
    if (!this.syncEnabled) {
      return;
    }
    try {
      if (typeof value === 'boolean') {
        AppStorage.setOrCreate<boolean>(key, value as boolean);
      } else {
        AppStorage.setOrCreate<string>(key, value as string);
      }
    } catch (_e) {
    }
  }
}

export const GlobalAuthStore: AuthStore = new AuthStore();
