/**
 * GitHub 网络地址常量与构造器，与 RN 端
 * [address.js](../../../../../../../reactnative/GSYGithubApp/app/net/address.js) 的语义对齐。
 *
 * 仅提供 ArkTS 项目当前阶段会用到的最小集合：
 * - 鉴权 / 用户 / 仓库 / 搜索 / 通知 / 趋势 等接口的 URL 构造。
 * 不再使用 RN 端默认对象 + 箭头属性的写法，改为命名空间风格静态方法，
 * 便于 ArkTS 静态类型推导与 IDE 跳转。
 */

export const HOST_API: string = 'https://api.github.com/';
export const HOST_WEB: string = 'https://github.com/';
export const DOWNLOAD_URL: string = 'https://www.pgyer.com/GSYGithubApp';
export const GRAPHIC_HOST: string = 'https://ghchart.rshah.org';
export const TRENDING_API_HOST: string = 'https://guoshuyu.cn/github/trend/list';
export const TRENDING_GTREND_HOST: string = 'https://gtrend.yapie.me';
export const TRENDING_HUCHEN_HOST: string = 'https://ghapi.huchen.dev';

const DEFAULT_PAGE_SIZE: number = 30;

export class Address {
  static getAuthorization(): string {
    return `${HOST_API}authorizations`;
  }

  static getAuthorizationWeb(clientId: string): string {
    return `${HOST_WEB}login/oauth/authorize?client_id=${clientId}&state=app&scope=user,repo,gist,notifications,read:org,workflow&redirect_uri=gsygithubapp://authed`;
  }

  static search(q: string,
                sort: string | null,
                order: string | null,
                type: string | null,
                page: number,
                pageSize: number = DEFAULT_PAGE_SIZE): string {
    if (type === 'user') {
      return `${HOST_API}search/users?q=${q}&page=${page}&per_page=${pageSize}`;
    }
    const finalPage: number = page > 0 ? page : 1;
    const allowed: string[] = ['stars', 'forks', 'help-wanted-issues', 'updated'];
    const finalSort: string = sort && allowed.indexOf(sort) >= 0 ? sort : '';
    const finalOrder: string = order ? order : 'desc';
    let url: string = `${HOST_API}search/repositories?q=${q}&page=${finalPage}&per_page=${pageSize}`;
    if (finalSort.length > 0) {
      url += `&sort=${finalSort}&order=${finalOrder}`;
    }
    return url;
  }

  static searchTopic(topic: string): string {
    return `${HOST_API}search/repositories?q=topic:${topic}&sort=stars&order=desc`;
  }

  static getSearchRepos(q: string,
                        sort: string | null,
                        page: number,
                        pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalQ: string = q && q.length > 0 ? q : 'stars:>1';
    const finalSort: string = sort && sort.length > 0 ? sort : 'stars';
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}search/repositories?q=${finalQ}&sort=${finalSort}&page=${finalPage}&per_page=${finalSize}`;
  }

  static getSearchReposPageSize(): number {
    return DEFAULT_PAGE_SIZE;
  }

  static getSearchUsers(q: string,
                        sort: string | null,
                        page: number,
                        pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalQ: string = q && q.length > 0 ? q : 'a';
    const allowed: string[] = ['followers', 'repositories', 'joined'];
    const finalSort: string = sort && allowed.indexOf(sort) >= 0 ? sort : '';
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    let url: string = `${HOST_API}search/users?q=${finalQ}&page=${finalPage}&per_page=${finalSize}`;
    if (finalSort.length > 0) {
      url += `&sort=${finalSort}`;
    }
    return url;
  }

  static getSearchUsersPageSize(): number {
    return DEFAULT_PAGE_SIZE;
  }

  static getSearchIssues(q: string,
                         sort: string | null,
                         page: number,
                         pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalQ: string = q && q.length > 0 ? q : 'a';
    const finalSort: string = sort && sort.length > 0 ? sort : 'created';
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}search/issues?q=${finalQ}&sort=${finalSort}&page=${finalPage}&per_page=${finalSize}`;
  }

  static getSearchIssuesPageSize(): number {
    return DEFAULT_PAGE_SIZE;
  }

  static userRepos(userName: string, sort: string | null = null): string {
    const finalSort: string = sort ? sort : 'pushed';
    return `${HOST_API}users/${userName}/repos?sort=${finalSort}`;
  }

  static getReposDetail(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}`;
  }

  static getReposEvent(reposOwner: string, reposName: string): string {
    return `${HOST_API}networks/${reposOwner}/${reposName}/events`;
  }

  static getReposForks(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/forks`;
  }

  static getReposStar(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/stargazers`;
  }

  static getReposWatcher(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/subscribers`;
  }

  static getReposCommits(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/commits`;
  }

  static getReposCommitsPaged(reposOwner: string,
                              reposName: string,
                              page: number,
                              pageSize: number = DEFAULT_PAGE_SIZE,
                              branch: string | null = null): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    let url: string = `${HOST_API}repos/${reposOwner}/${reposName}/commits?page=${finalPage}&per_page=${finalSize}`;
    if (branch !== null && branch !== undefined && branch.length > 0) {
      url = url + `&sha=${encodeURIComponent(branch)}`;
    }
    return url;
  }

  static getReposCommitsInfo(reposOwner: string, reposName: string, sha: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/commits/${sha}`;
  }

  static getReposIssue(reposOwner: string,
                       reposName: string,
                       state: string | null = null,
                       sort: string | null = null,
                       direction: string | null = null): string {
    const finalState: string = state ? state : 'all';
    const finalSort: string = sort ? sort : 'created';
    const finalDirection: string = direction ? direction : 'desc';
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues?state=${finalState}&sort=${finalSort}&direction=${finalDirection}`;
  }

  static getReposRelease(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/releases`;
  }

  static getReposTag(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/tags`;
  }

  static getReposContributors(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/contributors`;
  }

  static getIssueComment(reposOwner: string, reposName: string, issueNumber: number): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues/${issueNumber}/comments`;
  }

  static createIssue(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues`;
  }

  static getIssueInfo(reposOwner: string, reposName: string, issueNumber: number): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues/${issueNumber}`;
  }

  static repositoryIssueSearch(q: string): string {
    return `${HOST_API}search/issues?q=${q}`;
  }

  static getRepositoryIssueSearch(fullName: string,
                                  state: string | null,
                                  query: string,
                                  page: number,
                                  pageSize: number = DEFAULT_PAGE_SIZE): string {
    const safeFullName: string = fullName !== null && fullName !== undefined ? fullName : '';
    const finalState: string = state !== null && state !== undefined && state.length > 0
      ? state : 'all';
    const safeQuery: string = query !== null && query !== undefined ? query.trim() : '';
    const queryPart: string = safeQuery.replace(/\s+/g, '+');
    const statePart: string = finalState === 'all' ? '' : `+state:${finalState}`;
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}search/issues?q=${queryPart}+repo:${safeFullName}${statePart}&page=${finalPage}&per_page=${finalSize}`;
  }

  static myStar(sort: string | null = null): string {
    const finalSort: string = sort ? sort : 'updated';
    return `${HOST_API}user/starred?sort=${finalSort}`;
  }

  static userStar(userName: string, sort: string | null = null): string {
    const finalSort: string = sort ? sort : 'updated';
    return `${HOST_API}users/${userName}/starred?sort=${finalSort}`;
  }

  static resolveStarRepos(reposOwner: string, repos: string): string {
    return `${HOST_API}user/starred/${reposOwner}/${repos}`;
  }

  static resolveWatcherRepos(reposOwner: string, repos: string): string {
    return `${HOST_API}user/subscriptions/${reposOwner}/${repos}`;
  }

  static reposDataDir(reposOwner: string, repos: string, path: string, branch: string = 'master'): string {
    const refSuffix: string = branch ? `?ref=${branch}` : '';
    return `${HOST_API}repos/${reposOwner}/${repos}/contents/${path}${refSuffix}`;
  }

  static readmeFile(reposNameFullName: string, curBranch: string | null = null): string {
    const refSuffix: string = curBranch ? `?ref=${curBranch}` : '';
    return `${HOST_API}repos/${reposNameFullName}/readme${refSuffix}`;
  }

  static getMyUserInfo(): string {
    return `${HOST_API}user`;
  }

  static getUserInfo(userName: string): string {
    return `${HOST_API}users/${userName}`;
  }

  static doFollow(name: string): string {
    return `${HOST_API}user/following/${name}`;
  }

  static getUserFollow(userName: string): string {
    return `${HOST_API}users/${userName}/following`;
  }

  static getMyFollower(): string {
    return `${HOST_API}user/followers`;
  }

  static getUserFollower(userName: string): string {
    return `${HOST_API}users/${userName}/followers`;
  }

  static createFork(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/forks`;
  }

  static getBranches(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/branches`;
  }

  static getReadme(reposOwner: string, reposName: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/readme`;
  }

  static getEventReceived(userName: string): string {
    return `${HOST_API}users/${userName}/received_events`;
  }

  static getReceivedEvent(userName: string,
                          page: number,
                          pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}users/${userName}/received_events?page=${finalPage}&per_page=${finalSize}`;
  }

  static getReceivedEventPageSize(): number {
    return DEFAULT_PAGE_SIZE;
  }

  static getEvent(userName: string): string {
    return `${HOST_API}users/${userName}/events`;
  }

  static getUserEvent(userName: string,
                      page: number,
                      pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}users/${userName}/events?page=${finalPage}&per_page=${finalSize}`;
  }

  static getUserEventPageSize(): number {
    return DEFAULT_PAGE_SIZE;
  }

  static getMember(orgs: string): string {
    return `${HOST_API}orgs/${orgs}/members`;
  }

  static getOrgMembers(orgs: string,
                       page: number,
                       pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}orgs/${orgs}/members?page=${finalPage}&per_page=${finalSize}`;
  }

  static getUserOrgs(userName: string): string {
    return `${HOST_API}users/${userName}/orgs`;
  }

  static getUserOrgsPaged(userName: string,
                          page: number,
                          pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}users/${userName}/orgs?page=${finalPage}&per_page=${finalSize}`;
  }

  static getUserStarred(userName: string,
                        page: number,
                        pageSize: number = DEFAULT_PAGE_SIZE,
                        sort: string | null = null): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    const finalSort: string = sort && sort.length > 0 ? sort : 'updated';
    return `${HOST_API}users/${userName}/starred?sort=${finalSort}&page=${finalPage}&per_page=${finalSize}`;
  }

  static getNotification(all: boolean | null = null, participating: boolean | null = null): string {
    if (all === null && participating === null) {
      return `${HOST_API}notifications`;
    }
    const finalAll: boolean = all === null ? false : all;
    const finalParticipating: boolean = participating === null ? false : participating;
    return `${HOST_API}notifications?all=${finalAll}&participating=${finalParticipating}`;
  }

  static getNotifications(all: boolean,
                          participating: boolean,
                          page: number,
                          pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}notifications?all=${all}&participating=${participating}&page=${finalPage}&per_page=${finalSize}`;
  }

  static getNotificationPageSize(): number {
    return DEFAULT_PAGE_SIZE;
  }

  static setNotificationAsRead(threadId: string): string {
    return `${HOST_API}notifications/threads/${threadId}`;
  }

  static markNotificationsThread(threadId: string): string {
    return `${HOST_API}notifications/threads/${threadId}`;
  }

  static setAllNotificationAsRead(): string {
    return `${HOST_API}notifications`;
  }

  static markRepoNotifications(fullName: string): string {
    return `${HOST_API}repos/${fullName}/notifications`;
  }

  static trending(since: string, languageType: string | null = null): string {
    if (languageType) {
      return `${HOST_WEB}trending/${languageType}?since=${since}`;
    }
    return `${HOST_WEB}trending?since=${since}`;
  }

  static trendingApi(since: string, languageType: string | null = null): string {
    if (languageType !== null) {
      return `${TRENDING_API_HOST}?languageType=${languageType}&since=${since}`;
    }
    return `${TRENDING_API_HOST}?since=${since}`;
  }

  static trendingRepositories(since: string,
                              languageType: string | null = null,
                              host: string = TRENDING_GTREND_HOST): string {
    const base: string = host && host.length > 0 ? host : TRENDING_GTREND_HOST;
    if (languageType !== null && languageType.length > 0) {
      return `${base}/repositories?since=${since}&language=${encodeURIComponent(languageType)}`;
    }
    return `${base}/repositories?since=${since}`;
  }

  static trendingRepositoriesGtrend(since: string, languageType: string | null = null): string {
    return Address.trendingRepositories(since, languageType, TRENDING_GTREND_HOST);
  }

  static trendingRepositoriesHuchen(since: string, languageType: string | null = null): string {
    return Address.trendingRepositories(since, languageType, TRENDING_HUCHEN_HOST);
  }

  static getPageParams(tab: string, page: number, pageSize: number = DEFAULT_PAGE_SIZE): string {
    if (page > 0) {
      if (pageSize > 0) {
        return `${tab}page=${page}&per_page=${pageSize}`;
      }
      return `${tab}page=${page}`;
    }
    return '';
  }

  static getUserRepos(login: string,
                      page: number,
                      sort: string | null = null,
                      pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalSort: string = sort ? sort : 'pushed';
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}users/${login}/repos?sort=${finalSort}&page=${finalPage}&per_page=${finalSize}`;
  }

  static getUserReposPageSize(): number {
    return DEFAULT_PAGE_SIZE;
  }

  static getFollowStatus(login: string): string {
    return `${HOST_API}user/following/${login}`;
  }

  static setFollow(login: string): string {
    return `${HOST_API}user/following/${login}`;
  }

  static setUnfollow(login: string): string {
    return `${HOST_API}user/following/${login}`;
  }

  static getReposReadme(reposOwner: string,
                        reposName: string,
                        branch: string | null = null): string {
    const refSuffix: string = branch !== null && branch.length > 0 ? `?ref=${branch}` : '';
    return `${HOST_API}repos/${reposOwner}/${reposName}/readme${refSuffix}`;
  }

  static getStar(reposOwner: string, reposName: string): string {
    return `${HOST_API}user/starred/${reposOwner}/${reposName}`;
  }

  static setStar(reposOwner: string, reposName: string): string {
    return `${HOST_API}user/starred/${reposOwner}/${reposName}`;
  }

  static setUnstar(reposOwner: string, reposName: string): string {
    return `${HOST_API}user/starred/${reposOwner}/${reposName}`;
  }

  static getWatch(reposOwner: string, reposName: string): string {
    return `${HOST_API}user/subscriptions/${reposOwner}/${reposName}`;
  }

  static setWatch(reposOwner: string, reposName: string): string {
    return `${HOST_API}user/subscriptions/${reposOwner}/${reposName}`;
  }

  static setUnwatch(reposOwner: string, reposName: string): string {
    return `${HOST_API}user/subscriptions/${reposOwner}/${reposName}`;
  }

  static getRepositoryEvent(reposOwner: string,
                            reposName: string,
                            page: number,
                            pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}repos/${reposOwner}/${reposName}/events?page=${finalPage}&per_page=${finalSize}`;
  }

  static getReposFileDir(reposOwner: string,
                         reposName: string,
                         path: string = '',
                         branch: string | null = null): string {
    const safePath: string = path === null || path === undefined ? '' : path;
    const refSuffix: string = branch !== null && branch !== undefined && branch.length > 0
      ? `?ref=${branch}` : '';
    return `${HOST_API}repos/${reposOwner}/${reposName}/contents/${safePath}${refSuffix}`;
  }

  static getRepositoryIssue(reposOwner: string,
                            reposName: string,
                            page: number,
                            state: string | null = null,
                            pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalState: string = state !== null && state !== undefined && state.length > 0
      ? state : 'all';
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues?state=${finalState}&page=${finalPage}&per_page=${finalSize}`;
  }

  static getRepositoryPageSize(): number {
    return DEFAULT_PAGE_SIZE;
  }

  static getRepositoryStars(reposOwner: string,
                             reposName: string,
                             page: number,
                             pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}repos/${reposOwner}/${reposName}/stargazers?page=${finalPage}&per_page=${finalSize}`;
  }

  static getRepositoryForks(reposOwner: string,
                             reposName: string,
                             page: number,
                             pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}repos/${reposOwner}/${reposName}/forks?page=${finalPage}&per_page=${finalSize}`;
  }

  static getRepositoryWatchers(reposOwner: string,
                                reposName: string,
                                page: number,
                                pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}repos/${reposOwner}/${reposName}/subscribers?page=${finalPage}&per_page=${finalSize}`;
  }

  static getUserFollowers(userName: string,
                           page: number,
                           pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}users/${userName}/followers?page=${finalPage}&per_page=${finalSize}`;
  }

  static getUserFollowed(userName: string,
                          page: number,
                          pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}users/${userName}/following?page=${finalPage}&per_page=${finalSize}`;
  }

  static getSubListPageSize(): number {
    return DEFAULT_PAGE_SIZE;
  }

  static getIssue(reposOwner: string, reposName: string, issueNumber: number): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues/${issueNumber}`;
  }

  static getIssueComments(reposOwner: string,
                          reposName: string,
                          issueNumber: number,
                          page: number,
                          pageSize: number = DEFAULT_PAGE_SIZE): string {
    const finalPage: number = page > 0 ? page : 1;
    const finalSize: number = pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues/${issueNumber}/comments?page=${finalPage}&per_page=${finalSize}`;
  }

  static createIssueComment(reposOwner: string, reposName: string, issueNumber: number): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues/${issueNumber}/comments`;
  }

  static setIssueState(reposOwner: string, reposName: string, issueNumber: number): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues/${issueNumber}`;
  }

  static editIssue(reposOwner: string, reposName: string, issueNumber: number): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues/${issueNumber}`;
  }

  static lockIssue(reposOwner: string, reposName: string, issueNumber: number): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues/${issueNumber}/lock`;
  }

  static editIssueComment(reposOwner: string, reposName: string, commentId: number): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/issues/comments/${commentId}`;
  }

  static getIssuePageSize(): number {
    return DEFAULT_PAGE_SIZE;
  }

  static getCommitDetail(reposOwner: string, reposName: string, sha: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/commits/${sha}`;
  }

  static getCommitDiff(reposOwner: string, reposName: string, sha: string): string {
    return `${HOST_API}repos/${reposOwner}/${reposName}/commits/${sha}`;
  }

  static getRawFile(reposOwner: string,
                    reposName: string,
                    branch: string,
                    path: string): string {
    const safeBranch: string = branch !== null && branch !== undefined && branch.length > 0
      ? branch : 'master';
    const safePath: string = path !== null && path !== undefined ? path : '';
    const trimmed: string = safePath.indexOf('/') === 0 ? safePath.substring(1) : safePath;
    return `${HOST_WEB}${reposOwner}/${reposName}/raw/${safeBranch}/${trimmed}`;
  }

  static getReposIssueByFullName(fullName: string,
                                 state: string | null,
                                 page: number,
                                 pageSize: number = DEFAULT_PAGE_SIZE): string {
    const safe: string = fullName !== null && fullName !== undefined ? fullName : '';
    const idx: number = safe.indexOf('/');
    if (idx < 0) {
      return Address.getRepositoryIssue(safe, '', page, state, pageSize);
    }
    const owner: string = safe.substring(0, idx);
    const name: string = safe.substring(idx + 1);
    return Address.getRepositoryIssue(owner, name, page, state, pageSize);
  }

  static getReposEventsByFullName(fullName: string,
                                  page: number,
                                  pageSize: number = DEFAULT_PAGE_SIZE): string {
    const safe: string = fullName !== null && fullName !== undefined ? fullName : '';
    const idx: number = safe.indexOf('/');
    if (idx < 0) {
      return Address.getRepositoryEvent(safe, '', page, pageSize);
    }
    const owner: string = safe.substring(0, idx);
    const name: string = safe.substring(idx + 1);
    return Address.getRepositoryEvent(owner, name, page, pageSize);
  }
}
