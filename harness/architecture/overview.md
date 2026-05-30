# 架构总览（ArkUI / HarmonyOS）

## 1. 分层

```
┌──────────────────────────────────────────────────────┐
│  UI 层 (entry/src/main/ets/pages, components)        │
├──────────────────────────────────────────────────────┤
│  导航层 (Navigation + NavPathStack, Tabs, SideBar)   │
├──────────────────────────────────────────────────────┤
│  状态层 (@Observed/@ObjectLink + AppStorage, store/) │
├──────────────────────────────────────────────────────┤
│  数据层 (dao/ + net/ + relationalStore + preferences)│
├──────────────────────────────────────────────────────┤
│  系统层 (HarmonyOS API：Web/request/share/picker…)   │
└──────────────────────────────────────────────────────┘
```

- **UI 层**：ArkTS / ArkUI 声明式组件；通用控件入 `components/common`，业务卡片入 `components/widget`，屏幕级 ETS 入 `pages/`。
- **导航层**：`Navigation + NavPathStack`（页面栈）+ `Tabs`（底部 Tab）+ `SideBarContainer`（Drawer，position End）。
- **状态层**：`@Observed` + `@ObjectLink` 拆分领域 store 类，全局轻量数据用 `AppStorage`。
- **数据层**：`@ohos.net.http` 统一封装；`@ohos.data.relationalStore` 持久化 24 张离线表；`@ohos.data.preferences` 存 token/语言/偏好。
- **系统层**：`Web()` 渲染 Markdown / OAuth；`@ohos.request` 下载；`@ohos.systemShare` 分享；`@ohos.file.picker` 选图；`@ohos.pasteboard` 剪贴板；`@ohos.events.emitter` 跨页桥。

## 2. 关键依赖

| 依赖 | 作用 | 备注 |
|---|---|---|
| @ohos.net.http | HTTP / GraphQL | 替代 RN fetch |
| @ohos.data.relationalStore | 关系型数据库 | 替代 Realm，对齐 24 张表 |
| @ohos.data.preferences | KV 存储 | 替代 AsyncStorage |
| @ohos.web.webview / Web() | WebView | 渲染 Markdown + OAuth |
| @ohos.events.emitter | 事件总线 | 替代 actionUtils.refreshHandler |
| @ohos.hilog | 日志 | Logger 底座 |
| @ohos/lottie | 动画 | 启动 / 空态动画 |

## 3. 配置入口
- 应用：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/AppScope/app.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/AppScope/app.json5)（bundleName=cn.gsy.githubapp）
- 模块：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/module.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/module.json5)（OAuth scheme：gsygithub://authed）
- 工程：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/build-profile.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/build-profile.json5)（compatibleSdkVersion 6.1.0(23)，runtimeOS HarmonyOS）
- 入口：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets)
- 启动页：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WelcomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WelcomePage.ets)
- 深链总线：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/AuthDeepLinkBus.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/AuthDeepLinkBus.ets)
- 签名：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/README.md)

## 4. 启动流程
1. EntryAbility `onCreate` → 解析启动参数 / 深链（gsygithub://authed?code=...）→ 写入 [AuthDeepLinkBus.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/AuthDeepLinkBus.ets)。
2. `onWindowStageCreate` → loadContent('pages/WelcomePage')。
3. WelcomePage 读 preferences 中的 token / language → 决定路由：
   - 无 token → LoginPage（PAT 优先，OAuth Web 兜底）
   - 有 token → 调用 `userDao.refreshUserInfo` → MainTabs（Dynamic / Trend / Search / My）。
4. 业务页通过 store 类触发 dao.method() → `@ohos.net.http` 请求 → relationalStore 缓存 + UI 刷新。

## 5. 关键风险点
- HarmonyOS API 版本（6.1.0/23）与 ArkUI 声明式约束严格，三方包须确认 `compatibleSdkVersion` 兼容。
- relationalStore 不支持 Realm 风格的对象图，列要扁平化为 TEXT/INTEGER；JSON 大字段统一存 `data TEXT`。
- Web 组件加载 highlight.js / dracula 必须使用 `$rawfile()` 协议或 base64 注入，避免跨域。
- OAuth 回调 scheme 与 [module.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/module.json5) skills 一致（`gsygithub://authed`）。
