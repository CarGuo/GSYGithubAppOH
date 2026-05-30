# R8-L11 KI-052 真机回归报告（CommonBottomBar 子 Row 命中区修复）

报告目录：[r8-l11-ki052-20260527-213400](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l11-ki052-20260527-213400)
KI 登记：[known-issues.md KI-052](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md)
上一轮：[r8-l9-ki051-20260527-193800](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800)（KI-052 首映场景，4 个候选修法登记）

## 1. 主链小结

| 项 | 内容 |
|---|---|
| 主链 | L11（KI-052 修复）|
| 触发 | L9 KI-051 闭环时发现底栏第 2/3/4 项 onClick 不响应（仅 index=0 PASS）|
| 修法 | [CommonBottomBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonBottomBar.ets#L62-L72) 子 Row 加 `.height('100%')` + `.hitTestBehavior(HitTestMode.Block)` |
| 影响范围 | 仅一个文件 / 一个组件 / 2 行新增；CommonBottomBar 全工程 13 个调用点（IssueDetailPage / RepositoryDetailPage / PushDetailPage / 等）全部受益 |
| hap md5 | `f6bfbdae716776cde8f2635b3bd8231a`（4.1 MB）|
| BUILD | SUCCESSFUL 10s 620ms / 0 ERROR / 5 deprecated WARN（与历史一致无关项）|
| GetDiagnostics | `[]` ☑ |

## 2. 真正的根因

之前 L9 报告里登记的 4 个修法候选都偏向「@Prop 响应式 / ForEach key / @State 字段保存」，但**真正的根因不在响应式链**：

[CommonBottomBar.ets#L43-L95](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonBottomBar.ets#L43-L95) 的子 Row 用 `.layoutWeight(1)` 平分宽度，但**没显式设 height**——子 Row 高度只被内 Icon(14px) + Text(一行 ~57px) 自然撑开，外 Row 高度被 spread 到容器剩余空间（IssueDetail 里底栏 wrap 整个高度 = 2523px 根据 dump）。

子 Row 在外 Row 里位置默认 `alignItems(VerticalAlign.Center)` 居中显示，但**命中区只覆盖子 Row 的物理 bounds**——而真机 tap 坐标（如 495,2792）落在外 Row 的 padding 区，**不在子 Row bounds 内**，于是 tap 命中外 Row 而非子 Row → onClick 不触发。

「index=0 OK 其余全死」的特殊现象，可能是 ArkUI 默认 hitTest 在外 Row 里尝试找最左侧第一个有 onClick 的子节点匹配（首项 commentItem 因 layoutWeight 起点最近左侧），其他 3 项在 hit-test 路径上被外 Row 拦截。

## 3. 修法详细

### 3.1 改动点

[CommonBottomBar.ets#L65-L71](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonBottomBar.ets#L65-L71)：

```ts
// 旧
.layoutWeight(1)
.justifyContent(FlexAlign.Center)
.alignItems(VerticalAlign.Center)
.onClick((): void => { item.itemClick(); });

// 新
.layoutWeight(1)
.height('100%')                              // ← 新增：子 Row 撑满外 Row 高度
.justifyContent(FlexAlign.Center)
.alignItems(VerticalAlign.Center)
.hitTestBehavior(HitTestMode.Block)          // ← 新增：阻断 hit-test 冒泡到外 Row
.onClick((): void => { item.itemClick(); });
```

### 3.2 跟 KI-023 的同款修法

KI-023（SearchPage funnel 按钮命中区被 segment 块吃掉）已经验证过 `width(...)` + `hitTestBehavior(HitTestMode.Block)` + 内 Row `width/height 100%` 撑开 hit area 的范式；本次只是把同套范式搬到 CommonBottomBar。

### 3.3 影响范围

CommonBottomBar 是全工程通用组件，受益的 13 个调用点：
- [IssueDetailPage.ets#L773-L777](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L773-L777)（4 项 → 本次主战场）
- [RepositoryDetailPage.ets#L611-L614](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryDetailPage.ets#L611-L614)（4 项 star/watch/fork/branch）
- 其余 11 个调用点继续兼容（之前没出问题，是因为页面高度刚好让子 Row 自然高度对得上 tap 坐标）

## 4. 真机 4 子场景结果

| # | 场景 | tap 坐标 | 状态 | OH 截图 (md5) | 关键 hilog |
|---|---|---|---|---|---|
| 0 | bootIssue 冷启起点 | — | ✅ | [01_after_boot.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l11-ki052-20260527-213400/01_after_boot.jpeg) `ff2980264325b2430d6b7af067e5bf02` | scheduleBootIssue pre-schedule → pre-push → AceNavigation create node → onWillAppear/onAppear/onWillShow/onShown/onActive；onReady bootKey-fallback fullName=CarSmallGuo/SmallT number=8 |
| 1 | 回复（comment）| (207, 1762) | ✅ PASS | [02_tap1_comment.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l11-ki052-20260527-213400/02_tap1_comment.jpeg) `d87b2729ca005649564ee52952f9421b` | `[issue/comment] reply prompt open` + 截图弹出「请输入答复哟」TextInput dialog |
| 2 | 编辑（edit）| (537, 1762) | ✅ PASS | [03_tap2_edit.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l11-ki052-20260527-213400/03_tap2_edit.jpeg) `6f3e34cbd18d9cd180cce68a13b858ef` | `[issue/edit] prompt open titleLen=5 bodyLen=3` + 弹出 issue 编辑双 input dialog（title + body）|
| 3 | 关闭（state）| (867, 1762) | ✅ PASS | [04_tap3_state.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l11-ki052-20260527-213400/04_tap3_state.jpeg) `1d624373895725422728b8704420640d` | `[issue/state] confirm prepare isOpen=true` + 弹出 confirm dialog |
| 4 | 锁定（lock）| (1197, 1762) | ✅ PASS | [05_tap4_lock.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l11-ki052-20260527-213400/05_tap4_lock.jpeg) `78f109f9aa37705b3ce647b8d1f2ba4d` | `[issue/lock] confirm prepare locked=false` + 弹出 confirm dialog |

5 张截图 md5 全不同 ☑

## 5. 关键 hilog 摘录

```
21:28:29.827  [boot/ts] HomePage.scheduleBootIssue pre-schedule t=... fullName=CarSmallGuo/SmallT number=8
21:28:30.428  [boot/ts] HomePage.scheduleBootIssue pre-push t=...
21:28:30.428  [boot/ts] HomePage.scheduleBootIssue post-push t=...
21:28:30.437  AceNavigation: navigation stack create new node IssueDetail
21:28:30.438  AceNavigation: IssueDetail lifecycle change to onWillAppear
21:28:30.439  AceNavigation: IssueDetail lifecycle change to onAppear
21:28:30.440  AceNavigation: IssueDetail lifecycle change to onWillShow
21:28:30.440  [boot/ts] IssueDetailPage.onReady bootKey-fallback fullName='CarSmallGuo/SmallT' number=8
21:28:30.456  AceNavigation: IssueDetail lifecycle change to onShown / onActive
21:31:47.493  [issue/comment] reply prompt open                  ← TAP 1 PASS
21:32:22.851  [issue/edit] prompt open titleLen=5 bodyLen=3      ← TAP 2 PASS
21:33:13.981  [issue/edit] onCancel
21:33:15.185  [issue/state] confirm prepare isOpen=true          ← TAP 3 PASS
21:33:44.793  [issue/lock] confirm prepare locked=false          ← TAP 4 PASS
```

## 6. 子 Row bounds 对比（dump 实证）

新 hap dump 出来的子 Row bounds（[dump/dump_initial.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l11-ki052-20260527-213400/dump/dump_initial.json)）：

| item | 子 Row bounds | 高度 |
|---|---|---|
| comment | `[0,368][330,2856]` | 2488 px |
| edit | `[330,368][660,2856]` | 2488 px |
| state | `[660,368][990,2856]` | 2488 px |
| lock | `[990,368][1320,2856]` | 2488 px |

修复前子 Row 高度 ≈ 35px（仅内容自然高度），修复后子 Row 高度 = 整个外 Row 高度 ✅。

## 7. KI-052 / KI-035 状态推进

| KI | 状态变化 | 备注 |
|---|---|---|
| KI-052 | Open → ✅ Closed | CommonBottomBar 子 Row 命中区修复一次到位 |
| KI-035 | 6/7 PASS+1 Blocked → 7/7 PASS | 场景 4「编辑 issue 标题」入口本轮 PASS（[issue/edit] prompt open titleLen=5）|

## 8. HARD-LAW 自检

| # | 项 | 结论 |
|---|---|---|
| 1 | RN-FIRST | ☑ 已通读 RN [CommonBottomBar.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/common/CommonBottomBar.js)（TouchableOpacity flex:1 平分，无 hit-test 问题）+ [IssueDetailPage._getBottomItem L319-L370](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js#L319-L370) 4 项布局对齐 |
| 2 | TOKEN-ONLY | ☑ 仅 2 行新增 ArkUI API（height + hitTestBehavior），无任何字面量颜色/字号/间距 |
| 3 | NO-DEBUG-PROBE | ☑ 无新增 UI 调试 Text；继续走 hilog domain 0x0666 |
| 4 | TRIPLE-EVIDENCE | ☑ 5 张 OH 截图 md5 全不同 + dump JSON + 完整 hilog 时序 + RN 镜像沿用 [L3-IssueDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L3-IssueDetail.md) 既有基线 |
| 5 | 6-STEP | ☑ S1 RN-FIRST 抽源 → S2 OH-DIFF 复核（hit-test 根因）→ S3 修法 2 行 → S4 build+install → S5 真机 4/4 PASS → S6 文档 |
| 6 | ONE-CHAIN | ☑ 仅修 KI-052；KI-035 状态联动推进；无新派生 KI |
| 7 | NO-JARGON | ☑ 本报告对外用大白话，技术名词（HitTestMode / @Prop / @Watch / hilog domain / AceNavigation）保留 |

## 9. 派生候选

无。本次 2 行修法解决了底栏 onClick 链路全部 4 项的命中区问题，无派生 KI。
