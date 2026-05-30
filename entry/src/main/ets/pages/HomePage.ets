/**
 * HomePage —— 对齐 Android Compose 版 HomeScreen。
 *
 * Compose 结构：
 *   - 顶部栏固定 app_name，左侧 menu 打开 ModalNavigationDrawer，右侧 SearchActionIcon。
 *   - 底部导航 Dynamic/Trending/Profile，对应文案 Feed/Trending/My。
 *   - DrawerContent 顺序：history / feedback / personal_info / language / check_update / about / logout。
 */
import { AppBar, AppBarAction } from '../common/AppBar';
import { DividerMode, HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';
import { CommonToast } from '../common/CommonToast';
import { DrawerHeader } from '../common/DrawerHeader';
import { DrawerMenu } from '../common/DrawerMenu';
import { EventBus, EVENT_TAB_DOUBLE_TAP } from '../utils/EventBus';
import { I18n } from '../i18n/I18n';
import { LoginExpiredBus } from '../net/HttpManager';
import { NetworkMonitor } from '../net/NetworkMonitor';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';
import { TabIcon, TabIconKey } from '../widget/TabIcon';
import { DynamicTabPage } from './tabs/DynamicTabPage';
import { TrendTabPage } from './tabs/TrendTabPage';
import { MyTabPage } from './tabs/MyTabPage';
import { SAFE_AREA_BOTTOM_KEY } from '../utils/SafeAreaInsets';
import { BOOT_TAB_KEY, BOOT_REPO_KEY, BOOT_PUSH_KEY, BOOT_ISSUE_KEY, BOOT_CODE_KEY, BOOT_USER_KEY, BOOT_PHOTO_KEY, BOOT_WEB_KEY, BOOT_COMMON_LIST_KEY, BOOT_NOTIFY_ISSUE_KEY } from '../entryability/EntryAbility';
import { Logger } from '../ai-debug/Logger';

interface HomeTabItem {
  key: string;
  title: string;
  icon: TabIconKey;
  index: number;
}

interface BootRepoRouteParam {
  fullName: string;
  reposOwner: string;
  reposName: string;
}

interface BootPushRouteParam {
  fullName: string;
  sha: string;
}

interface BootIssueRouteParam {
  fullName: string;
  number: number;
}

interface BootCodeRouteParam {
  fullName: string;
  branch: string;
  path: string;
}

interface BootUserRouteParam {
  login: string;
}

interface BootPhotoRouteParam {
  uri: string;
}

interface BootWebRouteParam {
  uri: string;
}

interface BootCommonListRouteParam {
  dataType: string;
  showType: string;
  currentUser: string;
  title: string;
  repoName: string;
}

const DOUBLE_TAP_INTERVAL_MS: number = 300;

@Component
export struct HomePage {
  @State currentIndex: number = 0;
  @State drawerOpen: boolean = false;
  @StorageProp(SAFE_AREA_BOTTOM_KEY) safeAreaBottom: number = 0;
  @StorageLink(BOOT_TAB_KEY) bootTab: string = '';
  private tabsController: HdsTabsController = new HdsTabsController();
  private lastTapAt: Map<number, number> = new Map<number, number>();
  private unsubscribeLoginExpired: (() => void) | null = null;
  private unsubscribeNetwork: (() => void) | null = null;
  private offlineToastShown: boolean = false;
  private tabs: HomeTabItem[] = [
    { key: 'dynamic',   title: I18n('tabDynamic'),     icon: 'aperture', index: 0 },
    { key: 'trend',     title: I18n('tabRecommended'), icon: 'activity', index: 1 },
    { key: 'my',        title: I18n('tabMy'),          icon: 'user',     index: 2 },
  ];

  aboutToAppear(): void {
    this.applyBootTab();
    this.scheduleBootRepo();
    this.scheduleBootPush();
    this.scheduleBootIssue();
    this.scheduleBootCode();
    this.scheduleBootUser();
    this.scheduleBootPhoto();
    this.scheduleBootWeb();
    this.scheduleBootCommonList();
    this.scheduleBootNotifyIssue();
    this.unsubscribeLoginExpired = LoginExpiredBus.subscribe((): void => {
      CommonToast.showShort(I18n('loginExpired'));
      NavigationService.replace(RouteName.Login);
    });
    this.unsubscribeNetwork = NetworkMonitor.onChange((online: boolean): void => {
      if (!online && !this.offlineToastShown) {
        this.offlineToastShown = true;
        CommonToast.showShort(I18n('networkOffline'));
        return;
      }
      if (online && this.offlineToastShown) {
        this.offlineToastShown = false;
        CommonToast.showShort(I18n('networkOnline'));
      }
    });
  }

  aboutToDisappear(): void {
    if (this.unsubscribeLoginExpired !== null) {
      this.unsubscribeLoginExpired();
      this.unsubscribeLoginExpired = null;
    }
    if (this.unsubscribeNetwork !== null) {
      this.unsubscribeNetwork();
      this.unsubscribeNetwork = null;
    }
  }

  private currentTitle(): string {
    if (this.currentIndex < 0 || this.currentIndex >= this.tabs.length) {
      return I18n('appName');
    }
    return this.tabs[this.currentIndex].title;
  }

  /**
   * 真机回归测试通道：读取 EntryAbility 注入的 bootTab，切到对应 tab。
   * 用完即清，避免下一次冷启动残留。
   * 直接走 AppStorage.get 避免 @StorageLink 在 aboutToAppear 时尚未同步的时序问题。
   */
  private applyBootTab(): void {
    const fromStorage: string | undefined = AppStorage.get<string>(BOOT_TAB_KEY);
    const tab: string = ((fromStorage !== undefined ? fromStorage : this.bootTab) || '').trim().toLowerCase();
    if (tab.length === 0) {
      return;
    }
    let target: number = -1;
    if (tab === 'dynamic') {
      target = 0;
    } else if (tab === 'trend') {
      target = 1;
    } else if (tab === 'my') {
      target = 2;
    }
    if (target < 0) {
      return;
    }
    this.currentIndex = target;
    this.tabsController.changeIndex(target);
    AppStorage.setOrCreate<string>(BOOT_TAB_KEY, '');
    this.bootTab = '';
  }

  /**
   * 真机回归测试通道：读取 EntryAbility 注入的 bootRepo=owner/name，
   * NavPathStack 绑定后再 push 到 RepositoryDetailPage（延迟 600ms 等 NavigationService.bind）。
   * 用完即清，避免下次冷启动残留。
   */
  private scheduleBootRepo(): void {
    const repo: string | undefined = AppStorage.get<string>(BOOT_REPO_KEY);
    const fullName: string = (repo || '').trim();
    if (fullName.length === 0) {
      return;
    }
    Logger.i('boot/ts', `HomePage.scheduleBootRepo pre-schedule t=${Date.now()} fullName=${fullName}`);
    setTimeout((): void => {
      const slash: number = fullName.indexOf('/');
      const owner: string = slash > 0 ? fullName.substring(0, slash) : '';
      const repoName: string = slash > 0 ? fullName.substring(slash + 1) : fullName;
      Logger.i('boot/ts', `HomePage.scheduleBootRepo pre-push t=${Date.now()} owner=${owner} name=${repoName}`);
      NavigationService.push(RouteName.RepositoryDetail, {
        fullName: fullName,
        reposOwner: owner,
        reposName: repoName,
      } as BootRepoRouteParam as Object);
      Logger.i('boot/ts', `HomePage.scheduleBootRepo post-push t=${Date.now()}`);
      setTimeout((): void => {
        AppStorage.setOrCreate<string>(BOOT_REPO_KEY, '');
      }, 1500);
    }, 600);
  }

  /**
   * 真机回归测试通道：读取 EntryAbility 注入的 bootPush=fullName|sha，
   * 延迟 600ms 后 push 到 PushDetailPage（保证 NavigationService.bind 已完成）。
   */
  private scheduleBootPush(): void {
    const value: string | undefined = AppStorage.get<string>(BOOT_PUSH_KEY);
    const raw: string = (value || '').trim();
    if (raw.length === 0) {
      return;
    }
    const sep: number = raw.indexOf('|');
    if (sep <= 0 || sep >= raw.length - 1) {
      return;
    }
    const fullName: string = raw.substring(0, sep);
    const sha: string = raw.substring(sep + 1);
    Logger.i('boot/ts', `HomePage.scheduleBootPush pre-schedule t=${Date.now()} fullName=${fullName} sha=${sha}`);
    setTimeout((): void => {
      Logger.i('boot/ts', `HomePage.scheduleBootPush pre-push t=${Date.now()}`);
      const param: BootPushRouteParam = {
        fullName: fullName,
        sha: sha,
      };
      NavigationService.push(RouteName.PushDetail, param as Object);
      Logger.i('boot/ts', `HomePage.scheduleBootPush post-push t=${Date.now()}`);
      setTimeout((): void => {
        AppStorage.setOrCreate<string>(BOOT_PUSH_KEY, '');
      }, 1500);
    }, 600);
  }

  /**
   * 真机回归测试通道：读取 EntryAbility 注入的 bootIssue=fullName|number，
   * 延迟 600ms 后 push 到 IssueDetailPage（保证 NavigationService.bind 已完成）。
   * 与 [scheduleBootRepo](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets#L147-L167) / scheduleBootPush 同款做法。
   */
  private scheduleBootIssue(): void {
    const value: string | undefined = AppStorage.get<string>(BOOT_ISSUE_KEY);
    const raw: string = (value || '').trim();
    if (raw.length === 0) {
      return;
    }
    const sep: number = raw.indexOf('|');
    if (sep <= 0 || sep >= raw.length - 1) {
      return;
    }
    const fullName: string = raw.substring(0, sep);
    const numberStr: string = raw.substring(sep + 1);
    const issueNumber: number = parseInt(numberStr, 10);
    if (isNaN(issueNumber) || issueNumber <= 0) {
      return;
    }
    Logger.i('boot/ts', `HomePage.scheduleBootIssue pre-schedule t=${Date.now()} fullName=${fullName} number=${issueNumber}`);
    setTimeout((): void => {
      Logger.i('boot/ts', `HomePage.scheduleBootIssue pre-push t=${Date.now()}`);
      const param: BootIssueRouteParam = {
        fullName: fullName,
        number: issueNumber,
      };
      NavigationService.push(RouteName.IssueDetail, param as Object);
      Logger.i('boot/ts', `HomePage.scheduleBootIssue post-push t=${Date.now()}`);
      setTimeout((): void => {
        AppStorage.setOrCreate<string>(BOOT_ISSUE_KEY, '');
      }, 1500);
    }, 600);
  }

  /**
   * 真机回归测试通道：读取 EntryAbility 注入的 bootCode=fullName|branch|path，
   * 延迟 600ms 后 push 到 CodeDetailPage（保证 NavigationService.bind 已完成）。
   * 与 [scheduleBootIssue](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets#L209-L236) 同款做法。
   */
  private scheduleBootCode(): void {
    const value: string | undefined = AppStorage.get<string>(BOOT_CODE_KEY);
    const raw: string = (value || '').trim();
    if (raw.length === 0) {
      return;
    }
    const sep1: number = raw.indexOf('|');
    if (sep1 <= 0 || sep1 >= raw.length - 1) {
      return;
    }
    const sep2: number = raw.indexOf('|', sep1 + 1);
    if (sep2 <= sep1 + 1 || sep2 >= raw.length - 1) {
      return;
    }
    const fullName: string = raw.substring(0, sep1);
    const branch: string = raw.substring(sep1 + 1, sep2);
    const path: string = raw.substring(sep2 + 1);
    if (fullName.length === 0 || branch.length === 0 || path.length === 0) {
      return;
    }
    Logger.i('boot/ts', `HomePage.scheduleBootCode pre-schedule t=${Date.now()} fullName=${fullName} branch=${branch} path=${path}`);
    setTimeout((): void => {
      Logger.i('boot/ts', `HomePage.scheduleBootCode pre-push t=${Date.now()}`);
      const param: BootCodeRouteParam = {
        fullName: fullName,
        branch: branch,
        path: path,
      };
      NavigationService.push(RouteName.CodeDetail, param as Object);
      Logger.i('boot/ts', `HomePage.scheduleBootCode post-push t=${Date.now()}`);
      // KI-029 同款 boot 通道时序竞争：push 后延迟 1500ms 再清空 BOOT_CODE_KEY，
      // 给 CodeDetailPage.aboutToAppear 的 tryAdoptBootCode 兜底读取留窗口期。
      setTimeout((): void => {
        AppStorage.setOrCreate<string>(BOOT_CODE_KEY, '');
      }, 1500);
    }, 600);
  }

  /**
   * 真机回归测试通道：读取 EntryAbility 注入的 bootUser=login（单字段，无 `|`），
   * 延迟 600ms 后 push 到 UserDetailPage（保证 NavigationService.bind 已完成）。
   * 与 [scheduleBootCode](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets#L250-L286) 同款做法。
   */
  private scheduleBootUser(): void {
    const value: string | undefined = AppStorage.get<string>(BOOT_USER_KEY);
    const raw: string = (value || '').trim();
    if (raw.length === 0) {
      return;
    }
    const login: string = raw;
    Logger.i('boot/ts', `HomePage.scheduleBootUser pre-schedule t=${Date.now()} login=${login}`);
    setTimeout((): void => {
      Logger.i('boot/ts', `HomePage.scheduleBootUser pre-push t=${Date.now()}`);
      const param: BootUserRouteParam = {
        login: login,
      };
      NavigationService.push(RouteName.UserDetail, param as Object);
      Logger.i('boot/ts', `HomePage.scheduleBootUser post-push t=${Date.now()}`);
      // KI-029 同款 boot 通道时序竞争：push 后延迟 1500ms 再清空 BOOT_USER_KEY，
      // 给 UserDetailPage.aboutToAppear 的 tryAdoptBootUser 兜底读取留窗口期。
      setTimeout((): void => {
        AppStorage.setOrCreate<string>(BOOT_USER_KEY, '');
      }, 1500);
    }, 600);
  }

  /**
   * 测试通道：want.parameters.bootPhoto=<image url>，
   * 启动后延迟 600ms push 到 PhotoPage（保证 NavigationService.bind 已完成）。
   * 与 [scheduleBootUser](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets#L300-L325) 同款做法。
   */
  private scheduleBootPhoto(): void {
    const value: string | undefined = AppStorage.get<string>(BOOT_PHOTO_KEY);
    const raw: string = (value || '').trim();
    if (raw.length === 0) {
      return;
    }
    const uri: string = raw;
    Logger.i('boot/ts', `HomePage.scheduleBootPhoto pre-schedule t=${Date.now()} uri=${uri}`);
    setTimeout((): void => {
      Logger.i('boot/ts', `HomePage.scheduleBootPhoto pre-push t=${Date.now()}`);
      const param: BootPhotoRouteParam = {
        uri: uri,
      };
      NavigationService.push(RouteName.Photo, param as Object);
      Logger.i('boot/ts', `HomePage.scheduleBootPhoto post-push t=${Date.now()}`);
      // KI-029 同款时序竞争：push 后延迟 1500ms 再清空 BOOT_PHOTO_KEY。
      setTimeout((): void => {
        AppStorage.setOrCreate<string>(BOOT_PHOTO_KEY, '');
      }, 1500);
    }, 600);
  }

  /**
   * 接住 want.parameters.bootWeb 注入：HomePage 起来后延迟 push 到 WebPage，
   * 让 WebPage aboutToAppear 用 BOOT_WEB_KEY 兜底拿 url。
   * 与 [scheduleBootPhoto](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets#L342-L362) 同款做法。
   */
  private scheduleBootWeb(): void {
    const value: string | undefined = AppStorage.get<string>(BOOT_WEB_KEY);
    const raw: string = (value || '').trim();
    if (raw.length === 0) {
      return;
    }
    const uri: string = raw;
    Logger.i('boot/ts', `HomePage.scheduleBootWeb pre-schedule t=${Date.now()} uri=${uri}`);
    setTimeout((): void => {
      Logger.i('boot/ts', `HomePage.scheduleBootWeb pre-push t=${Date.now()}`);
      const param: BootWebRouteParam = {
        uri: uri,
      };
      NavigationService.push(RouteName.WebPage, param as Object);
      Logger.i('boot/ts', `HomePage.scheduleBootWeb post-push t=${Date.now()}`);
      // KI-029 同款时序竞争：push 后延迟 1500ms 再清空 BOOT_WEB_KEY。
      setTimeout((): void => {
        AppStorage.setOrCreate<string>(BOOT_WEB_KEY, '');
      }, 1500);
    }, 600);
  }

  /**
   * 测试通道：读取 bootCommonList=dataType|showType|currentUser|repoName，
   * 用于覆盖 Compose ListViewModel 支持但主流程入口较深的列表类型。
   */
  private scheduleBootCommonList(): void {
    const value: string | undefined = AppStorage.get<string>(BOOT_COMMON_LIST_KEY);
    const raw: string = (value || '').trim();
    if (raw.length === 0) {
      return;
    }
    const parts: string[] = raw.split('|');
    if (parts.length < 3) {
      return;
    }
    const dataType: string = parts[0].trim();
    const showType: string = parts[1].trim();
    const currentUser: string = parts[2].trim();
    const repoName: string = parts.length > 3 ? parts[3].trim() : '';
    if (dataType.length === 0 || showType.length === 0 || currentUser.length === 0) {
      return;
    }
    Logger.i('boot/ts', `HomePage.scheduleBootCommonList pre-schedule t=${Date.now()} value=${raw}`);
    setTimeout((): void => {
      Logger.i('boot/ts', `HomePage.scheduleBootCommonList pre-push t=${Date.now()}`);
      const param: BootCommonListRouteParam = {
        dataType: dataType,
        showType: showType,
        currentUser: currentUser,
        title: '',
        repoName: repoName,
      };
      NavigationService.push(RouteName.CommonList, param as Object);
      Logger.i('boot/ts', `HomePage.scheduleBootCommonList post-push t=${Date.now()}`);
      setTimeout((): void => {
        AppStorage.setOrCreate<string>(BOOT_COMMON_LIST_KEY, '');
      }, 1500);
    }, 600);
  }

  /**
   * 测试通道：读取 EntryAbility 注入的 bootNotifyIssue=fullName|number，
   * 延迟进入 NotifyPage，让 NotifyPage 注入一条 Issue 通知并验证点击跳转。
   */
  private scheduleBootNotifyIssue(): void {
    const value: string | undefined = AppStorage.get<string>(BOOT_NOTIFY_ISSUE_KEY);
    const raw: string = (value || '').trim();
    if (raw.length === 0) {
      return;
    }
    Logger.i('boot/ts', `HomePage.scheduleBootNotifyIssue pre-schedule t=${Date.now()} value=${raw}`);
    setTimeout((): void => {
      Logger.i('boot/ts', `HomePage.scheduleBootNotifyIssue pre-push t=${Date.now()}`);
      NavigationService.push(RouteName.Notify);
      Logger.i('boot/ts', `HomePage.scheduleBootNotifyIssue post-push t=${Date.now()}`);
    }, 600);
  }

  private handleTabTap(index: number): void {
    const now: number = Date.now();
    const previous: number | undefined = this.lastTapAt.get(index);
    if (this.currentIndex === index && previous !== undefined && now - previous < DOUBLE_TAP_INTERVAL_MS) {
      EventBus.emit(EVENT_TAB_DOUBLE_TAP, index);
      this.lastTapAt.set(index, 0);
      return;
    }
    this.lastTapAt.set(index, now);
    this.currentIndex = index;
    this.tabsController.changeIndex(index);
  }

  /**
   * RN 端 TabIcon 内部同时绘制图标 + title（参考 [TabIcon.js#L52-L55](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/TabIcon.js#L52-L55)）。
   * 选中态 / 未选中态颜色由 TabIcon 根据 GSYColor.tabSelected / tabUnSelect 切换。
   * 注意：selected 必须以 @Prop 传入，currentIndex 切换才会触发子组件 rebuild。
   */
  @Builder
  buildTabBar(item: HomeTabItem): void {
    Column() {
      TabIcon({
        iconKey: item.icon,
        selected: this.currentIndex === item.index,
        title: item.title,
      });
    }
    .id('home_tab_bar_' + item.key)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => {
      this.handleTabTap(item.index);
    });
  }

  build(): void {
    Stack() {
      Column() {
        AppBar({
          title: I18n('appName'),
          showBack: false,
          titleStart: true,
          leftActions: [
            {
              iconKey: 'menu',
              onAction: (): void => {
                this.drawerOpen = !this.drawerOpen;
              },
            } as AppBarAction,
          ],
          rightActions: [
            {
              iconKey: 'search',
              onAction: (): void => {
                NavigationService.push(RouteName.Search);
              },
            } as AppBarAction,
          ],
        })
          .id('home_appbar');

        HdsTabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tabsController }) {
          TabContent() {
            DynamicTabPage();
          }
          .tabBar(this.buildTabBar(this.tabs[0]));

          TabContent() {
            TrendTabPage();
          }
          .tabBar(this.buildTabBar(this.tabs[1]));

          TabContent() {
            MyTabPage();
          }
          .tabBar(this.buildTabBar(this.tabs[2]));
        }
        .id('home_tabs')
        .barHeight(GSYSpacing.tabBarHeight)
        .barMode(BarMode.Fixed)
        .divider({ mode: DividerMode.FOLLOW_SCROLL })
        .barOverlap(true)
        .barBackgroundColor(GSYColor.transparent)
        .barFloatingStyle({
          barSideMargin: GSYSpacing.hdsFloatingTabSideMargin,
          barBottomMargin: this.safeAreaBottom + GSYSpacing.hdsFloatingTabBottomMargin,
          gradientMask: {
            maskColor: GSYColor.hdsFloatingTabMask,
            maskHeight: GSYSpacing.hdsFloatingTabMaskHeight,
          },
          lightColor: GSYColor.hdsFloatingTabLight,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE,
          },
          thermoCtrl: true,
        })
        .scrollable(false)
        .layoutWeight(1)
        .onChange((index: number): void => {
          this.currentIndex = index;
        });
      }
      .id('home_main_content')
      .width('100%')
      .height('100%')
      .padding({ bottom: this.safeAreaBottom })
      .backgroundColor(GSYColor.tabBackground)
      .zIndex(0);

      if (this.drawerOpen) {
        Blank()
          .id('home_drawer_scrim')
          .width('100%')
          .height('100%')
          .backgroundColor('#33000000')
          .zIndex(8)
          .onClick((): void => {
            this.drawerOpen = false;
          });
      }

      Column() {
        DrawerHeader({
          onAvatarTap: (): void => {
            this.drawerOpen = false;
          },
        });
        DrawerMenu({
          onItemTap: (_key: string): void => {
            this.drawerOpen = false;
          },
        });
      }
      .id('home_drawer_content')
      .width(304)
      .height('100%')
      .backgroundColor(GSYColor.white)
      .translate({ x: this.drawerOpen ? 0 : -320, y: 0, z: 0 })
      .zIndex(10)
      .animation({ duration: 260, curve: Curve.EaseOut });
    }
    .id('home_root')
    .width('100%')
    .height('100%')
    .alignContent(Alignment.TopStart);
  }
}
