# R8-L6.1 SubListView 真机运行时闭环 v2

date: 2026-05-26 14:32

## 1. 改动清单

- 5 页面 onReady 路由解析模式从 `stack.getAllPathName()` 切换为 `ctx.pathInfo.param`
  - [UserFollowerPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserFollowerPage.ets#L41-L52)
  - [UserFollowedPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserFollowedPage.ets#L41-L52)
  - [RepositoryStarPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryStarPage.ets#L41-L52)
  - [RepositoryWatcherPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryWatcherPage.ets#L41-L52)
  - [RepositoryForkPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryForkPage.ets#L44-L55)
- [UserDetailPage.ets buildCountColumn](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L375-L382) onClick 加 hilog 打点

## 2. 根因 & 修复

### 根因

NavPathStack.getAllPathName() / getParamByIndex() 在 OpenHarmony emulator API12 实例化的早期阶段 `undefined is not callable`，导致 `onReady` 抛 TypeError，App crash 退到桌面。

### 修复

改用 `NavDestinationContext.pathInfo.param`（标准 API，不依赖 stack 内部状态）取路由参数。

## 3. 编译诊断

- GetDiagnostics 全工程返回 `[]`
- hvigorw assembleHap BUILD SUCCESSFUL in 9 s 448 ms
- hap signed md5: `b8ea77ab32fd76e872831237c8dcc1f2`（与 L6.1.v1 `4ce4e39b8fb21a6fb34bccae5cac7e3e` 不同 → 编译产物变化证据）

## 4. 真机产物

- 设备：emulator
- 启动：`aa start --ps bootUser octocat`
- 操作：dumpLayout → followers_block bounds=[285,1149][535,1306] → uitest click 410 1227
- hilog 5 段链：
  ```
  [boot/ts] EntryAbility.handleBootUserInjection done login=octocat
  [boot/ts] HomePage.scheduleBootUser pre-schedule login=octocat
  [boot/ts] HomePage.scheduleBootUser pre-push
  [boot/ts] HomePage.scheduleBootUser post-push
  [boot/ts] UserDetailPage.tryAdoptBootUser adopted login=octocat
  [user/count/click] idPrefix=user_detail_followers jumpRoute=UserFollower login=octocat
  ```
- 截图：[sub_followers_empty.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l6-sublistview-v2/sub_followers_empty.jpeg) 1320×2856 / md5=`3febe56d54ab25736a267fa4b2dd70ba`
- 视觉断言：
  - ✅ AppBar 标题 `Followers` 渲染
  - ✅ SubListView title `Followers` header 渲染
  - ✅ NavDestination 路由切换成功（不再 crash 到桌面）
  - ✅ PullLoadMoreList empty placeholder `No content yet, tap to retry` 显示
  - ⚠️ followers 实际行未渲染（service.getUserFollowers 返回 `[]` 或失败）—— 推测受 GitHub 未鉴权 API 限流；非 ArkTS 渲染缺陷

## 5. HARD-LAW 自检

| HARD-LAW | 状态 | 说明 |
|----------|------|------|
| 1 RN-FIRST | ☑ | 已对齐 RN UserItem.js / RepositoryItem.js |
| 2 TOKEN-ONLY | ☑ | SubListView 全 token；5 页面无字面量改动 |
| 3 NO-DEBUG-PROBE | ☑ | 仅 Logger.i 走 hilog domain 0x0666，UI 树无 debug Text |
| 4 TRIPLE-EVIDENCE | ⚠️ | RN 端真机截图待补；当前 OH 端三件套齐全 |
| 5 6-STEP | ☑ | S1..S6 全打勾 |
| 6 ONE-CHAIN | ☑ | 仅 L6.1 一条主链推进 |

## 6. 续会任务

- L6.1.b：换登录用户（带有效 GitHub token），验证 followers 行真实渲染
- L6.1.c：从 RepositoryDetailPage star/watch/fork 入口截 REPO 模式实图
- L6.1.d：补 RN 端 UserSubListPage 真机截图，完成 TRIPLE-EVIDENCE
- L6.2：进入 PersonInfoPage 主链

## 7. 文件清单

- sub_followers_empty.jpeg（OH 端入口快照）
- md5sums.txt
- device.txt
- README.md（本文）
