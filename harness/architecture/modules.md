# 模块清单（ArkUI / HarmonyOS）

> 蓝本：[https://github.com/CarGuo/GSYGithubApp/blob/master/harness/architecture/modules.md](https://github.com/CarGuo/GSYGithubApp/blob/master/harness/architecture/modules.md)。下表列出 ArkUI 端规划的目录映射，未实现的模块标 *计划*。

## entry/src/main/ets/pages（屏幕级 Page）

| 文件 | 域 | 对应 RN 蓝本 |
|---|---|---|
| WelcomePage.ets | 启动判定登录态 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WelcomePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WelcomePage.js) |
| LoginPage.ets *（计划）* | PAT + OAuth 入口 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/LoginPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/LoginPage.js) |
| LoginWebPage.ets *（计划）* | OAuth Web | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/LoginWebPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/LoginWebPage.js) |
| MainTabsPage.ets *（计划）* | Dynamic/Trend/Search/My | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/navigation/AppNavigator.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/navigation/AppNavigator.js) |
| RepositoryDetailPage.ets *（计划）* | 仓库详情 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailPage.js) |

> 维护原则：屏幕级文件放 `pages/`；可复用业务卡片放 `components/widget/`；纯 UI 组件放 `components/common/`。

## entry/src/main/ets/components

| 路径 | 类型 | 说明 |
|---|---|---|
| common/ *（计划）* | 通用 | Toast、Loading、ErrorView、CustomDialog、PullRefreshList |
| widget/ *（计划）* | 业务卡片 | EventItem / RepositoryItem / IssueItem / UserItem / SearchDrawerFilter |

## entry/src/main/ets/store *（计划）*
- 按域拆分 `EventStore.ets / IssueStore.ets / LoginStore.ets / RepositoryStore.ets / UserStore.ets`。
- 每个 store 类用 `@Observed` 装饰，被页面通过 `@ObjectLink` 引用；全局共享走 `AppStorage.SetOrCreate(...)`。
- 对应 RN 蓝本：[https://github.com/CarGuo/GSYGithubApp/blob/master/app/store/](https://github.com/CarGuo/GSYGithubApp/blob/master/app/store/)。

## entry/src/main/ets/dao *（计划，业务整合 + 缓存）*

| 文件 | 作用 | 对应 RN 蓝本 |
|---|---|---|
| db/Schema.ets | 24 张 relationalStore 表定义 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/db/index.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/db/index.js) |
| EventDao.ets | 用户/关注动态 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/eventDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/eventDao.js) |
| IssueDao.ets | Issue / Notification | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/issueDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/issueDao.js) |
| RepositoryDao.ets | 仓库详情 / 文件 / 提交 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/repositoryDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/repositoryDao.js) |
| UserDao.ets | 用户 / 登录 / Token | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/userDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/userDao.js) |

## entry/src/main/ets/net *（计划）*
- `HttpClient.ets`：`@ohos.net.http` 封装（鉴权头、错误码、重试、GraphQL）。对应 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/net/index.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/net/index.js)。
- `Address.ets`：API 常量。对应 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/net/address.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/net/address.js)。
- `NetCode.ets`：错误码 → 文案。对应 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/net/netwrokCode.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/net/netwrokCode.js)。

## entry/src/main/ets/utils *（计划）*

| 文件 | 作用 | RN 对应 |
|---|---|---|
| TimeUtil.ets | 时间转化 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/timeUtil.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/timeUtil.js) |
| HtmlUtils.ets | Markdown→HTML（dracula） | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js) |
| EventUtils.ets | 动态文案 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/eventUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/eventUtils.js) |
| FilterUtils.ets | 搜索过滤 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/filterUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/filterUtils.js) |
| IssueUtils.ets | issue 工具 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/issueUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/issueUtils.js) |
| TrendingUtil.ets | Trending HTML 解析 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/trending/TrendingUtil.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/trending/TrendingUtil.js) |
| Logger.ets | hilog + 环形缓冲 | 新增（RN 端无统一） |
| ActionBus.ets | emitter 事件常量 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/actionUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/actionUtils.js) |

## entry/src/main/ets/style *（计划）*
- `Constant.ets`：颜色 / 尺寸 / 事件名。对应 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js)。
- `Theme.ets`：通用样式 / 间距。
- `lottie/`：Lottie JSON 资源。

## entry/src/main/ets/i18n *（计划）*
- `I18n.ets` 自研：读 `ResourceManager` + preferences 当前语言；导出 `I18n(key)` + `changeLocale(language)`。对应 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/i18n.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/i18n.js)。

## entry/src/main/ets/navigation *（计划）*
- `NavService.ets`：脱离组件触发 NavPathStack 跳转。对应 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/navigation/NavigationService.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/navigation/NavigationService.js)。
- `Routes.ets`：路由名常量。

## entry/src/main/ets/ai-debug *（计划）*
- `DebugDumper.ets`：dump 当前路由栈 / store / 最近 N 条 http / 控制台到 `internal://app/files/ai-debug/<ts>.json`，触发方式见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/ai-auto-debug.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/ai-auto-debug.md)。

## 资源
- 图标：`entry/src/main/resources/base/media/*.svg`（替代 react-native-vector-icons）。
- 字符串：`entry/src/main/resources/base/element/string.json` + `zh_CN/element/string.json`。
- 颜色：`entry/src/main/resources/base/element/color.json`。
- 主页签：`entry/src/main/resources/base/profile/main_pages.json`。
