# WelcomePage UI Parity Report

## 1. RN 基准清单

- 源：[WelcomePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WelcomePage.js)
- 顶层容器：`View` 满屏，`backgroundColor = Constant.white (#FFFFFF)`、`styles.mainBox`
- 核心结构：
  ```
  View (mainBox, white)
  └─ View (centered, flex:1)
     ├─ Image welcome.png  width=screenWidth, height=screenHeight, resizeMode=contain
     └─ View (absoluteFull, justifyContent:'flex-end', centered)
        └─ View (150x150 centered)
           └─ LottieView animation-w800-h800.json (autoPlay, loop=false)
  ```
- 样式 token：
  - Color: `Constant.white (#FFFFFF)`
  - Layout: `styles.mainBox` (flex:1)、`styles.centered`、`styles.absoluteFull`
- 交互序列：
  ```
  componentDidMount
    → userActions.initUserInfo()
    → toNext(res)
       setTimeout 3000ms
         → res.result === true ? Actions.reset("MainTabs") : Actions.reset("LoginPage")
  ```

## 2. ArkUI 落地

- 源：[WelcomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WelcomePage.ets)
- 顶层 `Stack` 满屏 `GSYColor.white`，居中放置 `Image($r('app.media.welcome'))`，`width('100%') / height('100%')`、`objectFit(ImageFit.Contain)`，对齐 RN 端 `welcome.png` 全屏 contain 显示。
- 启动延迟：`onPageShow` 中 `setTimeout(WELCOME_DELAY_MS = 3000)`，超时后调用 `routeByToken()`：
  - 优先读取 `GlobalAuthStore.token`
  - 其次读取 `AppStorage.get(APP_STORAGE_KEY_TOKEN)` 镜像
  - 最后读取 `Preferences.getString(KEY_USER_TOKEN)`
  - 有 token → `NavigationService.replace(RouteName.Home)`；否则 `NavigationService.replace(RouteName.Login)`
- 颜色：`GSYColor.white`，无任何 `#xxx` 内联色号。
- 偏差点：
  - RN 端 Lottie 动画 `animation-w800-h800.json` 暂未在 ArkUI 端引入，OH 端仅渲染静态 welcome.png；如后续接入 Lottie 解码再补。
  - RN 端 token 判断走 `userActions.initUserInfo()`（带网络 self user 校验），OH 端仅做本地 token 存在性判断 + Home 内再异步刷新；行为差异已记录在 [auth.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/auth.md)。

## 3. 截图对照

| RN | ArkUI |
|---|---|
| ![RN WelcomePage](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WelcomePage.js) （RN 端运行截图待用户回填） | ![OH WelcomePage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/oh_WelcomePage_20260524.png) |

- OH 截图来源：[01_welcome.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/device-smoke-20260524-113416/01_welcome.png)
- 实测视觉：白底 + 居中 welcome 插画 + "Welcome" 手写体，与 RN `welcome.png` 一致。

## 4. 差异处理

- 已修齐：
  - 顶层背景使用 `GSYColor.white`，居中 contain 渲染 `welcome.png`，整体视觉与 RN 端一致。
  - 3000ms 延迟后路由分流（LoginPage / HomePage），与 RN 行为对齐。
- OH 增强：
  - 提供 `Preferences` + `AppStorage` 双层 token 兜底读取，避免重复登陆。
- 平台豁免：
  - Lottie 动画：待 Lottie ArkTS 解码方案落地后补回。
  - `userActions.initUserInfo()` 网络校验：拆分到 HomePage 的 `aboutToAppear` 处再做，避免在 Welcome 阻塞 3 秒外的额外网络等待。
