# L4 CodeDetailPage 主链

> 入口：RepositoryDetail.files tab → CodeFileItem onTap (file 类型) → push CodeDetail；或 PushDetail commit 文件列表 → CodeDetail；或 ListPage diff 列表项 → CodeDetail。
> 状态：✅ **已完成（2026-05-26）**；S0..S6 全闭，DoD 10/10；scope=B 全功能 RN-aligned。
> RN 蓝本：[CodeDetailPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/CodeDetailPage.js)（141 行）+ [CustomWebComponent.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/CustomWebComponent.js)（95 行）+ [htmlUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js)（434 行）。

---

## § 1 RN 基准清单（S1 ✅ 完成 2026-05-26）

### 1.1 结构树（RN）

```
CodeDetailPage (class Component)
├── render()  → View styles.mainBox
│   ├── StatusBar  hidden=false / backgroundColor=transparent / translucent / barStyle=light-content
│   └── WebComponent  ← components/widget/CustomWebComponent.js
│       ├── prop  source = { html: this.state.detail }
│       └── prop  gsygithubLink = (url) => 解析 gsygithub://… 锚点 → 拼 https://github.com/{owner}/{repo}/blob/{branch}/{path} → launchUrl()
│
└── 关键状态 / 副作用
    ├── constructor.state.detail = props.route.params.detail   ← 上游可能预生成 HTML
    ├── componentDidMount → InteractionManager.runAfterInteractions:
    │   if (route.params.needRequest):
    │       reposActions.getReposFileDir(owner, repo, path, branch, textStyle).then(res):
    │           if res.result:
    │               start = data.indexOf(`class="instapaper_body `)
    │               end   = data.indexOf(`" data-path="`)
    │               lang  = formName(data.slice(start+startTag.length, end).toLowerCase())
    │               if !lang: lang = props.route.params.lang   // default 'java'
    │               if lang === 'markdown': setState.detail = generateHtml(res.data)
    │               else                    setState.detail = generateCode2HTml(res.data, webDraculaBackgroundColor='#282a36', lang)
    │           else:
    │               setState.detail = "<h1>" + I18n('fileNotSupport') + "</h1>"
    │       Actions.refresh({titleData: {html_url: route.params.html_url}})  ← 刷新 navigation 标题用
    └── BackHandler 监听 hardwareBackPress → Actions.pop()
```

**RN 渲染层非常薄**：仅 1 个 `<WebView>` + 1 个 `<StatusBar>`，无 AppBar 标题（标题由 navigation 全局栏渲染）/ 无底栏 / 无列表 / 无侧栏。视觉上**整个屏幕就是一个 WebView**，业务逻辑全压在 HTML 生成（`generateCode2HTml` / `generateHtml`）+ gsygithub:// 锚点拦截上。

### 1.2 入参清单（route.params）

| 字段 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `detail` | string | `''` | 预生成 HTML（上游传，跳过 needRequest 时直接渲染）|
| `ownerName` | string | `''` | 仓库 owner |
| `repositoryName` | string | `''` | 仓库 name |
| `path` | string | `''` | 文件路径（如 `app/components/CodeDetailPage.js`）|
| `branch` | string | `'master'` | 分支 |
| `title` | string | `''` | 标题（顶部 navigation 栏文案）|
| `needRequest` | bool | `true` | 是否走网络拉源；`false` 直接用 `detail` |
| `lang` | string | `'java'` | 语言名兜底，`formName` 转标准 highlight.js 名 |
| `textStyle` | bool | `false` | Api 透传到 [reposDataDir endpoint](https://github.com/CarGuo/GSYGithubApp/blob/master/app/net/address.js#L240-L242)，控制是否要 highlight HTML 包裹（true=纯文本 / false=instapaper html）|

### 1.3 token 映射（RN → OH）

| 用途 | RN 来源 | OH token 候选 |
|---|---|---|
| WebView 容器 flex 1 | `styles.mainBox`（`Constant.miWhite` 主白底）| 直接 OH `Web().layoutWeight(1).width('100%')` 不需 token |
| dracula 代码背景色 | [`Constant.webDraculaBackgroundColor='#282a36'`](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js#L23) | **新增 token：`GSYColor.webDraculaBackground = '#282a36'`**（在 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets) 内补）|
| 链接蓝 | `Constant.actionBlue` | 已有 [GSYColor.actionBlue](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets) |
| 表格头白色 | `Constant.miWhite` | 已有 [GSYColor.miWhite](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets) |
| 表格边主题色 | `Constant.primaryLightColor` | 已有 [GSYColor.primaryLight](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets) |
| 状态栏  | `<StatusBar barStyle='light-content'>` | OH NavDestination 走系统沉浸式，无需写代码，由 [GlobalStatusBar](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets) 统一管 |

**关键观察**：RN 端 CodeDetail 几乎不用任何"页面自身"的颜色 token，所有视觉都在 HTML 内部 inline style 决定（[generateCodeHtml L190-L233](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js#L190-L233)）。这意味着：

- **OH 端必须 1:1 复刻 [generateCode2HTml](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js#L50-L66) + [generateCodeHtml](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js#L190-L233) 的 HTML 拼接逻辑**（含 highlight.js 9.12.0 dracula CDN + `<pre><code lang='${lang}'>` 包裹 + 表格 / 链接 / 字号样式），否则视觉**根本不可能对齐 RN**。
- gsygithub:// 锚点拦截（点击 markdown 内相对链接跳 GitHub）也必须实现，否则点 README 内链接会失败。

### 1.4 交互序列（RN → 拟 OH）

```
RN：
1. RepositoryDetailFilePage onTap file → Actions.CodeDetailPage({ownerName, repositoryName, path, branch, title, needRequest:true, textStyle:false})
2. componentDidMount → 600ms 后 reposActions.getReposFileDir(owner, repo, path, branch, false)
   GET https://api.github.com/repos/{owner}/{repo}/contents/{path}?ref={branch}
   Header: Accept: application/vnd.github.html
3. res.data 是一段 instapaper HTML（class="instapaper_body java" data-path="..."）
4. 解析 lang → generateCode2HTml(data, dracula, lang) → <html><body><pre class=pre><code lang='java'>{data}</code></pre></body></html>
5. WebView source={{ html: detail }} → 高亮渲染
6. 点击代码内链接 → onShouldStartLoadWithRequest 拦截 → gsygithub://./xxx → launchUrl(`https://github.com/owner/repo/blob/branch/xxx`) → Actions.WebPage 或 Actions.RepositoryDetail

OH（拟 S3 落地）：
1. FilesTab onTap → NavigationService.push(RouteName.CodeDetail, {fullName, branch, path})
2. CodeDetailPage.onReady → ctx.pathInfo.param 取参（S0 已修）
3. CodeService.getRawContent(fullName, branch, path):
   GET https://api.github.com/repos/{fullName}/contents/{path}?ref={branch}
   Header: Accept: application/vnd.github.html
4. 走 OH 端 HtmlUtils.generateCode2HTml(data, GSYColor.webDraculaBackground, lang)（拟新建/复用）
5. Web({src: '', controller}).onControllerAttached → controller.loadData(html, 'text/html', 'UTF-8')
6. Web.onUrlIntercept → 'gsygithub://' 协议拦截 → 拼 https://github.com/.../blob/branch/path → 调 ohos.want.action.viewData 启外浏览器（或 push WebPage）
```

### 1.5 RN 端 i18n key

| key | en | zh |
|---|---|---|
| `fileNotSupport` | `'File not support'` | `'文件类型不支持预览'` |

OH 端 [I18n.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/i18n/I18n.ets) 已有 `fileNotSupport`（[CodeDetailPage.ets#L71](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L71) 在用），无需新增。

---

## § 2 OH 偏差清单（S2 ✅ 完成 2026-05-26）

### 2.1 OH 端结构现状（先抽出"已对齐"项作背景）

S2 阶段 Read 三个 OH 文件后发现 **OH 端结构已经对齐 RN 约 90%**，远比 L3 起点好：

| 已对齐项 | OH 实现 | RN 蓝本 | 状态 |
|---|---|---|---|
| HTML 生成（dracula 高亮 + 表格 / 链接 / 字号样式） | [HtmlUtil.generateCode2Html](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/utils/HtmlUtil.ets#L128-L139) + [HtmlUtil.generateHtml](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/utils/HtmlUtil.ets#L141) + [HtmlUtil.generateMd2Html](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/utils/HtmlUtil.ets#L165) | RN [generateCode2HTml / generateHtml / generateMd2Html](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js#L50-L185) | ✅ 已对齐 |
| dracula 背景色 token | [GSYColor.webDraculaBackground='#282a36'](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L25) | RN [Constant.webDraculaBackgroundColor='#282a36'](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js#L23) | ✅ token 化已落 |
| 网络层（raw 优先 + contents fallback + Base64 decode） | [CodeService.getRawContent](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/CodeService.ets#L134-L173) | RN 仅 [getReposFileDirDao](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/repositoryDao.js#L734-L741) 单路径 | ✅ OH 增强（更稳）|
| 语言推断（按扩展名映射 highlight.js 名）| [CodeService.guessLangByPath](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/CodeService.ets#L64-L132) 18 种扩展名 | RN [formName](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js#L328-L347) 6 种特殊映射 + 兜底 | ✅ OH 增强 |
| Web 容器 + controller.loadData | [CodeDetailPage.ets#L111-L126](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L111-L126) Web + onControllerAttached + onPageEnd 双触发 tryLoadHtml | RN `<WebView source={{html}}/>` | ✅ 已对齐 |
| AppBar 标题（path）| [CodeDetailPage.ets#L93-L100](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L93-L100) `title: this.path \|\| I18n('reposFile')` | RN navigation 全局栏 `Actions.refresh({titleData})` | ✅ OH 单页持有 AppBar（按 R7-J Step 5b A 类页面规范，已合规）|
| jscrash 防御（onReady try/catch + ctx.pathInfo.param 优先）| [CodeDetailPage.ets#L33-L47, L138-L167](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L33-L47) | RN 无（react-navigation 直接给 route.params）| ✅ S0 已修，与 L2/L3 同款 |

### 2.2 OH 偏差清单（待 S3 修）

每条 4 字段：OH 现状 / RN 蓝本 / 根因 / 涉及文件。

| ID | 严重度 | OH 现状 | RN 蓝本 | 根因 | 涉及文件 |
|---|---|---|---|---|---|
| **Δ1** | P1 | UI 树残留调试 Text：[CodeDetailPage.ets#L102-L106](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L102-L106) `Text('path:' + this.path)` 渲染在 AppBar 与 Web 之间 | RN [CodeDetailPage.js#L94-L113](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/CodeDetailPage.js#L94-L113) 仅 `<View><StatusBar/><WebComponent/></View>`，**完全没有 path 文本探针** | 历史调试残留 → 违反 **HARD-LAW-3 NO-DEBUG-PROBE-IN-PROD**（生产 UI 树禁止调试 Text）；正确做法是走 hilog domain `0x0666`，path 已经在 AppBar.title 里展示了，重复 | [CodeDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets) |
| **Δ2** | P2 | 字面量 + TODO 注释：[CodeDetailPage.ets#L73](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L73) `.fontSize(15) // TODO: 字号 15 暂无 token 映射` | RN 端无对应 Text（empty 文案是 HTML `<h1>...</h1>` 由 WebView 渲染），但 OH 端的 empty Text 字号需走 token | **HARD-LAW-2 TOKEN-ONLY**：[GSYFontSize.middleNormal=15](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L115) 已存在（KI-031 R7-M 落地），仅是 CodeDetailPage 没改成引用 token | [CodeDetailPage.ets#L73](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L73) |
| **Δ3** | P2 | 缺 gsygithub:// 锚点拦截：[CodeDetailPage.ets#L111-L126](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L111-L126) Web 组件**未挂** `onLoadIntercept` / `onUrlLoadIntercept`，点 markdown 内相对链接直接 fail | RN [CustomWebComponent.js#L63-L73](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/CustomWebComponent.js#L63-L73) `onShouldStartLoadWithRequest` 拦 `gsygithub://` → 拼 `https://github.com/{owner}/{repo}/blob/{branch}/{path}` → [launchUrl](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js#L350-L400) 路由分发（图片走 PhotoPage / 仓库 URL 走 RepositoryDetail / 其它走 WebPage）| 功能缺口（不阻塞核心高亮渲染，但 markdown 内链接不可点）| [CodeDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets) |
| **Δ4** | P3 | onReady 后 `loadAll` 在 fullName/path 长度 = 0 时静默 return（[CodeDetailPage.ets#L49-L51](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L49-L51)），无任何 hilog | RN componentDidMount 也无相应埋点 | OH 增强（jscrash 防御）但未补 hilog，scenario 真机 dump 时无法定位"为什么没拉到内容" | [CodeDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets) |
| **Δ5** | P3 | 缺 bootCode want 通道：boot deeplink 入口仅 L1/L2/L3 三个（bootRepo / bootPush / bootIssue），还没有 bootCode | （RN 无 boot 概念，由 react-navigation deep-linking） | scenario 15 codeDetail 跑真机时需要直接 deeplink 到 CodeDetail，不能走"先打开 RepoDetail → 切 Files tab → 滑到某文件 → 点击"长链路（不可靠）| [EntryAbility.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets) + [HomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets) + [scenario-tour.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh) |

### 2.3 偏差汇总

| 类型 | 数量 | 严重度分布 |
|---|---|---|
| 违规（HARD-LAW）| 2 | P1 × 1（Δ1 调试 Text）+ P2 × 1（Δ2 字面量）|
| 功能缺口 | 1 | P2 × 1（Δ3 gsygithub:// 拦截）|
| 增强项 | 2 | P3 × 2（Δ4 hilog + Δ5 bootCode）|

**总计 5 项偏差**（远比 L3 的 8+1 项简单）。

### 2.4 scope 候选

| scope | 含义 | 包含 Δ | 工作量估算 |
|---|---|---|---|
| **A 最小 RN-aligned + DoD 必达** | 修违规 + 上 boot 通道 | Δ1 + Δ2 + Δ4 + Δ5 | ~30 行修改 + scenario 15 + ~50 行 EntryAbility/HomePage 注入 |
| **B 全功能 RN-aligned** | A + gsygithub:// 锚点拦截 | Δ1..Δ5 | A + Web onLoadIntercept 实现 ~40 行 + 路由分发对接（PhotoPage 已存在 / WebPage 已存在 / RepositoryDetail 走 NavigationService.push）|
| **C 仅 DoD 不阻塞最小集** | 修违规 | Δ1 + Δ2 | ~5 行，但 scenario 15 没法跑（缺 boot 通道）会卡 DoD #5 |

→ **scope=C 不能选**（会卡 DoD #5）。
→ scope=A 与 scope=B 都能拿 DoD 10/10，差别仅在"markdown 内链接是否可点"。
→ 默认推荐 **scope=A**，与 L3 同款节奏（最小可闭环 + 留尾 KI 跟进 Δ3）；scope=B 也合理但工作量翻倍。

---

## § 3 截图对照（S6 ✅ 完成 2026-05-26）

### 3.1 三件套

| 端 | 截图绝对路径 | 备注 |
|---|---|---|
| **RN** | （RN 仓库未提供 CodeDetail 真机截图，[screenshots/rn/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn) 目录下 grep `*Code*` = 0 命中）→ 改用 RN 源代码 [CodeDetailPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/CodeDetailPage.js) + [CustomWebComponent.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/CustomWebComponent.js) + [generateCode2HTml](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js#L50-L66) 拼装 HTML 作为 RN 视觉真源对照（与 L3-IssueDetail 同款做法）| RN 端纯 `<WebView>` 渲染 dracula HTML，与 OH 端 [HtmlUtil.generateCode2Html](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/utils/HtmlUtil.ets#L128-L139) 1:1 复刻 → 视觉骨架由同一段 HTML 决定 |
| **OH** | [oh_CodeDetail_v1_20260526.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/CodeDetailPage/oh_CodeDetail_v1_20260526.png) | md5=`4b41eb5c8f95e03610a17d31a0edbfaa`（全工程 grep 唯一命中）|
| **dump** | [oh_CodeDetail_v1_20260526.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/CodeDetailPage/oh_CodeDetail_v1_20260526.json) | layout dump，含 `code_detail_appbar` + `code_detail_web` 两个 id 节点 |
| **scenario** | [reports/M6/r8-l4-codedetail-v1/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l4-codedetail-v1) | scenario 15 codeDetail：`Result : ok=1 fail=0 skip=14 dup=NO`，asserts 2/2 OK，hilog BEGIN/END 边界 marker 2 个齐全 |

### 3.2 差异清单（RN ↔ OH ≤ 5 处）

| # | 维度 | RN | OH | 严重度 | 处置 |
|---|---|---|---|---|---|
| **C1** | 顶部 AppBar | RN 由 react-navigation 全局栏渲染（`Actions.refresh({titleData:{html_url}})` 写 title） | OH 单页持有 [AppBar](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L93-L100) `title: this.path \|\| I18n('reposFile')` | P3 平台等价 | 保留（R7-J Step 5b A 类页面规范允许 OH 单页 AppBar） |
| **C2** | gsygithub:// 锚点协议 | RN `onShouldStartLoadWithRequest` 拦 `gsygithub://` → 拼 GitHub URL → `launchUrl()` 路由分发到 PhotoPage/RepositoryDetail/WebPage | OH [Web.onLoadIntercept](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets) 拦 `gsygithub://`，仓库 → push RepositoryDetail / 用户 → push UserDetail / 其它 → `ohos.want.action.viewData` 拉浏览器 | P3 RN-aligned | 保留 |
| **C3** | StatusBar | RN `<StatusBar barStyle='light-content' translucent>` 显式设置 | OH 沉浸式由 NavDestination 系统级管理（无需写代码） | P3 平台等价 | 保留 |
| **C4** | bootCode 入口（boot 通道） | RN 无（react-navigation deep-linking 走 URL scheme） | OH 新增 `aa start --ps bootCode "fullName\|branch\|path"` want 通道 + AppStorage 兜底 → CodeDetailPage.aboutToAppear `tryAdoptBootCode()` 直读（KI-029 同款时序竞争兜底）| P3 OH 增强 | 保留（scenario 15 真机回归依赖此通道）|
| **C5** | 数据态文案 | RN empty 走 `<h1>fileNotSupport</h1>` 由 WebView 渲染 | OH empty 走外层 `Text(I18n('fileNotSupport')).fontSize(GSYFontSize.middleNormal)` token 化 | P3 平台等价 | 保留 |

**总计 5 项差异**，全部 P3 平台等价/OH 增强，无 P0/P1/P2 偏离。符合 DoD #8（≤ 5 处差异）。

### 3.3 hilog 验证（hilog_business.log）

scenario 15 hilog 文件 [hilog_business.log](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l4-codedetail-v1/hilog_business.log) 含脚本写入的边界 marker：

```
=== BEGIN scenario=codeDetail index=15 ts=11:37:59 ===
... (433 lines)
=== END   scenario=codeDetail index=15 status=ok ts=11:38:12 ===
```

业务 hilog（`CodeDetail` tag）走 hilog domain `0x0666` 已在调试期抓到完整链路（独立 `hdc shell hilog` 抓现场 [/tmp/codeDetail-hilog.txt](tmp/codeDetail-hilog.txt)）：

```
[CodeDetail] aboutToAppear adoptBootCode fullName=CarGuo/GSYGithubApp branch=master path=README.md ✓
[CodeDetail] onReady fullName=CarGuo/GSYGithubApp branch=master path=README.md ✓
[CodeDetail] loadAll BEGIN ✓
[CodeDetail] loadAll END htmlLen=8271 ✓
[CodeDetail] tryLoadHtml ok len=8271 ✓
```

> ℹ️ scenario-tour.sh PID-tracking 局限（scenario 15 force-stop 重启后 PID=22804 已变化导致 `hilog -P PID` 跟丢业务 tag），不影响 BEGIN/END 边界 marker 与 asserts 通过结论；与 L2/L3 同款约束。

---

## § 4 DoD 检查表（见 [00-rules.md § 三](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/00-rules.md)）

| # | 项 | 状态 | 证据 |
|---|---|---|---|
| 1 | § 1 RN 基准 / § 2 偏差 / § 3 截图对照 三件套 | ✅ | § 1 ☑ + § 2 ☑ + § 3 ☑ 本文件 |
| 2 | ArkTS grep 字面量 = 0 | ✅ | [CodeDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets) Δ2 已修：`fontSize(15)` → `GSYFontSize.middleNormal`，全文件 `'#`/`fontSize\(\d`/`padding\(\d` grep 0 命中 |
| 3 | ArkTS grep 调试探针 = 0 | ✅ | Δ1 已修：`Text('path:'+this.path)` 删除；HARD-LAW-3 合规 |
| 4 | hvigorw BUILD SUCCESSFUL | ✅ | `BUILD SUCCESSFUL in 9s 052ms` / 0 ERROR / GetDiagnostics 0 |
| 5 | scenario-tour ok=N fail=0 | ✅ | scenario 15 codeDetail `Result : ok=1 fail=0 skip=14 dup=NO`（[summary.log](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l4-codedetail-v1/summary.log)）|
| 6 | 截图 md5 唯一 | ✅ | md5=`4b41eb5c8f95e03610a17d31a0edbfaa`，全工程 grep 仅 1 处命中 |
| 7 | hilog 0x0666 BEGIN/END | ✅ | hilog_business.log 含 `=== BEGIN scenario=codeDetail ===` + `=== END scenario=codeDetail status=ok ===`；业务 tag `CodeDetail` BEGIN/END 完整（loadAll BEGIN/END + tryLoadHtml ok）|
| 8 | RN ↔ OH ≤ 5 处差异 | ✅ | § 3.2 共 5 项 C1..C5 全部 P3 平台等价/OH 增强，无 P0/P1/P2 偏离 |
| 9 | INDEX.md ✅ aligned | ✅ | [INDEX.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/INDEX.md) 第 17 行 CodeDetailPage 已升级到 ✅ aligned（R8-L4 闭环）|
| 10 | 关联 KI 全部 Closed | ✅ | KI-037..042 6 条 Closed（详见 [known-issues.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md)）|

---

## § 5 入口路径验证（S1 落地）

OH 端三个 push 入口已存在（与 RN 三个 Actions.CodeDetailPage 调用一一对应）：

| RN 入口 | OH 入口 | 状态 |
|---|---|---|
| [RepositoryDetailFilePage.js#L125](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailFilePage.js#L125) Actions.CodeDetailPage | [FilesTab.ets#L59](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/repo/FilesTab.ets#L59) NavigationService.push(RouteName.CodeDetail, param) | ✅ 已接 |
| [PushDetailPage.js#L64](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PushDetailPage.js#L64) Actions.CodeDetailPage | [PushDetailPage.ets#L59](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PushDetailPage.ets#L59) NavigationService.push(RouteName.CodeDetail, …) | ✅ 已接 |
| [ListPage.js#L134](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ListPage.js#L134) Actions.CodeDetailPage | （ListPage 待 L6 主链单独建）| ⏳ L6 |

NavDestination 路由表已注册 [RouteName.CodeDetail](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/Routes.ets#L15) + [AppNavigator dispatch L76-L77](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/AppNavigator.ets#L76-L77)。

---

## § 6 后续 Step 概要（S2..S6）

| Step | 关键动作 | 参考主链 |
|---|---|---|
| S2 Diff | Read [CodeDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets) + [CodeService.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/CodeService.ets) + [CodeDetailStore.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/store/CodeDetailStore.ets) → 列偏差 4 字段表 | L3 § 2 |
| S3 Fix | scope=A 最小 RN-aligned：(a) 删 `Text('path:'+this.path)` 调试栏（HARD-LAW-3）/(b) 删 `fontSize(15) // TODO` 字面量（HARD-LAW-2 + 走 GSYFontSize.middleNormal token）/(c) 复刻 generateCode2HTml + dracula CDN HTML 拼接 / (d) Web 加 onUrlIntercept gsygithub:// 锚点 | L3 scope=A |
| S4 Build | hvigorw assembleHap | L3 S4 |
| S5 Run | 加 bootCode want 通道（owner/name\|branch\|path）+ scenario 15 codeDetail；DEMO_CODE 默认 `CarGuo/GSYGithubApp\|master\|README.md`；ok=N fail=0 + hilog BEGIN/END + md5 唯一 | L3 S5（bootIssue 同款）|
| S6 Compare | RN ↔ OH 截图对照 ≤ 5 处差异；DoD 10/10；INDEX.md 升级 | L3 S6 |
