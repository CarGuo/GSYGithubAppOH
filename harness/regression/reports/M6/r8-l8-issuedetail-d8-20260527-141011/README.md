# R8-L8 IssueDetailPage Δ8（KI-035）真机回归报告

报告目录：[r8-l8-issuedetail-d8-20260527-141011](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011)
主链文档：[L3-IssueDetail.md § 7](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L3-IssueDetail.md)
KI 登记：[known-issues.md KI-035](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md)

## 1. 测试沙箱

- 目标 issue：[CarSmallGuo/SmallT#8](https://github.com/CarSmallGuo/SmallT/issues/8)（沙箱仓库；6 条评论全部由 owner CarSmallGuo 发出）
- 启动方式：`aa start --ps bootIssue 'CarSmallGuo/SmallT|8'`
- 设备：模拟器 `127.0.0.1:5555`，bundleName `cn.gsy.githubapp`，PID=1025
- 当前 hap：含 [CommonBottomBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonBottomBar.ets) ForEach key dataListRev 修复（2026-05-27 18:23 build），无任何调试 Logger 残留

## 2. 7 张子场景结果

| # | 场景 | 状态 | OH 截图 (md5) | 服务端校验 | 备注 |
|---|---|---|---|---|---|
| 1 | 锁定 issue | ✅ PASS | [02_lock_confirm.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/02_lock_confirm.jpeg) `fabd91fb…` → [03_locked_state.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/03_locked_state.jpeg) `0e97a3bf…` | curl `api.github.com/.../issues/8` → `locked=true` | hilog `[issue/lock] result=ok code=204`；锁后用 UI 解锁恢复 |
| 2 | 关闭 issue | ✅ PASS | [02_close_confirm.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/02_close_confirm.jpeg) `0e7d3414…` → [02_closed_state.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/02_closed_state.jpeg) `73e98227…` | API → `state=closed` | hilog `[issue/state] result=true code=200 wasOpen=true` |
| 3 | 重开 issue | ✅ PASS | [03_reopen_confirm.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/03_reopen_confirm.jpeg) `fd052abd…` → [03_reopened_state.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/03_reopened_state.jpeg) `5709e3ab…` | API → `state=open` | hilog `[issue/state] result=true code=200 wasOpen=false` |
| 4 | 编辑评论（owner） | ⛔ Blocked | — | — | hilog `[comment/longpress] index=0 cid=3501165480 owner=false`；ActionSheet 仅显「复制」一项；根因见 § 4 KI-051 |
| 5 | 删除评论（owner） | ⛔ Blocked | — | — | 同 § 4，ActionSheet 缺「删除」 |
| 6 | 编辑 issue（owner） | ⛔ Blocked | — | — | `onEditMenuTap` 因 `isIssueOwner()=false` 直接 `CommonToast('noPower')` 中断 |
| 7 | 复制评论 | ✅ PASS | [07_copy_sheet.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/07_copy_sheet.jpeg) `77ff5e25…` → [07_copy_done.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/07_copy_done.jpeg) `5bf1aacc…` | — | toast 文案 `已经复制到粘贴板`，居中偏下显示清晰 |

辅助证据：[01_issue_loaded.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/01_issue_loaded.jpeg) `0b45d9ca…`（场景起点）；[04_close_confirm.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/04_close_confirm.jpeg) `91afe02c…`（场景 2 复测中间态）。

## 3. 中途修复：CommonBottomBar 底栏 itemClick 冻结

### 3.1 现象

场景 2/3 卡住：tap 屏幕底栏第 3 项「关闭/打开」按钮（坐标约 825,2792）连续 30+ 次完全无响应；同时第 1 项 comment（165）和第 4 项 lock（1155）正常工作。

### 3.2 排查过程

| 假设 | 验证 | 结论 |
|---|---|---|
| `buildBottomBarItems` 在 lock 后 rebuild 把 itemClick 失绑 | 冷启再测仍不响应 | 排除 |
| `@Builder buildItem` 值参冻结（KI-048 同款）| 内联到 ForEach lambda 后仍不响应 | 排除 |
| iconColor / itemTextColor 红色字符串拼 key 跳变不彻底 | 跳变正确但仍复用旧节点 | 排除 |
| uitest hit-test 误差 | uinput 直接触摸注入也不触发 | 排除 |
| 临时探针 `Logger.i('bottom-bar/click', id=..., name=...)` | onClick 触发 ✅，但 `item.itemClick()` 跑的是 `(): void => {}` 空函数 | **捉到** |

### 3.3 根因

[CommonBottomBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonBottomBar.ets) `ForEach` 的 key 函数返回值在 dataList 多次 rebuild 之间稳定（即使 isOpen / itemName / iconColor 切换也只是字段变化，key 字符串首次组成后稳定），ArkUI 因此复用旧节点，**外层 onClick handler 的 `item` 闭包引用被冻结在初始时刻的 itemClick 空函数**，后面 buildBottomBarItems 重做的真业务 lambda 永远写不进去。

### 3.4 修法

ForEach key 头部追加 `this.dataListRev.toString()` 版本号；`@Watch onDataListChanged` 在写入 `dataList` 时 `dataListRev++` 让 key 字符串完全变化，强制 ArkUI 重建子节点，`item` 引用同步刷新到最新 itemClick。

```ts
build(): void {
  Row() {
    ForEach(this.dataList, (item: CommonBottomBarItem, index: number): void => {
      Row() { /* IconFont + Text inline，KI-048 直读 this 字段 */ }
        .id('common_bottom_bar_item_' + (item.itemId || index.toString()))
        .layoutWeight(1).justifyContent(FlexAlign.Center)
        .onClick((): void => { item.itemClick(); });
    }, (item, index): string =>
      this.dataListRev.toString() + ':' + index + ':' +
      item.itemId + ':' + item.itemName + ':' +
      item.icon + ':' + item.iconColor + ':' + item.itemTextColor);
  }
}
```

与 KI-019（R7-F v5 SearchPage segment ✓ 不跟手）完全同款修法范式，已在 [known-issues.md KI-050](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) 登记 Closed。HARD-LAW-3 自检：定位根因后立即移除 Logger import + Logger.i 调用，重 build + install + 验证场景 2/3 仍 work（PID=1025 再次抓到 `[issue/state] confirm prepare isOpen=true`）。

## 4. 场景 4/5/6 阻挡：auth.userLogin 冷启未恢复（KI-051 候选）

### 4.1 现象

issue#8 的 6 条评论全部由 `CarSmallGuo` 发出，App 也以 `CarSmallGuo` 登录（token 来自 `aa start --ps bootToken ...`）。但长按第一条评论后 hilog 出现：

```
[comment/longpress] index=0 cid=3501165480 owner=false
```

ActionSheet dump 仅显示 `复制` 一项（[140,2457][1180,2523]），缺 `编辑` / `删除`。`onEditMenuTap` 同样走 `if (!this.isIssueOwner()) { CommonToast('noPower'); return; }` 被阻断。

### 4.2 根因

[currentLogin / isCommentOwner / isIssueOwner](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L266-L292) 都依赖 `AppStorage.get<string>(APP_STORAGE_KEY_USER_LOGIN)`，而：

- [AuthStore.setUser](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/store/AuthStore.ets#L153-L180) 内才会 `writeAppStorage(APP_STORAGE_KEY_USER_LOGIN, ...)`
- `setUser` 当前**仅**由 [LoginUseCase.ets#L208](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/LoginUseCase.ets#L208) 标准登录路径调用
- [EntryAbility.handleBootTokenInjection](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets#L130-L154) 冷启只持久化 token，不调 setUser

冷启之后 AppStorage 里没有 `auth.userLogin`，所有依赖 owner 判定的能力全部退化为 false → 阻挡场景 4/5/6。

### 4.3 处置

本轮按 ONE-CHAIN 原则不动代码，登记 [known-issues.md KI-051](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) Open（P2）。后续修法候选：(a) EntryAbility bootToken 路径补一次 `UserService.fetchUserInfo` 后写 AppStorage；(b) AuthStore 启动期从 Preferences 主动恢复 userLogin；(c) IssueDetailPage 做一层 fallback：`AppStorage` 空时取 `Address.getUserInfoDao().login`。

## 5. KI-035 状态推进

`Open → Code-Ready → 部分 PASS（2026-05-27）`：

- 场景 1/2/3/7 真机三件套齐 ✅
- 场景 4/5/6 因 KI-051 阻挡，本轮无法验证；待 KI-051 修后重跑这 3 张子场景即可 Closed

## 6. HARD-LAW 自检

| # | 项 | 结论 |
|---|---|---|
| 1 | RN-FIRST | ☑ 已通读 RN [IssueDetailPage.js _getOptionItem L373-L407 + _getBottomItem L319-L370](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js)、[issueDao.js editIssue/lockIssue/editComment/deleteComment](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/issueDao.js) |
| 2 | TOKEN-ONLY | ☑ [IssueDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets) + [CommonBottomBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonBottomBar.ets) 全 GSYColor/GSYFontSize/GSYIconSize/GSYSpacing/GSYShadow，无字面量颜色/字号/间距 |
| 3 | NO-DEBUG-PROBE | ☑ 临时排查 Logger 已撤；UI 树无 `xxx-count:N` Text；状态反馈走 hilog domain 0x0666 + CommonToast |
| 4 | TRIPLE-EVIDENCE | 🟡 OH 三件齐（截图 + dump + hilog/API）；RN 镜像截图沿用 L3-IssueDetail 历史基线（RN 端不存在等价 issue#8 沙箱，差异点已在主链文档说明） |
| 5 | 7-STEP | ☑ 按 L3 § 6 / § 7 / 本节 § 2 严格分子场景执行 |
| 6 | ONE-CHAIN | ☑ 仅推 KI-035 + 顺手修 KI-050（同一文件）；KI-051 仅登记不修 |
| 7 | NO-JARGON | ☑ 本报告对外描述用大白话，技术名词（ForEach key / @Watch / AppStorage / hilog domain）保留 |
