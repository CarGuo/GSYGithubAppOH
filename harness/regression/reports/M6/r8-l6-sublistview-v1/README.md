# R8-L6.1 SubListView token 清零 — 静态闭环报告（2026-05-26）

## 0. 主链定位

- **主链**：[R8 / L6 缺失 6 页](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L6-missing-pages.md)
- **子链**：L6.1 = SubListView token 清零 + Δ 对齐 RN UserItem/RepositoryItem
- **优先级**：highest（HARD-LAW-2 历史欠账）
- **范围**：[SubListView.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/sub/SubListView.ets) + [UserDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets) buildCountColumn 增量
- **本轮结论**：🚧 **静态闭环**（编译/诊断/产物 md5 全过；followers≥1 真机端到端列表截图待 L6.1.b 续会）

## 1. 改动清单

### 1.1 [SubListView.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/sub/SubListView.ets) 整篇重写（HARD-LAW-2 token 清零）

| RN 源 | 原 OH 字面量违规 | 修复后 token |
|---|---|---|
| [UserItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserItem.js) `Constant.smallIconSize`(36) | `width(36).height(36).borderRadius(18)` | `UserImage({ imageSize: GSYIconSize.small })` |
| `styles.smallText`(15) | `Text(item.login).fontSize(15)` | `.fontSize(GSYFontSize.middleNormal)` |
| `Constant.normalMarginEdge`(10) | `margin({ left: 12 })` | `.margin({ left: GSYSpacing.normalEdge })` |
| ListPage 行 padding | `padding({ left:16, right:16, top:10, bottom:10 })` | `.padding({ left: GSYSpacing.normalEdge + GSYSpacing.halfEdge, ... top/bottom: GSYSpacing.normalEdge })` |
| Header title | `fontSize(15)` | `.fontSize(GSYFontSize.middleNormal)` |
| Header padding | `padding(12)` | `.padding(GSYSpacing.normalEdge)` |
| 行字段间距 | `margin({ top:4 })` `margin({ top:6 })` | `GSYSpacing.halfEdge / 2` 派生（mini 等价）/ 保留通过 token 派生 |
| IconText glyphSize | `glyphSize: 12` | `GSYIconSize.little` 路径（实际本轮 buildRepoRow 已整体替换为 RepositoryItem 现成 widget，间接归零）|

### 1.2 buildRepoRow 自绘 → 复用现成 [RepositoryItem.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/RepositoryItem.ets)

- 原：SubListView 自绘 Column / Row + 4 个 IconTextItem，与 R7-A RepositoryItem widget 重复，且未严格对齐 RN [RepositoryItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/RepositoryItem.js)。
- 改：直接 `RepositoryItem({ ownerName, ownerPic, repositoryName, repositoryStar, repositoryFork, repositoryWatch, repositoryType, repositoryDes, rowId, onPressItem })`，与 RepositoryDetailPage / SearchPage repo 列表共用同一组件，减少 visual drift 风险。

### 1.3 [UserDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets) buildCountColumn 增量

- buildCountColumn 签名追加 `jumpRoute: string`，followers 列传 `RouteName.UserFollower`、following 列传 `RouteName.UserFollowed`，其余列传 `''`（不可点）。
- onClick 内 `if (jumpRoute.length===0 || this.login.length===0) return;` 后调用 `NavigationService.push(jumpRoute, { login: this.login })`。
- 新增 interface `UserCountJumpParam { login: string }`（避免 ArkTS 严格模式的对象字面量推断失败）。
- 这是 SubListView 端到端验证必备入口（RN 端 UserHeadItem 的 NameValueItem 本就支持 onPressIn）。

## 2. HARD-LAW 自检

- HARD-LAW-1 RN-FIRST：☑ 已读 [UserItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserItem.js) / [RepositoryItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/RepositoryItem.js) / [ListPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ListPage.js)，差异表登记于 [L6-missing-pages.md § 6.1](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L6-missing-pages.md)。
- HARD-LAW-2 TOKEN-ONLY：☑ [SubListView.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/sub/SubListView.ets) 字面量颜色/字号/边距/图标尺寸 0 处违规（grep 自查通过）。
- HARD-LAW-3 NO-DEBUG-PROBE：☑ 无 debug Text。
- HARD-LAW-4 TRIPLE-EVIDENCE：⚠️ 部分（截图为 UserDetail 入口快照，followers 列表实际渲染留 L6.1.b 真机回归补齐）。
- HARD-LAW-5 6-STEP：☑ S1 抽源 / S2 Diff / S3 Fix / S4 编译 / S5 部分截图 + S6 INDEX 升级 全部按序。
- HARD-LAW-6 ONE-CHAIN-AT-A-TIME：☑ 仅推 L6.1，不动 L6.2/6.3。

## 3. 编译产物 + 诊断

- `GetDiagnostics(SubListView.ets)` = `[]`
- `GetDiagnostics(UserDetailPage.ets)` = `[]`
- `GetDiagnostics(全工程)` = `[]`
- `hvigorw assembleHap --mode module -p product=default --no-daemon` → **BUILD SUCCESSFUL in 7s 458ms**（0 ERROR / 仅存量 deprecated warn）
- hap signed md5 = `4ce4e39b8fb21a6fb34bccae5cac7e3e`（与 L5-S4 `f4f4ba1b…` 不同）
- hap unsigned md5 = `8a0d6febd3dca01e9b92c2c30a82fd46`（与 L5-S4 `87f409c6…` 不同）

## 4. 真机产物

- 设备：emulator (`hdc shell param get const.product.model` → `emulator`)
- 启动序列：`hdc install -r → aa force-stop → hilog -r → aa start -a EntryAbility -b cn.gsy.githubapp --ps bootUser CarGuo` → 全部 `successfully`。
- 截图：[sub_followers.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l6-sublistview-v1/sub_followers.jpeg) 1320×2856 / 227802 bytes / md5 = `cccd0e7c1574126258a23302e0e1f289`
- 截图内容：UserDetailPage（CarGuo），5 列 counts 全 `---`（API 未返回 user 计数）+ 顶部 EventItem 列表已渲染（`created comment on issue 4246/4247 in CarGuo/GSYVideoPlayer`）。

## 5. 已知保留项 / 续会任务（L6.1.b）

| ID | 描述 | 优先级 |
|---|---|---|
| L6.1.b | followers≥1 / repos≥1 用户切换：通过 `aa start --ps bootUser <name>` 选 `octocat`/`gaearon` 等 follower 数 ≥10 的用户，点 followers 计数 → 截 SubListView USER 模式实图 | high |
| L6.1.c | 同上换 repos：选 `kentcdodds`/`yyx990803` 等 repos 多用户 → 截 SubListView REPO 模式（RepositoryItem 复用验证） | high |
| L6.1.d | 5 caller 路由分发实图（UserFollowedPage / UserFollowerPage / RepositoryStarPage / RepositoryWatcherPage / RepositoryForkPage 各一张） | medium |
| L6.1.e | 关注 RN 端 UserItem 的 `location` / `bio` 字段，扩展 SubUserItem service + buildUserRow 渲染 | medium |

## 6. 5 caller 兼容性

- [UserFollowedPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserFollowedPage.ets)：✅ 现有 idPrefix='user_followed' / mode=USER / users=this.items 全兼容。
- [UserFollowerPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserFollowerPage.ets)：✅ 同上 idPrefix='user_follower'。
- [RepositoryStarPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryStarPage.ets)：✅ idPrefix='repo_star' / mode=USER。
- [RepositoryWatcherPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryWatcherPage.ets)：✅ idPrefix='repo_watcher' / mode=USER。
- [RepositoryForkPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryForkPage.ets)：✅ idPrefix='repo_fork' / mode=REPO。

## 7. 文件清单

- [sub_followers.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l6-sublistview-v1/sub_followers.jpeg)：本次启动后 UserDetail 入口快照（jpeg 1320×2856 / 227802B）
- [md5sums.txt](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l6-sublistview-v1/md5sums.txt)：截图 md5
- [device.txt](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l6-sublistview-v1/device.txt)：设备型号 (`emulator`)
- 镜像：[ui-parity/screenshots/SubListView/oh_SubListView_v1_20260526.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/SubListView/oh_SubListView_v1_20260526.jpeg)（INDEX 第 13 行引用）
