# 手工回归 — 登录与会话

### MC-AUTH-01：PAT 登录（首选路径）
- 前置：拥有有效 GitHub Personal Access Token（scope ≥ user, repo）。
- 步骤：
  1. 启动 App，等待 WelcomePage 跳到 LoginPage。
  2. 点击 "Login with Token" 入口。
  3. 在弹出的 Modal 中粘贴 PAT。
  4. 点击 OK。
  5. 观察主 Tab 是否进入。
  6. MyPage 是否显示 PAT 对应用户的统计信息。
- 期望：≤ 500ms 完成 `/user` 校验 → 自动跳 MainTabs；preferences 写入成功。

### MC-AUTH-02：PAT 登录失败兜底
- 前置：使用错误 token（如随便填 `ghp_invalid_xxx`）。
- 步骤：
  1. 在 LoginPage 点 Login with Token。
  2. 粘贴错误 token → OK。
  3. 等待响应。
- 期望：弹 Toast 提示无效 token；保持在 LoginPage；preferences 中 token 未被污染。

### MC-AUTH-03：OAuth Web 登录
- 前置：未登录、网络通畅。
- 步骤：
  1. LoginPage 点 "OAuth 登录"。
  2. LoginWebPage 加载 GitHub 授权页。
  3. 输入账号密码并授权（如已是 Web 登录态则直接同意）。
  4. 等待回调 `gsygithub://authed?code=...`。
  5. 观察是否自动跳回 LoginPage 并切到 MainTabs。
- 期望：完整链路成功；写入 preferences；MyPage 显示用户信息。

### MC-AUTH-04：自动登录（持久态）
- 前置：已用 PAT/OAuth 完成一次登录。
- 步骤：
  1. 杀掉 App。
  2. 重新启动。
  3. 观察 WelcomePage → MainTabs 直跳，不出现 LoginPage。
- 期望：≤ 1s 内进入主 Tab，并在后台静默刷新 UserInfo。

### MC-AUTH-05：退出登录
- 步骤：
  1. 进入 SettingPage。
  2. 点击"退出登录"。
- 期望：返回 LoginPage；再次启动 App 仍是 LoginPage（preferences token + UserInfo 已清）。

### MC-AUTH-06：401 兜底
- 前置：登录后手动撤销 GitHub 端 PAT（在 GitHub Settings → Developer settings 删除）。
- 步骤：触发任意需要登录的请求（如下拉刷新动态）。
- 期望：弹 Toast 提示会话失效，自动清 token + 跳回 LoginPage。
