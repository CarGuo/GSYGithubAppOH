import { I18n } from '../i18n/I18n';
import pasteboard from '@ohos.pasteboard';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import hilog from '@ohos.hilog';
import { PullLoadMoreList, PullLoadMoreController } from '../common/PullLoadMoreList';
import { GSYColor, GSYFontSize, GSYIconSize, GSYSpacing, GSYShadow } from '../style/Theme';
import { AppBar, AppBarAction } from '../common/AppBar';
import { CommonModal, CommonOptionItem } from '../common/CommonModal';
import { CommonToast } from '../common/CommonToast';
import { Logger } from '../ai-debug/Logger';
import {
  UserDetailStore,
  UserDetail,
  UserRepoItem,
  sanitizeUserDetail,
} from '../store/UserDetailStore';
import { DynamicStore, DynamicEvent } from '../store/DynamicStore';
import {
  UserService,
  FetchUserResult,
  FetchUserReposResult,
  FetchFollowResult,
  FetchSubUserListResult
} from '../service/UserService';
import { SubUserItem } from '../service/RepositoryService';
import { DynamicService } from '../service/DynamicService';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { RouteParamStore } from '../navigation/RouteParamStore';
import { ReadHistoryService, ReadHistoryAddParam } from '../service/ReadHistoryService';
import { READ_HISTORY_TYPE_USER } from '../store/ReadHistoryStore';
import { BOOT_USER_KEY } from '../entryability/EntryAbility';
import { IconTextItem } from '../widget/IconTextItem';
import { EventItem } from '../widget/EventItem';
import { IconFont, FA_CHECK, FA_GROUP, FA_MAP_MARKER, FA_USER_PLUS } from '../common/IconFont';
import { TimeUtil } from '../utils/TimeUtil';
import { EventActionUtil } from '../utils/EventActionUtil';
import { EventActionDispatcher } from '../utils/EventActionDispatcher';

interface UserDetailRouteParam {
  login: string;
}

interface RepositoryDetailRouteParam {
  owner: string;
  name: string;
  fullName: string;
}

interface UserCountJumpParam {
  dataType: string;
  showType: string;
  currentUser: string;
  title: string;
}

const FALLBACK_LOGIN: string = '';
const COMMON_LIST_DATA_TYPE_REPOSITORIES: string = 'repositories';
const COMMON_LIST_DATA_TYPE_FOLLOWER: string = 'follower';
const COMMON_LIST_DATA_TYPE_FOLLOWING: string = 'following';
const COMMON_LIST_DATA_TYPE_USER_STAR: string = 'user_star';
const COMMON_LIST_SHOW_TYPE_USER: string = 'user';
const COMMON_LIST_SHOW_TYPE_REPOSITORY: string = 'repository';

/**
 * 安全字符串：把 null/undefined 兜底成 ''，避免对 null 调 .length 直接崩。
 * GitHub API 对 description / language / full_name / bio / name 经常返回 null。
 */
function safeStr(v: string | null | undefined): string {
  return (v === null || v === undefined) ? '' : v;
}

@Component
export struct UserDetailPage {
  @State login: string = FALLBACK_LOGIN;
  @State store: UserDetailStore = new UserDetailStore();
  @State dynamicStore: DynamicStore = new DynamicStore();
  @State orgMembers: SubUserItem[] = [];
  @State orgMemberPage: number = 1;
  @State orgMemberHasMore: boolean = true;
  @State plmController: PullLoadMoreController = new PullLoadMoreController();
  private service: UserService = new UserService(this.store);
  private dynamicService: DynamicService = new DynamicService(this.dynamicStore);
  private readHistoryService: ReadHistoryService = new ReadHistoryService();
  private pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.service = new UserService(this.store);
    this.dynamicService = new DynamicService(this.dynamicStore);
    this.tryAdoptRouteParam();
    if (this.login.length === 0) {
      this.tryAdoptBootUser();
    }
  }

  /**
   * 优先从 RouteParamStore 拿（NavigationService.push 时同步写入），
   * 覆盖所有走 NavigationService.push(UserDetail, param) 的入口（CommonList / SearchPage / DrawerHeader / etc）。
   */
  private tryAdoptRouteParam(): void {
    const raw: Object | null = RouteParamStore.consume(RouteName.UserDetail);
    if (raw === null) {
      return;
    }
    const obj: UserDetailRouteParam = raw as UserDetailRouteParam;
    const login: string = obj.login !== undefined && obj.login !== null ? obj.login : '';
    if (login.length > 0) {
      this.login = login;
      Logger.i('user/route', `UserDetailPage.tryAdoptRouteParam adopted login=${login} t=${Date.now()}`);
    }
  }

  /**
   * KI-042 同款：直读 BOOT_USER_KEY 兜底解析 login，立即清空，避免 NavPathStack push 时序竞争。
   * 与 [CodeDetailPage.tryAdoptBootCode] / [PushDetailPage.tryAdoptBootPush] 同款做法。
   */
  private tryAdoptBootUser(): void {
    const value: string | undefined = AppStorage.get<string>(BOOT_USER_KEY);
    const raw: string = (value || '').trim();
    if (raw.length === 0) {
      return;
    }
    this.login = raw;
    AppStorage.setOrCreate<string>(BOOT_USER_KEY, '');
    Logger.i('user/boot', `UserDetailPage.tryAdoptBootUser adopted login=${raw} t=${Date.now()}`);
  }

  private resolveLoginFromParam(rawParam: Object | null | undefined): string {
    if (rawParam === undefined || rawParam === null) {
      return FALLBACK_LOGIN;
    }
    const obj: UserDetailRouteParam = rawParam as UserDetailRouteParam;
    return obj.login !== undefined && obj.login !== null ? obj.login : FALLBACK_LOGIN;
  }

  private resolveLoginFromStack(stack: NavPathStack): string {
    // 关键：NavDestinationContext.pathStack 在 onReady 早期阶段，
    // getAllPathName / getParamByIndex 可能尚未挂载（"undefined is not callable"），
    // 必须 try/catch 包裹，与 RepositoryDetailPage.resolveFullNameFromStack 保持一致。
    try {
      const all: string[] = stack.getAllPathName();
      if (all === undefined || all === null || all.length === 0) {
        return FALLBACK_LOGIN;
      }
      const param: Object | undefined = stack.getParamByIndex(all.length - 1) as Object | undefined;
      return this.resolveLoginFromParam(param === undefined ? null : param);
    } catch (_e) {
      return FALLBACK_LOGIN;
    }
  }

  private async loadAll(): Promise<void> {
    if (this.login.length === 0) {
      return;
    }
    this.plmController.showRefreshState();
    const userRes: FetchUserResult = await this.service.getUser(this.login);
    if (userRes.result && userRes.fromCache && safeStr(this.store.user.starred).length === 0) {
      // Old local user rows may not include the Compose `starred` field yet.
      // Refresh it when we are showing a cache fallback.
      await this.service.getUserStarredCount(this.login);
    }
    await this.service.getFollowStatus(this.login);
    if (userRes.result && this.isOrganizationProfile()) {
      const orgRes: FetchSubUserListResult = await this.service.getOrgMembers(this.login, 1,
        (items: SubUserItem[]): void => {
          this.orgMembers = items.slice();
          this.orgMemberPage = 1;
          this.orgMemberHasMore = items.length >= this.service.getPageSize();
        });
      if (orgRes.result) {
        this.orgMembers = orgRes.data.slice();
        this.orgMemberPage = 1;
        this.orgMemberHasMore = orgRes.data.length >= this.service.getPageSize();
      } else {
        this.orgMembers = [];
        this.orgMemberHasMore = false;
      }
      this.dynamicStore.list = [];
      this.plmController.refreshComplete(this.orgMemberHasMore, false);
    } else {
      this.orgMembers = [];
      await this.dynamicService.fetchUserEvents(this.login, 1);
      this.plmController.refreshComplete(this.dynamicStore.hasMore, false);
    }
    await this.writeReadHistory();
    if (!userRes.result) {
      return;
    }
  }

  private async writeReadHistory(): Promise<void> {
    if (this.login.length === 0) {
      return;
    }
    // 第二道防线：哪怕 store.user 万一出现 null 字段，这里再 sanitize 一次。
    const user: UserDetail = sanitizeUserDetail(this.store.user);
    const safeName: string = safeStr(user.name);
    const safeBio: string = safeStr(user.bio);
    const title: string = safeName.length > 0 ? safeName : this.login;
    const subtitle: string = safeBio.length > 0 ? safeBio : this.login;
    const avatar: string = safeStr(user.avatar_url);
    const payloadJson: string = JSON.stringify(user);
    const param: ReadHistoryAddParam = {
      'type': READ_HISTORY_TYPE_USER,
      'key': this.login,
      'title': title,
      'subtitle': subtitle,
      'avatar': avatar,
      'payloadJson': payloadJson,
      'time': Date.now(),
    } as ReadHistoryAddParam;
    await this.readHistoryService.add(param);
  }

  private async triggerLoadMore(): Promise<void> {
    if (this.isOrganizationProfile()) {
      if (!this.orgMemberHasMore) {
        this.plmController.loadMoreComplete(false);
        return;
      }
      const next: number = this.orgMemberPage + 1;
      const res: FetchSubUserListResult = await this.service.getOrgMembers(this.login, next);
      if (res.result) {
        const merged: SubUserItem[] = this.orgMembers.slice();
        for (let i: number = 0; i < res.data.length; i++) {
          merged.push(res.data[i]);
        }
        this.orgMembers = merged;
        this.orgMemberPage = next;
        this.orgMemberHasMore = res.data.length >= this.service.getPageSize();
      } else {
        this.orgMemberHasMore = false;
      }
      this.plmController.loadMoreComplete(this.orgMemberHasMore);
      return;
    }
    if (!this.dynamicStore.hasMore) {
      this.plmController.loadMoreComplete(false);
      return;
    }
    const next: number = this.dynamicStore.page + 1;
    await this.dynamicService.fetchUserEvents(this.login, next);
    this.plmController.loadMoreComplete(this.dynamicStore.hasMore);
  }

  private async toggleFollow(): Promise<void> {
    if (this.login.length === 0) {
      return;
    }
    let res: FetchFollowResult;
    if (this.store.followed) {
      res = await this.service.unfollow(this.login);
    } else {
      res = await this.service.follow(this.login);
    }
    if (res.result) {
      const userRes: FetchUserResult = await this.service.getUser(this.login);
      if (userRes.result) {
        return;
      }
    }
  }

  private openRepository(item: UserRepoItem): void {
    const ownerLogin: string = safeStr(item.owner_login);
    const param: RepositoryDetailRouteParam = {
      'owner': ownerLogin.length > 0 ? ownerLogin : this.login,
      'name': safeStr(item.name),
      'fullName': safeStr(item.full_name),
    } as RepositoryDetailRouteParam;
    NavigationService.push(RouteName.RepositoryDetail, param as Object);
  }

  @Builder
  buildHeader(): void {
    Column() {
      // ── Row 1：头像 + 名字/login + group/location 三行 ─────────────────────
      Row() {
        Image(safeStr(this.store.user.avatar_url))
          .id('user_detail_avatar')
          .width(GSYIconSize.large)
          .height(GSYIconSize.large)
          .borderRadius(GSYIconSize.large / 2)
          .objectFit(ImageFit.Cover)
          .margin({ top: GSYSpacing.halfEdge });

        Column() {
          Text(safeStr(this.store.user.name).length > 0 ? safeStr(this.store.user.name) : safeStr(this.store.user.login))
            .id('user_detail_name')
            .fontSize(GSYFontSize.large)
            .fontWeight(FontWeight.Bold)
            .fontColor(GSYColor.white);

          Text(safeStr(this.store.user.login))
            .id('user_detail_login')
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.subLightText)
            .margin({ top: GSYSpacing.halfEdge });

          if (safeStr(this.store.user.company).length > 0) {
            IconTextItem({
              text: safeStr(this.store.user.company),
              iconChar: FA_GROUP,
              iconColor: GSYColor.miWhite,
              textColor: GSYColor.miWhite,
              textFontSize: GSYFontSize.small,
              rowId: 'user_detail_company',
              rowMarginTop: GSYSpacing.halfEdge,
            });
          }

          if (safeStr(this.store.user.location).length > 0) {
            IconTextItem({
              text: safeStr(this.store.user.location),
              iconChar: FA_MAP_MARKER,
              iconColor: GSYColor.miWhite,
              textColor: GSYColor.miWhite,
              textFontSize: GSYFontSize.small,
              rowId: 'user_detail_location',
              rowMarginTop: GSYSpacing.halfEdge,
            });
          }
        }
        .id('user_detail_head_meta_col')
        .margin({ left: GSYSpacing.normalEdge })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
      }
      .id('user_detail_head_row')
      .width('100%')
      .alignItems(VerticalAlign.Top);

      if (safeStr(this.store.user.bio).length > 0) {
        Text(safeStr(this.store.user.bio))
          .id('user_detail_bio')
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.subLightText)
          .margin({ top: GSYSpacing.normalEdge });
      }

      if (this.buildJoinedText().length > 0) {
        Text(this.buildJoinedText())
          .id('user_detail_joined')
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.subLightText)
          .margin({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.normalEdge });
      }

      UserCountsRow({
        store: this.store,
        login: this.login,
        onJump: (dataType: string, showType: string, title: string): void => {
          this.openCommonList(dataType, showType, title);
        },
      });

      Row() {
        Text(I18n('personDynamic'))
          .id('user_detail_dynamic_title')
          .fontSize(GSYFontSize.small)
          .fontWeight(FontWeight.Medium)
          .fontColor(GSYColor.miWhite);
      }
      .id('user_detail_dynamic_title_bar')
      .width('100%')
      .padding({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge });
    }
    .width('100%')
    .padding({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: 2 * GSYSpacing.normalEdge,
    })
    .alignItems(HorizontalAlign.Start)
    .id('user_detail_header_stack')
    .backgroundColor(GSYColor.primary)
    .borderRadius({ bottomLeft: GSYShadow.radius, bottomRight: GSYShadow.radius })
    .shadow({
      radius: GSYShadow.radius,
      color: GSYShadow.cardShadowAlpha,
      offsetX: 1,
      offsetY: 2,
    });
  }

  @Builder
  buildFollowFab(): void {
    Row() {
      IconFont({
        char: this.store.followed ? FA_CHECK : FA_USER_PLUS,
        glyphSize: GSYFontSize.middleWhite,
        glyphColor: GSYColor.miWhite,
      })
        .id(this.store.followed ? 'user_detail_follow_fab_icon_following' : 'user_detail_follow_fab_icon_add');
    }
    .id('user_detail_follow_fab')
    .width(GSYSpacing.tabBarHeight)
    .height(GSYSpacing.tabBarHeight)
    .borderRadius(GSYSpacing.tabBarHeight / 2)
    .backgroundColor(GSYColor.primary)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .margin({
      right: GSYSpacing.normalEdge,
      bottom: GSYSpacing.normalEdge,
    })
    .onClick((): void => {
      this.toggleFollow();
    });
  }

  private buildJoinedText(): string {
    const created: string = safeStr(this.store.user.created_at);
    if (created.length === 0) {
      return '';
    }
    return I18n('userCreate') + TimeUtil.resolveTime(created);
  }

  private shouldShowFollow(): boolean {
    if (this.login.length === 0) {
      return false;
    }
    const userType: string = safeStr(this.store.user.type);
    return userType !== 'Organization';
  }

  private isOrganizationProfile(): boolean {
    return safeStr(this.store.user.type) === 'Organization';
  }

  private currentDataSource(): Object[] {
    if (this.isOrganizationProfile()) {
      return this.orgMembers as Object[];
    }
    return this.dynamicStore.list as Object[];
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
      rowId: 'user_detail_event_row_' + index.toString(),
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
  orgMemberRowBuilder(item: SubUserItem, index: number): void {
    Row() {
      Image(item.avatar_url)
        .id('user_detail_org_member_avatar_' + index.toString())
        .width(GSYIconSize.normal)
        .height(GSYIconSize.normal)
        .borderRadius(GSYIconSize.normal / 2)
        .objectFit(ImageFit.Cover);
      Text(item.login)
        .id('user_detail_org_member_login_' + index.toString())
        .fontSize(GSYFontSize.middleNormal)
        .fontColor(GSYColor.primary)
        .margin({ left: GSYSpacing.normalEdge })
        .layoutWeight(1);
    }
    .id('user_detail_org_member_row_' + index.toString())
    .width('100%')
    .padding({
      left: GSYSpacing.normalEdge + GSYSpacing.halfEdge,
      right: GSYSpacing.normalEdge + GSYSpacing.halfEdge,
      top: GSYSpacing.normalEdge,
      bottom: GSYSpacing.normalEdge,
    })
    .alignItems(VerticalAlign.Center)
    .onClick((): void => {
      const param: UserDetailRouteParam = { login: item.login };
      NavigationService.push(RouteName.UserDetail, param as Object);
    });
  }

  /**
   * 事件点击：统一走 EventActionDispatcher，覆盖 RN ActionUtils 全 5 分支。
   */
  private dispatchEventTap(item: DynamicEvent): void {
    EventActionDispatcher.dispatch(item, '', (url: string): boolean => {
      return this.openUrlInBrowser(url);
    });
  }

  @Builder
  emptyBuilder(): void {
    Column() {
      Text(I18n('listEmpty'))
        .id('user_detail_empty_text')
        .fontSize(GSYFontSize.middleWhite)
        .fontColor(GSYColor.subText);
    }
    .id('user_detail_empty_root')
    .width('100%')
    .padding({ top: GSYSpacing.normalEdge * GSYSpacing.normalNumberOfLine })
    .justifyContent(FlexAlign.Center);
  }

  private buildAppBarTitle(): string {
    const login: string = this.login.length > 0 ? this.login : safeStr(this.store.user.login);
    return login.length > 0 ? login : '';
  }

  private openCommonList(dataType: string, showType: string, title: string): void {
    const login: string = this.login.length > 0 ? this.login : safeStr(this.store.user.login);
    if (login.length === 0) {
      return;
    }
    const param: UserCountJumpParam = {
      dataType: dataType,
      showType: showType,
      currentUser: login,
      title: title,
    };
    Logger.i('user/count/click', 'CommonList dataType=' + dataType + ' showType=' + showType + ' login=' + login);
    NavigationService.push(RouteName.CommonList, param as Object);
  }

  private resolveHtmlUrl(): string {
    const user: UserDetail = this.store.user;
    const login: string = this.login.length > 0
      ? this.login
      : (user !== null && user !== undefined ? safeStr(user.login) : '');
    if (login.length === 0) {
      return '';
    }
    return 'https://github.com/' + login;
  }

  private copyToPasteboard(text: string): void {
    if (text.length === 0) {
      return;
    }
    try {
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const board: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      board.setData(data);
      CommonToast.showShort(I18n('hadCopy'));
    } catch (_e) {
      CommonToast.showShort(I18n('hadCopy'));
    }
  }

  private showMoreMenu(): void {
    const htmlUrl: string = this.resolveHtmlUrl();
    Logger.i('UserDetailPage', 'headerRight more tapped, login=' + this.login + ' url=' + htmlUrl);
    const items: CommonOptionItem[] = [
      { itemName: I18n('browserOpen') } as CommonOptionItem,
      { itemName: I18n('copy') } as CommonOptionItem,
      { itemName: I18n('share') } as CommonOptionItem,
    ];
    CommonModal.options(
      { title: this.login, items: items },
      (index: number, _item: CommonOptionItem): void => {
        if (htmlUrl.length === 0) {
          Logger.w('UserDetailPage', 'more menu skipped, html_url empty');
          return;
        }
        if (index === 0) {
          Logger.i('UserDetailPage', 'more menu browserOpen url=' + htmlUrl);
          this.openUrlInBrowser(htmlUrl);
        } else if (index === 1) {
          this.copyToPasteboard(htmlUrl);
        } else if (index === 2) {
          Logger.i('UserDetailPage', 'more menu share url=' + htmlUrl);
          this.openUrlInBrowser(htmlUrl);
        }
      }
    );
  }

  private openUrlInBrowser(url: string): boolean {
    if (url.length === 0) {
      return false;
    }
    try {
      const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: url,
      };
      ctx.startAbility(want)
        .then((): void => {
          Logger.i('UserDetailPage', 'startAbility viewData ok url=' + url);
        })
        .catch((err: Error): void => {
          Logger.w('UserDetailPage', 'startAbility viewData fail msg=' + err.message);
          CommonToast.showShort(I18n('browserOpen'));
        });
      return true;
    } catch (e) {
      const err = e as Error;
      Logger.w('UserDetailPage', 'startAbility viewData throw msg=' + err.message);
      CommonToast.showShort(I18n('browserOpen'));
      return false;
    }
  }

  private buildRightActions(): AppBarAction[] {
    const list: AppBarAction[] = [];
    list.push({
      iconKey: 'more',
      onAction: (): void => {
        this.showMoreMenu();
      },
    } as AppBarAction);
    return list;
  }

  build(): void {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {
          AppBar({
            title: this.buildAppBarTitle(),
            titleStart: true,
            showBack: true,
            onBack: (): void => {
              NavigationService.pop();
            },
            rightActions: this.buildRightActions(),
          });
          PullLoadMoreList({
            dataSource: this.currentDataSource(),
            controller: this.plmController,
            renderRow: (item: Object, index: number): void => {
              if (this.isOrganizationProfile()) {
                this.orgMemberRowBuilder(item as SubUserItem, index);
              } else {
                this.rowBuilder(item as DynamicEvent, index);
              }
            },
            renderHeader: (): void => this.buildHeader(),
            renderEmpty: (): void => this.emptyBuilder(),
            refresh: (): void => {
              this.loadAll();
            },
            loadMore: (): void => {
              this.triggerLoadMore();
            },
          })
            .id('user_detail_pull_list')
            .layoutWeight(1);
        }
        .width('100%')
        .height('100%');

        if (this.shouldShowFollow()) {
          this.buildFollowFab();
        }
      }
      .id('user_detail_root')
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
      const stack: NavPathStack | undefined = ctx.pathStack;
      if (stack !== undefined && stack !== null) {
        this.pathStack = stack;
      }
      // 优先从 ctx.pathInfo 拿参数（最稳，不依赖 stack 接口可用性）
      let resolved: string = FALLBACK_LOGIN;
      try {
        const info: NavPathInfo | undefined = ctx.pathInfo;
        if (info !== undefined && info !== null) {
          resolved = this.resolveLoginFromParam(info.param as Object | null | undefined);
        }
      } catch (_e) {
        resolved = FALLBACK_LOGIN;
      }
      // 兜底：再尝试通过 stack
      if (resolved.length === 0 && stack !== undefined && stack !== null) {
        resolved = this.resolveLoginFromStack(stack);
      }
      // 终兜底：BOOT_USER_KEY 旁路（KI-045 同款，dispatcher 在 push 前注入 AppStorage）
      if (resolved.length === 0) {
        const boot: string | undefined = AppStorage.get<string>(BOOT_USER_KEY);
        const bootLogin: string = (boot || '').trim();
        if (bootLogin.length > 0) {
          resolved = bootLogin;
        }
      }
      if (resolved.length > 0 && resolved !== this.login) {
        this.login = resolved;
        this.loadAll();
      } else if (this.login.length > 0) {
        this.loadAll();
      }
    });
  }
}

@Component
struct UserCountsRow {
  @ObjectLink store: UserDetailStore;
  login: string = '';
  onJump: (dataType: string, showType: string, title: string) => void =
    (_dataType: string, _showType: string, _title: string): void => {};

  private fmt(n: number): string {
    return n >= 0 ? n.toString() : '---';
  }

  build(): void {
    Row() {
      Column() {
        Text(this.fmt(this.store.user.public_repos))
          .id('user_detail_repos_count')
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.white);
        Text(I18n('repositoryText'))
          .id('user_detail_repos_label')
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.miWhite)
          .margin({ top: GSYSpacing.halfEdge / 2 });
      }
      .id('user_detail_repos_block')
      .layoutWeight(1)
      .padding({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge })
      .alignItems(HorizontalAlign.Center)
      .onClick((): void => {
        Logger.i('user/count/click', 'idPrefix=user_detail_repos dataType=' + COMMON_LIST_DATA_TYPE_REPOSITORIES + ' login=' + this.login);
        if (this.login.length === 0) {
          return;
        }
        this.onJump(COMMON_LIST_DATA_TYPE_REPOSITORIES, COMMON_LIST_SHOW_TYPE_REPOSITORY, I18n('repositoryText'));
      });

      Column() {
        Text(this.fmt(this.store.user.followers))
          .id('user_detail_followers_count')
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.white);
        Text(I18n('FollowersText'))
          .id('user_detail_followers_label')
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.miWhite)
          .margin({ top: GSYSpacing.halfEdge / 2 });
      }
      .id('user_detail_followers_block')
      .layoutWeight(1)
      .padding({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge })
      .alignItems(HorizontalAlign.Center)
      .border({ width: { left: 1 }, color: { left: GSYColor.primaryLight } })
      .onClick((): void => {
        Logger.i('user/count/click', 'idPrefix=user_detail_followers dataType=' + COMMON_LIST_DATA_TYPE_FOLLOWER + ' login=' + this.login);
        if (this.login.length === 0) {
          return;
        }
        this.onJump(COMMON_LIST_DATA_TYPE_FOLLOWER, COMMON_LIST_SHOW_TYPE_USER, I18n('FollowersText'));
      });

      Column() {
        Text(this.fmt(this.store.user.following))
          .id('user_detail_following_count')
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.white);
        Text(I18n('FollowedText'))
          .id('user_detail_following_label')
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.miWhite)
          .margin({ top: GSYSpacing.halfEdge / 2 });
      }
      .id('user_detail_following_block')
      .layoutWeight(1)
      .padding({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge })
      .alignItems(HorizontalAlign.Center)
      .border({ width: { left: 1 }, color: { left: GSYColor.primaryLight } })
      .onClick((): void => {
        Logger.i('user/count/click', 'idPrefix=user_detail_following dataType=' + COMMON_LIST_DATA_TYPE_FOLLOWING + ' login=' + this.login);
        if (this.login.length === 0) {
          return;
        }
        this.onJump(COMMON_LIST_DATA_TYPE_FOLLOWING, COMMON_LIST_SHOW_TYPE_USER, I18n('FollowedText'));
      });

      Column() {
        Text(this.fmt(this.store.starredCount))
          .id('user_detail_stared_count')
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.white);
        Text(I18n('staredText'))
          .id('user_detail_stared_label')
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.miWhite)
          .margin({ top: GSYSpacing.halfEdge / 2 });
      }
      .id('user_detail_stared_block')
      .layoutWeight(1)
      .padding({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge })
      .alignItems(HorizontalAlign.Center)
      .border({ width: { left: 1 }, color: { left: GSYColor.primaryLight } })
      .onClick((): void => {
        Logger.i('user/count/click', 'idPrefix=user_detail_stared dataType=' + COMMON_LIST_DATA_TYPE_USER_STAR + ' login=' + this.login);
        if (this.login.length === 0) {
          return;
        }
        this.onJump(COMMON_LIST_DATA_TYPE_USER_STAR, COMMON_LIST_SHOW_TYPE_REPOSITORY, I18n('staredText'));
      });
    }
    .id('user_detail_counts_row')
    .width('100%')
    .border({
      width: { top: 1 },
      color: { top: GSYColor.primaryLight },
    });
  }
}
