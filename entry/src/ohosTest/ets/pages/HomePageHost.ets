/**
 * HomePageHost —— UiTest 专用的 HomePage 镜像
 * 严格对齐 [HomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets)：
 *   - 3 Tab：Feed / Trending / My
 *   - 底部 TabBar，图标 + 文案（TabIcon）
 *   - AppBar 固定 appName，左侧 menu 打开抽屉，右侧 search
 *   - 双击当前 Tab 触发 EVENT_TAB_DOUBLE_TAP（与生产保持一致，但不再渲染计数器）
 *   - Drawer 菜单顺序跟 Compose HomeScreen 保持一致
 *
 * 与生产 HomePage 的唯一差异：
 *   - 不订阅 LoginExpiredBus / NetworkMonitor，避免测试中跨页副作用
 *   - search action onAction 留空（不实际跳转）
 */
import { AppBar, AppBarAction } from '../../../main/ets/common/AppBar';
import { DrawerHeader } from '../../../main/ets/common/DrawerHeader';
import { DrawerMenu } from '../../../main/ets/common/DrawerMenu';
import { EventBus, EVENT_TAB_DOUBLE_TAP } from '../../../main/ets/utils/EventBus';
import { I18n } from '../../../main/ets/i18n/I18n';
import { GSYColor, GSYSpacing } from '../../../main/ets/style/Theme';
import { TabIcon, TabIconKey } from '../../../main/ets/widget/TabIcon';
import { DynamicTabPage } from '../../../main/ets/pages/tabs/DynamicTabPage';
import { TrendTabPage } from '../../../main/ets/pages/tabs/TrendTabPage';
import { MyTabPage } from '../../../main/ets/pages/tabs/MyTabPage';

interface HomeTabItem {
  key: string;
  title: string;
  icon: TabIconKey;
  index: number;
}

const DOUBLE_TAP_INTERVAL_MS: number = 300;

@Entry
@Component
struct HomePageHost {
  @State currentIndex: number = 0;
  @State drawerOpen: boolean = false;
  private tabsController: TabsController = new TabsController();
  private lastTapAt: Map<number, number> = new Map<number, number>();
  private tabs: HomeTabItem[] = [
    { key: 'dynamic', title: I18n('tabDynamic'),     icon: 'aperture', index: 0 },
    { key: 'trend',   title: I18n('tabRecommended'), icon: 'activity', index: 1 },
    { key: 'my',      title: I18n('tabMy'),          icon: 'user',     index: 2 },
  ];

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
              },
            } as AppBarAction,
          ],
        })
          .id('home_appbar');

        Tabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tabsController }) {
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
        .scrollable(false)
        .layoutWeight(1)
        .onChange((index: number): void => {
          this.currentIndex = index;
        });
      }
      .id('home_main_content')
      .width('100%')
      .height('100%')
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
