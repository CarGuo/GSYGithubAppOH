# 需求 — Trending / 推荐

## 用户故事
- **US-TRD-1**：作为用户，我可以按"今日 / 本周 / 本月"和编程语言筛选 GitHub Trending 仓库（数据来自 trending HTML 抓取）。
- **US-TRD-2**：作为用户，我可以查看推荐位 / 编辑精选（RecommendPage），并跳转到对应仓库详情。

## 关键路径与文件
- TrendPage（计划）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/TrendPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/TrendPage.js)
- RecommendPage（计划）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RecommendPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RecommendPage.js)
- TrendingUtil（解析 since/lang 入口）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/trending/TrendingUtil.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/trending/TrendingUtil.js)
- GitHubTrending（HTML scraping 实现）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/trending/GitHubTrending.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/trending/GitHubTrending.js)
- 缓存表：`TrendRepositoryV2`（见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0004-persistence-choice.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0004-persistence-choice.md)）。

## 验收标准
1. 切换时间维度（today / weekly / monthly）/ 语言筛选时列表立即刷新；loading 期间不阻塞 UI（异步 + 骨架）。
2. Trending 抓取失败（HTML 结构变化 / 网络错误）显示空态 + 重试按钮，错误信息走 Toast。
3. 推荐位条目点击 → 跳 RepositoryDetailPage，参数携带 fullName。
4. 切语言时筛选下拉条与列表同步重渲染。

## 测试矩阵
- 单测：`TrendingUtil.test.ets`（用 fixture HTML 验证解析正确性，至少 3 条样本）。
- 组件：`TrendPage.test.ets`（hypium，mock 解析结果，验证筛选条交互）。
- 手工：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/trending.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/trending.md)。
