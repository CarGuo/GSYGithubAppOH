# ADR-0003：RN → ArkUI 技术栈映射

- **状态**：Accepted
- **日期**：2026-05-24

## 背景
- GSYGithubAppOH 复刻 RN 端 GSYGithubApp（[https://github.com/CarGuo/GSYGithubApp/blob/master/](https://github.com/CarGuo/GSYGithubApp/blob/master/)）的全部业务功能。
- 需要明确每一个 RN 概念在 ArkUI / HarmonyOS 上的对位实现，避免 AI 与新成员重复试错。

## 决策

| RN 端 | ArkUI / HarmonyOS 对位 | 备注 |
|---|---|---|
| Redux + redux-thunk | @Observed / @ObjectLink + AppStorage（按域拆 store 类） | 见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0002-arkui-state-mgmt-choice.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0002-arkui-state-mgmt-choice.md) |
| Realm | @ohos.data.relationalStore | 24 张表见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0004-persistence-choice.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0004-persistence-choice.md) |
| AsyncStorage | @ohos.data.preferences | token / language / recentSearch |
| fetch / 自封 net/index.js | @ohos.net.http | 统一 HttpClient.ets，鉴权头 + 401 拦截 + GraphQL |
| react-native-webview | Web() + @ohos.web.webview | Markdown / OAuth |
| react-navigation Stack/Tab | Navigation + NavPathStack + Tabs | 路由名常量化在 navigation/Routes.ets |
| react-navigation Drawer | SideBarContainer（position End） | 搜索 Drawer 与设置侧边栏复用 |
| BottomTabNavigator | Tabs + TabBar 自定义 | Dynamic / Trend / Search / My |
| react-i18next | ResourceManager + 自研 I18n() | 切语言 emitter `REFRESH_LANGUAGE` |
| Lottie (react-native-lottie) | @ohos/lottie | 启动动画 / 空态 |
| react-native-vector-icons | SVG 静态资源 + Image() | resources/base/media/*.svg |
| AppState / Linking | @ohos.application + @ohos.events.emitter | 深链统一在 EntryAbility |
| Alert | AlertDialog / promptAction | 二次确认 |
| Toast (react-native-root-toast) | promptAction.showToast | 与系统一致 |
| react-native-image-crop-picker | @ohos.file.picker | 头像 / 上传 |
| react-native-fs / RNFetchBlob | @ohos.request + @ohos.file.fs | 下载 + 本地读写 |
| 分享（react-native-share） | @ohos.systemShare | 兜底剪贴板 |
| Clipboard | @ohos.pasteboard | 复制 token / URL |
| Jest + RNTL + Maestro | hypium 单测 / 组件 / E2E | 见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/strategy.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/strategy.md) |
| patches/ + patch-package | DevEco 模块定制 + ohpm overrides | ohpm 体系不一样 |
| MainApplication / AppDelegate | EntryAbility | 入口 ability，处理深链 |
| .env / config/index.js | resources/base/element + 本地 ignore 文件 | CLIENT_ID / SECRET 不入库 |

## 备选方案
- 直接复用 ReactNative-Harmony 项目把 RN 跑在鸿蒙：与"原生 ArkUI 体验"相悖，否决。
- 用 Flutter HarmonyOS：脱离 RN 蓝本生态，无法复用现有 utils 解析逻辑（HTML/Trending），否决。

## 影响
- 任何 RN 端新增的概念需要先回到本表加一行映射，再开始实现。
- RN 端代码引用必须用公开 GitHub 链接或项目相对路径，避免相对路径错位。
