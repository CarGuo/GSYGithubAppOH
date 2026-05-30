# 系统能力与桥接（HarmonyOS）

> 蓝本：[https://github.com/CarGuo/GSYGithubApp/blob/master/harness/architecture/native-bridges.md](https://github.com/CarGuo/GSYGithubApp/blob/master/harness/architecture/native-bridges.md)。
> ArkUI 端不存在 RN 那种"原生壳 + JS Bundle"双层结构，所有能力直接调用 HarmonyOS API。

## 1. Web 组件（@ohos.web.webview）
- 用途：Markdown 渲染（README / Issue Body / Diff）+ OAuth 登录页。
- 资源：`entry/src/main/resources/rawfile/md.html` + `highlight.min.js` + `dracula.css`，通过 `Web({ src: $rawfile('md.html'), controller: this.controller })` 加载。
- 主题：dracula（本地内置，禁止 CDN 拉取）。
- 链接拦截：`onLoadIntercept`，匹配 `gsygithub://` scheme → 走 NavService。
- OAuth callback：[entry/src/main/module.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/module.json5) skills 注册 `gsygithub://authed`。

## 2. 文件下载（@ohos.request）
- 用途：Release / 文件页 "Download" 入口、版本更新 APK 下载。
- 关键 API：`request.downloadFile({ url, filePath })`、监听 `progress / complete / fail`。
- 存储位置：`getContext().filesDir + '/downloads/'`。
- 失败兜底：fallback 调起浏览器（IntentBuilder + `ohos.want.action.viewData`）。

## 3. 分享（@ohos.systemShare）
- 用途：仓库 / Issue / 用户主页"分享"按钮。
- API：`systemShareUtils.share({ ... data: { type: 'text/plain', content: url, title } })`。
- 兜底：失败时复制到剪贴板 + Toast 提示。

## 4. 图片选择（@ohos.file.picker）
- 用途：个人头像 / 上传图片到 Issue / 评论。
- API：`new picker.PhotoViewPicker().select({ MIMEType: IMAGE_TYPE, maxSelectNumber: 1 })`。
- 后续：本工程当前无图床；如需上传需引入七牛 / OBS 接口（参考 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/net/qiniu/](https://github.com/CarGuo/GSYGithubApp/blob/master/app/net/qiniu/)）。

## 5. 剪贴板（@ohos.pasteboard）
- 用途：复制仓库地址 / Token / 链接兜底。
- API：`pasteboard.getSystemPasteboard().setData(pasteboard.createData(MIMETYPE_TEXT_PLAIN, content))` → Toast 提示。

## 6. 事件总线（@ohos.events.emitter）
- 用途：跨 Page 刷新桥，参见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/data-flow.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/data-flow.md) 第 4 节。

## 7. 日志（@ohos.hilog）
- 用途：Logger 底座 + 环形缓冲（最近 500 条），dump 配合 ai-debug。
- domain：`0x0666`，tag：`gsygithub`，level：DEBUG / INFO / WARN / ERROR。

## 8. 系统能力门控
- 任何对 [entry/src/main/module.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/module.json5)（权限 / skills / abilities）、[build-profile.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/build-profile.json5)（compatibleSdkVersion / signing）的改动 **必须** 写 ADR 并更新 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/upgrade-deveco.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/upgrade-deveco.md)。
- 新增第三方 ohpm 依赖时：先确认 compatibleSdkVersion ≥ 6.1.0(23)，更新 [oh-package.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/oh-package.json5)，并在本表登记。

## 9. 三方依赖矩阵（计划）
| 包 | 用途 | 风险 |
|---|---|---|
| @ohos/lottie | 启动页 / 空态动画 | 与 SDK 版本绑定，升级时复测 |
| @ohos/axios *（备选）* | 若 @ohos.net.http 不够 | 默认不引入 |
