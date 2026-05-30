# HomePage UI Parity Report

## 1. RN 基准清单

- 源：[AppNavigator.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/navigation/AppNavigator.js#L72-L114) 中的 `MainTabScreen` BottomTabNavigator 定义
- 顶层结构：
  ```
  Tab.Navigator
    screenOptions:
      tabBarStyle: { height: tabBarHeight, backgroundColor: tabBackgroundColor }
      tabBarShowLabel: false
      headerStyle: navigationBar (primary 深色 #24292E)
      headerTitleStyle: { color: titleTextColor }
      headerRight: <SearchButton />
    Tab.Screen "DynamicPage"   icon=aperture title=I18n('tabDynamic')
    Tab.Screen "TrendPage"     icon=activity title=I18n('tabRecommended')
    Tab.Screen "MyPage"        icon=user     title=I18n('tabMy')
  ```
- 共 **3 个 Tab**：Dynamic / Trend / My（**没有** Recommend Tab，**没有** Drawer / 抽屉）
- 标签栏底部 (`barPosition: BarPosition.End`)，纯图标无文字 (`tabBarShowLabel: false`)
- AppBar 标题随当前 Tab 切换；右侧固定 SearchButton

## 2. ArkUI 落地

- 源：[HomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets)
- 顶层 `Column`（`id=home_main_content`，`backgroundColor=GSYColor.tabBackground`）
  - `AppBar` (`id=home_appbar`)：title 走 `currentTitle()` 随 `currentIndex` 变；rightActions 包含 `I18n('search')`，点击 `NavigationService.push(RouteName.Search)`
  - `Tabs(barPosition=BarPosition.End, ...)` (`id=home_tabs`)：3 个 `TabContent`（DynamicTabPage / TrendTabPage / MyTabPage），每个 tabBar 仅 [TabIcon](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/TabIcon.ets) 渲染，对应 `aperture / activity / user`，颜色 `GSYColor.tabSelected (#24292E) | tabUnSelect (#A6AAAF)`，`barHeight=GSYSpacing.tabBarHeight`，`barMode=Fixed`，`scrollable=false`
- TabBar id：`home_tab_bar_dynamic` / `home_tab_bar_trend` / `home_tab_bar_my`
- 双击当前 Tab → `EventBus.emit(EVENT_TAB_DOUBLE_TAP, index)`，由各 TabPage 自行响应（滚到顶 / 刷新）；阈值 `DOUBLE_TAP_INTERVAL_MS=300`
- 全局副作用：
  - `LoginExpiredBus.subscribe` → 401 时 toast `I18n('loginExpired')` + `NavigationService.replace(RouteName.Login)`
  - `NetworkMonitor.onChange` → 离线时 toast `I18n('networkOffline')`，恢复时 toast `I18n('networkOnline')`

## 3. 截图对照

| Tab | OH 真机截图 | 说明 |
|---|---|---|
| Dynamic | [oh_home_dynamic.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_dynamic.png) | AppBar title=「动态」；EventList 已渲染（受 fetchReceivedEvents 数据驱动） |
| Trend   | [oh_home_trend.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_trend.png) | AppBar title 切到「推荐」；today / all 二级选择条 + 刷新指示 |
| My      | [oh_home_my.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_my.png) | AppBar title 切到「我的」；UserHeadItem 14 个 id 全部渲染（fetchUser 飞行中显示占位 `---`） |

- 真机回归脚本：[device-home-smoke.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/device-home-smoke.sh)（PAT 通过 `aa start --PS bootToken` 注入，跳过 LoginPage）
- UiTest Host：[HomePageHost.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/pages/HomePageHost.ets)（与生产一致：3 Tab、AppBar、底部图标 TabBar、双击事件桥接）
- UiTest 用例：[HomeUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/HomeUiTest.ets)（6 个 it：根渲染 / 3 TabBar / 不渲染 recommend & drawer & 计数器 / 默认 dynamic / 切 trend / 切 my）

## 4. 差异处理

- 已修齐：
  - **3 Tab 严格一致**：去除旧版 4 Tab 的 RecommendTabPage（已删除文件，对齐 RN 端 MainTabScreen 仅 3 Tab）
  - **去除 Drawer / 抽屉**：旧版 HomePage 把 SearchPage 抽屉揉到 Home，违背 RN 端结构（RN 端 Drawer 仅在 SearchPage 上）；本轮重构后 HomePage 不再含 SideBarContainer
  - **去除调试探针**：旧 `home_double_tap_count` 调试文本已下线，符合 [ui-parity-with-rn.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/rules/ui-parity-with-rn.md) 规则一
  - **TabBar 纯图标**：使用 [TabIcon](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/TabIcon.ets) 组件，颜色与 GSYColor token 严格一致
  - **AppBar 标题动态切换 fix**：[AppBar.ets#L12-L13](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets#L12-L13) `title` / `subtitle` 改为 `@Prop` 修饰，HomePage @State currentIndex 变化时 AppBar 子组件能被框架正确 rebuild，title 真机切换可见（截图已回填）
- OH 增强：
  - **沉浸式 / 光感安全区**（HarmonyOS 6.1.0 / API 23）：[SafeAreaInsets.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/utils/SafeAreaInsets.ets) 在 [EntryAbility.onWindowStageCreate](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets#L41-L53) 调 `enableImmersive(windowStage)`：
    - `setWindowLayoutFullScreen(true)` 让内容延伸到 statusBar / navIndicator
    - `setWindowSystemBarProperties` 把 statusBar / navBar 设透明，内容 light-icon（深色 AppBar 配亮字图标）
    - 监听 `avoidAreaChange`，把安全区（vp 单位）写入 AppStorage：`SAFE_AREA_TOP_KEY` / `SAFE_AREA_BOTTOM_KEY`
    - [AppBar.ets#L105-L162](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets#L105-L162) `@StorageProp(SAFE_AREA_TOP_KEY)` 订阅，背景延伸到状态栏并自动让出 statusBar 高度
    - [HomePage.ets#L177](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets#L177) `padding({ bottom: this.safeAreaBottom })` 让 TabBar 离底部 navIndicator 留出安全区
    - RN 端无对应处理（RN 用 `react-native-safe-area-context`，OH 端这里走系统 window API，目标视觉一致）
  - `LoginExpiredBus` 全局 401 兜底（RN 端在 HttpManager fetch 处单点处理；OH 端补到 HomePage 外壳，行为一致但实现位置不同）
  - `NetworkMonitor` 弱网 / 离线 toast（OH 增强项，RN 端无）
- 平台豁免：
  - RN 端 Feather 图标库在 ArkUI 无对应字体 → 用 [TabIcon](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/TabIcon.ets) 几何绘制等价识别度（aperture 双圆 / activity 折线心电图 / user 头肩剪影）
