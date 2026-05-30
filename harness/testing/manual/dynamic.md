# 手工回归 — 动态 / 通知

### MC-DYN-01：动态首屏加载
- 前置：已登录，账号至少关注 5 个用户或 5 个仓库。
- 步骤：
  1. 进入 MainTabs。
  2. 切到 Dynamic Tab。
  3. 观察首屏渲染时间。
- 期望：缓存 / 骨架屏 ≤ 200ms 出现；网络成功后 ≤ 1s 替换列表。

### MC-DYN-02：下拉刷新
- 步骤：
  1. 在 DynamicPage 顶部下拉。
  2. 等待 Refresh 完成。
- 期望：列表更新到最新；下拉指示器有动画；离线时弹 Toast 提示。

### MC-DYN-03：上拉加载更多
- 步骤：
  1. 在 DynamicPage 列表向下滚动到底部。
  2. 等待 onReachEnd 触发加载。
- 期望：底部出现 loading；加载新一页拼接到尾部；连续滚动可至少加载 3 页。

### MC-DYN-04：列表项跳转
- 步骤：
  1. 找一条 PushEvent → 点击。
  2. 找一条 IssuesEvent → 点击。
  3. 找一条 ForkEvent → 点击。
- 期望：分别跳到 RepositoryDetailPage / IssueDetailPage / RepositoryDetailPage（fork 仓库），返回后列表位置保留。

### MC-DYN-05：通知列表
- 步骤：
  1. 进入 NotifyPage。
  2. 点单条"标记已读"。
  3. 点"全部已读"。
- 期望：UI 即时更新；离线时仍可走缓存读取上一次列表。

### MC-DYN-06：弱网兜底
- 前置：开飞行模式。
- 步骤：杀掉 App → 重启 → 进入 DynamicPage。
- 期望：从 ReceivedEvent 表读到上一次缓存列表，并在顶部 Toast 提示离线。

### MC-DYN-07：切语言重渲染
- 步骤：进入 SettingPage → 切换中英文 → 返回 DynamicPage。
- 期望：动态卡片内文案（如 "Push to" / "Star 了"）随语言变化；时间格式同步。
