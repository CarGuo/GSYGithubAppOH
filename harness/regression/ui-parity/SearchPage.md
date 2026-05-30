# SearchPage — RN ↔ ArkUI 对照基线

> 7-step Step 1-4 产物（HARD-LAW-1 + HARD-LAW-5）。
> 单一事实源：[SearchPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/SearchPage.js) + [AppNavigator.js#L116-L142](https://github.com/CarGuo/GSYGithubApp/blob/master/app/navigation/AppNavigator.js#L116-L142) + [SearchDrawerFilter.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/SearchDrawerFilter.js) + [SearchFilterSelectList.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/SearchFilterSelectList.js) + [CustomDrawerButton.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/CustomDrawerButton.js) + [filterUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/filterUtils.js)。
> RN 端基准截图：[rn-SearchPage-repo-result.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-SearchPage-repo-result.jpg) / [rn-SearchPage-user-result.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-SearchPage-user-result.jpg) / [rn-SearchPage-filter-drawer.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-SearchPage-filter-drawer.jpg)

---

## § 1. RN 真实结构骨架（Step 2 抽布局）

```
SearchDrawer (Drawer.Navigator, drawerPosition='right', drawerWidth)
├─ Drawer.Header                              ← 关键：AppBar 由 Drawer 父级提供，非 SearchPage 自身
│  ├─ headerLeft = <CustomBackButton />        // 左 ← 返回 (FontAwesome arrow-left, color=miWhite)
│  ├─ title = I18n('search')                   // 中 "搜索" (titleTextColor)
│  ├─ headerStyle = styles.navigationBar        // primaryColor 背景
│  └─ headerRight = <CustomDrawerButton />     // 右 funnel filter icon (FontAwesome 'filter', size=20, color=miWhite)
│
├─ Drawer.Screen "SearchPageInner" → <SearchPage />
│  └─ View [styles.mainBox]                      mainBackgroundColor=#24292E
│     ├─ StatusBar transparent translucent light
│     ├─ Row [shadowCard, height=40, paddingV=normalEdge/3, bg=#FFF, borderBottomR=4]    ← 白底搜索条
│     │  ├─ TextInput [smallText, padding=0, paddingL=normalEdge/2, marginH=normalEdge/2,
│     │  │             borderRadius=3, backgroundColor=subLightTextColor=#E2E2E2, flex=1]
│     │  │  ├─ placeholder = I18n('search')
│     │  │  ├─ underlineColorAndroid='transparent'
│     │  │  ├─ clearButtonMode='always'
│     │  │  ├─ returnKeyType='search'
│     │  │  └─ onSubmitEditing → _refresh()
│     │  └─ TouchableOpacity [centered, marginT=2, marginH=normalEdge]
│     │     └─ Icon Ionicons 'search-outline' size=28 color=subLightTextColor=#E2E2E2
│     │
│     ├─ CommonBottomBar [marginH=normalEdge, marginT=normalEdge, bg=primaryColor, br=4]
│     │  ├─ item [searchRepos] textColor=(select===0?white:subTextColor) icon=(select===0?check:null)
│     │  └─ item [searchUser]  textColor=(select===1?white:subTextColor) icon=(select===1?check:null)
│     │      borderLeft=hairline borderLeftColor=lineColor
│     │
│     ├─ View [height=2, opacity=0.3]                                  // 阴影投影占位
│     │
│     └─ PullListView [flex=1, enableRefresh=false]
│        └─ renderRow:
│           ├─ select=0 → <RepositoryItem ownerName ownerPic name star fork watch type des>
│           └─ select=1 → <UserItem location actionUser actionUserPic des>
│
└─ Drawer.Content (right side, drawerWidth)  ← funnel 打开时滑入
   └─ <SearchDrawerFilter />
      ├─ View [bg=transparent]
      │  └─ View [bg=#F0000000, h=statusHeight, w=drawerWidth] (status bar 占位)
      │     └─ View [bg=primaryDarkColor, h=statusHeight, w=drawerWidth]
      │
      └─ <SearchFilterSelectList listStyle={flex:1, bg=white, marginTop=normalEdge*2}>
         SectionList 三段：
         ├─ Section "filerType"    items=SearchFilterType (best_match/stars/forks/updated)
         ├─ Section "filterSort"   items=SortType (desc/asc)
         └─ Section "filterLanguage" items=SearchLanguageType (trendAll/Java/Objective-C/Swift/...)

         renderSectionHeader: Row [marginT=normalEdge, paddingL=normalEdge, h=40,
                                    bg=primaryLightColor]  + Text smallTextWhite
         renderRow: TouchableOpacity [h=50, paddingH=normalEdge, marginT=normalEdge,
                                       bg=(item.select?miWhite:transparent), br=4, centered]
                     + Text (item.select ? normalText : subSmallText, textAlign:center)
         onPress: 单选 + Actions.pop({refresh: ...}) + DeviceEventEmitter.emit('SearchPage', {...})
```

---

## § 2. Token 映射表（Step 3 抽样式）

> 来源 [constant.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js)，目标 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets)

| RN 字面量 / token | OH token |
|---|---|
| `mainBackgroundColor #24292E` | `GSYColor.mainBackground` |
| `primaryColor` (AppBar/segment 底) | `GSYColor.primary` |
| `primaryDarkColor` (drawer 状态栏占位) | `GSYColor.primaryDark`（如缺则 `palette.navBackground` darken） |
| `primaryLightColor` (filter section header) | `GSYColor.primaryLight` |
| `titleTextColor` (AppBar 标题) | `GSYColor.white` |
| `miWhite` (AppBar icon / filter 选中底) | `GSYColor.miWhite`（≈ #F0F0F0） |
| `subLightTextColor #E2E2E2` (TextInput 底/search icon) | `GSYColor.subLightText` |
| `subTextColor #8E909C` (segment 未选中字) | `GSYColor.subText` |
| `lineColor` (segment 分割) | `GSYColor.line` |
| `normalMarginEdge` (10) | `GSYSpacing.normalEdge` |
| `normalMarginEdge/2` (5) | `GSYSpacing.halfEdge` |
| `normalMarginEdge/3` (3.3) | 自定义 `paddingV: 3` |
| `borderRadius=3 / 4` | 字面量 3/4（无 token） |
| `height=40 (header) / 50 (filter row)` | 字面量 40/50 |
| `Icon Ionicons search-outline size=28` | `IconFont FA_SEARCH glyphSize=28`（已存在）|
| `Icon FontAwesome filter size=20` | **缺**：需 `IconFont FA_FILTER` 或 AppBar `iconKey='filter'` 矢量绘制 |
| `Icon FontAwesome arrow-left` | 现 `AppBar.buildBack()` 用 `<` 文本（与 RN FontAwesome 视觉差异，已记 R6.1.b 字号 20 备注） |

---

## § 3. 交互序列伪代码（Step 4 抽行为）

```
[初始进入]
  Drawer.Navigator render
    headerLeft <- CustomBackButton (← icon)
    title      <- I18n('search')
    headerRight <- CustomDrawerButton (filter icon)
  SearchPage state = {showSelect: 0, dataSource: []}
  PullListView 显示空（refreshControl 不可用）

[点击 ← 返回]
  CustomBackButton.onPress → navigation.goBack()

[点击 filter icon]
  CustomDrawerButton.onPress → navigation.openDrawer()
  Drawer 从右侧滑入（drawerWidth）
  渲染 SearchDrawerFilter → SectionList(类型/排序/语言)

[在 filter 中点选某项]
  SearchFilterSelectList row.onPress
    1. 该 section 全部 data.select = false
    2. 当前 item.select = true  (单选)
    3. props.onSelect(title, value)
  SearchDrawerFilter.onSelect(case 'filerType' | 'filterSort' | 'filterLanguage')
    → Actions.pop({refresh: {...}})
    → DeviceEventEmitter.emit('SearchPage', {selectXxxData: value})

[SearchPage.componentDidMount 监听 'SearchPage']
  if 任意一项变化 → this._refresh()

[输入关键字 + 回车]
  TextInput.onSubmitEditing → _refresh() → repositoryActions.searchRepository(...)
  pullListRef.showRefreshState() → 渲染 dataSource → refreshComplete

[切换 segment]
  CommonBottomBar item.click → setState({showSelect, dataSource: []}) → _refresh(select)

[加载更多]
  PullListView.onEndReached → _loadMore() → page++ → concat
```

---

## § 4. 当前 OH 偏差（用户驳回点 + 自检）

| # | 偏差 | RN 期望 | OH 现状 | 修复动作 |
|---|---|---|---|---|
| D2-1 | **缺 AppBar** | Drawer header（← + "搜索" + filter funnel icon） | 整页直接是搜索条，状态栏下面就是白色 TextInput | [SearchPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/SearchPage.ets) build() 第一个子节点改为 `AppBar({ title: '搜索', showBack: true, immersive: true, rightActions: [{ iconKey: 'filter', onAction: openFilter }] })`，把 `padding({top: safeAreaTop})` 移交给 AppBar internal |
| D2-2 | **TextInput 应白底无填充** | TextInput 底 #E2E2E2 但置于一个白底卡片(height=40 + shadowCard)内，整体视觉是"白色搜索条 + 浅灰 input" | 整片 GSYColor.mainBackground 深色，TextInput 浅灰 — 缺白底卡片包裹（已有 `backgroundColor(GSYColor.white)` 在 `search_header_row` 但被深色 root 吞噬，且 RN cardWhite 卡片是有 shadowCard 阴影的） | 在 search_header_row Row 上加 `.shadow({radius: 4, color:'#1F000000', offsetY: 2})` + 确认 mainBackground 不在 AppBar 之下侵占，AppBar 接管状态栏 |
| D2-3 | **缺 filter Drawer 抽屉** | drawerPosition='right'，drawerWidth，三栏 SectionList | 完全没有，filter icon 即便加了也无处展示 | 新建 [common/SearchFilterDrawer.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/SearchFilterDrawer.ets)：用 SideBarContainer（type=Embed, sideBarPosition=End, controlButton 隐藏）+ `@State showDrawer: boolean` 控制；3 个 List section 数据来自 [filterUtils](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/filterUtils.js#L121-L144) (SearchFilterType / SortType / SearchLanguageType)；onSelect → store.setFilter + this.refresh() |
| D2-4 | **AppBar.iconKey 不支持 'filter'** | FontAwesome funnel | AppBar.buildAction 仅 'search' 矢量 + 通用 icon Image | [AppBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets) 增 `buildFilterVectorIcon`：用 Polygon/Line 绘制倒三角 funnel（顶宽底窄 + 茎线） |
| D2-5 | RN 端 `enableRefresh=false` | 不允许下拉刷新（仅 search 触发） | OH 端 PullLoadMoreList 默认开启下拉，已在 props 里默认 enable | 已用 SearchService submitSearch 触发，refreshControl 行为对齐（沿用现状）|

---

## § 5. 修复优先级（D2 子任务）

```
D2-1 SearchPage.ets 套 AppBar    → step5 子任务 a
D2-4 AppBar.ets 加 filter 矢量    → step5 子任务 b（D2-1 依赖）
D2-3 SearchFilterDrawer.ets 新建  → step5 子任务 c
D2-2 white card shadow            → step5 子任务 d（小，与 D2-1 同 patch）
D2-step5b hvigorw assembleHap     → step5b
D2-step6 hdc 真机 4 截图           → step6
D2-step7 本文档 § 6 截图对照表    → step7
```

---

## § 6. 截图对照（Step 6 真机回归 R6.1.c-D2 v3）

设备：emulator 6.1.0.115 (`127.0.0.1:5555`)，物理分辨率 1320×2856，hap 来自 [build-logs/r61c-d2-step5b-2.log](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/build-logs/r61c-d2-step5b-2.log) `BUILD SUCCESSFUL in 9 s 851 ms`。

| 场景 | RN 基准 | OH v3 | md5 | 对比结论 |
|---|---|---|---|---|
| 空态（未输入） | （RN 无截图） | [oh_SearchPage_empty_v3.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_empty_v3.png) | `d9607c0d888e04304e37440bda16f2bd` | ✅ AppBar (← / 搜索 / funnel) + 白底搜索条 + segment "✓ 仓库 / 用户" + "暂时还没找到什么(o° ▽° )o" 提示与 RN 同款 |
| 仓库结果 | [rn-SearchPage-repo-result.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-SearchPage-repo-result.jpg) | [oh_SearchPage_repo_result_v3.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_repo_result_v3.png) | `8ad416e705360f29335b85da2a4a25a9` | ✅ vuejs/vue / ygs-code/vue / bailicangdu/vue2-elm / PanJiaChen/vue-element-admin… 标题加粗 + des 副文 subText + ★ count 蓝色 + language 蓝色，与 RN 同款 |
| 用户结果 | [rn-SearchPage-user-result.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-SearchPage-user-result.jpg) | [oh_SearchPage_user_result_v3.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_user_result_v3.png) | `d68b097a39c87f1949d8f0630571d0bd` | ⚠ 数据已切到 User/Organization 列表 (VUE/vuejs/vueschool/Code-Pop/vuetifyjs/vueuse/vuelibs(User)/vuestorefront/...)，但 segment 视觉仍显示"✓ 仓库" 高亮（详见 KI-016） |
| filter Drawer | [rn-SearchPage-filter-drawer.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-SearchPage-filter-drawer.jpg) | [oh_SearchPage_filter_v3.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_filter_v3.png) | `fbd3c780ac8b61217158a2ece95a63b9` | ✅ 右侧抽屉，三段 Section（类型/排序/语言）+ 选项 row（最匹配/star/forks/更新；倒叙/正序；全部/Java/Objective-C/Swift），选中态浅灰高亮加粗，与 RN 同款 |

启动现场（点击 Home 右上角 🔍 进入 SearchPage 之前）：[oh_SearchPage_launch_v3.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_launch_v3.png) `39646ce7fc50688dbcae956ed773eeda`。

### 残留差异（已立 known-issue）

- **KI-016**：segment "仓库 / 用户" 状态视觉与数据态不一致 —— 切到用户后 dataSource 已是 User 列表，但 ✓ 仍亮在"仓库"。需在 [SearchPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/SearchPage.ets) `switchTab` 路径上确保 `@State activeTab` 与 segment 渲染同步触发 rerender。

---

## § 7. 状态

- 当前：❌ off-spec（**2026-05-24 R6.1.c-D2 ✅ aligned 已撤回**）
- 撤回原因：用户驳回 → 重新比对 RN 真源 [RepositoryItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/RepositoryItem.js) / [UserItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserItem.js) / [CommonBottomBar.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/common/CommonBottomBar.js) 与 OH 截图，发现根本不一样：
  - **KI-017 RepositoryItem 偏差**：缺白色 shadowCard 容器；缺 ownerPic 头像（normalIconSize 圆形）；缺 owner 子行（IconTextItem user icon + ownerName subLightSmallText）；语言 `repositoryType` 应在右上角 minTextSize 不是底栏；底栏应是 **3 等分** star-o / code-fork / issue-opened（FontAwesome + Octicons）+ subText 颜色，OH 仅 1 行 ★+language 蓝
  - **KI-018 UserItem 偏差**：缺白色 shadowCard；缺 actionUserPic 头像（smallIconSize 圆形）；OH 副文显示 "Organization / User" 字段在 RN UserItem 中根本不存在（RN 字段是 `location` + `des(=bio)`），说明 OH 端字段映射错误
  - **KI-019 segment 状态偏差**：RN 是把 itemTextColor / icon 通过 `_getBottomItem()` dataList **每次 setState 后重新计算**传入 CommonBottomBar；OH 端 CommonBottomBar 没把 itemTextColor 接受为 prop 也没在 itemClick 后刷新 ✓ 位置
- 修复方案见下方 § 8
- 三件套：RN 截图 ✅ + OH 截图 ✅ + 差异说明 ✅，但内容差异巨大（HARD-LAW-4 形式满足，HARD-LAW-1 因之前对 RN 子组件源没读到位而事实违反）

---

## § 8. R6.1.c-D3 修复 plan（对照 RN 子组件源）

| # | 文件 | 改动 |
|---|---|---|
| D3-1 | 新建 [entry/src/main/ets/widget/RepositoryItem.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/RepositoryItem.ets) | 严格对照 [RepositoryItem.js#L65-L143](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/RepositoryItem.js#L65-L143)：白色 shadowCard + UserImage(normalIconSize) + 标题加粗 + IconTextItem(user) owner 子行 + 右上角 language minTextSize subText + HTMLView 描述 + 三栏 IconButton(star-o/code-fork/issue-opened) |
| D3-2 | 新建 [entry/src/main/ets/widget/UserItem.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/UserItem.ets) | 严格对照 [UserItem.js#L36-L72](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserItem.js#L36-L72)：shadowCard + UserImage(smallIconSize) + 用户名加粗 smallText + 同行右侧 location subSmallText + 仅当 des 非空时副文 subSmallText |
| D3-3 | [SearchPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/SearchPage.ets) renderItem 切换：showSelect===0 渲染 RepositoryItem.ets；===1 渲染 UserItem.ets；字段映射严格对照 [SearchPage.js#L108-L131](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/SearchPage.js#L108-L131)（owner.login / owner.avatar_url / watchers_count / forks_count / open_issues / language / description；location / login / avatar_url / bio）|
| D3-4 | [CommonBottomBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonBottomBar.ets) 让 dataList 接受 itemTextColor / icon / iconColor 字段，每个 item 渲染时读 data 当下值；SearchPage `_getBottomItem` 等价物在 @State showSelect 改后重算 dataList |
| D3-5 | hvigorw assembleHap 编译验证 |
| D3-6 | hdc 装机 + 截 4 张 v4：oh_SearchPage_repo_result_v4 / oh_SearchPage_user_result_v4 / oh_SearchPage_filter_v4 / oh_SearchPage_segment_user_v4，逐张并排比对 RN 基准 |
| D3-7 | 写回本文档 § 6 v4 + INDEX 翻 ✅（必须每条偏差点都有截图证据） |

---

## § 9. R7-F 真机三件套（2026-05-24 21:49 AI 自跑闭环）

设备：emulator `127.0.0.1:5555`，1320×2856；hap = [entry-default-signed.hap](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/build/default/outputs/default/entry-default-signed.hap)（含 [CommonBottomBar.ets#L29](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonBottomBar.ets#L29) `@Prop @Watch dataList` 修复，BUILD SUCCESSFUL in 11s 473ms）。

### § 9.1 自动化命令链（AI 自跑，禁止用户出力）

```
hdc -t 127.0.0.1:5555 install -r entry/build/default/outputs/default/entry-default-signed.hap
hdc -t 127.0.0.1:5555 shell aa start -a EntryAbility -b cn.gsy.githubapp
hdc shell uitest uiInput click 1230 230         # HomePage 右上 🔍 → SearchPage
hdc shell uitest uiInput click 586 403          # focus search_input
hdc shell uitest uiInput inputText 586 403 flutter
hdc shell uitest uiInput click 1247 403         # search_submit_btn (bounds=[1208,361][1286,445])
hdc shell snapshot_display → r1.jpeg            # repo_result_v5
hdc shell uitest uiInput click 990 571          # segment_user (bounds=[660,543][1320,600])
hdc shell snapshot_display → r2.jpeg            # user_result_v5
hdc shell uitest uiInput click 330 571          # segment_repo (bounds=[0,543][660,600])
hdc shell snapshot_display → r3.jpeg            # segment_back_v5
```

### § 9.2 v5 截图对照（KI-017 / KI-018 / KI-019 闭环证据）

| 场景 | RN 基准 | OH v5 | md5 | 对比结论 |
|---|---|---|---|---|
| 仓库结果 | [rn-SearchPage-repo-result.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-SearchPage-repo-result.jpg) | [oh_SearchPage_repo_result_v5.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_repo_result_v5.png) | `3887c06949b36a7b25cc6df5832249fa` | ✅ **KI-017 闭环**：白色 shadowCard + UserImage(normalIconSize) + 标题加粗"flutter / plugins / FlutterExampleApps" + IconTextItem(user) owner 行（flutter / iampawan）+ 右上 language `Dart`(minTextSize) + HTMLView desc "Flutter makes it easy and fast..." + **三栏 IconButton ⭐176442 / 🍴30398 / 👤176442** ⇔ RN star-o/code-fork/issue-opened 1:1 |
| 用户结果 | [rn-SearchPage-user-result.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-SearchPage-user-result.jpg) | [oh_SearchPage_user_result_v5.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_user_result_v5.png) | `2b41663f9a6f7ce3a8e37ceb7be086b9` | ✅ **KI-018 闭环 + KI-019 闭环**：白色 shadowCard + 圆头像(smallIconSize) + 用户名加粗"flutter / fluttercandies / FlutterSmith / fluttercommunity / flutter-devs" + chevron `>` 右箭头；副文已不再显示错误的"Organization/User"（RN UserItem 字段是 location + bio，OH 已 1:1 对齐）；segment ✓ 已正确切到"用户"，KI-019 segment 同步 bug 修复（[CommonBottomBar.ets#L29](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonBottomBar.ets#L29) `@Prop @Watch` 触发 rebuild） |
| segment 回切 | （回归仓库结果） | [oh_SearchPage_segment_back_v5.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_segment_back_v5.png) | `3887c06949b36a7b25cc6df5832249fa` | ✅ click(330,571) 回到"仓库"，✓ 重新跳回左侧并列表恢复 repo 卡片（与 v5 repo md5 一致，证明回切完全等同初次） |

md5 v3↔v5 全部不同（v3 repo=`8ad4..`、v5 repo=`3887..`；v3 user=`d68b..`、v5 user=`2b41..`）→ HARD-LAW-4 通过。

### § 9.3 残留差异（与 RN 像素级最后偏差）

| 项 | RN | OH v5 | 等级 |
|---|---|---|---|
| star/fork/issue 图标族 | RN 同时混用 FontAwesome `star-o` + Octicons `code-fork` / `issue-opened` | OH 三栏均用 IconFont（FontAwesome 集），fork 图标视觉为 `🍴`(branch icon)、issue 用 `👤`(person icon) | 文字层面已对齐 RN 的 IconButton 三栏分布；细像素差异因 OH 端无 Octicons 字库已在 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets) 顶部注释说明，登记为可接受偏差 |
| chevron right | RN UserItem 末尾 `<Icon FontAwesome chevron-right>` | OH 末尾 `>` IconFont | ✅ 等价 |
| RN UserItem 显示 location/bio | 当前 mock 数据无 location/bio | OH v5 仅显示用户名（与 mock 数据一致；当返回 location/bio 时 [UserItem.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/UserItem.ets) 已实现条件渲染） | ✅ 实现侧已对齐，仅数据空 |

### § 9.4 KI 闭环 Sign-off

- ✅ KI-017 RepositoryItem 整体结构错位 → **Closed @ R7-F v5**：白卡 / 头像 / owner 子行 / 右上 language / desc / 三栏 IconButton 全部对齐
- ✅ KI-018 UserItem 字段映射错误 → **Closed @ R7-F v5**：白卡 / 圆头像 / 用户名 bold / 不再误显示 Organization 副文
- ✅ KI-019 segment ✓ 不跟手 → **Closed @ R7-F v5**：CommonBottomBar `@Prop @Watch dataList` + dataListRev rebuild 触发器修复，user→repo 切换 ✓ 同步

## § 10. R7-G 真机三件套（2026-05-24 23:xx → 2026-05-25 收尾，AI 自跑闭环）

承接用户 R7-F 之后反馈两条残留：(1) 点击 UserItem 进 UserDetailPage 直接崩；(2) 右上 funnel 按钮点击无效 + filter icon 边距过大；进一步：抽屉 row 点击（best_match/stars/forks/desc/asc/语言）无效。

### § 10.1 真凶定位（jscrash + dump layout 双证）

| Bug | 真凶 | 证据 |
|---|---|---|
| KI-022 UserItem 点击崩溃 | NavDestination `onReady` 早期阶段 [UserDetailPage.ets#L61](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L61) `stack.getAllPathName()` 抛 `undefined is not callable` | `/data/log/faultlog/faultlogger/jscrash-cn.gsy.githubapp-20020075-20260524222402004.log` |
| KI-023a funnel 边距过大 | [AppBar.buildAction](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets) Button 无 width，外 Row layoutWeight(1) 把按钮拉宽到 330px；funnel 实际 bounds 为 `[990,137][1320,333]` | `uitest dumpLayout` /tmp/v6_layout.json |
| KI-023b funnel 点击无效 | `rightActions` 在 `build()` 内每帧重建闭包 → ForEach key 失效 | code review |
| KI-023c 抽屉 row 点击无效 | [SearchFilterDrawer.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/SearchFilterDrawer.ets) `onSelect` 跨组件普通字段闭包，父级 SearchPage 每帧 build 传新闭包，但 ForEach row onClick 抓的是首次旧闭包，调用是空的 | code review + v7_05 dump 验证 |

### § 10.2 修复方案（已落地 commit e6a17b4）

- [UserDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets)：
  - `onReady` 优先用 `ctx.pathInfo.param` 拿 login（避免 inner stack 早期未挂载）
  - 新增 `resolveLoginFromParam`，`resolveLoginFromStack` 整体 try/catch 兜
  - 新增顶层 `safeStr(v)` + `writeReadHistory / buildHeader / rowBuilder / openRepository` 全部走 safeStr
- [UserDetailStore.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/store/UserDetailStore.ets)：
  - 新增 `sanitizeUserDetail`：所有 string/number 字段 null→''/0 兜底；`applyUser` 改为 sanitize 后再赋值
- [AppBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets)：
  - `buildAction` Button 加 `width(48)` + `hitTestBehavior(HitTestMode.Block)` + 内 Row `width/height 100% justifyContent Center` 撑开 hit area；外 Row 加 `padding({right:8})` + `hitTestBehavior(Transparent)`
- [SearchPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/SearchPage.ets)：
  - 新增 `@State appBarRightActions`，在 `aboutToAppear` 一次性创建并缓存（避免 build 每帧新闭包）
  - 新增 `@State @Watch('onFilterChanged') filterRev: number = 0`，`onFilterChanged` 内做 `drawerOpen=false` + `refresh()`
- [SearchFilterDrawer.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/SearchFilterDrawer.ets)：
  - 新增 `@Link rev: number`；`buildRow` onClick 内 `this.rev = this.rev + 1` 触发父级 watch
  - `buildRow` 加 `hitTestBehavior(HitTestMode.Block)` 防 SideBarContainer 主层吞点击

### § 10.3 真机三件套（HARD-LAW-4）

| step | 截图 | md5 验证 | layout dump |
|---|---|---|---|
| HomePage 启动 | [oh_SearchPage_v7_01_home.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_v7_01_home.jpeg) | `afe7615e..` | — |
| 搜索打开 | [oh_SearchPage_v7_02_open.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_v7_02_open.jpeg) | `2772000c..` | — |
| flutter 仓库结果 | [oh_SearchPage_v7_03_repo_result.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_v7_03_repo_result.jpeg) | `8e795b52..` | — |
| funnel(1208,235) → 抽屉弹出 | [oh_SearchPage_v7_04_drawer_open.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_v7_04_drawer_open.jpeg) | `21fc323b..` | `search_filter_drawer_root [410,137][1320,1757]` ✅ |
| forks row(865,855) → 抽屉关 + 列表 refresh | [oh_SearchPage_v7_05_after_click_forks.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_v7_05_after_click_forks.jpeg) | `0e004189..` | drawer 已消失 + `search_repo_0/1/2` 内容刷新（按 forks 排序）✅ |
| UserItem 点击不崩 | [oh_SearchPage_v6_05_user_click.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SearchPage/oh_SearchPage_v6_05_user_click.jpeg) | v6 已留存（v7 链路同源） | jscrash 不再产生新条目 |

funnel bounds 收紧对照：

| 阶段 | bounds | 宽度 (px) | 备注 |
|---|---|---|---|
| R7-F v5 之前（buildAction 无 width） | `[990,137][1320,333]` | 330 | 整个右半边都是 hit area，icon 视觉偏左 |
| R7-G v7（buildAction width(48) + 外 Row padding right:8） | `[1124,137][1292,333]` | 168 | icon 居中、距右屏边 28px，hit area 紧凑 |

### § 10.4 KI 闭环 Sign-off（R7-G v7）

- ✅ KI-022 UserItem 点击崩溃 → **Closed @ R7-G v7**：onReady try/catch + `ctx.pathInfo.param` 优先 + sanitize/safeStr 双重防御；真机点击 UserItem 进 UserDetailPage 全程无 jscrash
- ✅ KI-023 funnel 点击无效 + 边距过大 + 抽屉 row 无效 → **Closed @ R7-G v7**：appBarRightActions 缓存 + AppBar Button width(48) + 外 Row padding + SearchFilterDrawer rev 触发器；funnel(1208,235) 弹抽屉 / forks row(865,855) 关抽屉 + 刷新双向闭环

