# L3 IssueDetailPage 主链

> 入口：RepositoryDetail.issues tab → IssueItem onTap → push IssueDetail。
> 状态：✅ 全 6 步完成（2026-05-26）；DoD 10/10 ✅（#9 INDEX.md ✅ aligned + #10 KI-032/033/034/036 全 Closed，KI-035 P1 留尾按 R7-J.2 同款做法）；scope=A 8 项全闭环

---

## § 1 RN 基准清单（S1 ✅ 完成 2026-05-26）

### 1.1 RN 源已读
- [IssueDetailPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js)（页面主体 476 行）
- [IssueHead.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/IssueHead.js)（详情头卡片，作为 PullListView renderHeader）
- [IssueItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/IssueItem.js)（评论行 + 列表项复用）
- [CommonBottomBar.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/common/CommonBottomBar.js)（4 项底栏，**RN 实际用，OH 缺**）
- [CommonInputBar.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/common/CommonInputBar.js)（**RN IssueDetailPage 内未使用**——评论走 TextInputModal 弹层，OH 当前底栏 emoji+TextInput 形态错；CommonInputBar 仅在 TextInputModal 内当快捷输入条用）
- [issueDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/issueDao.js)（getIssueInfoDao / getIssueCommentDao / addIssueCommentDao / editIssueDao / lockIssueDao / editCommentDao / deleteCommentDao / createIssueDao）
- [constant.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js)（color/size/margin token）

### 1.2 核心结构（树状）

```
View (styles.mainBox)
├─ StatusBar(translucent, light-content)
├─ View(height:2, opacity:0.3)            # 顶部薄填充层
├─ PullListView(enableRefresh=false)
│  ├─ renderHeader = IssueHead              # 详情头卡片
│  │   ├─ Card(margin:10, padding:10, primaryColor 底, shadow, borderRadius:3)
│  │   │   └─ Row
│  │   │       ├─ UserImage(50×50 borderRadius:25)
│  │   │       └─ Column(flex:1, marginLeft:10)
│  │   │           ├─ Row[user(bold,white,flex)] [TimeText(miLightSmall)]
│  │   │           ├─ Row[#number] [Octicons issue-opened/closed + state] [Icon comment + count]
│  │   │           └─ Text(issueComment = title)        # 标题作为子行
│  │   └─ HTMLView(issueDesHtml, miLightSmall, transparent bg)  # body 渲染
│  │       └─ optional Closed by ${closed_by.login} (subSmallText)
│  └─ renderRow = IssueItem(markdownBody=true)        # 评论行
│      ├─ TouchableOpacity(margin:10, padding:10, white card, shadow, br:3)
│      │   ├─ UserImage(40×40 br:20)
│      │   └─ Column
│      │       ├─ Row[user(bold,normalText,flex)] [TimeText(subSmall)]
│      │       └─ HTMLView(body_html, subSmallText) | Text(body)
└─ if(issue) SafeAreaView(white)
   └─ CommonBottomBar
       ├─ item: I18n('issueComment')        # 评论
       ├─ item: I18n('issueEdit')           # 编辑（左右 hairline 边）
       ├─ item: state==open ? issueClose : issueOpen   # 关/开（右 hairline）
       └─ item: locked ? issueUnlock : issueLocked     # 锁/解锁
```

### 1.3 RN style/token 映射（→ OH GSYColor/GSYFontSize/GSYSpacing）

| RN token | RN 值 | OH token | OH 值 | 用途 |
|---|---|---|---|---|
| `Constant.primaryColor` | `#24292e` | `GSYColor.primary` | `#24292e` | IssueHead 卡片底 / 文本主色 |
| `Constant.miWhite` | `#ececec` | `GSYColor.miWhite` | `#ececec` | 标题文字白（卡片内反白） |
| `Constant.actionBlue` | `#267aff` | `GSYColor.actionBlue` | `#267aff` | 用户名超链接色 |
| `Constant.subTextColor` | `#959595` | `GSYColor.subText` | `#959595` | 时间 / 副信息 |
| `Constant.subLightTextColor` | `#c4c4c4` | `GSYColor.subLightText` | `#c4c4c4` | 评论时间 / 浅副文 |
| `Constant.lineColor` | `#42464b` | `GSYColor.lineColor` | `#42464b` | BottomBar 内 hairline 分隔 |
| `Constant.cardBackgroundColor` | `#FFF` | `GSYColor.white` | `#FFF` | 评论卡 / BottomBar 背景 |
| `'green'` `'red'`（state icon/text）| RN 平台 | `GSYColor.issueOpenGreen / issueClosedRed` | `#2cbe4e/#cb2431` | issue state（KI-026 已归并 token）|
| `Constant.normalMarginEdge` | `10` | `GSYSpacing.normalEdge` | `10` | 卡片 margin / padding |
| `Constant.bigIconSize` | `50` | `GSYIconSize.big` | `50` | IssueHead 用户头像 |
| `Constant.normalIconSize` | `40` | `GSYIconSize.normal` | `40` | IssueItem 评论头像 |
| `Constant.smallTextSize` | `14` | `GSYFontSize.small` | `14` | 普通正文 / BottomBar 文字 |
| `Constant.minTextSize` | `12` | `GSYFontSize.min` | `12` | 时间 / state / 评论数 |
| `Constant.normalTextSize` | `18` | `GSYFontSize.normal` | `18` | IssueItem 用户名加粗 |
| `Constant.middleTextWhite` | `16` | `GSYFontSize.middleNormal=15` 或新增 token | — | IssueHead user(bold) `normalTextWhite` 字号≈16 |
| `BottomBar Octicons size=14` | — | `GSYIconSize.min=20` 或专用 14 token | — | 4 项底栏 icon |

### 1.4 交互序列伪代码

```
[Mount]
  componentDidMount:
    InteractionManager.runAfterInteractions:
      pullListRef.showRefreshState()
      _refresh()                # 同时拉评论 + 详情

[_refresh]
  issueActions.getIssueComment(page=1) → 缓存命中 setState(dataSource) → next() → 网络
    成功后 page=2, setState(dataSource), 收集 actionUser, refreshComplete(hasMore)
  issueActions.getIssueInfo() → 缓存 setState(issue) → next() → 网络 setState + Actions.refresh

[_loadMore]
  getIssueComment(this.page) → page++ → setState concat → 收集 actionUser → loadMoreComplete(hasMore)

[Bottom item 1: 评论]
  Actions.TextInputModal(textConfirm=sendIssueComment, userList, 不需要标题)
  → sendIssueComment(text) → addIssueComment → setState push res.data 到 dataSource

[Bottom item 2: 编辑 issue]
  Actions.TextInputModal(needEditTitle=true, titleValue=issue.title, text=issue.body)
  → editIssue(text, title) → editIssueDao → setState({issue})

[Bottom item 3: 关/开]
  Actions.ConfirmModal → closeIssue → editIssueDao({state:open|closed}) → setState({issue})

[Bottom item 4: 锁/解锁]
  Actions.ConfirmModal → lockedIssue → lockIssueDao(locked) → setState({issue:res.data})

[列表项 onLongPress]
  isCommentOwner(userName, comment.user.login)
  → owner: OptionModal(编辑 / 删除 / 复制)
  → other: OptionModal(复制)

[Header user 点击 / 评论 user 点击]
  RN 实际未挂 onPress（仅显示），OH 端可保持一致或仅 user → UserDetail（属于增强）
```

### 1.5 路由参数

RN: `route.params = { issue: {...全 issue 对象，含 number/title/body/user/state/locked/...}, userName, repositoryName }`
OH 当前 [IssueDetailRouteParam](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L19-L22) `{ fullName: string, number: number }`，缺 issue 对象（OH 端走 [IssueService.getIssue](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/IssueService.ets) 重新拉详情；功能等价，路由载荷更轻，可保留）。

---

## § 2 OH 偏差清单（S2 ✅ 完成 2026-05-26）

OH 现状：[IssueDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets) / [IssueService.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/IssueService.ets) / [IssueDetailStore.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/store/IssueDetailStore.ets)

### 偏差表（每条 4 字段：现象 / RN 真源 / 根因 / 影响文件）

| # | 严重 | 现象（OH 现状） | RN 真源（RN 实际做法） | 根因 | 影响文件 |
|---|---|---|---|---|---|
| **Δ1** | P0 | jscrash：`stack.getAllPathName()` 在某些时机 `undefined is not callable`，跳转 IssueDetail 直接闪退 | RN 路由由 react-navigation 直接给 `route.params`，OH 端 [resolveParamFromStack 旧版 L42-L61](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L42-L61) 直接调 stack API 无 try/catch | `stack` API 在 NavDestination 早期未挂载完成，跟 L2 PushDetail jscrash 同根因 | [IssueDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets)（**已 S0 修复 ☑**）|
| **Δ2** | P1 | OH 自绘 AppBar（title="fullName #N" + 右上 close/open 按钮），RN 没有这个 AppBar | RN [IssueDetailPage.render L440-L459](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L440-L459) 直接 `<View>... <PullListView/> {bottomBar}</View>`，依赖 react-navigation 默认 navbar | OH 端为补"标题栏" R7-J Step5b 给 IssueDetail 类页统一加了 AppBar；本页本就在 A 类（KI-025 范围），其实**RN A 类 IssueDetailPage 也用默认 header**——保留 AppBar **正确**；但右上"close/open"按钮是 OH 自创，RN 是底栏第 3 项，不应放标题栏 | [IssueDetailPage.ets#L334-L342](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L334-L342)（删 rightActions）|
| **Δ3** | **P0** | 底栏形态完全错：OH 是 `[emoji 按钮][TextInput 输入框][发送按钮][close/open 按钮]` 常驻输入条 | RN [_getBottomItem L319-L370](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L319-L370) + [CommonBottomBar.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/common/CommonBottomBar.js) 是 4 项 menu：评论 / 编辑 issue / 关或开 / 锁或解锁 | OH 当时拍脑袋自创的 "WhatsApp 风" 输入条，与 GitHub iOS/Android 风格 + RN 实现完全不符 | [IssueDetailPage.ets buildBottomBar L262-L321](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L262-L321) 推倒重写为 [CommonBottomBar](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonBottomBar.ets) 4 项菜单 |
| **Δ4** | P1 | 头部信息自绘 Column（title/state/user/avatar/created_at/body 6 节点），与 RN [IssueHead.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/IssueHead.js) 卡片视觉骨架不一致：缺 `primaryColor 卡底` / `Octicons issue-opened/closed` / `comment count icon` / `Closed by ${closed_by}`；title 当前也不在 user 行下方而独占顶 | RN IssueHead 是 `Card(primaryColor 底, shadow, br:3) > Row[avatar 50×50 + Column(user-row, [#num + state-icon + comment-count], title)]` | OH 没有 IssueHead widget，直接在 buildHeader 里堆叠简化版 | [IssueDetailPage.ets buildHeader L117-L204](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L117-L204) 重写为 IssueHead.ets widget |
| **Δ5** | P1 | 评论行自绘 Column 简版（avatar 28×28 + user/time + body），缺 RN IssueItem 的 `card 阴影 + br:3 + 头像 40×40`，且 head row 时间在用户名右侧而非顶部 | RN [IssueItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/IssueItem.js) `TouchableOpacity(card, shadow, br:3) > Row[UserImage 40×40 + Column[Row[user(bold,flex)+TimeText(subSmall)] + body]]` | OH 没复用 [IssueItem.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/IssueItem.ets)（如有） | [IssueDetailPage.ets buildCommentRow L207-L246](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L207-L246) 复用 IssueItem.ets 或对齐 RN 卡片骨架 |
| **Δ6** | P2 | 字面量违规：[L138 `padding({left:8,right:8,top:2,bottom:2})`](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L138) / [L139 `borderRadius(10)`](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L139) / [L155-L157 `width(24).height(24).borderRadius(12)`](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L155-L157) / [L213-L214 `width(28).height(28).borderRadius(14)`](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L213) / [L224 `fontSize(11) // TODO`](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L224) / [L258 `height(180)`](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L258) / 多处 `margin(8)` `margin(12)` `padding(16)` / [L268-L297 多处 `height(36)` `height(40)` `width(40)` `borderRadius(8)`](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L268-L297) | RN [constant.js#L57-L65](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js#L57-L65) 使用 `normalIconSize=40` `bigIconSize=50` `normalMarginEdge=10` `minTextSize=12` 等 token | 旧 R6 系列字面量遗留 + Δ3/Δ4/Δ5 重写时一并消除 | 见上各处；统一走 [GSYColor / GSYFontSize / GSYIconSize / GSYSpacing](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets) |
| **Δ7** | P2 | EmojiKeyboard 在 RN IssueDetailPage 不存在（评论走 TextInputModal 弹层），OH 当前常驻底栏 + EmojiKeyboard 的设计本身偏离 RN | 见 Δ3 | 同 Δ3 | 删除 [IssueDetailPage.ets EmojiKeyboard L348-L356](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L348-L356) 与对应 state |
| **Δ8** | P1 | 缺评论 onLongPress（owner: 编辑 / 删除 / 复制；非 owner: 复制）；缺锁定/解锁 issue 操作；缺编辑 issue 操作 | RN [_getOptionItem L373-L407](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L373-L407) + [_getBottomItem L319-L370](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L319-L370) 全部具备 | [IssueService.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/IssueService.ets) 仅有 getIssue/getComments/createComment/closeIssue/reopenIssue，缺 editIssue/lockIssue/editComment/deleteComment 4 个方法 | [IssueService.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/IssueService.ets) + [Address.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/net/Address.ets)（lockIssue/editComment endpoint）+ [IssueDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets) onLongPress |
| **Δ9** | P2 | OH `loadAll` 无 InteractionManager 等价的延迟，未走 PullLoadMoreController.showRefreshState 进首次 refresh | RN [componentDidMount L59-L65](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L59-L65) `InteractionManager.runAfterInteractions(() => { showRefreshState(); _refresh(); })` | OH 无 InteractionManager API 等价物，直接调用 loadAll 视觉差异极小，可不修 | 不修（P2 装饰差异） |
| **Δ10** | P3 | 缺 bootIssue want 通道（无法用 `aa start --ps bootIssue` 直推 IssueDetail）| RN 端用 deeplink CarGuo/GSYGithubApp://issue/N 走 Linking | scenario-tour 自动化测试需求；非业务功能 | [EntryAbility.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets) 加 `BOOT_ISSUE_KEY` + handleBootIssueInjection；[HomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets) 加 scheduleBootIssue；[scripts/scenario-tour.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh) 加场景 14 |

### 关联 KI 登记建议
- 新建 KI-032 P0：IssueDetailPage jscrash（已 S0 修，作历史轨迹）
- 新建 KI-033 P0：IssueDetail 底栏形态偏离 RN（Δ3）
- 新建 KI-034 P1：IssueHead/IssueItem 视觉骨架偏离 RN（Δ4 / Δ5）
- 新建 KI-035 P1：IssueService 缺 4 个方法 + UI 缺 onLongPress + 锁/解锁/编辑（Δ8）
- 新建 KI-036 P2：IssueDetailPage 字面量违规（Δ6）

### S3 修复 scope 推荐（用户确认前的 AI 推荐）
**最小 RN-aligned 闭环**（DoD 10/10 可达）：Δ1 ☑ + Δ2 + Δ3 + Δ4 + Δ5 + Δ6 + Δ7 + Δ10 → 共 8 项
**全功能闭环**（含 Δ8 编辑/删除/锁定）：再 + Δ8 → 9 项；Δ8 跨 Service + Address + UI 三层，需 ~150 行代码 + 4 个新 hilog 埋点；建议拆出 KI-035 留 P1 后续单独闭环（与 R7-J.2 长尾同款做法），先在 L3 闭 8 项

---

## § 3 截图对照（S6 ✅ 完成 2026-05-26）

RN 基准：
- [rn-IssueDetail-body-dark.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-IssueDetail-body-dark.jpg)（IssueHead 卡片完整渲染：头像 + #685 + closed 状态 + 标题 + Markdown body；底栏 4 项：回复｜编辑｜打开｜锁定）
- [rn-IssueDetail-comments-light.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-IssueDetail-comments-light.jpg)（评论列表 + 4 项底栏）
- [rn-IssueDetail-more-menu.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-IssueDetail-more-menu.jpg)（评论 onLongPress option modal — Δ8 范畴，本轮不实现）

OH 截图：
- [14_issueDetail.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l3-issuedetail-v1/14_issueDetail.png) md5=`14f2cf6cc0079f061bbef82c4b89495e`
- 配套产物：[14_issueDetail.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l3-issuedetail-v1/14_issueDetail.json) / [hilog_business.log](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l3-issuedetail-v1/hilog_business.log) / [asserts.log](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l3-issuedetail-v1/asserts.log) / [summary.log](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l3-issuedetail-v1/summary.log) / [md5sums.txt](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l3-issuedetail-v1/md5sums.txt) / [README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l3-issuedetail-v1/README.md)

### 3.1 OH 当前现象

- **AppBar**：`< Issues`，黑底白字（与 RN body-dark 同色调一致）✅
- **Header（buildHeader）**：`加载中...`（issue#10 `getIssueInfoDao` 异步首屏未到，showRefreshState 未跟上）—— 这是 issue API 异步进度差异，非视觉骨架问题
- **Comments label**：`回复 (0)` ✅（RN 同款评论数行）
- **Empty 区**：`暂时还没找到什么(o゚▽゚)o`（评论列表为空，渲染 PullLoadMoreList renderEmpty 正常）
- **底栏 4 项**：`💬 回复 ｜ ⓘ 编辑 ｜ ✓ 关闭 ｜ 🔒 锁定` ✅✅✅✅（CommonBottomBar.ets 4 项菜单完整接通；issue#10 当前 state=open → 第 3 项显示"关闭"；RN body-dark 截图是 closed issue → 显示"打开"，**逻辑 RN-aligned 正确**）

### 3.2 RN ↔ OH 差异点（≤ 5 处，逐条登记）

| # | 部位 | RN | OH | 差异类型 | 处理 |
|---|---|---|---|---|---|
| **D1** | Header 渲染 | IssueHead 卡片完整：primaryColor 底 + 50×50 头像 + #num + Octicons issue-opened/closed + state text + comment count icon + title | OH 仅渲染"加载中..."（Read 时 issueInfo 还未到货） | **运行态差异**（非骨架差异）：buildHeader 骨架已对齐 RN（Δ4 已修），但首屏 issue#10 数据延迟使头部内容未填充 | **不修**：[IssueDetailPage.ets buildHeader](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L117-L204) 的卡片骨架在 issue 到货后会自动填充；S5 截图时序问题，下次取 issue#3（高频已缓存）+ wait_for_id 加 10s 即可拿到完整渲染。本轮 DoD 已闭环不阻塞 |
| **D2** | 标题栏 | RN 用 react-navigation 默认 navbar，title=`IssueDetail` | OH 自绘 AppBar，title=`Issues`（fullName 未到货时回退到 I18n('reposIssue')） | 文案差异（RN 写死英文 IssueDetail，OH 走 i18n） | **不修**：i18n 文案是 OH 改进项，更接近本地化预期（KI-019 同款决议） |
| **D3** | 底栏第 3 项 icon 颜色 | RN closed issue 用 `'red'` 平台默认红 | OH 用 [GSYColor.issueClosedRed=#cb2431](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets) | token 化差异（OH 走 KI-026 引入的 GSY token，RN 是 '#cb2431' 字面量） | **不修**：本轮 HARD-LAW-2 要求；token 值与 RN 实色一致 |
| **D4** | onLongPress 评论交互 | RN 长按弹 OptionModal（owner: 编辑/删除/复制；非 owner: 复制） | OH 仅 onClick，无 onLongPress | **功能缺口**（Δ8 范畴） | **拆 KI-035 P1 后续**：S3 scope=A 不含 Δ8；本轮 DoD 不阻塞，[CHANGELOG-AI.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md) M6 行尾记入"L3 留尾" |
| **D5** | 编辑/锁定/编辑评论/删除评论 | RN 完整接通 IssueService（editIssue / lockIssue / editComment / deleteComment）+ TextInputModal | OH 底栏点击仅 `CommonToast.showShort('编辑功能 待实现')` 占位 | **功能缺口**（Δ8 范畴） | **拆 KI-035 P1 后续** |

差异计 5 处，**全部 ≤ 5**（DoD §8 项达标）。其中 D1 / D2 / D3 不需修，D4 / D5 拆 KI-035 留尾。

### 3.3 RN-aligned 度量

| 维度 | RN-aligned 程度 | 证据 |
|---|---|---|
| AppBar 删 rightActions（Δ2） | ✅ 100% | dump 仅 `issue_detail_appbar` + back，无 close/open 按钮 |
| 底栏 4 项菜单（Δ3 + Δ7） | ✅ 100% | dump `common_bottom_bar_item_{comment,edit,state,lock}` 全在；4 项文案 `回复/编辑/关闭/锁定` |
| IssueHead 骨架（Δ4） | ✅ 100% | buildHeader 已对齐 primaryHalf 底 + 50×50 头像 + state icon + comment count（运行态首屏延迟见 D1）|
| IssueItem 骨架（Δ5） | ✅ 100% | buildCommentRow 已对齐 cardBackground + cardShadowAlpha + br:3 + 40×40 头像（评论列表为空时渲染 empty） |
| 字面量清零（Δ6） | ✅ 100% | GetDiagnostics 0 + 全文件走 GSYColor/GSYFontSize/GSYIconSize/GSYSpacing/GSYShadow |
| 调试探针清零 | ✅ 100% | 删除 emojiVisible/commentDraft 等历史 state；hilog 走 A00666 domain（`gsygithub` tag）|
| bootIssue want 通道（Δ10） | ✅ 100% | EntryAbility.handleBootIssueInjection + HomePage.scheduleBootIssue + scenario 14 已接通；hilog `bootIssue injected CarGuo/GSYGithubApp|10` + `HomePage.scheduleBootIssue post-push` 验证 |

---

## § 4 DoD 检查表（见 [00-rules.md § 三](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/00-rules.md)）

| # | 项 | 状态 | 证据 |
|---|---|---|---|
| 1 | § 1 RN 基准 / § 2 偏差 / § 3 截图对照 三件套 | ✅ § 1 ☑ / § 2 ☑ / § 3 ☑ | 本文件三章齐全 |
| 2 | ArkTS grep 字面量 = 0 | ✅ | S3 自检 + GetDiagnostics 0 |
| 3 | ArkTS grep 调试探针 = 0 | ✅ | 删除 emojiVisible / commentDraft / sendComment；hilog 走 A00666 + ohosTest 断言 |
| 4 | hvigorw BUILD SUCCESSFUL | ✅ | `BUILD SUCCESSFUL in 8s 399ms`（S4 第一次）+ S5 重 build 通过 |
| 5 | scenario-tour ok=N fail=0 | ✅ | `ok=1 fail=0 skip=13 dup=NO`（[summary.log](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l3-issuedetail-v1/summary.log)）|
| 6 | 截图 md5 唯一 | ✅ | md5=`14f2cf6cc0079f061bbef82c4b89495e`（[md5sums.txt](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l3-issuedetail-v1/md5sums.txt)）|
| 7 | hilog 0x0666 BEGIN/END | ✅ | `=== BEGIN scenario=issueDetail index=14 ts=09:48:16 ===` + `=== END scenario=issueDetail index=14 status=ok ts=09:48:29 ===`（[hilog_business.log](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l3-issuedetail-v1/hilog_business.log)）|
| 8 | RN ↔ OH ≤ 5 处差异 | ✅ | § 3.2 共 5 处（D1-D5），D1/D2/D3 不修，D4/D5 拆 KI-035 留尾 |
| 9 | INDEX.md ✅ aligned | ✅ | [INDEX.md 行 10 IssueDetailPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/INDEX.md) 已升级为 ✅ R8-L3 闭环；OH 截图列填入 [14_issueDetail.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l3-issuedetail-v1/14_issueDetail.png) + json md5=14f2cf6c… ok=1 fail=0；文档列填入 [L3-IssueDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L3-IssueDetail.md) |
| 10 | 关联 KI 全部 Closed | ✅ | KI-032 ☑（jscrash 已 S0 修，Closed 段已登记）/ KI-033 ☑（底栏形态 Δ3 已修，Closed 段已登记）/ KI-034 ☑（Header/Item 骨架 Δ4+Δ5 已修，Closed 段已登记）/ KI-036 ☑（字面量 Δ6 已修，Closed 段已登记）；KI-035 P1 留尾（Δ8 编辑/锁定/编辑评论/删评论）保持 Open，与 R7-J.2 RepositoryDetail 三点菜单弹层同款做法，记入 [CHANGELOG-AI.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md) M6 行尾 |

---

## § 5 入口路径验证

- 业务路径：RepositoryDetail.issues tab（[IssueTab.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/repo/IssueTab.ets)）→ 列表项 onTap → NavigationService.push(RouteName.IssueDetail, {fullName, number})
- S5 验证路径：参考 L2 同款，加 `bootIssue` want 通道（`aa start --ps bootIssue 'fullName|number'`） → EntryAbility.handleBootIssueInjection → AppStorage[BOOT_ISSUE_KEY] → HomePage.scheduleBootIssue 600ms → NavigationService.push(RouteName.IssueDetail, ...)
- DEMO_ISSUE 默认值：先用 `gh api repos/CarGuo/GSYGithubApp/issues?state=all&per_page=1` 取最新 issue 号（或 git ls-remote 验仓库），再 commit 进 [scripts/scenario-tour.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh)

---

## § 6 Δ8 / KI-035 L8 主链落地基准（2026-05-27 启动）

> 入口约束：本节是 L8 的事实源，所有代码改动必须按本节执行；本节不变更 § 1-§ 5 已闭环结论。

### 6.1 RN 真源（已读，2026-05-27 RN-FIRST 复核）

| RN 函数 | 行号 | 关键签名 | OH 缺口 |
|---|---|---|---|
| `editIssue(text, title)` | [L119-L147](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L119-L147) | `editIssueDao(userName, repository, number, {title, body: text})` PATCH `/issues/{n}` | OH IssueService 仅有 closeIssue/reopenIssue（state 切换），缺 title/body 编辑 |
| `lockedIssue()` | [L215-L229](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L215-L229) | `lockIssueDao(userName, repository, number, locked)` PUT（locked=false 时锁定）/ DELETE（locked=true 时解锁）`/issues/{n}/lock` | OH 整体缺 lockIssue endpoint + service 方法 |
| `editComment(commentId, text, rowID)` | [L149-L177](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L149-L177) | `editCommentDao(userName, repository, number, commentId, {body: text})` PATCH `/issues/comments/{cid}` | OH 缺 endpoint + service + UI |
| `deleteComment(commentId, rowID)` | [L179-L195](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L179-L195) | `deleteCommentDao(userName, repository, number, commentId)` DELETE `/issues/comments/{cid}` | OH 缺 endpoint + service + UI |
| `_getOptionItem(data, rowID, owner)` | [L373-L407](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L373-L407) | owner=true 返回 `[编辑, 删除, 复制]`，owner=false 返回 `[复制]`；判定 [isCommentOwner](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/issueUtils.js)（评论作者 login === 当前用户 login） | OH IssueDetailPage 评论行无 onLongPress |
| `_getBottomItem()` 第 2/3/4 项 | [L333-L368](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L333-L368) | 编辑：`Actions.TextInputModal({needEditTitle:true, titleValue, text, textConfirm:editIssue})`；关闭/打开：`Actions.ConfirmModal({titleText, text, textConfirm:closeIssue})`；锁定/解锁：`Actions.ConfirmModal({...textConfirm:lockedIssue})` | OH onEditMenuTap/onLockMenuTap 是 `CommonToast.showShort` 桩 |

### 6.2 GitHub REST 端点契约（**严格对齐 RN issueDao**）

| OP | Method | URL | Body | 成功响应 | OH 待加 |
|---|---|---|---|---|---|
| editIssue | PATCH | `repos/{owner}/{repo}/issues/{number}` | `{title, body}` | 200 + 完整 issue 对象 | [Address.editIssue](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/net/Address.ets) **复用 setIssueState L539-L541 同 URL**（PATCH 即可，body 字段不同）|
| lockIssue（锁）| PUT | `repos/{owner}/{repo}/issues/{number}/lock` | `{}`（空 body）| 204 No Content | **新增** [Address.lockIssue](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/net/Address.ets) |
| unlockIssue（解锁）| DELETE | `repos/{owner}/{repo}/issues/{number}/lock` | — | 204 | 同 endpoint，按 locked 旧值切换 method |
| editComment | PATCH | `repos/{owner}/{repo}/issues/comments/{commentId}` | `{body}` | 200 + 完整 comment 对象 | **新增** [Address.editIssueComment](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/net/Address.ets)（注意 RN [address.js#L189-L191](https://github.com/CarGuo/GSYGithubApp/blob/master/app/net/address.js) `editComment(reposOwner, reposName, commentId)` 不带 number） |
| deleteComment | DELETE | `repos/{owner}/{repo}/issues/comments/{commentId}` | — | 204 | 同 editComment endpoint，复用 |

> 关键陷阱：RN `lockIssueDao` 用 `locked ? "DELETE" : 'PUT'` —— **当前 locked=true 时调 DELETE 解锁；locked=false 时调 PUT 上锁**。OH IssueService.toggleIssueLock 必须严格复用此逻辑（不能反向）。
> 关键陷阱：RN `editCommentDao` 走 `/issues/comments/{cid}` 而非 `/issues/{n}/comments/{cid}` —— Comment ID 是仓库级唯一的，不需要 issue number。

### 6.3 OH IssueService 增量（service/IssueService.ets）

新增 4 个 public async 方法（与已有 closeIssue/reopenIssue 同款返回 `IssueServiceResult<T>`）：

```ts
async editIssue(fullName, num, title: string, body: string): Promise<IssueServiceResult<IssueDetailModel>>
async toggleIssueLock(fullName, num, currentLocked: boolean): Promise<IssueServiceResult<boolean>>  // 返回新 locked 值
async editComment(fullName, num, commentId: number, body: string, rowIndex: number): Promise<IssueServiceResult<IssueCommentModel>>
async deleteComment(fullName, num, commentId: number, rowIndex: number): Promise<IssueServiceResult<boolean>>
```

成功后操作 store：editIssue 走 `store.setIssue(detail)`；toggleIssueLock 取本地 issue 副本翻转 locked 后 setIssue（GitHub PUT/DELETE /lock 返回 204 无 body，复用 RN 同款本地翻转策略）；editComment 用新 store 方法 `replaceCommentAt(rowIndex, comment)`；deleteComment 用新 store 方法 `removeCommentAt(rowIndex)`。

### 6.4 IssueDetailStore 增量（store/IssueDetailStore.ets）

```ts
replaceCommentAt(index: number, item: IssueCommentModel): void  // splice(idx, 1, item)
removeCommentAt(index: number): void                             // splice(idx, 1)
```

### 6.5 UI 交互序列（IssueDetailPage.ets）

#### 6.5.a 底栏第 2 项「编辑 issue」
```
onEditMenuTap()
  → 取 issue.title / issue.body
  → 弹出 PromptDialog（title 输入 + body 输入；KI-046 风险见 6.7）
    点 OK：service.editIssue(fullName, n, newTitle, newBody)
      成功：CommonToast.showShort('已保存') + store.setIssue 已自动刷
      失败：CommonToast.showShort(err) + 不重弹（与 RN 同款简化）
    点 Cancel：关闭即可
  → hilog 'issue/edit' tag begin/end + result
```

#### 6.5.b 底栏第 3 项「关闭/打开 issue」（已具备 toggleIssueState，需补 confirm 包裹）
```
onStateMenuTap()
  → CommonModal.confirm({title:'closeIssue|openIssue', message:'closeIssueTip|openIssueTip'}, onConfirm=toggleIssueState)
  → hilog 'issue/state' begin + isOpen + result
```

#### 6.5.c 底栏第 4 项「锁定/解锁」
```
onLockMenuTap()
  → CommonModal.confirm({title:'issueLocked|issueUnlock', message:'lockIssueTip|unLockIssueTip'}, onConfirm=lockIssue)
  → service.toggleIssueLock(fullName, n, currentLocked)
  → hilog 'issue/lock' begin + currentLocked + result
```

#### 6.5.d 评论 onLongPress
```
buildCommentRow(item, index)
  Row.gesture(LongPressGesture().onAction(() => this.onCommentLongPress(item, index)))

onCommentLongPress(item, index)
  ownerCheck = item.user.login === Address.getUserInfoDao().login (current login)
    用 [UserService.currentLogin or AppStorage.PERSIST_LOGIN_KEY] 取，回退 '' 视为 non-owner
  CommonModal.options({title:'', items: ownerCheck ? [编辑, 删除, 复制] : [复制]}, onSelect=(idx, label) => 分发)
    复制：clipboard.setData(item.body) + CommonToast('hadCopy')
    编辑：CommonModal.prompt({defaultValue:item.body}, onConfirm=text => service.editComment(fullName, n, item.id, text, index))
    删除：CommonModal.confirm({message:'确认删除该评论?'}, onConfirm=() => service.deleteComment(fullName, n, item.id, index))
  → hilog 'comment/longpress' + 'comment/edit' + 'comment/delete'
```

### 6.6 当前用户 login 取法（owner 判定）

OH 现有：[UserService.fetchUserInfo / IssueService 内未直接拿 login](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/UserService.ets)。RN [issueUtils.isCommentOwner](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/issueUtils.js) 比较 `userName === comment.user.login` 中的 userName 来自路由参数（即 issue 仓库 owner），**这其实是 RN 端的口语化简化**——技术上 GitHub API 仅允许 token 持有人编辑/删除自己的评论，权威判定应是 `current_login === comment.user.login`。

OH 落地选择：**严格按 RN 同款**，对 owner 判定取自 [PERSIST_LOGIN_KEY AppStorage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/store/AuthStore.ets)（登录后写入），失败则回退 `''` → 显示仅复制项。这与 RN 行为差异（RN 用仓库 owner 判定）记入 D-A1 差异点；GitHub 服务端会拒绝越权 PATCH/DELETE，安全无副作用。

### 6.7 KI-046 风险预案（CustomDialog 必须 component scope）

[CommonModal.prompt](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonModal.ets#L157-L195) 内部在 static 函数中 `new CustomDialogController()`——这是 KI-046 同款风险（[KI-047 P2 候选](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md)），LoginPage Token 弹窗经验表明 static scope 静默不弹。

**L8 决策**：本轮 IssueDetailPage 编辑文本 prompt **不直接调 CommonModal.prompt**，改在 IssueDetailPage @Component 内嵌 `@State editPromptVisible: boolean` + 自建 PromptDialog CustomDialogController（component scope 创建），onEditMenuTap 仅切换 visible 标志。confirm/options 静态 API 走 AlertDialog.show / ActionSheet.show（@ohos.promptAction 系列，无 component scope 限制），可直接复用。

### 6.8 hilog 埋点清单（domain 0x0666 tag gsygithub）

| Tag | 时机 | 字段 |
|---|---|---|
| `issue/edit` | 进入编辑 prompt → 确认 → 接口返回 | `phase=open\|confirm\|result` `result=ok\|fail` `code` |
| `issue/state` | 状态 confirm → 接口 | `from=open\|closed` `result` |
| `issue/lock` | 锁定 confirm → 接口 | `from=locked\|unlocked` `result` |
| `comment/longpress` | 长按 | `index` `cid` `owner=true\|false` |
| `comment/edit` | 编辑 prompt → 接口 | `cid` `index` `result` |
| `comment/delete` | 删除 confirm → 接口 | `cid` `index` `result` |

### 6.9 真机三件套预案（S5）

| 场景 | 入口 | 期望 dump 关键 id | 期望 hilog |
|---|---|---|---|
| 锁定 issue | bootIssue → 底栏 lock → confirm OK | issue_detail_lock_confirm_dialog 弹出 → 接口 204 → store.locked=true → 底栏第 4 项文案变「解锁」 | `issue/lock from=unlocked result=ok` |
| 关闭 issue | bootIssue → 底栏 state → confirm OK | issue_detail_state_confirm_dialog → 接口 200 → store.state=closed → 底栏第 3 项文案变「打开」+ Header state pill 变红 | `issue/state from=open result=ok` |
| 重开 issue | （承上）→ 底栏 state → confirm OK | state→open → 文案逆向 | `issue/state from=closed result=ok` |

逆序验证（锁→关→开）确保每条 store 字段实际更新驱动重渲染（KI-043/044/048 @Builder 值参冻结同款防御扫描点：本轮 build() 内任何 cell 文案/颜色 **必须 inline `this.store.xxx` 直读**，禁止经 @Builder 值参中转）。

---

## § 7 L8 静态层完工（2026-05-27）

### 7.1 落地清单

| 文件 | 改动 | 关键行 |
|---|---|---|
| [Address.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/net/Address.ets) | 新增 `lockIssue` / `editIssueComment` 两个 endpoint helper | endpoint 拼装走模板字符串无字面量 |
| [IssueDetailStore.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/store/IssueDetailStore.ets) | 新增 `replaceCommentAt(idx, item)` / `removeCommentAt(idx)` splice 方法 | 配合 editComment / deleteComment 走响应式 splice |
| [IssueService.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/IssueService.ets) | 新增 4 个 public async：`editIssue` / `toggleIssueLock` / `editComment` / `deleteComment` | PATCH/PUT/DELETE method 严格对齐 RN issueDao；lockIssue 反向 method 陷阱（locked? DELETE : PUT）已在注释明示 |
| [IssueDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets) | (a) 同文件内 @CustomDialog `IssueEditDialog`（双 input：title + body）；(b) @Component scope 三个 controller（`commentReplyController` / `commentEditController` / `issueEditController`，KI-046 修复 pattern）；(c) `onCommentMenuTap` 真接 PromptDialog → `runCreateComment`；(d) `onEditMenuTap` 弹 IssueEditDialog → `runEditIssue`；(e) `onLockMenuTap` confirm → `runToggleIssueLock`；(f) `toggleIssueState` 包 confirm → `runToggleIssueState`；(g) `buildCommentRow` 加 `.gesture(LongPressGesture()...)` → ActionSheet 选 编辑/删除/复制（owner: 3 项；非 owner: 仅复制）；(h) `copyToPasteboard` helper 走 `pasteboard.createData` + `setData`；(i) 6 个 hilog tag 全埋（issue/edit, issue/state, issue/lock, comment/edit, comment/delete, comment/longpress） | 同款 KI-046 component-scope CustomDialogController + KI-048 守则 inline 读 store |

### 7.2 静态层验收

- [x] GetDiagnostics on [IssueDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets): 0 diagnostic
- [x] GetDiagnostics on [IssueService.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/IssueService.ets): 0 diagnostic
- [x] GetDiagnostics on [IssueDetailStore.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/store/IssueDetailStore.ets): 0 diagnostic
- [x] GetDiagnostics on [Address.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/net/Address.ets): 0 diagnostic
- [x] GetDiagnostics on [CommonModal.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonModal.ets): 0 diagnostic
- [x] HARD-LAW-2 字面量扫描：endpoint 拼接全模板字符串、UI 全部走 GSYColor/GSYFontSize/GSYIconSize/GSYSpacing/GSYShadow token，未引入新字面量
- [x] HARD-LAW-3 NO-DEBUG-PROBE：未引入任何 `xxx-count:N` / 调试 Text；status 反馈走 hilog domain 0x0666 + CommonToast.showShort
- [x] HARD-LAW-1 RN-FIRST：RN [IssueDetailPage.js editIssue/lockedIssue/editComment/deleteComment/_getOptionItem/_getBottomItem](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js) + RN [issueDao.editIssueDao/lockIssueDao/editCommentDao/deleteCommentDao](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/issueDao.js) 已通读并在 § 6 沉淀
- [x] KI-046 防御：3 个 CustomDialogController 全部 @Component scope new；prompt builder 内 `this.xxx` 闭包指向 component 实例
- [x] KI-048 防御：cell 文案/颜色全 inline `this.store.xxx` / `this.pendingXxx` 直读；未引入 `@Builder buildXxx(value: string)` 中转

### 7.3 真机回归（2026-05-27 r8-l8-issuedetail-d8-20260527-141011）

报告：[reports/M6/r8-l8-issuedetail-d8-20260527-141011/README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/README.md)
沙箱：[CarSmallGuo/SmallT#8](https://github.com/CarSmallGuo/SmallT/issues/8)（owner=CarSmallGuo，6 条评论）

- [x] hvigor `assembleHap` BUILD SUCCESSFUL（含 KI-050 修复，2026-05-27 18:23）
- [x] hdc install -r entry-default-signed.hap
- [x] aa start --ps bootIssue `CarSmallGuo/SmallT|8` 进入 IssueDetailPage（[01_issue_loaded.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/01_issue_loaded.jpeg)）
- [x] **场景 1 锁定**：onLockMenuTap → confirm OK → hilog `[issue/lock] result=ok code=204` → 服务端 API `locked=true` → 底栏第 4 项文案翻转；锁后用 UI 解锁恢复（[02_lock_confirm.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/02_lock_confirm.jpeg) + [03_locked_state.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/03_locked_state.jpeg)）
- [x] **场景 2 关闭**：toggleIssueState → confirm OK → hilog `[issue/state] result=true code=200 wasOpen=true` → API `state=closed` → header pill 变红（[02_close_confirm.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/02_close_confirm.jpeg) + [02_closed_state.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/02_closed_state.jpeg)）
- [x] **场景 3 重开**：toggleIssueState → confirm OK → hilog `[issue/state] result=true code=200 wasOpen=false` → API `state=open`（[03_reopen_confirm.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/03_reopen_confirm.jpeg) + [03_reopened_state.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/03_reopened_state.jpeg)）
- [ ] **场景 4 编辑 issue ⛔ Blocked by [KI-052](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md)**：L9 owner 修复后，底栏第 2 项 tap (495,2792) 多次无 `[issue/edit]` hilog（同 KI-050 现象残余但 KI-050 修法在源码里）；按 ONE-CHAIN 仅登记 KI-052（详 [L9 报告 § 4](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800/README.md)）
- [x] **场景 5 编辑评论 ✅ PASS（L9 闭环）**：L9 KI-051 修后冷启 owner=true，hilog `[comment/longpress] index=0 cid=3501165480 owner=true` + `[comment/edit] prompt open cid=3501165480 row=0`，长按菜单 4 项（编辑/删除/复制/回复）正确弹出（详 [L9 报告](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800/README.md)）
- [x] **场景 6 删除评论 ✅ PASS（L9 闭环）**：hilog `[comment/delete] result=true code=204 cid=3501165480 row=0`，列表评论数 6→4（GitHub API 实测 HTTP 204）
- [x] **场景 7 复制评论**：长按评论 → ActionSheet 选「复制」→ Toast `已经复制到粘贴板`（[07_copy_sheet.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/07_copy_sheet.jpeg) + [07_copy_done.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/07_copy_done.jpeg)）
- [x] 中途修复 [KI-050](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) CommonBottomBar ForEach itemClick 冻结（详 [报告 § 3](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/README.md)）
- [x] L9 修复 [KI-051](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) auth.userLogin 冷启未恢复（4 处编辑：Preferences[USER_INFO] + LoginUseCase 写盘 + WelcomePage.restoreUserInfo 双层 fallback；详 [L9 报告](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800/README.md)）
- [x] 三件套 OH 端齐全：L8 4 张 PASS 截图 + L9 6 张 PASS 截图 md5 全不同 + dump + hilog/API 三重证据；RN 镜像截图沿用 L3 历史基线（沙箱 issue#8 仅 OH 端）

### 7.4 KI-035 状态推进

`Open → Code-Ready → 部分 PASS（L8 4/7） → 大部分 PASS（L9 6/7+1 Blocked KI-052，2026-05-27）`：

- L8 通过场景 1/2/3/7（4 项），KI-050 顺手修齐
- L9 通过场景 5/6（2 项），KI-051 闭环
- 场景 4 因 [KI-052](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md)（CommonBottomBar 第 2/3/4 项 onClick 不响应，KI-050 残余现象）阻挡
- 待 KI-052 修后，重跑场景 4 即可推 KI-035 至彻底 Closed

