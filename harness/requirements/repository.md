# 需求 — 仓库

## 用户故事
- **US-REPO-1**：作为用户，我可以查看仓库详情，包含 README、Star/Fork/Watch 数、Owner、Topics、Pulse 摘要。
- **US-REPO-2**：我可以浏览仓库文件树并查看代码（语法高亮）。
- **US-REPO-3**：我可以查看仓库 Issue / PR 列表，并对自己的 Issue 进行评论 / 关闭。
- **US-REPO-4**：我可以查看 Pulse、Release、Activity（提交历史 / Push 详情）。
- **US-REPO-5**：我可以 Star / Unstar、Watch / Unwatch、Fork，状态即时反映在 UI。

## 关键路径与文件
- 详情页：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailPage.js)
- 文件页：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailFilePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailFilePage.js)
- 活动页：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailActivityPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailActivityPage.js)
- Issue 列表：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryIssueListPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryIssueListPage.js)
- Issue 详情：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/IssueDetailPage.js)
- 代码 / Md：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/CodeDetailPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/CodeDetailPage.js) + [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js)
- Push 详情：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PushDetailPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PushDetailPage.js)
- Release：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ReleasePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ReleasePage.js)
- 数据层：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/repositoryDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/repositoryDao.js) + [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/issueDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/issueDao.js)
- Pulse 解析：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/pulse/PulseUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/pulse/PulseUtils.js)

## 验收标准
1. 仓库详情进入 < 1s（缓存优先：先读 RepositoryDetail/RepositoryDetailReadme 表，触网后回写）。
2. 文件树点击进入子目录 / 代码页；代码页通过 Web + highlight.js + dracula 渲染并显示行号。
3. Issue 列表分页正确，支持过滤 open / closed / all；列表项缓存写入 RepositoryIssue 表。
4. Star / Watch / Fork 操作即时更新 UI 并通过 emitter 广播 `REFRESH_STAR_STATE`，写入 RepositoryStar/Watcher/Fork 表。
5. PushDetail 页显示完整提交 commit 列表（diff 可选展开）。

## 测试矩阵
- 单测：`HtmlUtils.test.ets`（getFullName / launchUrl / parseDiffSource 边界）；`RepositoryDao.test.ets`（mock HttpClient，关键解析路径）；`PulseUtils.test.ets`（fixture 解析）。
- 组件：`RepositoryHeader.test.ets`、`IssueItem.test.ets`、`RepositoryItem.test.ets`。
- E2E：`flows/repository.spec.ets`（进入仓库 → README → 文件树 → 代码页 → 返回）。
- 手工：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/repository.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/repository.md)。
