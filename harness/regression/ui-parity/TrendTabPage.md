# TrendTabPage UI Parity Report

## 1. RN 基准清单

- 源：[TrendPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/TrendPage.js)
- 顶层结构：`PullListView` + 顶部 `TrendingFilter` 选择条
- 选择器维度：
  - **since**：daily / weekly / monthly（默认 daily）
  - **language**：All Language / JavaScript / Java / Kotlin / Swift / Python / ...（来自 [trend.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/trend.js)）
- 数据流：
  ```
  componentDidMount / 切换 since / language
    → trendActions.getTrend(since, language)
    → setState({ dataSource })
  onRefresh → 重新拉取
  ```
- ItemRow：`<TrendItem fullName={item.fullName} description={item.description} language={item.language} stars={item.stars} forks={item.forks} contributors={item.contributors} todayStars={item.currentPeriodStars} onPressed={...} />`

## 2. ArkUI 落地

- 源：[TrendTabPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/tabs/TrendTabPage.ets)
- 顶层 `Column`（`id=tab_page_root_trend`）
  - 顶部 `TrendPickerItem` 行（`id=trend_picker_bar`）：since 段落 + language 段落，与 RN 端 TrendingFilter 行为对齐
  - 数据源：[TrendService.fetchTrend](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/TrendService.ets)
  - Store：[TrendStore](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/store/TrendStore.ets)
  - DAO：[TrendDao](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/dao/TrendDao.ets) 以 `since|lang` 为 key 缓存
  - 列表：[PullLoadMoreList](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/PullLoadMoreList.ets)
  - 行：[RepositoryItem](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/RepositoryItem.ets)（owner avatar / name / description / language / stars / forks / contributors / todayStars 标签）
  - 路由：点击行 → `RouteName.RepositoryDetail`，参数用 `const repoParam: Record<string, Object>`
- since 默认 daily，language 默认 'All Language'
- 双击 Tab → 列表滚回顶（订阅 `EVENT_TAB_DOUBLE_TAP`）

## 3. 截图对照

| RN | ArkUI |
|---|---|
| RN 端 TrendPage 截图待回填 | [oh_home_trend.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_trend.png) — 真机 R5j device-home-smoke 截图：AppBar 切到「推荐」+「今日 ▼」「全部 ▼」二级选择条 + Empty 文案，沉浸式 statusBar light icon 与 AppBar 同色衔接 |
| — | [oh_home_trend_v2_immersive.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_trend_v2_immersive.png) (md5=0b9b94f1…) — **R5n + R5o + R5p 真机回归（bootTab=trend 路由注入 + 沉浸式光感 v2）**：① 沉浸式 OK（AppBar 深色 + statusBar 透明白图标 / navBar 透明白底 tabBar 黑文字）；② 顶部「今日 ▼」「全部 ▼」shadowCard 选择条与 RN 1:1；③ 推荐列表区初始空态（与 RN 一致行为，需切 since/language 后才填充）；④ 底部 3 Tab，推荐 tab 选中圆环 + 黑文字，间距对齐 RN，已让出 navIndicator。证据链：HomePage `applyBootTab` 读取 AppStorage `gsy_boot_tab='trend'` 后 `tabsController.changeIndex(1)` 切到推荐 tab |

- 测试 Host：[TrendTabListHostPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/pages/TrendTabListHostPage.ets)
- 单测：[TrendServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/TrendServiceTest.ets)
- UiTest：[TrendUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/TrendUiTest.ets)

## 4. 差异处理

- 已修齐：
  - since / language 二级选择条字段与 RN 端 trend.js 一致，默认值 `daily / All Language`
  - RepositoryItem 字段与 RN TrendItem 一一对齐：`fullName / description / language / stars / forks / contributors / todayStars`
  - 接口路径走 [trending github API mirror](https://github.com/huchenlei/github-trending-api)（与 RN 一致），见 [Address.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/net/Address.ets)
  - 修复 ArkTS 严格模式 `arkts-no-untyped-obj-literals`：路由参数全部用 `Record<string, Object>` 局部变量
- OH 增强：
  - **本地缓存**：以 `since|lang` 联合 key 缓存到 RDB（RN 端纯网络）
  - 双击 Tab 滚顶（EventBus 模拟，行为对齐）
  - **沉浸式 / 光感安全区**：依赖 HomePage 外壳的 [SafeAreaInsets.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/utils/SafeAreaInsets.ets) `enableImmersive`，AppBar 通过 `@Prop title` 切换到「推荐」时，statusBar 区段同色延伸不再出现行重叠（R5j 已修）
- 平台豁免：
  - RN 端选择器使用 react-native-picker-select 弹层；ArkUI 用 `TrendPickerItem` 行内段控件，视觉与交互不完全一致但语义对齐
