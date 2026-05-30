# 需求 — 搜索

## 用户故事
- **US-SCH-1**：作为用户，我可以搜索仓库 / 用户 / Issue，并通过 Drawer 设置过滤条件（语言、排序、时间）。Drawer 走 `SideBarContainer`（position End）。
- **US-SCH-2**：搜索历史可以快速复用（preferences 持久化最近 N 条）。

## 关键路径与文件
- SearchPage（计划）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/SearchPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/SearchPage.js)
- 抽屉过滤：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/SearchDrawerFilter.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/SearchDrawerFilter.js)
- 工具：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/filterUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/filterUtils.js)

## 验收标准
1. 输入关键字后 300ms 防抖触发请求；中途变更关键字会取消上一次未完成请求（或忽略其结果）。
2. 切换 Tab（仓库 / 用户 / Issue）时维护各自独立的状态与分页位置。
3. Drawer 中改动过滤项后立刻发起新请求并合并到 URL/参数（FilterUtils 拼接）。
4. 历史记录最多 20 条，FIFO 淘汰；点击历史回填关键字 + 触发搜索。

## 测试矩阵
- 单测：`FilterUtils.test.ets`（参数拼接、空值忽略、特殊字符 URL encode）。
- 组件：`SearchDrawerFilter.test.ets`（hypium，覆盖 Drawer 切换 / 选项联动 / 重置）。
- 手工：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/search.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/search.md)。
