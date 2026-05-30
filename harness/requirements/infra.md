# 需求 — 基础设施

## 域

### 1. 国际化 (i18n)
- 入口：`utils/I18n.ets`（自研），结合 `ResourceManager` + preferences 当前语言。
- 关键 API：`I18n(key)` / `changeLocale(language)`。
- 资源：`entry/src/main/resources/base/element/string.json` + `entry/src/main/resources/zh_CN/element/string.json`。
- 验收：切换语言后立即在所有 Page 生效；通过 emitter `REFRESH_LANGUAGE` 触发各 Page 重渲染。
- 蓝本：[https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/i18n.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/i18n.js)。

### 2. 主题 / 样式常量
- `style/Constant.ets`：颜色（primary、actionBlue、miWhite…）、尺寸（tabBarHeight、screenWidth、drawerWidth）、emitter 事件名。
- `style/Theme.ets`：通用 padding / margin / border。
- 验收：所有页面颜色 / 字号 / 间距均使用常量；禁止硬编码 16 进制色值。
- 蓝本：[https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js)。

### 3. 缓存与数据库
- relationalStore Schema：见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0004-persistence-choice.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0004-persistence-choice.md) 的 24 张表 CREATE TABLE 草案。
- preferences：`token` / `language` / `recentSearch` / `userInfo`（轻量序列化）。
- 验收：清缓存功能必须清空 24 张 relationalStore 表 + 部分非敏感 preferences（保留 token 直到主动登出）。
- 蓝本：[https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/db/index.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/db/index.js)。

### 4. 网络层
- `net/HttpClient.ets`：`@ohos.net.http` 封装、鉴权头、错误码映射、GraphQL 通道。
- `net/Address.ets`：API base url、graphic host。
- `net/NetCode.ets`：错误码 → 文案。
- 验收：401 全局拦截清 token；网络异常按 NetCode 弹 Toast。

### 5. 日志 / 错误
- `utils/Logger.ets`：基于 `@ohos.hilog` 封装 + 环形缓冲（保留最近 500 条）。
- 生产 sink（计划）：dump 到 `internal://app/files/ai-debug/<ts>.log`，配合 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/ai-auto-debug.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/ai-auto-debug.md)。

### 6. 深链
- 入口：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/AuthDeepLinkBus.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/AuthDeepLinkBus.ets)。
- scheme：`gsygithub://`。注册：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/module.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/module.json5) `skills.uris`。
- 用途：OAuth callback `gsygithub://authed?code=xxx`、Markdown 内链跳转。

### 7. AI Debug
- DebugDumper（计划）：长按 logo / 摇一摇触发 → dump 路由栈 / store 快照 / 最近 N 条 http / 控制台日志到 JSON 文件，hdc file recv 取出。
- 详见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/ai-auto-debug.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/ai-auto-debug.md)。

## 验收测试
- 单测：`TimeUtil.test.ets`、`HtmlUtils.test.ets`、`Logger.test.ets`。
- 手工：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/infra.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/infra.md)。
