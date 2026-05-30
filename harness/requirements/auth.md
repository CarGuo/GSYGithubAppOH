# 需求 — 登录与会话

## 用户故事
- **US-AUTH-1**：作为用户，我希望使用 GitHub Personal Access Token（PAT）一键登录，作为首选方式（粘贴即用，无需走 Web）。
- **US-AUTH-2**：作为用户，当我没有 PAT 时，可以走 OAuth 网页登录（Web 组件），授权后通过 `gsygithub://authed?code=xxx` 深链回到 App。
- **US-AUTH-3**：作为用户，我希望应用记住我的登录态，下次自动进入主界面（preferences 持久化 token）。
- **US-AUTH-4**：作为用户，我可以在"设置"中退出登录，并清除本地缓存（preferences + relationalStore）。

## 关键路径与文件
- LoginPage（PAT + OAuth 入口，计划）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/LoginPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/LoginPage.js)
- LoginWebPage（OAuth Web）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/LoginWebPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/LoginWebPage.js)
- 启动判定：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WelcomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WelcomePage.ets)，蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WelcomePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WelcomePage.js)
- UserDao（loginInWithToken / loginInWithCode / loginOut / refreshUserInfo）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/userDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/userDao.js)
- 深链：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/AuthDeepLinkBus.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/AuthDeepLinkBus.ets) + [https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/module.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/module.json5) skills 注册 `gsygithub://authed`。
- CLIENT_ID / SECRET：放在不入库的本地配置（参考 RN 端 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/config/index.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/config/index.js)）。

## 验收标准
1. PAT 登录：粘贴有效 token 后 ≤ 500ms 内 `/user` 校验通过 → 写 preferences `TOKEN_KEY` → 跳 MainTabs。无效 token 弹 Toast 并保持在 LoginPage。
2. OAuth：点击 OAuth 按钮 → LoginWebPage 加载 `https://github.com/login/oauth/authorize` → 用户授权 → 回调 `gsygithub://authed?code=...` → AuthDeepLinkBus 派发到 LoginPage → 换 access_token → 写 preferences → 跳 MainTabs。
3. 启动自动登录：有 token 时 WelcomePage 直接进 MainTabs，期间在后台调 `refreshUserInfo` 刷新缓存。
4. 退出登录：清 preferences `TOKEN_KEY` / `USER_INFO` + relationalStore deleteAll → emitter.emit(`LOGOUT`) → 跳 LoginPage。
5. 401 兜底：HttpClient 收到 401 全局清 token + 跳 LoginPage，确保下次启动无残留请求 401。

## 测试矩阵
- 单测：`UserDao.test.ets`（mock HttpClient，覆盖 token 解析、401、loginOut 清理路径）。
- 组件测：`LoginPage.test.ets`（hypium，验证 PAT 输入框 secureTextEntry、OAuth 按钮可点、Modal 对话框可关闭）。
- E2E：`flows/login-if-needed.spec.ets`（已登录自动跳过登录页）+ `login.spec.ets`（PAT 登录闭环）。
- 手工：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/auth.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/auth.md)。
