# L2 PushDetailPage 主链

> 入口：dynamic 列表 push 事件 onTap → NavigationService.push('PushDetail')；
> 真机回归通道：`aa start --ps bootPush "owner/name|sha"` 直推。
> 状态：✅ S1+S2+S3+S4+S5+S6 全部完成，DoD 10/10。

---

## § 1 RN 基准清单

### 1.1 RN 源
- 主壳：[PushDetailPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PushDetailPage.js) 178 行
- Header widget：[PushDetailHeader.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/PushDetailHeader.js) 121 行（注意：文件名是 PushDetailHeader，不是 PushHeader）
- 文件行：[CodeFileItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/CodeFileItem.js)
- 数据：repository action `getReposCommitsInfo(owner, name, sha)` → `{result, data:{committer, commit, files, stats}, next}` 二段式（先返回再 next() 拉 patch）

### 1.2 顶层结构

```
View(mainBox, bg=miWhite)
├─ StatusBar(translucent + light-content)
├─ View(height=2, opacity=0.3)  // 顶部 1 条细线
└─ PullListView(enableRefresh=false)
   ├─ renderHeader = PushDetailHeader
   │  └─ View(card, bg=primaryColor, borderRadius=4, shadowCard)
   │     └─ Row
   │        ├─ UserImage(actionUserPic, size=bigIconSize, circle)
   │        └─ Column
   │           ├─ Row(stats line) editCount + addCount + deleteCount   // icon: edit / diff-added / minus-square-o, color=miWhite, size=13
   │           ├─ Text(resolveTime(pushTime), miLightSmallText)
   │           └─ Text(pushDes = "Push at " + commit.message, miLightSmallText, selectable)
   └─ ForEach(files) → CodeFileItem(filename, onClick → CodeDetail patch)
```

### 1.3 token 映射

| RN constant.js | Theme.ets | 用途 |
|---|---|---|
| `primaryColor #24292e` | `GSYColor.primary` | header card bg |
| `miWhite #ececec` | `GSYColor.miWhite` | header 文字色 |
| `bigIconSize` | `GSYIconSize.big` | UserImage 头像 |
| `normalMarginEdge 10` | `GSYSpacing.normalEdge` | card 内/外边距 |
| `minTextSize 12` | `GSYFontSize.min` | 文件名行 minTextSize |
| `smallTextSize 14` | `GSYFontSize.small` | 文件 title |
| icon size 13 | （取 GSYFontSize.min 视觉接近）| stats 图标 |

### 1.4 交互序列

```
进入：Actions.PushDetailPage({userName, repositoryName, sha})
  → componentDidMount
  → InteractionManager.runAfterInteractions
     → pullListRef.showRefreshState()
     → _refresh
        → reposActions.getReposCommitsInfo(user, repo, sha) → setState({pushDetail, dataSource: data.files})
        → Actions.refresh({titleData})  // 更新 React Navigation 标题
        → res.next() → setState 二次填充

文件点击：rowData → patch → CodeDetailPage(generateCode2HTml(parseDiffSource(patch)))
```

---

## § 2 OH 偏差清单

| # | 现象 | RN 真源 | 根因 | 影响文件 | 状态 |
|---|---|---|---|---|---|
| D1 | OH commit card 用 author/email/message/date 4 段纯文本 | RN 是 UserImage + 3 stats 图标 + time + pushDes 单卡片 | OH 实现简化版本 | [PushDetailPage.ets#L112-L173](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PushDetailPage.ets#L112-L173) | P2（功能等价，视觉差异留 Δ）|
| D2 | 缺 UserImage 头像 | RN 卡片左侧大圆头像 | OH `buildCommitCard` 未渲染 author avatar | 同上 | P2 |
| D3 | stats 行无 edit/diff-added/minus icon 装饰 | RN 三 icon (FontAwesome edit / Octicons diff-added / FontAwesome minus-square-o) | OH 用 `+N`/`-N`/`files:N` 纯文字 | 同上 | P2 |
| D4 | OH 字面量违规 | — | `fontSize(15)` / `margin top:2/6` / `margin left:12` / `padding 12` / `top:4` / `padding {10}` 共 ~12 处 | [PushDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PushDetailPage.ets) | ✅ Closed（S3：全部替换为 GSYFontSize.middleNormal/halfEdge/halfEdge*0.5/normalEdge）|

代码层先前已对齐项：
- ✅ AppBar with 7-char sha title（[ets#L213-L220](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PushDetailPage.ets#L213-L220)）
- ✅ files 列表点击 → CodeDetail（[ets#L54-L60](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PushDetailPage.ets#L54-L60)）
- ✅ stats +additions/-deletions 着色（issueOpenGreen/issueClosedRed token）
- ✅ Theme token 全覆盖（S3 后）

---

## § 3 截图对照（S5/S6 已完成 2026-05-26 09:06:33）

### RN 基准
- [rn-PushDetailPage.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-PushDetailPage.jpg)

### OH 真机
- 入口通道：`aa start -a EntryAbility -b cn.gsy.githubapp --ps bootPush "CarGuo/GSYGithubApp|f09260730c9a6c4ff6dfe03845ee6caf32ef0cdc"`
  - EntryAbility 注入到 [BOOT_PUSH_KEY](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets#L19-L24)
  - HomePage 600ms 后 push 到 RouteName.PushDetail，参数 `{fullName, sha}`
- 截图：[oh_PushDetail_v1.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/PushDetail/oh_PushDetail_v1.png)（md5=`6661d80be6661c41915b8bb38f6e0110`）
- 跑分目录：[r8-l2-pushdetail-v4-090633](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l2-pushdetail-v4-090633)
- scenario-tour 结果：`ok=1 fail=0 skip=12  dup=NO`
- dump 命中 id：`push_detail_root` / `push_detail_appbar` / `push_detail_commit_card` / `push_detail_author_text` / `push_detail_message_text` / `push_detail_file_list`

### S6 RN ↔ OH 差异

| Δ | RN | OH | 处置 |
|---|---|---|---|
| Δ1 | `View(card, bg=primaryColor)` 单一深色卡片 | `Column(buildCommitCard, bg=GSYColor.surfaceGray)` 浅色卡片 | P2 留差，写入 [§ 2 D1](#2-OH-偏差清单) |
| Δ2 | UserImage 大圆头像（左侧） | 无头像 | P2 留差，[§ 2 D2](#2-OH-偏差清单) |
| Δ3 | stats 行 3 个 icon (edit / diff-added / minus-square-o) | `+N/-N/files:N` 纯文本 | P2 留差，[§ 2 D3](#2-OH-偏差清单) |
| Δ4 | RN 顶栏走 React Navigation Header（标题=`Actions.refresh({titleData})`） | OH 自绘 [AppBar](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PushDetailPage.ets#L228-L235)，title=`sha.substring(0,7)` | P2 留差，sha7 与 RN headerTitle 等价 |
| Δ5 | 文件列表用 [CodeFileItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/CodeFileItem.js) widget | OH 自绘 [buildFileItem](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PushDetailPage.ets#L181-L223)，结构等价 | P3 留差 |

差异共 5 处（≤ 5），符合 R-UI-04。

### S5 修复链（本轮新增）

S5 真机回归过程中暴露并修复的 4 处生产 bug：

1. ✅ ActivityTab/DynamicTabPage `dispatchEventTap` 缺 `PushEvent → PushDetail` 分支 —— [ActivityTab.ets#L208-L246](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/repo/ActivityTab.ets#L208-L246) + [DynamicTabPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/tabs/DynamicTabPage.ets) 补 `resolveFirstCommitSha` helper + PushEvent 分支
2. ✅ EntryAbility 新增 `bootPush` want 通道（与 bootRepo 同款）—— [EntryAbility.ets#L19-L24](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets#L19-L24) + handleBootPushInjection
3. ✅ HomePage 新增 `scheduleBootPush` —— [HomePage.ets#L172-L196](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets#L172-L196)
4. ✅ PushDetailPage `resolveParamFromStack` JS_ERROR (`undefined is not callable`) 修复（faultlog [jscrash 09:02:29](tmp/_pushcrash.log)）：onReady 优先用 `ctx.pathInfo.param`，stack API 加 try/catch fallback —— [PushDetailPage.ets#L257-L283](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PushDetailPage.ets#L257-L283)
5. ✅ scripts/scenario-tour.sh 新增场景 13 `pushDetail` 直推通道 + DEMO_PUSH 默认值

---

## § 4 DoD 检查表

```
☑ 1. § 1/2/3 三件套齐
☑ 2. ArkTS 0 字面量（S3 全部替换 token）
☑ 3. ArkTS 0 调试 Text
☑ 4. hvigorw BUILD SUCCESSFUL（2026-05-26 09:06:1x，8s 385ms）
☑ 5. scenario-tour pushDetail ok=1 fail=0（v4-090633）
☑ 6. 截图 md5 唯一（6661d80be6661c41915b8bb38f6e0110）
☑ 7. hilog 0x0666 marker（bootPush injected → handleBootPushInjection done → scheduleBootPush pre-schedule → pre-push → post-push）
☑ 8. RN ↔ OH 差异 = 5 处（Δ1..Δ5，≤ 5）
☑ 9. INDEX.md PushDetailPage ✅（同步更新）
☑10. KI Closed（无新 KI 待登记，S5 修复链全部 inline 关闭）
```

---

## § 5 入口路径验证

dynamic 列表 push 事件 → 在 [ActivityTab.dispatchEventTap](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/repo/ActivityTab.ets#L178-L226) 已有 push event 分支 + [DynamicTabPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/tabs/DynamicTabPage.ets) onItemTap 路径。

**S5 计划**：在 [scripts/scenario-tour.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh) 新增 `pushDetail` 场景：
1. `aa start --PS bootRepo CarGuo/GSYGithubApp` 推入 RepoDetail
2. tap_id `repo_detail_tab_bar_activity` 切到 activity tab
3. 等列表加载（hilog `EventItem ready`）
4. tap 第一个 push 类型 EventItem
5. wait_for_id `push_detail_root` + dump
6. 截图

**S6 计划**：与 [rn-PushDetailPage.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-PushDetailPage.jpg) 对照，差异填 § 3。
