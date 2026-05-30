# 手工回归 — 仓库

### MC-REPO-01：仓库详情进入
- 步骤：
  1. 在搜索 / Trending / 动态中点击一个仓库（如 `CarGuo/GSYGithubAppOH`）。
  2. 等待进入 RepositoryDetailPage。
- 期望：≤ 1s 显示头部（缓存优先）；后台触网后无感更新 Star/Fork/Watch 数。

### MC-REPO-02：README 渲染
- 步骤：在仓库详情页向下滚动看 README。
- 期望：Markdown 通过 Web 组件渲染；代码块走 highlight.js + dracula 主题；图片可加载；点链接走 `gsygithub://` 拦截 → 跳详情。

### MC-REPO-03：文件树 → 代码页
- 步骤：
  1. 切到 File Tab。
  2. 进入子目录。
  3. 打开任意源码文件。
- 期望：CodeDetailPage 渲染语法高亮代码 + 行号；左滑右滑可看长行。

### MC-REPO-04：Issue 列表
- 步骤：
  1. 切到 Issue Tab。
  2. 切换 open / closed / all 过滤。
  3. 上拉加载更多。
- 期望：每种状态下列表正确；分页连续；点击进入 IssueDetailPage 看到 body + comments。

### MC-REPO-05：Star / Watch / Fork
- 步骤：
  1. 在仓库详情页点 Star → 再点 Unstar。
  2. 点 Watch / Unwatch。
  3. 点 Fork（小心：会真 fork 一个仓库）。
- 期望：UI 即时反映 + Toast 成功；emitter 广播 `REFRESH_STAR_STATE`，MyPage 的 Stars 列表实时刷新。

### MC-REPO-06：Activity / 提交详情
- 步骤：
  1. 切到 Activity Tab。
  2. 点击任一 commit。
- 期望：进入 PushDetailPage；diff 可分组展开；返回后位置保留。

### MC-REPO-07：Pulse 摘要
- 步骤：进入仓库详情 → 找到 Pulse 入口（详情页内嵌或独立 Tab）。
- 期望：显示最近 N 周的 commit / contributor 分布；离线下走 RepositoryPulse 表缓存。

### MC-REPO-08：Release 列表
- 步骤：进入 Release 入口。
- 期望：显示 release 列表 + 更新日志（Markdown 渲染）+ 下载 asset 按钮（调用 @ohos.request）。
