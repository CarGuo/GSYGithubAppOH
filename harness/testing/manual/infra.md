# 手工回归 — 基础设施

### MC-INF-01：i18n 切换
- 步骤：
  1. SettingPage 切中文 → 全 App 浏览一遍主要 Tab。
  2. 再切英文 → 浏览一遍。
- 期望：所有静态文案、时间格式、空态、Toast 文案均切换；无残留旧语言。

### MC-INF-02：主题色与 styles 常量
- 步骤：进入 RepositoryDetailPage / IssueItem / EventItem。
- 期望：色值与 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/modules.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/modules.md) 中 style 对应；语言色块、状态色一致。

### MC-INF-03：preferences 持久化
- 步骤：
  1. 切语言 → 杀进程 → 重启。
  2. 退出登录 → 杀进程 → 重启。
- 期望：语言保留；token 已清。

### MC-INF-04：relationalStore 缓存（24 表）
- 步骤：
  1. 在线状态下浏览动态 / Trending / 一个仓库详情 + Issue 列表 + Issue 详情。
  2. 飞行模式 → 杀进程 → 重启 → 重新走一遍同样路径。
- 期望：离线下命中 ReceivedEvent / TrendRepositoryV2 / RepositoryDetail / RepositoryDetailReadme / RepositoryIssue / IssueDetail / IssueComment 缓存。

### MC-INF-05：网络层（@ohos.net.http）
- 步骤：在 SettingPage 临时改 baseUrl 或切换代理 → 触发任一请求。
- 期望：拦截器记录 hilog；401 触发清 token；网络错误统一 Toast。

### MC-INF-06：日志（hilog）
- 步骤：连接 hdc → 执行 `hdc shell hilog -P gsygithub`。
- 期望：domain 0x0666 下能看到关键事件日志；错误堆栈完整。

### MC-INF-07：深链 gsygithub://authed
- 步骤：在浏览器 / 短信 / 测试 App 触发 `gsygithub://authed?code=xxx`。
- 期望：拉起 GSYGithubAppOH，AuthDeepLinkBus 派发 code，LoginWebPage 完成 OAuth 闭环。

### MC-INF-08：AI Debug Dump
- 步骤：长按 LoginPage logo 2s（或 About 页连点版本号 7 次）。
- 期望：在 `internal://app/files/ai-debug/<ts>.json` 生成 dump，可用 `hdc file recv` 拉取（详见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/ai-auto-debug.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/ai-auto-debug.md)）。

### MC-INF-09：Markdown 渲染（HtmlUtils + Web）
- 步骤：在 README / Issue body / Release note 中验证：标题 / 列表 / 代码块 / 链接 / 图片 / 表情。
- 期望：dracula 主题；图片可加载；点链接走 `gsygithub://` 拦截分发。
