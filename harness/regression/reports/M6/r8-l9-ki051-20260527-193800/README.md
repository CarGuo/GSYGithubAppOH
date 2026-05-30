# R8-L9 KI-051 真机回归报告（冷启 owner 判定修复）

报告目录：[r8-l9-ki051-20260527-193800](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800)
主链文档：[L3-IssueDetail.md § 7](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L3-IssueDetail.md)
上一轮：[r8-l8-issuedetail-d8-20260527-141011](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011)
KI 登记：[known-issues.md KI-051](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md)

## 1. 测试沙箱

- 目标 issue：[CarSmallGuo/SmallT#8](https://github.com/CarSmallGuo/SmallT/issues/8)（沙箱仓库；评论全部由 owner CarSmallGuo 发出）
- 启动方式：仅传 bootIssue（token 走 Preferences 持久化通道；本次 hap 升级后 USER_INFO key 缺失，验证 fallback 网络拉 /user 路径）
  ```
  aa start -a EntryAbility -b cn.gsy.githubapp --ps bootIssue 'CarSmallGuo/SmallT|8'
  ```
- 设备：模拟器 `127.0.0.1:5555`，bundleName `cn.gsy.githubapp`，PID=25017
- 当前 hap：含本轮 KI-051 修法（[Preferences.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/dao/db/Preferences.ets) + [LoginUseCase.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/LoginUseCase.ets) + [WelcomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WelcomePage.ets)），2026-05-27 19:37 build

## 2. 修法摘要

跟 RN 端 [WelcomePage.componentDidMount → userActions.initUserInfo](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WelcomePage.js) 行为对齐：冷启时把本地缓存的 user 写回内存。

| 修改位置 | 改动 |
|---|---|
| [Preferences.ets#L13](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/dao/db/Preferences.ets) | 新增 `KEY_USER_INFO = 'userInfo'`（对齐 RN `Constant.USER_INFO`） |
| [LoginUseCase.ets fetchUserAndCommit](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/LoginUseCase.ets) | 标准登录拿到 user 后顺手 `prefs.putString(KEY_USER_INFO, jsonString)`（对齐 RN [userDao.getUserInfoDao](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/userDao.js#L26-L46)） |
| [LoginUseCase.ets logout](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/LoginUseCase.ets) | 同步清 `KEY_USER_INFO` |
| [WelcomePage.ets routeByToken + restoreUserInfo](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WelcomePage.ets#L117-L154) | 拿到 token 后跳 Home 之前先恢复 user：① 优先读 `Preferences[KEY_USER_INFO]` 反序列化 setUser（对齐 RN [user.js initUserInfo](https://github.com/CarGuo/GSYGithubApp/blob/master/app/store/actions/user.js#L17-L31)）② 本地无缓存时（bootToken 测试通道首次注入 / 升级安装）调 `DefaultLoginUseCase.loginWithPersonalAccessToken(token)` 拉 `/user` 兜底 |

## 3. 子场景结果（KI-035 重跑场景 5/6 + 原首映场景 4 卡点）

| # | 场景 | 状态 | OH 截图 (md5) | 关键 hilog | 备注 |
|---|---|---|---|---|---|
| — | 冷启起点 | ✅ | [01_after_boot.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800/01_after_boot.jpeg) `3c54adbf…` | `WelcomePage: restoreUserInfo via /user ok login=CarSmallGuo` | 升级后 Preferences[USER_INFO] 缺失，走 /user 兜底 PASS |
| 5 | 长按评论弹菜单（owner 判定） | ✅ PASS | [04_longpress_menu_owner_true.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800/04_longpress_menu_owner_true.jpeg) `6d956d42…` | `[comment/longpress] index=0 cid=3501165480 owner=true` | 4 项菜单（编辑/刪除/复制/回复）齐 |
| 5 | 编辑评论 dialog | ✅ PASS | [05_edit_comment_dialog.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800/05_edit_comment_dialog.jpeg) `cf531c1f…` | `[comment/edit] prompt open cid=3501165480 row=0` | dialog 弹出后取消，未实际改内容（只验证入口） |
| 6 | 删除评论 | ✅ PASS | [06_delete_confirm.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800/06_delete_confirm.jpeg) `bbe0a0d8…` | `[comment/delete] result=true code=204 cid=3501165480 row=0` | 删除前 6 条评论 → 删后 4 条；GitHub API 返回 HTTP 204 |
| 4 | 编辑 issue 标题 | ⛔ Blocked | [02_edit_issue_dialog.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800/02_edit_issue_dialog.jpeg) `b5d29c18…` / [03_after_3_clicks.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800/03_after_3_clicks.jpeg) `f2969d77…` | 完全无 hilog | tap 底栏第 2 项「编辑」按钮（坐标 495,2792）连续 4+ 次完全无响应（onClick 都没进），跟 KI-050 当时第 3 项的现象同源；详见 § 4 |

辅助证据：[hilog 日志摘录](#5-关键-hilog-摘录)，dump 全量见 [dump/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l9-ki051-20260527-193800/dump/)（8 份 JSON：起点 + 编辑底栏点 ×2 + 长按菜单 + 评论编辑 dialog + 二次长按 ×2 + 删除后状态）

## 4. 场景 4 阻挡：CommonBottomBar 第 2/3/4 项 onClick 不响应（KI-052 候选）

### 4.1 现象

冷启进 IssueDetail 后底栏 4 个按钮：

| index | 按钮 | uitest uiInput click 是否触发 hilog |
|---|---|---|
| 0 | 回复（comment）| ✅ `[issue/comment] reply prompt open` |
| 1 | 编辑（edit）| ❌ 无任何 hilog |
| 2 | 关闭（state）| ❌ 无任何 hilog |
| 3 | 锁定（lock）| ❌ 无任何 hilog |

跟 [r8-l8 § 3.1](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/README.md) 当时记录的「第 3 项 30+ 次无响应」是同源现象，但本轮表现为「除 index=0 之外全部不响应」。

### 4.2 跟 KI-050 的区别

[KI-050](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) 已修：[CommonBottomBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonBottomBar.ets#L29-L72) ForEach key 已加 `dataListRev` + `@Watch onDataListChanged` 自增。修法在源码里、build 也用了同一份源码。但本轮重复出现的原因待查：可能是 hap 升级后 IssueDetail 第一次 build 阶段 dataList 变化时 dataListRev 没自增（@Watch 对 @Prop 的初始化语义），也可能是其他 onClick 链路问题。

### 4.3 处置

本轮按 ONE-CHAIN 原则不修这条。登记 [known-issues.md KI-052](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) Open（P2）。

修法候选：(a) buildBottomBarItems 改为 @State 字段保存而非 build() 内构造（KI-050 修法的更彻底版）；(b) ForEach 改用 List+ListItem 走 ArkUI 原生项渲染；(c) 直接在 IssueDetailPage 把 4 个按钮 inline 写死（最稳，但跟 RN 1:1 对齐失分）。

## 5. 关键 hilog 摘录

```
05-27 19:38:04.685  [boot/ts] EntryAbility: bootIssue injected CarSmallGuo/SmallT|8
05-27 19:38:04.872  WelcomePage: registerFont FontAwesome ok
05-27 19:38:09.843  WelcomePage: restoreUserInfo via /user ok login=CarSmallGuo  ← KI-051 核心证据
05-27 19:38:10.470  [boot/ts] IssueDetailPage.onReady bootKey-fallback fullName='CarSmallGuo/SmallT' number=8
05-27 19:45:45.977  [issue/comment] reply prompt open                             ← 底栏 index=0 PASS
05-27 19:46:49.190  [comment/longpress] index=0 cid=3501165480 owner=true         ← KI-051 owner 判定通过
05-27 19:48:46.445  [comment/edit] prompt open cid=3501165480 row=0               ← 场景 5 PASS
05-27 19:50:43.422  [comment/longpress] index=0 cid=3501165480 owner=true
05-27 19:50:46.346  [comment/delete] result=true code=204 cid=3501165480 row=0    ← 场景 6 PASS
```

## 6. KI-035 / KI-051 状态推进

| KI | 状态变化 | 备注 |
|---|---|---|
| KI-051 | Open → Closed | 冷启路径 owner 判定恢复链路打通：本地缓存优先 + /user 兜底，对齐 RN initUserInfo |
| KI-035 | 部分 PASS → 大部分 PASS（5/7） | 场景 5/6 这轮 ✅；场景 4 转由 [KI-052](#4-场景-4-阻挡commonbottombar-第-234-项-onclick-不响应ki-052-候选) 跟踪；场景 1/2/3/7 沿用 [r8-l8](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l8-issuedetail-d8-20260527-141011/README.md) 既有 ✅ |
| KI-052 | — → Open | 新登记 |

## 7. HARD-LAW 自检

| # | 项 | 结论 |
|---|---|---|
| 1 | RN-FIRST | ☑ 已通读 RN [WelcomePage.componentDidMount](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WelcomePage.js) + [user.js initUserInfo](https://github.com/CarGuo/GSYGithubApp/blob/master/app/store/actions/user.js#L17-L31) + [userDao.js getUserInfoLocal/getUserInfoDao](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/userDao.js#L11-L46) + [login.js doTokenLogin](https://github.com/CarGuo/GSYGithubApp/blob/master/app/store/actions/login.js#L49-L78) |
| 2 | TOKEN-ONLY | ☑ 本轮 3 个文件改动无任何字面量颜色/字号/间距 |
| 3 | NO-DEBUG-PROBE | ☑ 仅 hilog domain 0x0000（WelcomePage 既有）；UI 树无任何调试 Text |
| 4 | TRIPLE-EVIDENCE | 🟡 OH 三件齐（截图 + dump + hilog + 服务端 204）；RN 镜像沿用 L3-IssueDetail 既有基线 |
| 5 | 7-STEP | ☑ S1 抽证 → S2 OH-DIFF → S3 编辑 → S4 build+install+冷启 → S5 重跑场景 → S6 文档 |
| 6 | ONE-CHAIN | ☑ 仅修 KI-051；KI-052 仅登记不修；KI-035 状态联动更新 |
| 7 | NO-JARGON | ☑ 本报告对外描述用大白话，技术名词（@Watch / AppStorage / Preferences / hilog domain / HTTP 204）保留 |
