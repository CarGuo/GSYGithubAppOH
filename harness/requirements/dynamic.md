# 需求 — 动态 / 通知

## 用户故事
- **US-DYN-1**：作为登录用户，我可以在动态 Tab 看到关注用户、关注仓库的事件流，按时间倒序。
- **US-DYN-2**：作为用户，我可以下拉刷新（Refresh）、上拉加载更多（List.onReachEnd）。
- **US-DYN-3**：作为用户，我可以查看 Notify（评论、Issue、Mention）通知列表，并标记单条 / 全部已读。
- **US-DYN-4**：在弱网下应能从 relationalStore 缓存读取上一次内容，离线可见。

## 关键路径与文件
- DynamicPage（计划）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/DynamicPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/DynamicPage.js)
- NotifyPage（计划）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/NotifyPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/NotifyPage.js)
- EventDao（getNewsEvent / getUserEvent / 写 ReceivedEvent / UserEvent 表）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/eventDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/eventDao.js)
- IssueDao Notification 部分：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/issueDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/issueDao.js)
- EventUtils（文案 / 跳转目标）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/eventUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/eventUtils.js)
- 通用列表：`Refresh + List + ListItem` 范式（替代 RN 的 PullLoadMoreListView）。

## 验收标准
1. 进入 DynamicPage ≤ 200ms 显示缓存 / 骨架屏，≤ 1s 完成首次 `received_events` 刷新并替换列表。
2. 列表项点击根据 type 跳对应详情页（仓库 / Issue / PR / User），EventUtils 输出准确文案与跳转目标。
3. NotifyPage 标记单条 / 全部已读后立即更新 UI；离线可走 relationalStore 缓存策略。
4. 切换语言后通过 `REFRESH_LANGUAGE` 自动重渲染卡片文案。

## 测试矩阵
- 单测：`EventUtils.test.ets`（文案模板、跳转目标）、`EventDao.test.ets`（mock HttpClient，分页参数 / 解析 / 入库）。
- 组件：`EventItem.test.ets`（hypium，覆盖头像 / 文案 / 时间 / 点击跳转）。
- E2E：`flows/dynamic.spec.ets`（登录后进入 DynamicPage，验证首屏与下拉刷新）。
- 手工：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/dynamic.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/dynamic.md)。
