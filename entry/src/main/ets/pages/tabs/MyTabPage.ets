/**
 * MyTabPage —— 以 Android Compose ProfileScreen/ProfileHeader 为准。
 *
 * Compose ProfileHeader 头像不可点击；通知铃铛进入 Notification。
 * Compose ProfileScreen 在 ProfileContent 下方保留 Logout 按钮；OH My 页同样保留
 * 该登出入口。调试探针（refresh-count/logout-click/entry-click）已移除。
 */

import { I18n } from '../../i18n/I18n';
import { NavigationService } from '../../navigation/NavigationService';
import { RouteName } from '../../navigation/Routes';
import {
  AuthUserInfo,
  GlobalAuthStore,
  APP_STORAGE_KEY_USER_INFO,
} from '../../store/AuthStore';
import { MyStore, GlobalMyStore } from '../../store/MyStore';
import {
  MyService,
  DefaultMyService,
  RefreshMeResult,
  FetchUnReadResult,
  FetchUserOrgsResult,
  FetchStarredCountResult,
  MyOrgItem,
} from '../../service/MyService';
import { DynamicService, FetchReceivedResult } from '../../service/DynamicService';
import { DynamicEvent, DynamicStore } from '../../store/DynamicStore';
import { PullLoadMoreList, PullLoadMoreController } from '../../common/PullLoadMoreList';
import { EventItem } from '../../widget/EventItem';
import { UserHeadItem, UserHeadOrgItem } from '../../widget/UserHeadItem';
import { EventActionUtil } from '../../utils/EventActionUtil';
import { EventActionDispatcher } from '../../utils/EventActionDispatcher';
import { ExternalUrlUtil } from '../../utils/ExternalUrlUtil';
import { GSYColor, GSYFontSize, GSYSpacing } from '../../style/Theme';
import { TimeUtil } from '../../utils/TimeUtil';
import { LoginUseCase, DefaultLoginUseCase } from '../../auth/LoginUseCase';

export class MyTabPageDeps {
  private static serviceImpl: MyService = DefaultMyService;
  private static dynamicServiceFactory: ((store: DynamicStore) => DynamicService) | null = null;
  private static storeImpl: MyStore = GlobalMyStore;
  private static loginUseCaseImpl: LoginUseCase = DefaultLoginUseCase;

  static setService(service: MyService): void {
    MyTabPageDeps.serviceImpl = service;
  }

  static setDynamicServiceFactory(factory: ((store: DynamicStore) => DynamicService) | null): void {
    MyTabPageDeps.dynamicServiceFactory = factory;
  }

  static setStore(store: MyStore): void {
    MyTabPageDeps.storeImpl = store;
  }

  static setLoginUseCase(useCase: LoginUseCase): void {
    MyTabPageDeps.loginUseCaseImpl = useCase;
  }

  static getService(): MyService {
    return MyTabPageDeps.serviceImpl;
  }

  static buildDynamicService(store: DynamicStore): DynamicService {
    if (MyTabPageDeps.dynamicServiceFactory !== null) {
      return MyTabPageDeps.dynamicServiceFactory(store);
    }
    return new DynamicService(store);
  }

  static getStore(): MyStore {
    return MyTabPageDeps.storeImpl;
  }

  static getLoginUseCase(): LoginUseCase {
    return MyTabPageDeps.loginUseCaseImpl;
  }

  static reset(): void {
    MyTabPageDeps.serviceImpl = DefaultMyService;
    MyTabPageDeps.dynamicServiceFactory = null;
    MyTabPageDeps.storeImpl = GlobalMyStore;
    MyTabPageDeps.loginUseCaseImpl = DefaultLoginUseCase;
  }
}

@Component
export struct MyTabPage {
  @StorageLink('auth.userInfo') userInfoRaw: string = '';
  @State eventStore: DynamicStore = new DynamicStore();
  @State plmController: PullLoadMoreController = new PullLoadMoreController();
  @State unRead: boolean = false;
  @State orgsList: UserHeadOrgItem[] = [];
  @State beStaredCount: string = '---';
  @State starCount: string = '---';
  @State reposCount: string = '---';
  @State followerCount: string = '---';
  @State followedCount: string = '---';
  @State headerDisplayName: string = '';
  @State headerLogin: string = '';
  @State headerAvatar: string = '';
  @State headerCompany: string = '';
  @State headerLocation: string = '';
  @State headerBlog: string = '';
  @State headerDes: string = '';
  @State headerJoinedText: string = '';
  @State headerType: string = '';
  @State errorMessage: string = '';
  private dynamicService: DynamicService = MyTabPageDeps.buildDynamicService(this.eventStore);

  aboutToAppear(): void {
    const store: MyStore = MyTabPageDeps.getStore();
    store.syncFromAppStorage();
    this.dynamicService = MyTabPageDeps.buildDynamicService(this.eventStore);
    this.applyUserToHeaderState();
    this.triggerRefresh();
  }

  private applyUserToHeaderState(): void {
    const user: AuthUserInfo | null = this.parseUser();
    if (user === null) {
      return;
    }
    this.headerDisplayName = user.name.length > 0 ? user.name : user.login;
    this.headerLogin = user.login;
    this.headerAvatar = user.avatarUrl;
    this.headerCompany = user.company;
    this.headerLocation = user.location;
    this.headerBlog = user.blog;
    this.headerType = user.type;
    this.headerDes = user.bio.length > 0 ? user.bio : '';
    this.headerJoinedText = this.buildJoinedText(user);
    this.reposCount = user.publicRepos.toString();
    this.followerCount = user.followers.toString();
    this.followedCount = user.following.toString();
    // star / beStared 由 fetchUserStarredCount / fetchUserBeStaredCount 单独写入，
    // 不要在这里用 user.starred 覆盖（GitHub /user 接口本身不返回 starred 字段）。
  }

  private parseUser(): AuthUserInfo | null {
    if (GlobalAuthStore.userInfo !== null && GlobalAuthStore.userInfo !== undefined) {
      return GlobalAuthStore.userInfo;
    }
    if (this.userInfoRaw === undefined || this.userInfoRaw === null
      || this.userInfoRaw.length === 0) {
      return null;
    }
    return AuthUserInfo.fromJson(this.userInfoRaw);
  }

  private resolveLogin(): string {
    const user: AuthUserInfo | null = this.parseUser();
    if (user !== null && user.login.length > 0) {
      return user.login;
    }
    return '';
  }

  private async triggerRefresh(): Promise<void> {
    let login: string = this.resolveLogin();
    this.plmController.showRefreshState();
    this.errorMessage = '';

    // bootToken 注入 / 冷启动场景下，AppStorage 里还没有 userInfo，login 为空。
    // 先单独拉一次 GET /user 把 GlobalAuthStore.userInfo 填好（refreshMe 内部会写 AppStorage），
    // 拿到 login 之后再启动其它并行请求；否则会直接卡在「---」占位。
    if (login.length === 0) {
      const meFirst: RefreshMeResult = await MyTabPageDeps.getService().refreshMe();
      if (meFirst.result && meFirst.data !== null) {
        login = meFirst.data.login;
      } else if (!meFirst.result && meFirst.msg.length > 0) {
        this.errorMessage = meFirst.msg;
      }
      if (login.length === 0) {
        this.plmController.refreshComplete(false, false);
        return;
      }
    }

    const refreshMe: Promise<RefreshMeResult> = MyTabPageDeps.getService().refreshMe();
    const fetchUnRead: Promise<FetchUnReadResult> = MyTabPageDeps.getService().fetchUnRead();
    const fetchStarred: Promise<FetchStarredCountResult>
      = MyTabPageDeps.getService().fetchUserStarredCount(login);
    const fetchEvents: Promise<FetchReceivedResult>
      = this.dynamicService.fetchUserEvents(login, 1);

    const meRes: RefreshMeResult = await refreshMe;
    const unReadRes: FetchUnReadResult = await fetchUnRead;
    const starredRes: FetchStarredCountResult = await fetchStarred;
    const eventRes: FetchReceivedResult = await fetchEvents;

    this.applyUserToHeaderState();
    if (unReadRes.result) {
      this.unRead = unReadRes.unRead;
    }
    this.orgsList = [];
    if (starredRes.result) {
      this.starCount = starredRes.count.toString();
    }
    if (!meRes.result && meRes.msg.length > 0) {
      this.errorMessage = meRes.msg;
    } else if (!eventRes.result && eventRes.msg.length > 0 && eventRes.data.length === 0) {
      this.errorMessage = eventRes.msg;
    } else {
      this.errorMessage = '';
    }
    this.plmController.refreshComplete(this.eventStore.hasMore, false);
  }

  private async triggerLoadMore(): Promise<void> {
    const login: string = this.resolveLogin();
    if (login.length === 0) {
      this.plmController.loadMoreComplete(false);
      return;
    }
    if (!this.eventStore.hasMore) {
      this.plmController.loadMoreComplete(false);
      return;
    }
    const next: number = this.eventStore.page + 1;
    await this.dynamicService.fetchUserEvents(login, next);
    this.plmController.loadMoreComplete(this.eventStore.hasMore);
  }

  private static toOrgItems(list: MyOrgItem[]): UserHeadOrgItem[] {
    const out: UserHeadOrgItem[] = [];
    if (list === null || list === undefined) {
      return out;
    }
    for (let i: number = 0; i < list.length; i++) {
      const it: MyOrgItem = list[i];
      if (it === null || it === undefined) {
        continue;
      }
      out.push({
        login: it.login !== null && it.login !== undefined ? it.login : '',
        avatar_url: it.avatar_url !== null && it.avatar_url !== undefined ? it.avatar_url : '',
      });
    }
    return out;
  }

  private buildJoinedText(user: AuthUserInfo | null): string {
    if (user === null) {
      return '';
    }
    const created: string = user.createdAt.length > 0
      ? TimeUtil.resolveTime(user.createdAt)
      : '';
    if (created.length === 0) {
      return '';
    }
    return I18n('profileJoined').replace('%s', created);
  }

  private dispatchEventTap(event: DynamicEvent): void {
    EventActionDispatcher.dispatch(event, '', (url: string): boolean => {
      return ExternalUrlUtil.openUrlInBrowser(this, url, 'MyTabPage');
    });
  }

  private handleNotifyTap(): void {
    NavigationService.push(RouteName.Notify);
  }

  private async handleLogoutTap(): Promise<void> {
    try {
      await MyTabPageDeps.getLoginUseCase().logout();
    } catch (_e) {
    }
    NavigationService.replace(RouteName.Login);
  }

  private handleCounterTap(key: string): void {
    const login: string = this.resolveLogin();
    if (login.length === 0) {
      return;
    }
    // RN [UserHeadItem.js#L156-L254](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserHeadItem.js#L156-L254)
    // 5 个 NameValueItem 全部走 Actions.ListPage(dataType, showType, currentUser, title, [localData])
    let dataType: string = '';
    let showType: string = '';
    let title: string = login;
    if (key === 'repos') {
      dataType = 'user_repos';
      showType = 'repository';
      title = login + ' - ' + I18n('repositoryText');
    } else if (key === 'follower') {
      dataType = 'follower';
      showType = 'user';
      title = login + ' - ' + I18n('FollowersText');
    } else if (key === 'followed') {
      dataType = 'followed';
      showType = 'user';
      title = login + ' - ' + I18n('FollowedText');
    } else if (key === 'star') {
      dataType = 'user_star';
      showType = 'repository';
      title = login + ' - ' + I18n('staredText');
    } else {
      return;
    }
    const param: Record<string, Object> = {
      'dataType': dataType,
      'showType': showType,
      'currentUser': login,
      'title': title,
    };
    NavigationService.push(RouteName.CommonList, param);
  }

  @Builder
  buildHeader(): void {
    UserHeadItem({
      userDisplayName: this.headerDisplayName,
      userName: this.headerLogin,
      userPic: this.headerAvatar,
      groupName: this.headerCompany,
      location: this.headerLocation,
      link: this.headerBlog,
      des: this.headerDes,
      joinedText: this.headerJoinedText,
      star: this.starCount,
      follower: this.followerCount,
      followed: this.followedCount,
      repos: this.reposCount,
      beStared: this.beStaredCount,
      setting: true,
      settingNeed: false,
      unRead: this.unRead,
      isOrganizations: this.headerType === 'Organization',
      needFollow: false,
      hadFollowed: false,
      userType: this.headerType,
      orgsList: this.orgsList,
      onNotifyTap: (): void => {
        this.handleNotifyTap();
      },
      onFollowTap: (): void => {},
      onCounterTap: (key: string): void => {
        this.handleCounterTap(key);
      },
    });
  }

  @Builder
  rowBuilder(item: DynamicEvent, index: number): void {
    EventItem({
      actionTime: item.created_at,
      actionUser: item.actor !== null && item.actor !== undefined
        ? (item.actor.display_login !== undefined && item.actor.display_login !== null
            && item.actor.display_login.length > 0
          ? item.actor.display_login
          : item.actor.login)
        : '',
      actionUserPic: item.actor !== null && item.actor !== undefined
        ? item.actor.avatar_url : '',
      actionTarget: EventActionUtil.getComposeActionText(item),
      des: '',
      rowId: 'my_event_row_' + index.toString(),
      onPressItem: (): void => {
        this.dispatchEventTap(item);
      },
      onPressUser: (): void => {
        const login: string = item.actor !== null && item.actor !== undefined ? item.actor.login : '';
        EventActionDispatcher.dispatchUser(login);
      },
    });
  }

  @Builder
  emptyBuilder(): void {
    Column() {
      Text(I18n('listEmpty'))
        .id('my_empty_text')
        .fontSize(GSYFontSize.middleWhite)
        .fontColor(GSYColor.subText);
    }
    .id('my_empty_root')
    .width('100%')
    .height(240)
    .justifyContent(FlexAlign.Center);
  }

  build(): void {
    Column() {
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .id('my_error_text')
          .width('100%')
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.actionBlue)
          .padding({
            left: GSYSpacing.normalEdge,
            right: GSYSpacing.normalEdge,
            top: GSYSpacing.halfEdge,
            bottom: GSYSpacing.halfEdge,
          });
      }
      PullLoadMoreList({
        dataSource: this.eventStore.list,
        controller: this.plmController,
        renderHeader: (): void => this.buildHeader(),
        renderRow: (item: Object, index: number): void => this.rowBuilder(item as DynamicEvent, index),
        renderEmpty: (): void => this.emptyBuilder(),
        refresh: (): void => {
          this.triggerRefresh();
        },
        loadMore: (): void => {
          this.triggerLoadMore();
        },
        refreshingText: I18n('refreshing'),
        loadingMoreText: I18n('loadMoreing'),
        loadEndText: I18n('loadMoreEnd'),
        emptyText: I18n('listEmpty'),
      })
        .id('my_pull_list')
        .layoutWeight(1);
    }
    .id('tab_page_root_my')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.mainBackground);
  }
}
