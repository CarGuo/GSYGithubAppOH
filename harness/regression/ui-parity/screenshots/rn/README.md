# RN 真机截图基准（Baseline）— 2026-05-24

> 用户提供的 17 张 GSYGithubApp（React Native）真机截图，作为 OH 端 ui-parity 比对基准。
> 拍摄设备：与本仓库 OH 端 emulator 6.1.0.115 同视觉密度（约 1080×2400 物理）。
> 归档原则：HARD-LAW-4 TRIPLE-EVIDENCE-REGRESSION 第 1 件——RN 端真机截图。

## 截图清单（按页面分组）

### 1. RepositoryDetail（仓库详情，4 tabs：动态/详情信息/文件/Issues）

| 文件 | 场景 | 关键 UI 元素 |
|---|---|---|
| [rn-RepositoryDetail-activity-tab.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-activity-tab.jpg) | 动态 tab（默认） | RepositoryHeader（owner/name + Python+大小+License + 描述 + 创建/最后提交时间 + 4 列统计 41024⭐/7563🍴/226👁/28❗ + topics 标签 9 个）+ 子 segment 动态/提交/Pulse + 事件流 + BottomBar UnStar/UnWatcher/Fork/master |
| [rn-RepositoryDetail-detail-tab.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-detail-tab.jpg) | 详情信息 tab（README 渲染） | GITHUB TRENDING #1 标签 + stars/watchers/forks/issues/pull requests 圆角 chip + license/version/Docker/Build chip + English\|中文文档 链接 + Important 提示 + banner 占位 + BottomBar |
| [rn-RepositoryDetail-files-root.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-files-root.jpg) | 文件 tab 根目录 | 文件夹卡片列表（.github/ForumEngine/InsightEngine/MediaEngine/MindSpider/QueryEngine/ReportEngine/SentimentAnalysisModel/SingleEngineApp/final_reports）+ 右箭头 + BottomBar |
| [rn-RepositoryDetail-files-breadcrumb.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-files-breadcrumb.jpg) | 文件 tab 子目录 | 面包屑 `. > InsightEngine > nodes >` + Python 文件列表（__init__.py / base_node.py / formatting_node.py / report_structure_node.py / search_node.py / summary_node.py）+ "加载完了哟" + BottomBar |
| [rn-RepositoryDetail-issues-tab.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-issues-tab.jpg) | Issues tab | 顶部搜索框（占位"搜索"）+ 子 segment 全部/打开/关闭 + Issue 卡片（avatar + 用户名 + 标题 + closed/open chip + #编号 + 评论数）+ FAB（白底 +）+ BottomBar |
| [rn-RepositoryDetail-issues-more-menu.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-issues-more-menu.jpg) | Issues tab 右上更多 | 居中弹窗 6 项：版本 / 浏览器打开 / 复制链接 / 复制克隆链接 / 下载 / 分享 |
| [rn-RepositoryDetail-commits-tab.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-RepositoryDetail-commits-tab.jpg) | 动态 tab/提交子段 | 子 segment "提交" 选中（动态/✓提交/Pulse）+ commit 卡片（"GitHub" + "Merge pull request #685..." + sha:40327d75... 灰色 等宽小字）|

### 2. SearchPage（搜索页）

| 文件 | 场景 | 关键 UI 元素 |
|---|---|---|
| [rn-SearchPage-repo-result.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-SearchPage-repo-result.jpg) | 仓库 tab 搜索结果 "gay" | **AppBar：左 ← 返回 + 标题"搜索" + 右 filter funnel icon** + 搜索条（白底卡片包裹一个浅灰 TextInput "gay" + 右侧 magnify icon）+ 黑色 segment ✓仓库/用户 + 仓库卡（avatar + name + 右上语言 + author + desc + ⭐数/🍴数/⊙数）|
| [rn-SearchPage-user-result.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-SearchPage-user-result.jpg) | 用户 tab 搜索结果 | 同上 AppBar + 搜索条 + segment（仓库/✓用户）+ 用户卡（仅 avatar + 用户名，更紧凑） |
| [rn-SearchPage-filter-drawer.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-SearchPage-filter-drawer.jpg) | filter Drawer 抽屉（右拉） | 三栏选择列表，深色 section 标题 + 浅色选中项：① 类型：最匹配/star/forks/更新；② 排序：倒叙/正序；③ 语言：全部/Java/Objective-C/Swift/... |

### 3. IssueDetail（Issue 详情）

| 文件 | 场景 | 关键 UI 元素 |
|---|---|---|
| [rn-IssueDetail-body-dark.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-IssueDetail-body-dark.jpg) | Issue 头 + Body（深色 mainBackground） | 作者卡（avatar + 用户名 + #685 + closed chip + 评论数 + "1天前"）+ Issue 标题（英文）+ Body（中文摘要 + 修复内容 段落 + Markdown 渲染：md 文件名 chip + 路径 chip）+ BottomBar 回复/编辑/打开/锁定 |
| [rn-IssueDetail-comments-light.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-IssueDetail-comments-light.jpg) | 评论流（浅色） | 评论卡片列表，每条：avatar + 用户名 + 时间右对齐 + 正文（@mention 蓝色 + 链接蓝色 + 普通中英文 + bullet 列表）+ BottomBar |
| [rn-IssueDetail-more-menu.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-IssueDetail-more-menu.jpg) | 右上更多菜单 | 居中弹窗 3 项：浏览器打开 / 复制链接 / 分享 |

### 4. PushDetailPage（Push 事件详情）

| 文件 | 场景 | 关键 UI 元素 |
|---|---|---|
| [rn-PushDetailPage.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-PushDetailPage.jpg) | Push 事件 | header 卡（GitHub avatar + 编辑统计 ✏2 / +8 / -8 + "2小时前" + "Push at Merge pull request #685..." + 提交描述）+ 文件分组（标题"README-EN.md"灰字 + `</>` 文件卡）+ "加载完了哟" |

### 5. 主 Tab（HomePage 三 tab）

| 文件 | 场景 | 关键 UI 元素 |
|---|---|---|
| [rn-DynamicTabPage.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-DynamicTabPage.jpg) | 动态 tab | 标题"动态" + 右上 search icon + 事件卡列表（avatar + 用户名 + 时间右对齐 + "started ..."/"Push to..."/"merged pull request..."/"Made ... public"）+ 主 tab bar 三键（拍立得/动态/我的） |
| [rn-TrendTabPage.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-TrendTabPage.jpg) | 推荐 tab | 标题"推荐" + 右上 search icon + 双 dropdown（今日 ▼ / 全部 ▼）+ trending 卡（avatar + 仓库名 + 右上语言 + author + desc + ⭐总/🍴总 + "N stars today"）|
| [rn-MyTabPage.jpg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn/rn-MyTabPage.jpg) | 我的 tab | 标题"我的" + 右上 search icon + 大头像 + 用户名 + 显示名 + 简介 + 位置 + 创建日期 + 5 列统计（仓库/粉丝/关注/星标/荣耀）+ 个人动态卡（贡献热力图）+ 事件流卡 |

## 字段对照（与 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets) 对齐）

| RN 视觉 | RN 来源（[constant.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js)） | OH 对应 |
|---|---|---|
| 主背景深灰 | mainBackgroundColor `#24292E` | GSYColor.mainBackground |
| 卡片白底 | cardWhite `#FFFFFF` | GSYColor.cardItemBackground |
| 主文字白色 | primaryTextColor `#FFFFFF` | GSYColor.primary |
| 次文字浅灰 | subTextColor `#8E909C` | GSYColor.subText |
| 浅灰底（搜索框/标签） | subLightTextColor `#E2E2E2` | GSYColor.subLightText |
| 主按钮蓝 | primaryGray `#FFFFFF`/链接 `#0366D6` | GSYColor.primaryGray |
| segment 选中黑底 | mainBackground 同色 | GSYColor.mainBackground |

## 后续比对约定

- OH 端真机截图统一放 `harness/regression/ui-parity/screenshots/<Page>/oh_<Page>_<vN>.png`
- 每页对比报告放 `harness/regression/ui-parity/<Page>.md`，含 § 截图对照（嵌入 RN+OH 缩略图）+ § 元素 diff 表 + § 修复 todo
- 全工程 OH ↔ RN 总览看板：[INDEX.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/INDEX.md)
