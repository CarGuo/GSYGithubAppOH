# DynamicTabPage UI Parity Report

## 1. RN 基准清单

- 源：[DynamicPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/DynamicPage.js)
- 顶层结构：`PullListView` 包裹 `EventItem` 列表
- 数据流：
  ```
  componentDidMount
    → eventActions.getEvent(1, userInfo.login)  /users/:user/received_events  page=1
    → setState({ dataSource })
  onRefresh
    → 重置 page=1 + 重新拉取
  onEndReached
    → eventActions.getEvent(page+1, login)
  ```
- ItemRow：`<EventItem actionUser={item.actor.login} actionUserPic={item.actor.avatar_url} actionTime={item.created_at} actionTarget={item.repo.name} des={EventDes(item)} onPressed={...} />`
- 双击 TabBar → 列表滚回顶
- 空数据 → `EmptyView` (GitHub icon + emptyDataText)
- 401 → 退出登录路由 LoginPage（统一由 HttpManager 抛出）

## 2. ArkUI 落地

- 源：[DynamicTabPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/tabs/DynamicTabPage.ets)
- 顶层 `Column`（`id=tab_page_root_dynamic`）
  - 数据源：[DynamicService.fetchReceivedEvents](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/DynamicService.ets)（GET `/users/:login/received_events`）
  - Store：[DynamicStore](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/store/DynamicStore.ets) → `applyRefresh / applyAppend / hasMore / pageIndex`
  - DAO：[DynamicDao](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/dao/DynamicDao.ets) `DYN_TABLE_RECEIVED` 缓存
  - 列表组件：[PullLoadMoreList](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/PullLoadMoreList.ets)（下拉刷新 + 上拉加载更多 + Loading + Empty）
  - 行：[EventItem](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/EventItem.ets)（actor avatar / login / repo / des / time）
  - 路由分发：`actor.login` → `RouteName.UserDetail`；`repo` → `RouteName.RepositoryDetail`（参数用 `Record<string, Object>` 局部变量，符合 ArkTS 严格模式）
- 双击 Tab：订阅 `EVENT_TAB_DOUBLE_TAP`，列表滚到顶
- Empty：`my_empty_root` + `my_empty_text` 占位（与 MyTab 一致风格）

## 3. 截图对照

| RN | ArkUI |
|---|---|
| RN 端 DynamicPage 截图待回填 | [oh_home_dynamic.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_dynamic.png) — 真机 R5j device-home-smoke 截图：状态栏白字图标 + AppBar「动态」「搜索」+ EventItem 列表，3 Tab 几何图标 + safeAreaBottom padding |
| — | [oh_home_dynamic_v2_immersive.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_dynamic_v2_immersive.png) (md5=2f57122b…) — **R5n + R5o + R5p 真机回归（bootTab=dynamic 路由注入 + 沉浸式光感 v2）**：① 沉浸式 OK，statusBar 透明白图标 / navBar 透明白底 tabBar 黑文字；② AppBar「动态」+ 搜索 icon（之前缺失，已修复）；③ EventItem 列表已加载真实 received_events 数据；④ 底部 3 Tab（动态选中圆环 + 黑文字 / 推荐 / 我的），间距对齐 RN，已让出 navIndicator。证据链：HomePage `applyBootTab` 读取 AppStorage `gsy_boot_tab` 后 `tabsController.changeIndex(0)` 切到动态 tab，绕开 uinput 在 navIndicator 区误触系统返回桌面手势的问题 |

- 测试 Host：[DynamicTabListHostPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/pages/DynamicTabListHostPage.ets) / [DynamicTabEmptyHostPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/pages/DynamicTabEmptyHostPage.ets)
- 单测：[DynamicServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/DynamicServiceTest.ets)（含 fetchReceivedEvents + fetchUserEvents + fetchRepoEvents 各 6 it）
- UiTest：[DynamicUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/DynamicUiTest.ets)

## 4. 差异处理

- 已修齐：
  - 列表行 `EventItem` 字段与 RN 端字段一一对齐（actor / repo / created_at / type-driven 描述串）
  - 接口路径严格使用 [Address.getEvent](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/net/Address.ets) `/users/:user/received_events`
  - 401 → 触发 `LoginExpiredBus.publish()`，由 HomePage 外壳兜底跳 LoginPage
  - 空数据 → 同款空态视图，无任何调试探针
  - 修复 ArkTS 严格模式 `arkts-no-untyped-obj-literals`：跳路由参数全部用 `const xx: Record<string, Object> = {...}`
- OH 增强：
  - **离线缓存**：首屏走 RDB DYN_TABLE_RECEIVED 缓存优先，再异步刷网络（RN 端为纯网络）
  - 双击 Tab 滚顶（RN 端默认行为，OH 通过 EventBus 模拟实现，行为对齐）
  - **沉浸式 / 光感安全区**：HomePage 外壳通过 [SafeAreaInsets.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/utils/SafeAreaInsets.ets) `enableImmersive` 开 `setWindowLayoutFullScreen(true)` + 透明 statusBar/navBar + light icon，DynamicTab 列表自动让出顶部 statusBar（AppBar 同色背景延伸）和底部 navIndicator（HomePage 外 Column padding bottom）
- 平台豁免：
  - RN 端 PullListView 自带的"上拉提示文案"在 PullLoadMoreList 用了 ArkUI 内置 RefreshOptions，文案走 I18n token，视觉等价
