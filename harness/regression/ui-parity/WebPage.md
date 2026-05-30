# WebPage UI Parity Report

> R8-L6.5 通用 Web 浏览页（github 站外链兜底 + gsygithub:// 业务深链回归）。
> 蓝本：[WebPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WebPage.js)
> OH 落地：[WebPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WebPage.ets) （L6.5 新建）

---

## 1. RN 基准清单

- 源：[WebPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WebPage.js#L1-L173)（173 行）
- 顶层容器：`View styles.mainBox` 全屏，包含两块：
  - 顶部地址栏（独立 Row：返回按钮 + URL TextInput + 搜索按钮，[L114-L152](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WebPage.js#L114-L152)）
  - 主体 `WebView`（[L153-L169](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WebPage.js#L153-L169)）
- 核心结构：

```
View styles.mainBox (全屏)
├─ View 地址栏 (flexDirectionRowNotFlex, primaryColor, paddingTop=normalMarginEdge+30)
│  ├─ TouchableOpacity (centered, mr=normalMarginEdge, ml=normalMarginEdge-3)
│  │  └─ Icon "chevron-back-outline" size=18 color=miWhite        ← goBack()
│  ├─ TextInput (smallText, padding=0, paddingLeft=normalMarginEdge/2, mh=normalMarginEdge/2,
│  │             borderRadius=3, backgroundColor=subLightTextColor, flex)
│  │   defaultValue={state.showCurUri}
│  │   autoCapitalize="none"
│  │   onSubmitEditing → pressGoButton()
│  │   onChange → handleTextInputChange()
│  └─ TouchableOpacity (centered, mr=normalMarginEdge, paddingLeft=20)
│     └─ Icon "search-circle-outline" size=19 color=miWhite       ← pressGoButton()
└─ WebView (flex=1, width=screenWidth)
   source={uri: state.uri}
   onNavigationStateChange={(navState) => {
     this.canGoBack = navState.canGoBack;
     setState({ backButtonEnabled, status: title, showCurUri: navState.url, loading })
   }}
   javaScriptEnabled domStorageEnabled scalesPageToFit mixedContentMode='always'
   automaticallyAdjustContentInsets allowUniversalAccessFromFileURLs
   mediaPlaybackRequiresUserAction startInLoadingState
```

- 样式 token：
  - Color: `Constant.primaryColor (#24292e)`、`Constant.miWhite (#ececec)`、`Constant.subLightTextColor (#c4c4c4)`
  - Font: `styles.smallText (14sp)`
  - Spacing: `Constant.normalMarginEdge = 10`（mr/ml/mh、paddingLeft/2、paddingTop+30）
  - Radius: `3`（TextInput）
  - Icon size: `18` (chevron) / `19` (search-circle)

- 交互序列：

```
constructor(props)
  this.state.uri = resolveUrl(route.params.uri)        ← 不带 scheme 时补 'http://'
  this.state.showCurUri = uri
  this.inputText = uri

componentDidMount()
  BackHandler.addEventListener('hardwareBackPress-WebPage', back)

handleTextInputChange(event)
  this.inputText = resolveUrl(event.nativeEvent.text)  ← 不立即跳转，仅更新本地缓冲

resolveUrl(url)
  return /^[a-zA-Z-_]+:/.test(url) ? url : 'http://' + url

onSubmitEditing() / pressGoButton()
  if (this.inputText.toLowerCase() === state.url) → reload()
  else → setState({ uri: this.inputText.toLowerCase() })
  textInput.blur()

reload()
  webview.reload()

goBack() / back()
  if (canGoBack) webview.goBack()
  else Actions.pop()                                   ← 兼容硬件返回 → 拦截后返 true

onNavigationStateChange(navState)
  this.canGoBack = navState.canGoBack
  setState({ showCurUri: navState.url, status: title, loading })

componentWillUnmount()
  handle.remove()                                      ← 解绑 BackHandler
```

- 依赖资产：
  - 兜底入口：[htmlUtils.launchUrl#L380-L399](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js#L380-L399)（github.com 路径 ≥4 段、非 github 域名时 fallback `Actions.WebPage`）
  - 二次入口：[CustomWebComponent#L69](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/CustomWebComponent.js#L69)（GFM HTML 中 `http(s)://` 非 github 链接 fallback `Actions.WebPage`）
  - 路由：`Actions.WebPage({ uri })` 单入参；route.params.uri 必填

---

## 2. ArkUI 落地（OH 增强：地址栏改 AppBar）

- 源：[WebPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WebPage.ets)
- 顶层 `Column` 全屏 `GSYColor.mainBackground`，包含两块：
  - 顶部 [AppBar](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets)（OH 增强：替代 RN 地址栏 Row，title=当前 web 标题或 host，右侧 actions=`reload`）
  - 主体 [Web](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-web-V5)（ArkUI 内置 Web 组件，layoutWeight(1)）
- 顶层 stack 与导航：
  - 通过 [AppNavigator.routerMap](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/AppNavigator.ets) 注册 `WebPage` route name
  - 入参 `WebPageParams { uri: string }` 通过 NavDestination context.pathInfo.param 获取
  - bootWeb want 通道兜底：参考 KI-042 / KI-045 范式，`BOOT_WEB_KEY = 'BOOT_WEB_URI'` 在 [EntryAbility.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets) onNewWant + onCreate 写 AppStorage，[WebPage.ets onReady](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WebPage.ets) 兜底读
- AppBar 行为（OH 增强标记）：
  - title: 优先用 `webController.getTitle()`，未取到时回退到 host（`URL parse → host`）
  - leftActions: 默认 back chevron（onBack → router.back）
  - rightActions: `[ { iconKey: 'reload', onAction: () => webController.refresh() } ]`
- Web 组件配置：
  - `Web({ src: this.uri, controller: this.webController })`
  - `.javaScriptAccess(true)` `.domStorageAccess(true)` `.mixedMode(MixedMode.All)` `.zoomAccess(true)`
  - `.onPageBegin(() => this.loading = true)` `.onPageEnd(() => this.loading = false)`
  - `.onTitleReceive((event) => this.pageTitle = event.title)`
  - `.onConfirm/.onAlert` → CommonModal.confirm
  - `.onLoadIntercept`：3 分支路由（与 RN CustomWebComponent 4 分支对齐，OH 端去掉 launchUrl 因 RN 是同款 fallback 到 WebPage）：
    1. `gsygithub://` → 内嵌 anchor（CodeDetail / IssueDetail 等业务深链回调，OH 此处 toast 占位 + hilog `0x0666 [web/anchor]` 埋点，**仅 WebPage 路径**不业务消费，留 KI-049 候选）
    2. `https://github.com/<owner>/<repo>` 或更深路径 → 站内 NavPathStack 业务路由（仓库/Issue/Pull）；本期 P1 仅记 hilog，KI-049 候选
    3. 其他 `http(s)://` → 让 Web 内部 navigate（return false 不拦截）
- 颜色/字号/间距/圆角全部走 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets)：
  - 顶层 bg = `GSYColor.mainBackground`
  - AppBar bg = palette.navBackground（默认 `GSYColor.primary`）
  - AppBar title color = `GSYColor.titleText`（即 miWhite #ececec）
  - 加载时无显式 loading mask（依赖 Web 组件原生进度），保持 RN `startInLoadingState` 视觉对齐
- HARD-LAW 自检：
  - LAW-1 RN-FIRST：本文档 §1 完整抽源
  - LAW-2 token-only：0 字面量颜色/字号/间距
  - LAW-3 NO-DEBUG-PROBE：UI 树仅 AppBar + Web；hilog tag `[web/page]`、`[web/anchor]`、`[web/intercept]` 三个埋点
  - LAW-4 三件套：本文档 §3 占位 Pending Device Evidence
  - R-UI-05：本页面无 @Builder 值参，[onLoadIntercept 内 inline 三元](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WebPage.ets) 直读 url
- 偏差点（与 RN 对照）：
  - **OH 增强：RN 地址栏 Row 改为标准 [AppBar](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets)**（用户拍板选定）。理由：OH 主链页面统一沉浸式 AppBar 风格（与 LoginPage / RepositoryDetail 一致），保持设计语言连贯；URL 编辑能力以 reload 替代，业务上 WebPage 多为只读外链兜底，可接受。
  - 多 tab / 历史栈：本期不做（RN 也无）
  - PullToRefresh：本期不做（OH Web 已有原生下拉，无需额外）
  - mediaPlaybackRequiresUserAction：ArkUI Web 默认行为已对齐，不需显式配置

---

## 3. 截图对照（2026-05-27 R8-L10 真机三件套 ✅）

| 场景 | OH 截图 | md5 | 大小 |
|---|---|---|---|
| 1. bootWeb 加载 + AppBar 标题 | [oh_WebPage_v1_20260527.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/WebPage/oh_WebPage_v1_20260527.jpeg) | `c1d978a83169e0278fe8a1e850e48119` | 112KB |
| 2. AppBar reload | [oh_WebPage_v1_reload_20260527.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/WebPage/oh_WebPage_v1_reload_20260527.jpeg) | `f12f8146059de5f3511afe5c59a56c94` | 112KB |
| 3. AppBar back 返回 HomePage | [oh_WebPage_v1_back_20260527.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/WebPage/oh_WebPage_v1_back_20260527.jpeg) | `2fe4c8dcde4e12cfe74fae082f2288f2` | 211KB |

- 详细报告：[reports/M6/r8-l10-webpage-20260527-200000/README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l10-webpage-20260527-200000/README.md)
- RN 端蓝本由 [WebPage.md §1](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/WebPage.md#L9-L89) 抽源覆盖（结构 + 交互 + token 完整记录）
- 验证子场景结果：
  1. **bootWeb want 通道**（PASS ✅）：`aa start --ps bootWeb 'https://example.com'` → EntryAbility.handleBootWebInjection → AppStorage[BOOT_WEB_KEY] → HomePage.scheduleBootWeb push → WebPage onAppear → adopt BOOT_WEB_KEY fallback → onTitleReceive 回写 AppBar title='Example Domain'
  2. **AppBar reload action**（PASS ✅）：点 (1208, 235) → `[web/page] reload` hilog + 396ms 后 onPageEnd
  3. **AppBar back**（PASS ✅）：点 (56, 235) → AceNavigation pop 动画 0.6s + Home onShown/onActive
  4. **gsygithub:// 拦截**（代码路径覆盖 ✅）：[onInterceptUrl#L107-L111](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WebPage.ets#L107-L111) 三分支齐全，业务路径已在 KI-049 真机闭环（ReadmeTab onLoadIntercept 接住 README 相对链接）

---

## 4. 差异处理

- **OH 增强标记**：RN 地址栏 Row（返回 + URL TextInput + 搜索）→ OH AppBar（title 自动跟随 + reload 右上）。在 [INDEX.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/INDEX.md) WebPage 行登记 OH 增强。
- **TextInput URL 编辑能力丢失**：本期不补；用户若需要重新输入 URL，可走 caller 入口或 reload。后续 P3 候选可在 AppBar subtitle 显示 host 让用户感知当前 URL。
- **Linking 系统外链**：RN 第 4 分支 `Linking.openURL`（gsygithub / github / http(s) 都不命中时）OH 端依赖 ArkUI Web 的 onLoadIntercept return false 让 Web 自处理，不再独立提系统浏览器；视为 OH 增强简化。
- **gsygithub:// 业务消费**：本期 WebPage 不做业务消费（CodeDetail 已自管），仅 hilog `[web/anchor]` 埋点。**KI-049 候选**：未来若需在 WebPage 内消费 gsygithub:// 跳回 NavPathStack（仓库/Issue 等），独立子链处理。
- **2026-05-27 KI-049 闭环更新**：发现真正漏点是 [ReadmeTab.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/repo/ReadmeTab.ets) 完全没装 `onLoadIntercept`，README 里的相对链接（被 RN [htmlUtils.js#L113](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js#L113) 重写成 `gsygithub://`）一点没反应。修法：(1) ReadmeTab 加 `@Prop fullName` + `@Prop branch` + 完整复刻 [CodeDetailPage.interceptUrl](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L129-L172) 的分发逻辑（用户名→UserDetail / 仓库名→RepositoryDetail / 深路径→OH WebPage / 站外→系统浏览器）；(2) [RepositoryDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryDetailPage.ets) 抽 `resolveDefaultBranch()` 助手把 fullName + branch 透传给 ReadmeTab；(3) WebPage 通用兜底 [onInterceptUrl](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WebPage.ets#L117-L132) 碰到 `gsygithub://` 不再静默吞掉，改用 `CommonToast.showShort(I18n('webRelativeLinkNeedRepoContext'))` 给用户明确反馈（让用户知道这种相对链接需要回到对应代码页打开）；(4) [I18n.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/i18n/I18n.ets) 双 locale 同步新 key。详见 [01-status.md § KI-049](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/01-status.md) 子节 + [known-issues.md KI-049](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md)。
