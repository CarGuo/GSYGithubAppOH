# M6 GitHub API 契约对比报告

> 实测时间：2026-05-24
> 鉴权方式：`Authorization: token <REDACTED>` + `User-Agent: GSYGithubAppOH/1.0` + `Accept: application/vnd.github+json`
> Token 仅通过环境变量 `GH_PAT` 注入 curl，**未落盘**；执行结束已 `unset GH_PAT && rm -f /tmp/gh_*.json`。
> 报告中所有 token 字面值统一以 `<REDACTED>` 占位。

## 1. 11 条 API 实测结果

| # | URL | HTTP | x-ratelimit-remaining / limit | 顶层结构 |
|---|-----|------|-------------------------------|----------|
| 1 | `GET https://api.github.com/user` | **200** | 4945 / 5000 | object |
| 2 | `GET https://api.github.com/users/CarGuo` | **200** | 4780 / 5000 | object |
| 3 | `GET https://api.github.com/repos/CarGuo/GSYGithubApp` | **200** | 4779 / 5000 | object |
| 4 | `GET https://api.github.com/repos/CarGuo/GSYGithubApp/readme` | **200** | 4778 / 5000 | object |
| 5 | `GET https://api.github.com/repos/CarGuo/GSYGithubApp/contents` | **200** | 4777 / 5000 | array(42) |
| 6 | `GET https://api.github.com/repos/CarGuo/GSYGithubApp/issues?per_page=2` | **200** | 4944 / 5000 | array(2) |
| 7 | `GET https://api.github.com/repos/CarGuo/GSYGithubApp/events?per_page=2` | **200** | 4943 / 5000 | array(2) |
| 8 | `GET https://api.github.com/users/CarGuo/received_events?per_page=2` | **200** | 4774 / 5000 | array(2) |
| 9 | `GET https://api.github.com/notifications?per_page=2` | **200** | 4942 / 5000 | array(2) |
| 10 | `GET https://api.github.com/search/repositories?q=harmonyos&per_page=2` | **200** | 29 / 30（search 桶） | object（含 items） |
| 11 | `GET https://github-contributions-api.jogruber.de/v4/CarGuo` | **200** | （第三方，无 GH rate-limit 头） | object |

> 注：rate-limit 字段名严格为 `x-ratelimit-remaining` / `x-ratelimit-limit`（小写）；search 接口使用独立的 `30/min` 桶。第三方贡献 API 不返回 GitHub rate-limit 头部。

---

## 2. 每条响应关键 key（前 10）

### #1 GET /user
`login, id, node_id, avatar_url, gravatar_id, url, html_url, followers_url, following_url, gists_url`

### #2 GET /users/CarGuo
`login, id, node_id, avatar_url, gravatar_id, url, html_url, followers_url, following_url, gists_url`
（与 UserDetail 重叠：`login/id/avatar_url/html_url`，扩展字段 `name/bio/company/location/email/blog/type/followers/following/public_repos/public_gists/created_at/updated_at` 也都存在）

### #3 GET /repos/CarGuo/GSYGithubApp
`id, node_id, name, full_name, private, owner, html_url, description, fork, url`
（`owner` 是嵌套对象：`login/id/avatar_url/html_url/...`）

### #4 GET /repos/.../readme
`name, path, sha, size, url, html_url, git_url, download_url, type, content`（含 `encoding`、`_links`）

### #5 GET /repos/.../contents（数组）
首元素 keys：`name, path, sha, size, url, html_url, git_url, download_url, type, _links`

### #6 GET /repos/.../issues?per_page=2（数组）
首元素 keys：`url, repository_url, labels_url, comments_url, events_url, html_url, id, node_id, number, title`
（含 `user/labels/state/locked/assignees/comments/created_at/updated_at/body` 等；`user` 为嵌套对象）

### #7 GET /repos/.../events?per_page=2（数组）
首元素 keys：`id, type, actor, repo, payload, public, created_at`
- `actor` keys：`id, login, display_login, gravatar_id, url, avatar_url`
- `repo` keys：`id, name, url`

### #8 GET /users/CarGuo/received_events?per_page=2（数组）
首元素 keys：`id, type, actor, repo, payload, public, created_at, org`
- `actor` / `repo` 同 #7

### #9 GET /notifications?per_page=2（数组）
首元素 keys：`id, unread, reason, updated_at, last_read_at, subject, repository, url, subscription_url`
- `subject` keys：`title, url, latest_comment_url, type`
- `repository` keys：`id, node_id, name, full_name, private, owner, html_url, description, fork, url`（`owner` 是嵌套对象）

### #10 GET /search/repositories?q=harmonyos&per_page=2
顶层：`total_count, incomplete_results, items`
- `items[0]` keys：`id, node_id, name, full_name, private, owner, html_url, description, fork, url`

### #11 GET https://github-contributions-api.jogruber.de/v4/CarGuo
顶层：`total, contributions`
- `contributions[0]` keys：`date, count, level`
- `total` 为对象：`{"<year>": <int>, ...}`

---

## 3. URL 拼装对比（Address.ets ↔ 实测 URL）

| 用例 | Address.ets 方法 | 生成 URL 模板 | 实测 URL | 一致性 |
|------|-----------------|--------------|---------|-------|
| #1 /user | `getMyUserInfo()` | `${HOST_API}user` | `https://api.github.com/user` | ✅ |
| #2 /users/CarGuo | `getUserInfo(login)` | `${HOST_API}users/{name}` | `.../users/CarGuo` | ✅ |
| #3 仓库详情 | `getReposDetail(o,n)` | `${HOST_API}repos/{o}/{n}` | `.../repos/CarGuo/GSYGithubApp` | ✅ |
| #4 readme | `getReposReadme(o,n,branch?)` / `getReadme(o,n)` | `${HOST_API}repos/{o}/{n}/readme[?ref=]` | `.../repos/CarGuo/GSYGithubApp/readme` | ✅ |
| #5 contents | `getReposFileDir(o,n,'',null)` | `${HOST_API}repos/{o}/{n}/contents/[?ref=]` | `.../contents` | ⚠️ 末尾会带斜杠 `contents/`（path='', refSuffix=''），仍可访问，但与"无尾斜杠"实测路径轻微不同 |
| #6 issues | `getRepositoryIssue(o,n,page,state?)` | `.../issues?state=all&sort=created&direction=desc&page=1&per_page=N` | `.../issues?per_page=2` | ⚠️ 强制带 `state/sort/direction`（功能等价但参数更多） |
| #7 仓库 events | `getRepositoryEvent(o,n,page,size)` | `.../repos/{o}/{n}/events?page=1&per_page=N` | `.../events?per_page=2` | ✅ |
| #8 received_events | `getReceivedEvent(user,page,size)` | `.../users/{name}/received_events?page=1&per_page=N` | `.../received_events?per_page=2` | ✅ |
| #9 notifications | `getNotifications(all,part,page,size)` 或 `getNotification()` | `.../notifications` 或 `.../notifications?all=...&participating=...&page=...&per_page=...` | `.../notifications?per_page=2` | ⚠️ 无与"仅 per_page"完全匹配的方法；`getNotification()` 无分页，`getNotifications()` 必带 `all/participating` |
| #10 search repos | `getSearchRepos(q,sort,page,size)` | `.../search/repositories?q={q}&sort=stars&page=1&per_page=N` | `.../search/repositories?q=harmonyos&per_page=2` | ⚠️ 强制带 `sort=stars`（Address.search 默认还会带 `sort=best%20match`，**GitHub 不支持该枚举值，可能 422**） |
| #11 contributions | `ContributionService.buildUrl(login)` | `https://github-contributions-api.jogruber.de/v4/{login}` | 同上 | ✅ |

---

## 4. Service 字段映射 ↔ 真实响应

### 4.1 UserService → `UserDetail`（store/UserDetailStore.ets）
- 直接消费 GET /users/{login}，字段全部为顶层平铺：`id/login/name/avatar_url/bio/company/location/email/blog/type/followers/following/public_repos/public_gists/created_at/updated_at`
- 真实响应包含上述全部字段 ✅
- `UserRepoItem.owner_login: string` —— **不一致**：GitHub `/users/{login}/repos` 与 `search/repositories` 的 `owner` 是嵌套对象 `{login, ...}`，并不返回扁平的 `owner_login`。代码层面仅作为接口声明，运行时 `as UserRepoItem` 是结构性转换，`owner_login` 实际为 `undefined`，使用处需要从 `repo.owner.login` 取。

### 4.2 RepositoryService
- `RepositoryDetail`：`id/name/full_name/description/default_branch/html_url/language/stargazers_count/watchers_count/forks_count/open_issues_count/subscribers_count/owner` ✅ 与 #3 响应吻合（owner 嵌套对象一致）。
- `RepositoryEventItem`：声明 `actor: {login, avatar_url}` 与 `repo: {id, name}`；但实测 actor 含 `id/login/display_login/gravatar_id/url/avatar_url`，repo 含 `id/name/url`。声明缺少 `url` 等字段（不是错误，仅是子集），**`avatar_url` 字段实测确实存在** ✅。
- `RepositoryIssueItem`：`id/number/title/body/state/user{login,avatar_url}/comments/created_at/updated_at/html_url` —— 全部存在 ✅
- `RepositoryFileItem`：`name/path/sha/size/type/download_url/html_url` —— 与 #5 contents 数组的元素一致 ✅
- `SubRepositoryItem.owner_login: string` —— **不一致**：search/repositories 与 forks 返回的均是嵌套 `owner`，不存在扁平 `owner_login`。

### 4.3 DynamicService → `DynamicEvent`（store/DynamicStore.ets）
- 字段：`id/type/actor{id,login,display_login,avatar_url}/repo{id,name,url}/created_at/payload`
- 真实 #8 received_events：`id/type/actor/repo/payload/public/created_at/org`，actor 与 repo 子字段完全覆盖 ✅
- 缺映射：`public/org` 字段未声明（运行时被丢弃，对当前业务无影响）。

### 4.4 ContributionService → `ContributionResp`
- `total: Record<string, number>` —— 与实测 `total: {<year>: int}` 一致 ✅
- `contributions: [{date, count, level}]` —— 与实测一致 ✅
- 注意：`HttpManager` 默认会带 `Authorization: token <REDACTED>` 与 `Accept: application/vnd.github+json`，但本接口为第三方（jogruber.de），鉴权头会被忽略，Accept 也不要求 GitHub MIME。本次实测使用 `Accept: application/json` 直接 200。

---

## 5. 关键不一致点（≥3 条）

1. **`UserRepoItem.owner_login` / `SubRepositoryItem.owner_login` / `NotifyRepository.owner_login` 不存在于真实响应**
   - 真实响应中 `owner` 是嵌套对象 `{login, avatar_url, html_url, ...}`，不会返回扁平的 `owner_login`。
   - 这些声明只在 ArkTS 侧使用结构性 cast（`as XxxItem`），运行时 `owner_login === undefined`。UI 若直接读 `item.owner_login` 会出现空字符串。
   - **建议**：要么在 service 层把响应里的 `owner.login` 显式映射到 `owner_login`，要么把接口字段改回 `owner: { login: string; avatar_url: string }` 嵌套形态。

2. **`Address.search()` 默认 `sort=best%20match` 是非法值**
   - GitHub 文档：`sort` 枚举仅支持 `stars / forks / help-wanted-issues / updated`，"best match" 应通过**省略 sort** 实现。
   - 当前实现把缺省 sort 写死成 `best%20match`，可能在严格场景下被服务端返回 422 Unprocessable Entity（实测 #10 没复现是因为 `getSearchRepos` 走了 `sort=stars` 分支；但 `Address.search()` 仍然有此风险）。
   - **建议**：当 sort 为空时不拼接 `sort` 参数。

3. **`Address.getRepositoryIssue` 强制注入 `sort=created&direction=desc`**
   - 实测 #6 仅传 `per_page=2`、不传 sort/direction 即返回；代码强制注入虽不会报错，但与契约文档（默认 `created,desc`）重复，且让 URL 与 RN/Flutter 端行为不一致。
   - **建议**：仅在调用方显式传值时拼接，保留 GitHub 服务端默认行为。

4. **`Address.reposDataDir` 与 `getReposFileDir` 当 `path=''` 时仍输出 `contents/`（带尾斜杠）**
   - 实测 GitHub 接受 `/contents` 与 `/contents/` 两种形式；但 RN 端 `address.js` 是不带尾斜杠版本，文档与对比 case 容易踩坑。
   - **建议**：当 `safePath === ''` 时直接拼成 `.../contents`，仅在非空时加 `/`。

5. **`RepositoryEventRepo` 类型缺失 `url` 字段**
   - 实测 events 响应里 `repo: {id, name, url}`；代码声明只有 `{id, name}`，导致 RepositoryEventItem 跳转到仓库详情时若想直接复用 `url` 字段需要绕道 `name` 拆分 owner/repo。
   - **建议**：把 `RepositoryEventRepo` 补齐 `url: string`（与 `DynamicRepo` 对齐）。

6. **`getNotifications()` 无法表达"只带 per_page"形态**
   - 当前两个重载：无参数版返回 `/notifications`，有参数版必带 `all=&participating=&page=&per_page=`。
   - 业务侧若仅希望按页拉取（与本次实测 #9 一致），需要绕路构造。
   - **建议**：增加 `getNotifications(page, pageSize)` 重载或允许 all/participating 为 null 时不拼接。

> 上述 1/2/3 三点是较高优先级、能够直接影响 UI 字段为空或潜在 422 的契约问题；4/5/6 属于工程性改进项，不影响功能可用性。

---

## 6. 清理动作

```text
unset GH_PAT
rm -f /tmp/gh_*.json /tmp/gh_*.h /tmp/inspect.py
```

> 报告生成过程未将 token 明文写入任何文件；本文件中所有 token 字面值均使用 `<REDACTED>`。
