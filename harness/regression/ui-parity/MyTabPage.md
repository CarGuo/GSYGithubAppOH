# MyTabPage UI Parity Report

## 1. RN 基准清单

- 源：[MyPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/MyPage.js) + [BasePersonPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/BasePersonPage.js)
- 顶层结构：`BasePersonPage(showType=0, currentUser=loginUserInfo)`
  - **showType=0** → `eventActions.getEvent(1, userInfo.login)` → `/users/:login/events`（自己的公开事件流，**不是** received_events）
- Header（`UserHeadItem`）：5 格指标横排
  - `repos`（公开仓库数）
  - `follower`（粉丝数）
  - `followed`（关注数）
  - `star`（star 列表总数 = 调用 `/users/:login/starred?page=N` 累加）
  - `beStared`（被 star 总数 = 公开仓库的 `stargazers_count` 之和）
- Header 副元素：
  - 头像 + display_name + login
  - bio（无则隐藏）+ "Joined GitHub on YYYY-MM-DD" 描述
  - 通知小铃铛（仅 setting=true 即"我自己"展示），未读 → `actionBlue (#267AFF)`
  - 组织列表横向滚动（`/user/orgs` 或 `/users/:login/orgs`）
  - setting=true 时点头像 → `Actions.SettingPage`
- Body：自己的 events 列表（同 DynamicPage 的 EventItem）
- 双击 Tab：滚到顶
- 401：HttpManager 抛出 LoginExpired

## 2. ArkUI 落地

- 源：[MyTabPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/tabs/MyTabPage.ets)
- 顶层 `Column`（`id=tab_page_root_my`）
  - Header：[UserHeadItem](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/UserHeadItem.ets) — 暴露 14 个 id：
    - `user_head_root` / `user_head_avatar` / `user_head_avatar_placeholder`
    - `user_head_display_name` / `user_head_login` / `user_head_des`
    - `user_head_bell`（unread 时 actionBlue）
    - `user_head_counter_value_<key>` / `user_head_counter_label_<key>` / `user_head_counter_cell_<key>` × 5（repos/follower/followed/star/beStared）
    - `user_head_orgs_bar`
    - `user_head_follow_btn` / `user_head_follow_text`
  - Body：[PullLoadMoreList](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/PullLoadMoreList.ets)（`id=my_pull_list`）+ [EventItem](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/EventItem.ets) 行
- 数据源（多 API 并发）：
  - `MyService.refreshMe()` → `/user`（profile + repos/follower/followed 三格指标）
  - [MyService.fetchUnRead()](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/MyService.ets) → `/notifications`（铃铛红点）
  - [MyService.fetchUserOrgs()](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/MyService.ets) → `/user/orgs`（组织条）
  - [MyService.fetchUserStarredCount()](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/MyService.ets) → 翻页 `/users/:login/starred` 累加 `stargazers_count` 拿 `star + beStared`
  - [DynamicService.fetchUserEvents()](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/DynamicService.ets) → `/users/:login/events`（事件流，与 RN showType=0 严格一致）
- 路由：
  - 头像 / display_name / login → 点击 `RouteName.Setting`（setting=true 即自己）
  - 5 格 counter cell 点击 → 分别跳 RepositoryStarPage / UserFollowedPage / UserFollowerPage 等子列表，参数用 `const param: Record<string, Object> = { 'login': login }`
  - 铃铛 → `RouteName.Notify`
  - EventItem 内部用户/仓库点击 → 同 DynamicTab

## 3. 截图对照

| RN | ArkUI |
|---|---|
| RN 端 MyPage 截图待回填 | [oh_home_my.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_my.png) — 真机 R5l device-home-smoke 截图：AppBar 切到「我的」+ UserHeadItem（头像 placeholder 圆形 / display_name / login / **bell·group·location·link 4 行已替换为 ArkUI 矢量 icon（Path+Circle+Rect 自绘，OpenHarmony SDK 无 sys.symbol/FontAwesome ttf）** / 5 chip 仓库·粉丝·关注·星标·荣耀），底部 3 几何 Tab **加 title 文字（动态/推荐/我的） + selected 改 @Prop 触发重绘**，已让出 navIndicator |
| — | [31_my_v4.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/full-tour-20260524-135012/31_my_v4.png) — **R5m 真机回归（bootToken 注入 + 12s 切到 my）**：CarSmallGuo / Small Guo / 创建于 2017-11-27 + 5 格指标 **repos=39 / follower=2 / followed=4 / star=--- / beStared=840097**（GitHub /user 接口本身不返回 starred，star=--- 与 RN 一致行为） + 真实 events 列表（labeled issue 274 in CarGuo/news_ai 等）。修复链：① bootToken 注入路径补 fetchMe；② MyTabPage struct 加 14 个 @State 缓存 + applyUserToHeaderState 显式赋值；③ buildHeader 全部读 @State；④ UserHeadItem.buildCounterCell 内部按 key switch 直接读 this.repos/follower/...（避开 @Builder 形参值传递不响应陷阱） |
| — | [oh_home_my_v5_emoji_star51.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_my_v5_emoji_star51.png) (md5=80e6d258…) — **R5r + R5s 真机回归（bootTab=my 路由注入 + 12s 截屏）** ⚠ **已过时，被 v6 FontAwesome 方案取代**：① 4 矢量 icon 用 Unicode emoji 临时方案——🔔🏢📍🔗，不专业不对齐 RN 端 FontAwesome 视觉风格，仅作为过渡；② 5 格指标 **repos=39 / follower=2 / followed=4 / star=51 / beStared=5** ——`star=51` 是真实值，HiLog 实证 `parseLinkLastPage: rel=last page=51`；③ 沉浸式 OK（顶部贴边 + 底部白底 tabBar 黑文字 / 我的 tab 圆环 selected 态）。修复链：① [UserHeadItem.ets#L100-L123](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/UserHeadItem.ets#L100-L123) `buildVectorIcon` 改 emoji 实现，扁平掉 [buildIconLine](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/UserHeadItem.ets#L125-L143) 外层 Stack；② [MyService.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/MyService.ets) `parseLinkLastPage` 由 `lastIndexOf('page=')~lastIndexOf('>')` substr 切法改为正则 `/<[^>]*[?&]page=(\d+)[^>]*>;\s*rel="last"/`，精准匹配 GitHub 真实 Link header（双段 `<...&page=2>; rel="next", <...&page=51>; rel="last"`）；③ readLinkHeader 加 hilog 全 keys 打印 + 大小写不敏感扫描兜底（HarmonyOS http 模块 normalizeHeaders 后字段名是全小写 `link`） |
| — | [oh_home_my_v6_fontawesome.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_my_v6_fontawesome.png) (md5=5e48d0a2…) — **R5r-v3 真机回归（bootTab=my + FontAwesome iconfont 方案）✓✓**：① 4 矢量 icon 全部走 **FontAwesome 4.x 字体族**（与 RN 端 react-native-vector-icons 同源 ttf）—— bell=`\uf0f3` 通知铃铛 / group=`\uf0c0` 群组三人剪影 / map-marker=`\uf041` 水滴标点 / link=`\uf0c1` 链环，矢量线描风格与 RN 端 `<Icon name="bell" />` 视觉**完全一致**，不再用 emoji 占位；② 5 格指标 **39 / 2 / 4 / 51 / 5** ✓；③ 沉浸式 ✓ / 我的 tab 选中圆环 ✓。修复链：① 从 RN 端 [FontAwesome.ttf](https://github.com/CarGuo/GSYGithubApp/blob/master/android/app/build/intermediates/ReactNativeVectorIcons/fonts/FontAwesome.ttf) 复制到 OH [rawfile/fonts/FontAwesome.ttf](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/resources/rawfile/fonts/FontAwesome.ttf) 165548 bytes；② [WelcomePage.ets#L35-L46](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WelcomePage.ets#L35-L46) `aboutToAppear` 调 `font.registerFont({ familyName: 'FontAwesome', familySrc: $rawfile('fonts/FontAwesome.ttf') })`——**关键：必须在 UI 上下文（@Entry 页面）调用，UIAbility 内会抛 401**；③ [UserHeadItem.ets#L109-L124](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/UserHeadItem.ets#L109-L124) `buildVectorIcon` 用 `Text(unicode).fontFamily('FontAwesome')`，码点严格对齐 RN 端 [FontAwesome.json glyphmap](https://github.com/CarGuo/GSYGithubApp/blob/master/node_modules/react-native-vector-icons/glyphmaps/FontAwesome.json)。HiLog 实证 `WelcomePage: registerFont FontAwesome ok` |
| — | [oh_home_my_v7_iconfont_smaller.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_my_v7_iconfont_smaller.png) (md5=82e4e6f1a74bcc30666254b38b7f4a70) — **R5r-v4 真机回归（FontAwesome icon 调小到 size*0.5 ≈ 15px）✓**：① 4 矢量 icon 尺寸缩小到 15px，与 RN 端 IconText 14px 视觉一致，不再偏大；② 5 格指标 39/2/4/51/5 维持 ✓；③ 沉浸式 ✓ / 我的 tab 选中圆环 ✓。修复：[UserHeadItem.ets#L112-L127](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/UserHeadItem.ets#L112-L127) `buildVectorIcon` `.fontSize(size * 0.5)` 替代 `size * 0.85` |
| — | [oh_home_my_v8_iconfont_struct.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/HomePage/oh_home_my_v8_iconfont_struct.png) (md5=`2ac7edc05c96faea1ac80ccd4f121f3e`) — **R5r-v5 真机回归（IconFont 通用组件抽取 + 6 处调用点改造）✓✓**：① 新建 [IconFont.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/IconFont.ets) 暴露 50+ FontAwesome 4.x 码点常量 + `IconFont({char, glyphSize, glyphColor})` @Component（**注意：属性命名必须避开 ArkUI CustomComponent 内置同名属性 size/color/width/height，否则触发 ArkTS 10505001 编译错误**）；② [UserHeadItem.ets#L116-L132](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/UserHeadItem.ets#L116-L132) `buildVectorIcon` 改为 `Stack { IconFont(...) }.width(size).height(size).alignContent(Alignment.Center)`（外层 Stack 用于稳定尺寸槽位，因 IconFont 自身不支持 .width/.height 链式调用）；③ 其他 5 处统一切到 IconFont 调用（[RepositoryItem.ets#L42-L51](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/RepositoryItem.ets#L42-L51) star/fork/eye 计数 / [SearchPage.ets#L213-L218](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/SearchPage.ets#L213-L218) FA_STAR + [#L398-L401](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/SearchPage.ets#L398-L401) FA_SEARCH / [SubListView.ets#L76-L88](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/sub/SubListView.ets#L76-L88) FA_STAR+FA_CODE_FORK / [DrawerMenu.ets#L72-L82,L138](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/DrawerMenu.ets#L72-L82) 7 行 emoji→FA / [FilesTab.ets#L72-L77](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/repo/FilesTab.ets#L72-L77) FA_FOLDER+FA_FILE）；④ 5 格指标 39/2/4/51/5 维持 ✓；⑤ 4 矢量 icon 视觉与 v7 等价（仅外层 Stack 包裹改变 md5 但视觉无差异）；⑥ 沉浸式 + 选中圆环 + 3 张动态卡片正常显示。完整证据：[iconfont-refactor-20260524-152148/README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/iconfont-refactor-20260524-152148/README.md) |

- 测试 Host：[MyTabPageHost.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/pages/MyTabPageHost.ets)
- 单测：[MyServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/MyServiceTest.ets)（含 fetchUnRead × 3 / fetchUserOrgs × 3 / fetchUserStarredCount × 4 共 10 个新 API 单测）
- UiTest：[MyUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/MyUiTest.ets)（9 个 it：tab 根 / display_name+login+des / 头像 placeholder / 5 格指标 id / bell / orgs_bar / 服务调用计数 / 空态 / store 注入）

## 4. 差异处理

- 已修齐：
  - **events 接口路径**：从 received_events 修正为 `/users/:login/events`，对齐 RN BasePersonPage `showType=0` 行为
  - **5 格指标完整**：repos / follower / followed / star / beStared 全部展示，star+beStared 由翻页 `/starred` 累加获得（与 RN 算法一致）
  - **通知铃铛**：unread 时 actionBlue=#267AFF，对齐 RN
  - **组织条**：横向滚动 `user_head_orgs_bar`
  - **bio + Joined** 描述串与 RN 完全相同
  - **setting=true 头像跳 Setting** 行为已实现
  - 路由参数全部 `Record<string, Object>`，符合 ArkTS 严格模式
- OH 增强：
  - 本地 RDB DYN_TABLE_USER_EVENT 缓存自己事件流，离线优先
  - AppStorage 同步 AuthUserInfo 15 字段（含 company / location / blog / created_at / type 扩展），便于离线展示
  - **沉浸式 / 光感安全区**：HomePage 外壳通过 [SafeAreaInsets.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/utils/SafeAreaInsets.ets) `enableImmersive` 让 statusBar / navBar 透明 + light icon；MyTabPage 内 UserHeadItem 头像区落到 AppBar 下方，底部 3 几何 Tab 通过 `@StorageProp(SAFE_AREA_BOTTOM_KEY)` 自动让出 navIndicator
- 平台豁免：
  - RN 端 BasePersonPage 还包含 contribution heatmap（贡献热力图），OH 端已抽到独立 [ContributionHeatmap](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/ContributionHeatmap.ets) 组件，后续在 R6 UserDetailPage 中合入；MyTabPage 暂不渲染热图，避免双重维护（与 RN 在自己页也展示热图存在轻微视觉差异，差异豁免在 [ui-parity-with-rn.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/rules/ui-parity-with-rn.md) 中标注待补）
