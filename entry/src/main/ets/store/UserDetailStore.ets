export interface UserDetail {
  id: number;
  login: string;
  name: string;
  avatar_url: string;
  bio: string;
  company: string;
  location: string;
  email: string;
  blog: string;
  type: string;
  followers: number;
  following: number;
  public_repos: number;
  public_gists: number;
  created_at: string;
  updated_at: string;
  starred: string;
}

export interface UserOrgItem {
  id: number;
  login: string;
  avatar_url: string;
}

export interface UserRepoItem {
  id: number;
  name: string;
  full_name: string;
  description: string;
  language: string;
  stargazers_count: number;
  forks_count: number;
  watchers_count: number;
  open_issues_count: number;
  fork: boolean;
  private: boolean;
  html_url: string;
  owner_login: string;
  pushed_at: string;
  updated_at: string;
}

export function emptyUserDetail(): UserDetail {
  return {
    'id': 0,
    'login': '',
    'name': '',
    'avatar_url': '',
    'bio': '',
    'company': '',
    'location': '',
    'email': '',
    'blog': '',
    'type': '',
    'followers': 0,
    'following': 0,
    'public_repos': 0,
    'public_gists': 0,
    'created_at': '',
    'updated_at': '',
    'starred': '',
  } as UserDetail;
}

/**
 * GitHub API 经常对 name / bio / company / location / email / blog 等字段返回 null。
 * ArkTS strict-null 下对 null 调 .length 会直接抛错，
 * 因此在写入 store 之前把所有可能为 null 的字符串字段统一兜底为 ''。
 * 与 RN 端 UserDetailReducer 的 PayloadObjectKey 行为一致：
 *   [reducer/user.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/store/reducers/user.js)
 *   会在使用前先 `userInfo && userInfo.name` 这样保护，OH 端等价地把字段在 store 入口归一化。
 */
export function sanitizeUserDetail(user: UserDetail | null | undefined): UserDetail {
  if (user === null || user === undefined) {
    return emptyUserDetail();
  }
  const safe: UserDetail = emptyUserDetail();
  const src: Record<string, Object | null | undefined> = user as Object as Record<string, Object | null | undefined>;
  const dst: Record<string, Object> = safe as Object as Record<string, Object>;

  const stringKeys: string[] = [
    'login', 'name', 'avatar_url', 'bio', 'company',
    'location', 'email', 'blog', 'type', 'created_at', 'updated_at', 'starred',
  ];
  for (let i = 0; i < stringKeys.length; i++) {
    const key: string = stringKeys[i];
    const v: Object | null | undefined = src[key];
    dst[key] = (v === null || v === undefined) ? '' : v as Object;
  }

  const numberKeys: string[] = [
    'id', 'followers', 'following', 'public_repos', 'public_gists',
  ];
  for (let i = 0; i < numberKeys.length; i++) {
    const key: string = numberKeys[i];
    const v: Object | null | undefined = src[key];
    dst[key] = (v === null || v === undefined) ? 0 : v as Object;
  }

  return safe;
}

@Observed
export class UserDetailStore {
  user: UserDetail = emptyUserDetail();
  repos: UserRepoItem[] = [];
  orgsList: UserOrgItem[] = [];
  starredCount: number = 0;
  beStaredCount: number = 0;
  followed: boolean = false;
  loading: boolean = false;
  page: number = 1;
  hasMore: boolean = true;
  error: string = '';

  reset(): void {
    this.user = emptyUserDetail();
    this.repos = [];
    this.orgsList = [];
    this.starredCount = 0;
    this.beStaredCount = 0;
    this.followed = false;
    this.loading = false;
    this.page = 1;
    this.hasMore = true;
    this.error = '';
  }

  startLoading(): void {
    this.loading = true;
    this.error = '';
  }

  finishLoading(): void {
    this.loading = false;
  }

  setError(msg: string): void {
    this.error = msg;
    this.loading = false;
  }

  applyUser(user: UserDetail): void {
    this.user = sanitizeUserDetail(user);
    const n: number = Number.parseInt(this.user.starred, 10);
    this.starredCount = Number.isNaN(n) ? 0 : n;
    this.error = '';
  }

  applyStarredCount(count: number): void {
    this.starredCount = count > 0 ? count : 0;
    const next: UserDetail = sanitizeUserDetail(this.user);
    next.starred = this.starredCount.toString();
    this.user = next;
  }

  applyFollowed(followed: boolean): void {
    this.followed = followed;
  }

  applyReposRefresh(repos: UserRepoItem[], pageSize: number): void {
    this.repos = repos.slice();
    this.page = 1;
    this.hasMore = repos.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyReposAppend(repos: UserRepoItem[], page: number, pageSize: number): void {
    const merged: UserRepoItem[] = this.repos.slice();
    for (let i = 0; i < repos.length; i++) {
      merged.push(repos[i]);
    }
    this.repos = merged;
    this.page = page;
    this.hasMore = repos.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyReposCachedFallback(repos: UserRepoItem[]): void {
    this.repos = repos.slice();
    this.page = 1;
    this.hasMore = false;
    this.loading = false;
  }
}
