# 关键数据流（ArkUI / HarmonyOS）

> 蓝本：[https://github.com/CarGuo/GSYGithubApp/blob/master/harness/architecture/data-flow.md](https://github.com/CarGuo/GSYGithubApp/blob/master/harness/architecture/data-flow.md)。

## 1. 启动 / 登录

```
EntryAbility.onCreate ──► 解析深链 (gsygithub://authed?code=...) ──► AuthDeepLinkBus
        │
        ▼
WelcomePage ──► preferences.get(TOKEN_KEY)
        │
        ├── 无 Token ──► LoginPage
        │                  ├── PAT 登录（优先）：填 Token → UserDao.loginInWithToken → /user 校验 → 写 preferences
        │                  └── OAuth Web（兜底）：LoginWebPage(Web 组件) → 跳 GitHub → callback gsygithub://authed
        │                                          → AuthDeepLinkBus.code → /login/oauth/access_token → 写 preferences
        │                  ──► UserDao.refreshUserInfo ──► AppStorage.userInfo ──► MainTabsPage
        └── 有 Token ──► UserDao.refreshUserInfo ──► MainTabsPage
```

- Token 存放：`@ohos.data.preferences`（key 与 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0004-persistence-choice.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0004-persistence-choice.md) 一致）。
- 401 拦截：`HttpClient` 统一处理 → 清 preferences token + 跳 LoginPage。
- 深链桥：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/AuthDeepLinkBus.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/auth/AuthDeepLinkBus.ets)。

## 2. 列表分页（Refresh + List.onReachEnd 范式）

```
Page state (@State items) ◄── store 类 (@Observed) ◄── dao.method(page) ◄── HttpClient
                                       ▲
                                       │
                                   relationalStore 缓存合并
```

- 通用约定：`Refresh` 包裹 `List`；`List.onReachEnd` 触发 `loadMore`；`onRefreshing` 触发 `pullRefresh`。
- 缓存优先策略：先读 relationalStore → 立刻渲染 → 异步触网 → 成功后 deleteAll + insert + 更新 store。

## 3. Markdown / 代码渲染

```
README / Issue Body ──► HtmlUtils.generateMd2Html ──► Web($rawfile('md.html')) ──► dracula 主题渲染
```

- 关键文件：`utils/HtmlUtils.ets`（待建），与 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js) 行为对齐。
- Web 资源：`entry/src/main/resources/rawfile/md.html` + `highlight.min.js` + `dracula.css`（本地内置，不走 CDN，避免内网阻塞）。
- 链接转换：自定义 scheme `gsygithub://` 在 Web 的 `onLoadIntercept` 中拦截 → 由 NavService 解析跳详情页。

## 4. 跨页刷新桥
- 工具：`@ohos.events.emitter`。
- 事件常量集中在 `utils/ActionBus.ets`：`REFRESH_LANGUAGE` / `REFRESH_NOTIFY` / `REFRESH_STAR_STATE` / `LOGOUT` 等。
- 用法：`emitter.on({ eventId: REFRESH_LANGUAGE }, cb)` / `emitter.emit({ eventId: REFRESH_LANGUAGE })`。
- 对照 RN 端 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/actionUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/actionUtils.js) 的 `getRefreshHandler()`。

## 5. 国际化
- 初始化：`I18n.ets` 读 preferences 中 `language`，配合 `ResourceManager` 取值。
- 切换：`changeLocale(lang)` → preferences.put → emitter.emit(`REFRESH_LANGUAGE`) → 各 Page 在 `aboutToAppear` 重新渲染。
- 对照 RN 端 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/i18n.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/i18n.js)。

## 6. 离线缓存
- relationalStore 24 张表 schema 见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0004-persistence-choice.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0004-persistence-choice.md)。
- 通用列：`fullName TEXT PRIMARY KEY`、`data TEXT`（JSON）、`updateAt INTEGER`。
- 读：`store.querySql('SELECT data FROM ... WHERE fullName=?', [...])` → JSON.parse。
- 写：`deleteAll + batchInsert`，事务包裹。
