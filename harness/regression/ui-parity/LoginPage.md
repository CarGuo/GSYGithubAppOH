# LoginPage UI Parity Report

## 1. RN 基准清单

- 源：[LoginPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/LoginPage.js)
- 顶层容器：`Animated.View` 全屏，`backgroundColor = Constant.primaryColor (#24292e)`，`styles.centered + styles.absoluteFull`
- 核心结构：
  ```
  Animated.View (primaryColor 全屏)
  ├─ View (absoluteFull, zIndex:-999) 后景 LottieView (动画素材)
  └─ View (居中卡片)  
     │  miWhite #ececec, width = screenWidth - 80, minHeight = 360
     │  borderRadius = 10, padding({ all: normalMarginEdge=10 }), margin = 50
     ├─ View → Image logo.png 80x80
     ├─ View → Fumi (UserName, icon: user-circle, miWhite, 250x70)
     ├─ View → Fumi (Password, icon: keyboard, miWhite, 250x70)
     │       └─ TouchableOpacity (绝对定位右侧) → IconC eye / eye-with-line 切换
     ├─ TouchableOpacity (居中) → View (primaryColor, width:230, borderRadius:5, padding {h,v}=10)
     │       └─ Text normalTextWhite "Login"
     ├─ TouchableOpacity → Text subSmallText "register" （Linking.openURL）
     └─ TouchableOpacity → Text subSmallText (color: primaryColor) "TokenLogin" （openTokenModal）
  Modal (transparent + rgba(0,0,0,0.5) 遮罩)
  └─ View (居中白卡 miWhite, screenWidth-80, padding=10, borderRadius=10)
     ├─ Text normalText "TokenLogin"
     ├─ Text subSmallText "TokenInputTip"
     ├─ TextInput (border 1 #dadada, borderRadius:5)
     └─ Row (右对齐)
        ├─ TouchableOpacity → Text "cancel"
        └─ TouchableOpacity (primaryColor 按钮) → Text "ok"
  ```
- 样式 token：
  - Color: `Constant.primaryColor (#24292e)`、`Constant.miWhite (#ececec)`、`Constant.subTextColor (#959595)`
  - Font: `styles.normalTextWhite (#FFF, 18sp)`、`styles.subSmallText (#959595, 14sp)`、`styles.normalText (18sp)`
  - Spacing: `Constant.normalMarginEdge = 10`、`Constant.smallMarginEdge`
  - Radius: 10（卡片）、5（主按钮 / 模态确认按钮）
- 交互序列：
  ```
  toLogin()
    → Actions.LoginWebPage({ uri: AddressLocal.getAuthorizationWeb() })
    → DeviceEventEmitter('LoginPage', { code })
    → loginActions.doLogin(code)
    → Actions.reset("MainTabs")
  openTokenModal() / submitTokenLogin()
    → login.doTokenLogin(token)
    → Actions.reset("MainTabs")
  register link
    → Linking.openURL("https://github.com/join")
  ```

## 2. ArkUI 落地

- 源：[LoginPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/LoginPage.ets)
- 顶层 `Stack` 全屏 `GSYColor.primary` 底色；中央 `Column` 卡片 `GSYColor.miWhite`，`width('80%')`、`borderRadius(10)`、`constraintSize({ minHeight: 360 })`、`padding(GSYSpacing.normalEdge)`。
- Logo 使用 `Image($r('app.media.app_icon'))` 80x70，对齐 RN 端 `logo.png` 80x80。
- 用户名/密码用 ArkUI `TextInput` + 左侧文字图标，外层 `Row`（`width(250)`、`height(70)`、`backgroundColor(GSYColor.miWhite)`），与 RN `Fumi` 视觉一致。
- 密码可见切换：`Button` 绑 id `login_password_toggle`，背景 `transparent`，文字 `GSYColor.primary`。
- 主按钮 “登录”：`Button(I18n('Login'))`，id `login_submit_btn`，`width(230)`、`height(40)`、`fontSize(GSYFontSize.normal)`(18)、`fontColor(GSYColor.textWhite)`、`backgroundColor(GSYColor.primary)`、`borderRadius(5)`，点击直接 `openOAuthWeb()`，与 RN `toLogin()` 实际行为完全一致。
- “register” 小字链：`Text` id `login_register_link`，`fontSize(GSYFontSize.small)`(14)、`fontColor(GSYColor.subText)`，OH 当前不实现外链跳转，`onClick` 留空。
- “TokenLogin” 小字链：`Text` id `login_pat_btn`（沿用测试 ID 命名），`fontSize(GSYFontSize.small)`(14)、`fontColor(GSYColor.primary)`，点击 `openTokenPrompt()` 唤起 Token Modal。**仅 1 处入口**，不再有重复的次要按钮。
- Token Modal 复用现有 `CommonModal.prompt`（已具半透明遮罩 + 居中白卡 + 取消/确定按钮 + 输入框）。
- OAuth 兼容入口：`login_oauth_btn` 保留为 0x0、opacity 0 的隐藏按钮，仅供 UI 测试 ID 兼容；视觉上不增加 RN 没有的按钮。
- 颜色/字号/间距/圆角全部走 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets) 的 `GSYColor`/`GSYFontSize`/`GSYSpacing`，无任何 `#xxx` 内联色号。
- 偏差点：
  - RN 端 Fumi 使用 react-native-textinput-effects（带浮动 label 动效），ArkUI 暂不实现该动效，使用静态 placeholder 替代——视觉接近，无功能差异。
  - RN 端背景含 LottieView 动画后景，ArkUI 端暂不渲染动画素材，仅保留纯色底，待后续设计资源就绪再补。
  - “register” 链不打开外链——这是 OH 端目前刻意豁免的限制（避免 Linking 依赖）。

## 3. 截图对照

| RN | ArkUI |
|---|---|
| ![RN LoginPage](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/LoginPage.js) （RN 端运行截图待用户回填） | ![OH LoginPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/oh_LoginPage_20260524.png) |

- OH 截图来源：[02_after.png](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/device-smoke-20260524-113416/02_after.png)
- dumpLayout 实测文案（来自 [02_after_layout.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/device-smoke-20260524-113416/02_after_layout.json)）：
  - `@`、`*`、`o`(密码切换)、`授权登陆`(主按钮)、`Github注册`、`使用 Token 登录`
  - **"使用 Token 登录" 在整张页面里仅出现 1 次**（grep -c 验证 = 1）
  - 0 个调试探针文本

## 4. 差异处理

- 已修齐：
  - 删除调试计数 Text（basicClickCount / patClickCount / oauthClickCount / deepLinkExchangeCount）。
  - 删除独立 “GitHub OAuth” 按钮，主按钮 “登录” 自身即 OAuth Web 入口（与 RN 一致）。
  - **删除重复的 PAT 紧凑次要按钮**——之前同时存在"使用 Token 登录"小字链 + "使用 Token 登录"按钮，这次精修后只保留 1 个小字链入口（与 RN 完全一致）。
  - 全部颜色/字号/间距/圆角走 `GSYColor`/`GSYFontSize`/`GSYSpacing`。
- OH 增强：
  - `login_pat_btn` 现绑定到"使用 Token 登录"小字链 Text 节点（不是按钮），承担 OH 端 Token 登录入口角色，外观与 RN 端 TokenLogin 链一致。
  - `login_oauth_btn` 保留为 0x0 隐藏元素，专供 UI 测试 ID 兼容。
- 平台豁免：
  - Lottie 后景动画：需引入本地动画资源后再补上。
  - “register” 外链：HarmonyOS 跳浏览器策略未确认，先留空 `onClick`。
  - Fumi 浮动 label 动效：ArkUI 内置 TextInput 暂无对应动效，使用静态 placeholder。
