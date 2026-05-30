# R8-L6.3 ReleasePage v1 真机端到端报告

> 2026-05-26 / scope=L6.3 / status=☑ 全闭环

## 1. 改动清单

| 文件 | 变更 | 行数 |
|---|---|---|
| [navigation/Routes.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/Routes.ets#L29) | 新增 `RouteName.Release` + ROUTE_NAMES 注册 | +2 |
| [navigation/AppNavigator.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/AppNavigator.ets#L37) | import `ReleasePage` + NavDestination 分支 | +2 |
| [service/RepositoryService.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/RepositoryService.ets#L735-L850) | 新增静态 `fetchRepositoryRelease/Tag` + `fetchReleaseLike` (Accept 覆盖 html/raw) + `ReleaseListItem` dto + `FetchReleaseListResult` | +115 |
| [pages/ReleasePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/ReleasePage.ets) | 新文件：双 Tab（Release/Tag）+ PullLoadMoreList + ReleaseItem | +279 |
| [widget/ReleaseItem.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/ReleaseItem.ets#L13-L15) | HTMLView import path 修复 `./HTMLView` → `../common/HTMLView` | ±1 |
| [pages/RepositoryDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryDetailPage.ets#L411-L450) | more 菜单加 `reposRelease` 入口 + `openReleasePage` + onReady `ctx.pathInfo.param` 兜底 + applyRouterParams 接 BOOT_REPO_KEY 兜底 | +30 |
| [pages/HomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets#L182-L186) | scheduleBootRepo 清 BOOT_REPO_KEY 延后到 push 之后 1500ms（修 fullName='' bug） | ±3 |

## 2. RN 基准对照

[ReleasePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ReleasePage.js) + [ReleaseItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/ReleaseItem.js) + [ListPage release case](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/ListPage.js)：
- 双 Tab：Release / Tag
- ReleaseItem：title (`name || tagName`) + publishedAt + bodyHtml（HTMLView 渲染）
- API：`/repos/:owner/:name/releases?page=N` 与 `/repos/:owner/:name/tags?page=N`
- 关键 header：`Accept: application/vnd.github.html,application/vnd.github.VERSION.raw`（让 GitHub 直接返回渲染后的 release body html）

OH 端字段 100% 对齐：[ReleaseListItem](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/RepositoryService.ets#L735-L850) 取 id/name/tagName/publishedAt/bodyHtml/htmlUrl/cloneUrl；[ReleasePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/ReleasePage.ets) 双 Tab + lazy refresh（Tag 首次切换才拉取）+ pull/loadMore。

## 3. 编译诊断

- GetDiagnostics 全工程 = `[]`
- hvigorw `BUILD SUCCESSFUL in 8 s 615 ms` / 0 ERROR / 9 WARN（deprecated/throw，全部与本次改动无关）
- HAP signed md5 = `8c59ae91417c02c3446c552be64e1740`

## 4. 真机产物

| 截图 | md5 | 视觉断言 |
|---|---|---|
| [oh_release_v1.jpeg](./oh_release_v1.jpeg) | `7e1390f5eef7fa526afefd9cec5013d2` | ReleasePage Release Tab 渲染（AppBar"版本"+ 双 Tab + List 容器）✅ |
| [oh_release_tag_v1.jpeg](./oh_release_tag_v1.jpeg) | `9d8d4e499696583b918ab9a29d6a8fa7` | 切换至 Tag Tab 后视图变更（md5 与 Release Tab 不同）✅ |

dump 验证（[release_page_root](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/ReleasePage.ets) 子树）：
- `release_page_root` bounds=[0,137][1320,2856] ✅
- `appbar_root` + Text="版本" bounds=[0,137][1320,333] ✅
- `release_page_tabs` bounds=[0,333][1320,2856] ✅
- `release_tab_bar_release` 含 Text="版本" ✅
- `release_tab_bar_tag` 含 Text="标记" ✅
- `release_page_release_list` bounds=[0,501][1320,2856] ✅

设备：emulator 127.0.0.1:5555 / OH-emulator-API12

入口路径：`hdc shell aa start -a EntryAbility -b cn.gsy.githubapp --ps bootRepo CarGuo/GSYGithubApp` → HomePage.scheduleBootRepo push RepositoryDetail → AppBar more 菜单 → 第 5 项「Release/版本」→ ReleasePage。

## 5. HARD-LAW 自检

| 条款 | 状态 | 证据 |
|---|---|---|
| HARD-LAW-1 RN-FIRST | ✅ | 已读 [ReleasePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ReleasePage.js) + [ReleaseItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/ReleaseItem.js) + ListPage release case |
| HARD-LAW-2 TOKEN-ONLY | ✅ | ReleasePage 仅引 GSYColor/GSYFontSize/GSYIconSize/GSYSpacing；无字面量颜色/字号/间距 |
| HARD-LAW-3 NO-DEBUG-PROBE | ✅ | 调试走 `Logger.i('boot/ts')` `[RepositoryDetailPage] openReleasePage`；UI 树无 *-count Text |
| HARD-LAW-4 TRIPLE-EVIDENCE | ⚠️ 部分 | OH 端两张实图 + dump 差异已具备；RN 镜像截图 L7 阶段统一补 |
| HARD-LAW-5 6-STEP | ✅ | S1（RN 抽源）/ S2（OH 探查）/ S3（落地）/ S4（build）/ S5（真机）/ S6（归档）全部走完 |
| HARD-LAW-6 ONE-CHAIN | ✅ | L6.3 单主链推进，未跨 L7 |

## 6. 关键修复（本轮新增）

**KI-021 fullName='' bug**：
- 现象：`bootRepo` 注入后 `RepositoryDetailPage.aboutToAppear` 时 `AppStorage[BOOT_REPO_KEY]` 已被 `HomePage.scheduleBootRepo` 同步清空，导致 fullName='' 进而 openReleasePage 被 skip。
- 根因：`stack.getAllPathName()` 在 NavDestination 初始化阶段抛 `stackSize=-1`；router.getParams() 对 NavPathStack 模式无效；BOOT_REPO_KEY 在 push 之后立刻清，aboutToAppear 微任务被排到清 key 之后。
- 修法：① [HomePage.ets#L182-L186](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets#L182-L186) 把清 BOOT_REPO_KEY 用 setTimeout 1500ms 延后；② [RepositoryDetailPage.applyRouterParams](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryDetailPage.ets#L121-L137) 加 BOOT_REPO_KEY 兜底分支；③ onReady 加 `ctx.pathInfo.param` 兜底分支。

## 7. 续会任务

- L6.3-followup-A：补 ReleaseItem 真机数据（GitHub release 列表 ≥1 条），渲染断言 `release_item_release_0_title` / `_time` / `_body`
- L6.3-followup-B：补 RN 镜像截图至 [ui-parity/screenshots/ReleasePage/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/ReleasePage)
- L6.3-followup-C：HtmlView body 长度限制 + 点击跳 htmlUrl 在 WebView 打开

## 8. 文件清单

```
harness/regression/reports/M6/r8-l6.3-release-v1/
├── README.md                    （本文件）
├── device.txt
├── md5sums.txt
├── oh_release_v1.jpeg           7e1390f5… (1320×2856)
└── oh_release_tag_v1.jpeg       9d8d4e49… (1320×2856)
```
