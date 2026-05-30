/**
 * CommonListPage —— 通用列表页（user_repos / user_star / follower / followed / user_be_stared）
 * 严格对齐 RN [ListPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ListPage.js)
 * 设计：dataType 决定接口分支；showType 决定行模板（user / repository）；localData 用于 user_be_stared 直接渲染。
 *
 * HARD-LAW-1：本文件由 RN ListPage.js + UserHeadItem.js 五处 Actions.ListPage 调用点抽源得来。
 * HARD-LAW-2：颜色/字号/间距全部走 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets)。
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { I18n } from '../i18n/I18n';
import { PullLoadMoreController } from '../common/PullLoadMoreList';
import { GSYColor } from '../style/Theme';
import { AppBar } from '../common/AppBar';
import {
  RepositoryService,
  SubListResult,
  SubUserItem,
  SubRepositoryItem
} from '../service/RepositoryService';
import { RepositoryDetailStore } from '../store/RepositoryDetailStore';
import {
  UserService,
  FetchSubUserListResult,
  FetchUserReposResult
} from '../service/UserService';
import { UserDetailStore, UserRepoItem } from '../store/UserDetailStore';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { SubListView, SubListMode } from './sub/SubListView';

const FALLBACK_LOGIN: string = '';
const FALLBACK_TITLE: string = '';

interface UserRepoOwnerLikeOwner {
  login?: string;
  avatar_url?: string;
}

interface UserRepoOwnerLike {
  owner?: UserRepoOwnerLikeOwner;
}

export const COMMON_LIST_DATA_TYPE_FOLLOWER: string = 'follower';
export const COMMON_LIST_DATA_TYPE_FOLLOWED: string = 'followed';
export const COMMON_LIST_DATA_TYPE_FOLLOWING: string = 'following';
export const COMMON_LIST_DATA_TYPE_REPOSITORIES: string = 'repositories';
export const COMMON_LIST_DATA_TYPE_STARGAZERS: string = 'stargazers';
export const COMMON_LIST_DATA_TYPE_REPO_STAR: string = 'repo_star';
export const COMMON_LIST_DATA_TYPE_WATCHERS: string = 'watchers';
export const COMMON_LIST_DATA_TYPE_REPO_WATCHER: string = 'repo_watcher';
export const COMMON_LIST_DATA_TYPE_FORKS: string = 'forks';
export const COMMON_LIST_DATA_TYPE_REPO_FORK: string = 'repo_fork';
export const COMMON_LIST_DATA_TYPE_USER_REPOS: string = 'user_repos';
export const COMMON_LIST_DATA_TYPE_USER_STAR: string = 'user_star';
export const COMMON_LIST_DATA_TYPE_USER_BE_STARED: string = 'user_be_stared';
export const COMMON_LIST_DATA_TYPE_USER_ORGS: string = 'user_orgs';
export const COMMON_LIST_DATA_TYPE_TOPICS: string = 'topics';

export const COMMON_LIST_SHOW_TYPE_USER: string = 'user';
export const COMMON_LIST_SHOW_TYPE_REPOSITORY: string = 'repository';

interface CommonListRouteParam {
  dataType: string;
  showType: string;
  currentUser: string;
  title: string;
  repoName?: string;
  localData?: SubRepositoryItem[];
}

interface UserDetailRouteParam {
  login: string;
}

interface RepoDetailRouteParam {
  owner: string;
  name: string;
  fullName: string;
  ownerName: string;
  reposName: string;
}

@Component
export struct CommonListPage {
  initialParam: Object | null = null;
  @State dataType: string = COMMON_LIST_DATA_TYPE_USER_REPOS;
  @State showType: string = COMMON_LIST_SHOW_TYPE_REPOSITORY;
  @State currentUser: string = FALLBACK_LOGIN;
  @State repoName: string = '';
  @State title: string = FALLBACK_TITLE;
  @State users: SubUserItem[] = [];
  @State repos: SubRepositoryItem[] = [];
  @State page: number = 1;
  @State hasMore: boolean = true;
  @State error: string = '';
  @State plmController: PullLoadMoreController = new PullLoadMoreController();
  private localData: SubRepositoryItem[] = [];
  private userStore: UserDetailStore = new UserDetailStore();
  private repoStore: RepositoryDetailStore = new RepositoryDetailStore();
  private userService: UserService = new UserService(this.userStore);
  private repoService: RepositoryService = new RepositoryService(this.repoStore);
  private pageSize: number = 30;

  aboutToAppear(): void {
    this.userService = new UserService(this.userStore);
    this.repoService = new RepositoryService(this.repoStore);
    this.pageSize = this.userService.getPageSize();
    if (this.initialParam !== null) {
      const ok: boolean = this.applyParamObj(this.initialParam);
      hilog.info(0x6666, 'CommonList', 'aboutToAppear initialParam ok=%{public}s dataType=%{public}s user=%{public}s',
        String(ok), this.dataType, this.currentUser);
    }
  }

  private applyParamObj(rawParam: Object | null | undefined): boolean {
    if (rawParam === undefined || rawParam === null) {
      return false;
    }
    const obj: CommonListRouteParam = rawParam as CommonListRouteParam;
    let touched: boolean = false;
    if (obj.dataType !== undefined && obj.dataType !== null && obj.dataType.length > 0) {
      this.dataType = obj.dataType;
      touched = true;
    }
    if (obj.showType !== undefined && obj.showType !== null && obj.showType.length > 0) {
      this.showType = obj.showType;
      touched = true;
    }
    if (obj.currentUser !== undefined && obj.currentUser !== null) {
      this.currentUser = obj.currentUser;
      if (obj.currentUser.length > 0) {
        touched = true;
      }
    }
    if (obj.repoName !== undefined && obj.repoName !== null) {
      this.repoName = obj.repoName;
      if (obj.repoName.length > 0) {
        touched = true;
      }
    }
    if (obj.title !== undefined && obj.title !== null) {
      this.title = obj.title;
    }
    if (obj.localData !== undefined && obj.localData !== null) {
      this.localData = obj.localData.slice();
    }
    return touched;
  }

  private resolveParamFromCtx(ctx: NavDestinationContext): boolean {
    let ok: boolean = false;
    try {
      const info: NavPathInfo | undefined = ctx.pathInfo;
      if (info !== undefined && info !== null) {
        const param: Object | undefined = info.param as Object | undefined;
        ok = this.applyParamObj(param === undefined ? null : param);
      }
    } catch (_e) {
      ok = false;
    }
    if (ok) {
      return true;
    }
    try {
      const stack: NavPathStack | undefined = ctx.pathStack;
      if (stack !== undefined && stack !== null) {
        const all: string[] = stack.getAllPathName();
        if (all !== undefined && all !== null && all.length > 0) {
          const idx: number = all.length - 1;
          const fromStack: Object | undefined = stack.getParamByIndex(idx) as Object | undefined;
          ok = this.applyParamObj(fromStack === undefined ? null : fromStack);
        }
      }
    } catch (_e) {
      ok = false;
    }
    return ok;
  }

  private mapUserRepoToSub(item: UserRepoItem): SubRepositoryItem {
    const raw: UserRepoOwnerLike = item as UserRepoOwnerLike;
    let avatar: string = '';
    let ownerLogin: string = '';
    if (raw.owner !== undefined && raw.owner !== null) {
      const a: string | null | undefined = raw.owner.avatar_url;
      if (a !== undefined && a !== null) {
        avatar = a;
      }
      const l: string | null | undefined = raw.owner.login;
      if (l !== undefined && l !== null) {
        ownerLogin = l;
      }
    }
    if (ownerLogin.length === 0 && item.owner_login !== undefined && item.owner_login !== null) {
      ownerLogin = item.owner_login;
    }
    if (ownerLogin.length === 0 && item.full_name !== undefined && item.full_name !== null) {
      const slash: number = item.full_name.indexOf('/');
      if (slash > 0) {
        ownerLogin = item.full_name.substring(0, slash);
      }
    }
    const safeName: string = item.name !== undefined && item.name !== null ? item.name : '';
    return {
      id: item.id !== undefined && item.id !== null ? item.id : 0,
      name: safeName,
      full_name: item.full_name !== undefined && item.full_name !== null ? item.full_name : '',
      description: item.description !== undefined && item.description !== null ? item.description : '',
      language: item.language !== undefined && item.language !== null ? item.language : '',
      stargazers_count: item.stargazers_count !== undefined && item.stargazers_count !== null ? item.stargazers_count : 0,
      forks_count: item.forks_count !== undefined && item.forks_count !== null ? item.forks_count : 0,
      watchers_count: item.watchers_count !== undefined && item.watchers_count !== null ? item.watchers_count : 0,
      owner_login: ownerLogin,
      owner_avatar_url: avatar,
    } as SubRepositoryItem;
  }

  private mapUserRepoList(list: UserRepoItem[]): SubRepositoryItem[] {
    const out: SubRepositoryItem[] = [];
    for (let i: number = 0; i < list.length; i++) {
      out.push(this.mapUserRepoToSub(list[i]));
    }
    return out;
  }

  private normalizedDataType(): string {
    if (this.dataType === COMMON_LIST_DATA_TYPE_REPOSITORIES) {
      return COMMON_LIST_DATA_TYPE_USER_REPOS;
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_FOLLOWING) {
      return COMMON_LIST_DATA_TYPE_FOLLOWED;
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_REPO_STAR) {
      return COMMON_LIST_DATA_TYPE_STARGAZERS;
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_REPO_WATCHER) {
      return COMMON_LIST_DATA_TYPE_WATCHERS;
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_REPO_FORK) {
      return COMMON_LIST_DATA_TYPE_FORKS;
    }
    return this.dataType;
  }

  private repoFullName(): string {
    if (this.currentUser.indexOf('/') > 0 && this.repoName.length === 0) {
      return this.currentUser;
    }
    if (this.currentUser.length === 0 || this.repoName.length === 0) {
      return '';
    }
    return this.currentUser + '/' + this.repoName;
  }

  private titleRepoName(): string {
    if (this.repoName.length > 0) {
      return this.repoName;
    }
    const slash: number = this.currentUser.indexOf('/');
    if (slash >= 0 && slash < this.currentUser.length - 1) {
      return this.currentUser.substring(slash + 1);
    }
    return this.currentUser;
  }

  private formatListTitle(template: string, value: string): string {
    return template.replace('%s', value);
  }

  private resolveComposeTitle(): string {
    if (this.dataType === COMMON_LIST_DATA_TYPE_REPOSITORIES) {
      return this.formatListTitle(I18n('listRepositories'), this.currentUser);
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_FOLLOWER) {
      return this.formatListTitle(I18n('listFollowers'), this.currentUser);
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_FOLLOWING
      || this.dataType === COMMON_LIST_DATA_TYPE_FOLLOWED) {
      return this.formatListTitle(I18n('listFollowing'), this.currentUser);
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_USER_REPOS) {
      return this.formatListTitle(I18n('listRepos'), this.currentUser);
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_STARGAZERS
      || this.dataType === COMMON_LIST_DATA_TYPE_REPO_STAR) {
      return this.formatListTitle(I18n('listStargazers'), this.titleRepoName());
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_USER_STAR) {
      return this.formatListTitle(I18n('listStar'), this.currentUser);
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_USER_ORGS) {
      return this.formatListTitle(I18n('listOrgs'), this.currentUser);
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_WATCHERS
      || this.dataType === COMMON_LIST_DATA_TYPE_REPO_WATCHER) {
      return this.formatListTitle(I18n('listWatchers'), this.titleRepoName());
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_FORKS
      || this.dataType === COMMON_LIST_DATA_TYPE_REPO_FORK) {
      return this.formatListTitle(I18n('listForks'), this.titleRepoName());
    }
    if (this.dataType === COMMON_LIST_DATA_TYPE_TOPICS) {
      return this.formatListTitle(I18n('listTopics'), this.currentUser);
    }
    return this.title.length > 0 ? this.title : this.currentUser;
  }

  private async refreshList(): Promise<void> {
    const type: string = this.normalizedDataType();
    hilog.info(0x6666, 'CommonList', 'refresh dataType=%{public}s showType=%{public}s user=%{public}s title=%{public}s local=%{public}d',
      this.dataType, this.showType, this.currentUser, this.title, this.localData.length);
    if (type === COMMON_LIST_DATA_TYPE_USER_BE_STARED) {
      // RN 那边把 100 仓库列表（用于荣耀汇总）通过 localData 透传过来；OH 暂未缓存，
      // localData 为空时 fallback 到 GET /users/:login/repos?sort=pushed&per_page=100，
      // 与 RN [getUserRepository100StatusDao](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserHeadItem.js#L240) 同源
      if (this.localData.length > 0) {
        this.repos = this.localData.slice();
        this.page = 1;
        this.hasMore = false;
        this.error = '';
        this.plmController.refreshComplete(false, false);
        return;
      }
      if (this.currentUser.length === 0) {
        this.plmController.refreshComplete(false, false);
        return;
      }
      this.plmController.showRefreshState();
      const res: FetchUserReposResult = await this.userService.getUserRepos(this.currentUser, 1);
      hilog.info(0x6666, 'CommonList', 'user_be_stared fallback res ok=%{public}s code=%{public}d size=%{public}d msg=%{public}s',
        String(res.result), res.code, res.data.length, res.msg);
      this.applyUserReposResult(res, true);
      return;
    }
    if (this.currentUser.length === 0) {
      this.plmController.refreshComplete(false, false);
      return;
    }
    this.plmController.showRefreshState();

    if (type === COMMON_LIST_DATA_TYPE_FOLLOWER) {
      const res: FetchSubUserListResult = await this.userService.getUserFollowers(this.currentUser, 1);
      hilog.info(0x6666, 'CommonList', 'follower res ok=%{public}s code=%{public}d size=%{public}d msg=%{public}s',
        String(res.result), res.code, res.data.length, res.msg);
      this.applyUserResult(res, true);
    } else if (type === COMMON_LIST_DATA_TYPE_FOLLOWED) {
      const res: FetchSubUserListResult = await this.userService.getUserFollowed(this.currentUser, 1);
      hilog.info(0x6666, 'CommonList', 'followed res ok=%{public}s code=%{public}d size=%{public}d msg=%{public}s',
        String(res.result), res.code, res.data.length, res.msg);
      this.applyUserResult(res, true);
    } else if (type === COMMON_LIST_DATA_TYPE_USER_REPOS) {
      const res: FetchUserReposResult = await this.userService.getUserRepos(this.currentUser, 1);
      hilog.info(0x6666, 'CommonList', 'user_repos res ok=%{public}s code=%{public}d size=%{public}d msg=%{public}s',
        String(res.result), res.code, res.data.length, res.msg);
      this.applyUserReposResult(res, true);
    } else if (type === COMMON_LIST_DATA_TYPE_USER_STAR) {
      const res: SubListResult<SubRepositoryItem> = await this.repoService.getUserStarredRepos(this.currentUser, 1);
      hilog.info(0x6666, 'CommonList', 'user_star res ok=%{public}s code=%{public}d size=%{public}d msg=%{public}s',
        String(res.result), res.code, res.data.length, res.msg);
      this.applySubRepoResult(res, true);
    } else if (type === COMMON_LIST_DATA_TYPE_USER_ORGS) {
      const res: FetchSubUserListResult = await this.userService.getUserOrgs(this.currentUser, 1);
      hilog.info(0x6666, 'CommonList', 'user_orgs res ok=%{public}s code=%{public}d size=%{public}d msg=%{public}s',
        String(res.result), res.code, res.data.length, res.msg);
      this.applyUserResult(res, true);
    } else if (type === COMMON_LIST_DATA_TYPE_STARGAZERS) {
      const res: SubListResult<SubUserItem> = await this.repoService.getStars(this.repoFullName(), 1);
      hilog.info(0x6666, 'CommonList', 'stargazers res ok=%{public}s code=%{public}d size=%{public}d msg=%{public}s',
        String(res.result), res.code, res.data.length, res.msg);
      this.applyUserResult(res, true);
    } else if (type === COMMON_LIST_DATA_TYPE_WATCHERS) {
      const res: SubListResult<SubUserItem> = await this.repoService.getWatchers(this.repoFullName(), 1);
      hilog.info(0x6666, 'CommonList', 'watchers res ok=%{public}s code=%{public}d size=%{public}d msg=%{public}s',
        String(res.result), res.code, res.data.length, res.msg);
      this.applyUserResult(res, true);
    } else if (type === COMMON_LIST_DATA_TYPE_FORKS) {
      const res: SubListResult<SubRepositoryItem> = await this.repoService.getForks(this.repoFullName(), 1);
      hilog.info(0x6666, 'CommonList', 'forks res ok=%{public}s code=%{public}d size=%{public}d msg=%{public}s',
        String(res.result), res.code, res.data.length, res.msg);
      this.applySubRepoResult(res, true);
    } else if (type === COMMON_LIST_DATA_TYPE_TOPICS) {
      const res: SubListResult<SubRepositoryItem> = await this.repoService.searchTopicRepos(this.currentUser, 1);
      hilog.info(0x6666, 'CommonList', 'topics res ok=%{public}s code=%{public}d size=%{public}d msg=%{public}s',
        String(res.result), res.code, res.data.length, res.msg);
      this.applySubRepoResult(res, true);
    } else {
      hilog.warn(0x6666, 'CommonList', 'unknown dataType=%{public}s', this.dataType);
      this.plmController.refreshComplete(false, false);
    }
  }

  private async loadMoreList(): Promise<void> {
    const type: string = this.normalizedDataType();
    if (!this.hasMore) {
      this.plmController.loadMoreComplete(false);
      return;
    }
    if (type === COMMON_LIST_DATA_TYPE_USER_BE_STARED) {
      this.plmController.loadMoreComplete(false);
      return;
    }
    if (this.currentUser.length === 0) {
      this.plmController.loadMoreComplete(false);
      return;
    }
    const next: number = this.page + 1;

    if (type === COMMON_LIST_DATA_TYPE_FOLLOWER) {
      const res: FetchSubUserListResult = await this.userService.getUserFollowers(this.currentUser, next);
      this.applyUserResult(res, false, next);
    } else if (type === COMMON_LIST_DATA_TYPE_FOLLOWED) {
      const res: FetchSubUserListResult = await this.userService.getUserFollowed(this.currentUser, next);
      this.applyUserResult(res, false, next);
    } else if (type === COMMON_LIST_DATA_TYPE_USER_REPOS) {
      const res: FetchUserReposResult = await this.userService.getUserRepos(this.currentUser, next);
      this.applyUserReposResult(res, false, next);
    } else if (type === COMMON_LIST_DATA_TYPE_USER_STAR) {
      const res: SubListResult<SubRepositoryItem> = await this.repoService.getUserStarredRepos(this.currentUser, next);
      this.applySubRepoResult(res, false, next);
    } else if (type === COMMON_LIST_DATA_TYPE_USER_ORGS) {
      const res: FetchSubUserListResult = await this.userService.getUserOrgs(this.currentUser, next);
      this.applyUserResult(res, false, next);
    } else if (type === COMMON_LIST_DATA_TYPE_STARGAZERS) {
      const res: SubListResult<SubUserItem> = await this.repoService.getStars(this.repoFullName(), next);
      this.applyUserResult(res, false, next);
    } else if (type === COMMON_LIST_DATA_TYPE_WATCHERS) {
      const res: SubListResult<SubUserItem> = await this.repoService.getWatchers(this.repoFullName(), next);
      this.applyUserResult(res, false, next);
    } else if (type === COMMON_LIST_DATA_TYPE_FORKS) {
      const res: SubListResult<SubRepositoryItem> = await this.repoService.getForks(this.repoFullName(), next);
      this.applySubRepoResult(res, false, next);
    } else if (type === COMMON_LIST_DATA_TYPE_TOPICS) {
      const res: SubListResult<SubRepositoryItem> = await this.repoService.searchTopicRepos(this.currentUser, next);
      this.applySubRepoResult(res, false, next);
    } else {
      this.plmController.loadMoreComplete(false);
    }
  }

  private applyUserResult(res: FetchSubUserListResult, isRefresh: boolean, nextPage: number = 1): void {
    if (res.result) {
      if (isRefresh) {
        this.users = res.data.slice();
        this.page = 1;
      } else {
        const merged: SubUserItem[] = this.users.slice();
        for (let i: number = 0; i < res.data.length; i++) {
          merged.push(res.data[i]);
        }
        this.users = merged;
        this.page = nextPage;
      }
      this.hasMore = res.data.length >= this.pageSize;
      this.error = '';
    } else {
      this.error = res.msg;
    }
    if (isRefresh) {
      this.plmController.refreshComplete(this.hasMore, false);
    } else {
      this.plmController.loadMoreComplete(this.hasMore);
    }
  }

  private applySubRepoResult(res: SubListResult<SubRepositoryItem>, isRefresh: boolean, nextPage: number = 1): void {
    if (res.result) {
      if (isRefresh) {
        this.repos = res.data.slice();
        this.page = 1;
      } else {
        const merged: SubRepositoryItem[] = this.repos.slice();
        for (let i: number = 0; i < res.data.length; i++) {
          merged.push(res.data[i]);
        }
        this.repos = merged;
        this.page = nextPage;
      }
      this.hasMore = res.data.length >= this.pageSize;
      this.error = '';
    } else {
      this.error = res.msg;
    }
    if (isRefresh) {
      this.plmController.refreshComplete(this.hasMore, false);
    } else {
      this.plmController.loadMoreComplete(this.hasMore);
    }
  }

  private applyUserReposResult(res: FetchUserReposResult, isRefresh: boolean, nextPage: number = 1): void {
    if (res.result) {
      const mapped: SubRepositoryItem[] = this.mapUserRepoList(res.data);
      if (isRefresh) {
        this.repos = mapped;
        this.page = 1;
      } else {
        const merged: SubRepositoryItem[] = this.repos.slice();
        for (let i: number = 0; i < mapped.length; i++) {
          merged.push(mapped[i]);
        }
        this.repos = merged;
        this.page = nextPage;
      }
      this.hasMore = res.data.length >= this.pageSize;
      this.error = '';
    } else {
      this.error = res.msg;
    }
    if (isRefresh) {
      this.plmController.refreshComplete(this.hasMore, false);
    } else {
      this.plmController.loadMoreComplete(this.hasMore);
    }
  }

  private openUser(item: SubUserItem): void {
    const param: UserDetailRouteParam = { 'login': item.login } as UserDetailRouteParam;
    NavigationService.push(RouteName.UserDetail, param as Object);
  }

  private openRepo(item: SubRepositoryItem): void {
    const owner: string = item.owner_login;
    const repoName: string = item.name;
    if (owner.length === 0 || repoName.length === 0) {
      return;
    }
    const fullName: string = item.full_name.length > 0 ? item.full_name : owner + '/' + repoName;
    const param: RepoDetailRouteParam = {
      owner: owner,
      name: repoName,
      fullName: fullName,
      ownerName: owner,
      reposName: repoName,
    } as RepoDetailRouteParam;
    NavigationService.push(RouteName.RepositoryDetail, param as Object);
  }

  private resolveSubListMode(): SubListMode {
    const type: string = this.normalizedDataType();
    if (type === COMMON_LIST_DATA_TYPE_STARGAZERS || type === COMMON_LIST_DATA_TYPE_WATCHERS
      || type === COMMON_LIST_DATA_TYPE_USER_ORGS) {
      return SubListMode.USER;
    }
    if (type === COMMON_LIST_DATA_TYPE_FORKS || type === COMMON_LIST_DATA_TYPE_TOPICS) {
      return SubListMode.REPO;
    }
    return this.showType === COMMON_LIST_SHOW_TYPE_USER ? SubListMode.USER : SubListMode.REPO;
  }

  private resolveTitle(): string {
    return this.resolveComposeTitle();
  }

  private resolveIdPrefix(): string {
    return 'common_list_' + this.dataType;
  }

  build(): void {
    NavDestination() {
      Column() {
        AppBar({
          title: this.resolveTitle(),
          titleStart: true,
          showBack: true,
          onBack: (): void => {
            NavigationService.pop();
          },
        });
        SubListView({
          title: this.resolveTitle(),
          mode: this.resolveSubListMode(),
          users: this.users,
          repos: this.repos,
          controller: this.plmController,
          idPrefix: this.resolveIdPrefix(),
          refresh: (): void => {
            this.refreshList();
          },
          loadMore: (): void => {
            this.loadMoreList();
          },
          onUserClick: (item: SubUserItem): void => {
            this.openUser(item);
          },
          onRepoClick: (item: SubRepositoryItem): void => {
            this.openRepo(item);
          },
        })
          .id(this.resolveIdPrefix() + '_view')
          .layoutWeight(1);
      }
      .id(this.resolveIdPrefix() + '_root')
      .width('100%')
      .height('100%')
      .backgroundColor(GSYColor.white);
    }
    .hideTitleBar(true)
    .onBackPressed((): boolean => {
      NavigationService.pop();
      return true;
    })
    .onReady((ctx: NavDestinationContext): void => {
      const ok: boolean = this.resolveParamFromCtx(ctx);
      hilog.info(0x6666, 'CommonList', 'onReady ok=%{public}s dataType=%{public}s showType=%{public}s user=%{public}s title=%{public}s',
        String(ok), this.dataType, this.showType, this.currentUser, this.title);
      this.refreshList();
    });
  }
}
