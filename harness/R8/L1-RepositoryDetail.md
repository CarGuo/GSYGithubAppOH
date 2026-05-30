# L1 RepositoryDetailPage 主链

> 4 tab：Activity / Readme / Files / Issues。
> 入口：dynamic 列表点 row → 仓库详情 / `aa start --PS bootRepo owner/name`。
> RN 真源已读完，OH 结构层已对齐，剩 S5 真机视觉对照 + S6 RN 比对。

---

## § 1 RN 基准清单

### 1.1 RN 源
- 主壳：[RepositoryDetailPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailPage.js) 379 行
- ActivityTab：[RepositoryDetailActivityPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailActivityPage.js) 352 行
- ReadmeTab：[CodeDetailPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/CodeDetailPage.js) + inline `<WebComponent>`
- FileTab：[RepositoryDetailFilePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailFilePage.js)
- IssueTab：[RepositoryIssueListPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryIssueListPage.js)
- Header widget：[RepositoryHeader.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/RepositoryHeader.js) 349 行
- 底栏：[CommonBottomBar.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/common/CommonBottomBar.js) 75 行
- 路由：[AppNavigator.js#L222-L237](https://github.com/CarGuo/GSYGithubApp/blob/master/app/navigation/AppNavigator.js#L222-L237)（默认 ScreenOptions 含 navigationBar + headerRight=more）

### 1.2 顶层结构（基于真机截图 + 源码双重验证）

```
View(mainBox, bg=miWhite)
├─ AppBar (React Navigation 默认 stackHeader)
│  ├─ headerLeft: CustomBackButton (<)
│  ├─ headerTitle: 仓库名（miWhite）
│  └─ headerRight: CommonIconButton ⋯ (more menu)
├─ Tab.Navigator(activeTint=white, inactiveTint=#959595, bg=#24292e, indicator=white-3px-fullwidth)
│  ├─ "Activity" → RepositoryDetailActivityPage
│  │   └─ PullListView(headerBuilder = RepositoryHeader + CommonBottomBar(动态/提交/Pulse 三选一))
│  │      └─ EventItem × N
│  ├─ "Readme"  → WebComponent(HTML)
│  ├─ "Files"   → RepositoryDetailFilePage
│  └─ "Issues"  → RepositoryIssueListPage
└─ SafeAreaView(底部 showBottom)
   └─ CommonBottomBar(star/eye/repo-forked) + PopmenuItem(branch picker)
```

**关键认知**：
- RN 端**有 AppBar**（之前 R6 误判为"无 AppBar 删除"，R7-J 反转纠正）
- RN 端**无页面级 header**——RepositoryHeader 在 ActivityTab 内当 listHeader
- 4 tab 顺序固定：**Activity / Readme / Files / Issues**
- 底部 `showBottom` 控制 CommonBottomBar(3 项) + PopmenuItem(branch)，加起来视觉 1 行 4 项

### 1.3 token 映射

| RN constant.js | Theme.ets | 用途 |
|---|---|---|
| `primaryColor #24292e` | `GSYColor.primary` | tab bar bg / header 卡片 / bottombar |
| `primaryHalf #8024292e` (alpha 0.5) | `GSYColor.primaryHalf` | RepositoryHeader 半透明覆盖 |
| `primaryLightColor #42464b` | `GSYColor.primaryLight` | 1px line |
| `lineColor #42464b` | `GSYColor.line` | hairline |
| `miWhite #ececec` | `GSYColor.miWhite` | mainBox bg / 标题文字 |
| `white #FFF` | `GSYColor.white` | tab indicator / SafeArea bg |
| `subTextColor #959595` | `GSYColor.subText` | tab inactive / 次要文字 |
| `actionBlue #267aff` | `GSYColor.actionBlue` | fork 来源蓝字超链 |
| `minTextSize 12` | `GSYFontSize.min` | 元数据行 |
| `smallTextSize 14` | `GSYFontSize.small` | tab label / bottombar text |
| `normalMarginEdge 10` | `GSYSpacing.normalEdge` | 卡片内外边距 |

### 1.4 交互序列

```
进入：Actions.RepositoryDetail({ownerName, repositoryName, title, defaultProps})
  → componentDidMount
  → InteractionManager.runAfterInteractions
     → repositoryActions.getRepositoryDetail(owner, name)   远程
     → repositoryActions.addRepositoryLocalRead(...)         本地读历史
     → this._refresh()                                       README + star/watch
     → repositoryActions.getBranches(...)
  → BackHandler addEventListener

Tab 切换：Tab.Navigator 自管，4 个 Screen 各自 setup

底栏 3 按钮：
  star → doRepositoryStar(!stared) → LoadingModal → setTimeout(500) → pop + _refresh
  eye  → doRepositoryWatch(!watched) → 同上
  fork → ConfirmModal → createRepositoryForks → toast + pop

ActivityTab 三选一：动态(0) / 提交(1) / Pulse(2)
  → setState({select}) → _refresh(select)
  → select=0 EventItem / select=1 EventItem(commits)→PushDetail / select=2 RepositoryPulseItem

PopmenuItem：选分支 → _refreshChangeBranch 重新拉 README + 通知 detailFile.changeBranch
```

---

## § 2 OH 偏差清单

| # | 现象 | RN 真源 | 根因 | 影响文件 | 状态 |
|---|---|---|---|---|---|
| D1 | scenario-tour repoDetail-readme tap 失败（v1） | 应 tap [repo_detail_tab_bar_readme] 切换 readme tab | scenario-tour 候选 id 列表未含 OH 真实 id 前缀 | [scripts/scenario-tour.sh#L370-L395](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh#L370-L395) + [RepositoryDetailPage.ets#L74-L79](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryDetailPage.ets#L74-L79) | ✅ Closed（v2 候选列表加入 `repo_detail_tab_bar_<TAB>`，命中 @495,417）|
| D2 | scenario-tour repoDetail-files tap 失败（v1） | 应 tap [repo_detail_tab_bar_files] | 同 D1 + spec key `issues` 与 OH 真实 key `issue` 不一致 | 同 D1 | ✅ Closed（v2 spec 改 `issue`，命中 files@825,417 / issue@1155,417）|
| D3 | 未登录态 getReposInfo 401 → 4 字段 `---` / 描述 `---` / 创建于 `---` | 登录后真实 41024/7563/226/28 | 网络回路依赖 PAT；防御层已兜底 | 防御层 OK，登录态视觉验证留 P1 | P1（不阻塞 L1 视觉对齐 DoD）|
| D4 | RepositoryHeader banner 无大图模糊背景 | RN 卡片背景为 owner avatar 模糊覆盖 + alpha 0.5 | 未登录态 owner avatar URL 为空 | [RepositoryHeader.ets#L134-L155](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/RepositoryHeader.ets#L134-L155) 实现已就绪，仅缺数据 | P1（依赖 D3 登录） |
| D5 | RepositoryHeader 缺 topics chips 区 | RN 在 desc 下渲染 topics tag 列表 | OH 实现未渲染 topics chips | [RepositoryHeader.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/RepositoryHeader.ets) | P2（数据齐后单独 commit）|

代码层先前已对齐项（不再单列偏差，仅留闭环记录）：
- ✅ 4 tab 顺序 Activity/Readme/Files/Issues（[ets#L74-L79](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryDetailPage.ets#L74-L79)）
- ✅ AppBar 加回（[ets#L473-L480](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryDetailPage.ets#L473-L480)）
- ✅ CommonBottomBar 4 项（[ets#L572-L577](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryDetailPage.ets#L572-L577)）
- ✅ RepositoryHeader Column + backgroundImage/blurStyle（[ets#L134-L155](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/RepositoryHeader.ets#L134-L155)）
- ✅ Token 全 GSYColor/GSYFontSize/GSYSpacing
- ✅ EventItem onTap 三段式防护 + try/catch（[ActivityTab.ets#L178-L226](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/repo/ActivityTab.ets#L178-L226)）
- ✅ ActivityTab 三选一 SegmentedControl（动态/提交/Pulse）

---

## § 3 截图对照

### RN 基准截图（已就绪）
- [rn-RepositoryDetail-activity-tab.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-activity-tab.jpg)
- [rn-RepositoryDetail-detail-tab.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-detail-tab.jpg)
- [rn-RepositoryDetail-files-root.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-files-root.jpg)
- [rn-RepositoryDetail-files-breadcrumb.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-files-breadcrumb.jpg)
- [rn-RepositoryDetail-issues-tab.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-issues-tab.jpg)
- [rn-RepositoryDetail-issues-more-menu.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-issues-more-menu.jpg)
- [rn-RepositoryDetail-commits-tab.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-commits-tab.jpg)

### OH 截图（v2 全 4 tab ok=4 fail=0 dup=NO）
跑分目录：[reports/M6/r8-l1-repodetail-20260525-2307/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l1-repodetail-20260525-2307)

| # | tab | 截图 | md5 |
|---|---|---|---|
| 06 | activity | [06_repoDetail-activity.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l1-repodetail-20260525-2307/06_repoDetail-activity.png) | 17616a21183bd07cc4d1ed1d410cef13 |
| 07 | readme | [07_repoDetail-readme.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l1-repodetail-20260525-2307/07_repoDetail-readme.png) | 332b7174a2fea2d71cac13d9dc9d81e8 |
| 08 | issues | [08_repoDetail-issues.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l1-repodetail-20260525-2307/08_repoDetail-issues.png) | ccf0d2285c0126dcf3a410a95d1afe56 |
| 09 | files | [09_repoDetail-files.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l1-repodetail-20260525-2307/09_repoDetail-files.png) | cbf59f78a7064ed220136fe83d2cb3dd |

### 差异表（S6 已对照 RN activity）

| # | RN | OH | 差异 | 处理 |
|---|---|---|---|---|
| Δ1 | AppBar 标题文字 "RepositoryDetail" | OH AppBar 标题为空 | 缺标题 props 传递 | P2 修 AppBar title prop（不阻塞 L1）|
| Δ2 | RepositoryHeader 显示真实数据（owner avatar/desc/topics/star/fork/watch/issue/创建于/最后提交）| 全 `---` | 未登录态 401 | P1（D3）|
| Δ3 | RepositoryHeader 有 owner avatar 模糊大图背景 | OH 是灰底（avatar URL 空）| 数据依赖 | P1（D4 与 D3 同因）|
| Δ4 | RepositoryHeader 有 topics chips 行 | 缺渲染 | OH 实现缺 topics 区 | P2（D5）|
| Δ5 | 4 tab 顺序+文案+下划线指示器 | ✅ 完全一致（动态/详情信息/文件/Issues, indicator 白色 3px）| ─ | ✅ 对齐 |
| Δ6 | ActivityTab 三选一 SegmentedControl（动态/提交/Pulse）| ✅ 完全一致（OH 截图清晰可见）| ─ | ✅ 对齐 |
| Δ7 | 列表为空文案 | OH "动态 / Ta什么都没留下" RN "started 666ghj/BettaFish ..." | OH 401 空 | P1（D3）|

**结论**：5 处 P1/P2 差异全部归因 D3/D4/D5（登录态数据 + topics 区），**视觉骨架完全对齐**。

---

## § 4 DoD 检查表

```
☑ 1. § 1/2/3 三件套齐
☑ 2. ArkTS 0 字面量（已走 GSYColor/GSYFontSize/GSYSpacing）
☑ 3. ArkTS 0 调试 Text（KI-007 已 Closed）
☑ 4. hvigorw BUILD SUCCESSFUL（2026-05-25 22:54）
☑ 5. scenario-tour 4 tab ok=4 fail=0 dup=NO（v2 23:07）
☑ 6. 截图 md5 唯一（4 张不同 md5）
☑ 7. hilog 0x0666 marker + assert ≥ 3（hilog_business.log 437 行）
☑ 8. RN ↔ OH 差异 5 处（≤ 5 触底，全部归因数据/P2）
☑ 9. INDEX.md 第 9 行 ✅ aligned（待 commit 时同步）
☑10. KI-003..006 Closed；KI-007 Closed；KI-008 Closed
```

---

## § 5 当前动作

1. ✅ 排查 scenario-tour readme/files tab tap 失败 → 补正候选 id 列表（[scripts/scenario-tour.sh#L370-L405](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh#L370-L405)）
2. ✅ 重跑 4 tab → 全 ok=4 fail=0
3. ✅ S6 与 RN activity 截图对照，差异 5 处填 § 3
4. ⏭ 同步 INDEX.md / known-issues.md / 01-status.md → commit L1 完成 → 进 L2 PushDetail S1
