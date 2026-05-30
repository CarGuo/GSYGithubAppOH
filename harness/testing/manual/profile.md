# 手工回归 — 个人中心

### MC-PRF-01：MyPage 基本信息
- 前置：已登录。
- 步骤：切到 My Tab。
- 期望：显示头像 / login / followers / following / 公司 / 简介；离线下从 UserInfo 表读缓存。

### MC-PRF-02：Stars / Repos 列表
- 步骤：
  1. 进入 MyPage 的 Stars 入口。
  2. 上拉分页。
  3. 点任一仓库进入详情。
- 期望：列表分页流畅；缓存命中 UserStared / UserRepos 表。

### MC-PRF-03：他人主页（PersonPage）
- 步骤：
  1. 在动态 / Issue / 仓库 contributor 中点头像。
  2. 进入 PersonPage。
  3. 切换 Repos / Stars / Followers / Following Tab。
- 期望：头像 / 资料 / Tab 列表均可加载；离线时从 UserFollower / UserFollowed / UserStared / UserRepos 读缓存。

### MC-PRF-04：关注 / 取关
- 步骤：在 PersonPage 点 Follow → Unfollow。
- 期望：UI 即时切换；emitter 广播 `REFRESH_FOLLOW_STATE`，MyPage 数字同步。

### MC-PRF-05：编辑资料（PersonInfoPage）
- 步骤：
  1. MyPage → 编辑资料。
  2. 修改 bio / company / location。
  3. 保存。
- 期望：调用 PATCH /user 成功后 Toast 提示 + 刷新 MyPage。

### MC-PRF-06：设置页
- 步骤：
  1. 进入 SettingPage。
  2. 切语言、切主题。
  3. 退出登录。
- 期望：preferences 写入正确；语言 / 主题立即生效。

### MC-PRF-07：关于页
- 步骤：进入 AboutPage。
- 期望：显示版本号、Logo、协议链接；连续点击版本号 7 次 → 触发 AI Debug Dump（参见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/ai-auto-debug.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/ai-auto-debug.md)）。

### MC-PRF-08：组织 / 通用 ListPage
- 步骤：
  1. PersonPage → Orgs。
  2. 点击进入组织详情（复用 ListPage / BasePersonPage）。
- 期望：成员 / 仓库列表正确；分页连续。
