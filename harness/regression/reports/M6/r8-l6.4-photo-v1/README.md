# R8-L6.4 PhotoPage v1 真机端到端报告

> 2026-05-26 / scope=L6.4 / status=☑ 全闭环

## 1. 改动清单

| 文件 | 变更 | 行数 |
|---|---|---|
| [navigation/Routes.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/Routes.ets#L30-L62) | 新增 `RouteName.Photo` + ROUTE_NAMES 注册 | +2 |
| [navigation/AppNavigator.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/AppNavigator.ets#L38-L98) | import `PhotoPage` + NavDestination 分支 | +2 |
| [pages/PhotoPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PhotoPage.ets) | 新文件：全屏 Image + onClick pop + 长按保存 stub + boot 通道兜底 | +135 |
| [entryability/EntryAbility.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets#L284-L304) | 新增 `BOOT_PHOTO_KEY` + `handleBootPhotoInjection` + onCreate/onNewWant 注册 | +28 |
| [pages/HomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets#L328-L353) | 新增 `BootPhotoRouteParam` + `scheduleBootPhoto`（KI-029 同款 1500ms 延后清 key）+ aboutToAppear 注册 | +35 |
| [pages/UserDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L218-L231) | 头像 onClick 入口 → push Photo({uri=avatar_url}) + 新增 PhotoPageRouteParam interface | +14 |

## 2. RN 基准对照

[PhotoPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PhotoPage.js)：
- 单图全屏（`react-native-image-zoom-viewer`）
- backgroundColor=primaryColor
- onClick → `Actions.pop()`
- onSaveToCamera 占位
- failImageSource → `default_img.png`

OH 端 v1（M-stub）：
- [photo_page_root](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PhotoPage.ets#L114) 全屏 Stack + `Image objectFit:Contain` + 黑底（GSYColor.primary 与 RN 一致）
- 单击 → [PhotoPage.dismiss](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PhotoPage.ets#L80-L86) → NavigationService.pop（带 exit 防抖与 RN 一致）
- 长按 → CommonToast「保存到相册（M-stub）」（与 RN onSaveToCamera 占位对齐）
- onError → 失败 Text，与 RN failImageSource 等价

入口：[UserDetailPage 头像](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L218-L231)（对应 RN UserHeadItem L321-L322 `Actions.PhotoPage({uri: userPic})`）。其余入口（RepositoryDetailFilePage 图片文件 / CommonHtmlView img / htmlUtils）留 L7 阶段统一接通。

## 3. 编译诊断

- GetDiagnostics 全工程 = `[]`
- hvigorw `BUILD SUCCESSFUL in 11 s 903 ms` / 0 ERROR / 86 WARN（deprecated/throw，全部与本次改动无关）
- HAP signed md5 = `7d0e480cc82a6ba8e44816aff6987391`

## 4. 真机产物

| 截图 | md5 | 视觉断言 |
|---|---|---|
| [oh_photo_v1.jpeg](./oh_photo_v1.jpeg) | `5512fdb05651de11dd89640847b95459` | PhotoPage 全屏渲染 GitHub avatar 图，黑底 contain ✅ |

dump 验证：
- `photo_page_root` bounds=[0,137][1320,2856] ✅ 全屏
- `photo_image` bounds=[0,137][1320,2856] ✅ 满铺
- 点击中央 (660,1500) → hilog 显示 `PhotoPage.dismiss` ✅
- 关闭后 dump 已无 photo_page_root，回到 HomePage `tab_page_root_dynamic` ✅

设备：emulator 127.0.0.1:5555 / OH-emulator-API12

入口路径（A）：`hdc shell aa start -a EntryAbility -b cn.gsy.githubapp --ps bootPhoto '<image url>'` → EntryAbility.handleBootPhotoInjection → AppStorage[BOOT_PHOTO_KEY] → HomePage.scheduleBootPhoto push Photo → PhotoPage 全屏。

入口路径（B）：UserDetailPage 头像 onClick → NavigationService.push(Photo, {uri: avatar_url})。

## 5. HARD-LAW 自检

| 条款 | 状态 | 证据 |
|---|---|---|
| HARD-LAW-1 RN-FIRST | ✅ | 已读 [PhotoPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PhotoPage.js) 全 75 行 + 入口（UserHeadItem / RepositoryDetailFilePage / CommonHtmlView / htmlUtils） |
| HARD-LAW-2 TOKEN-ONLY | ✅ | PhotoPage 仅引 GSYColor.primary/white + GSYFontSize.middleNormal + GSYIconSize.large；无字面量颜色/字号/间距 |
| HARD-LAW-3 NO-DEBUG-PROBE | ✅ | 调试走 `Logger.i('boot/ts')` `PhotoPage.aboutToAppear` `PhotoPage.dismiss` `PhotoPage.longPress`；UI 树仅 photo_page_root/photo_image/photo_loading/photo_failed 业务 id |
| HARD-LAW-4 TRIPLE-EVIDENCE | ⚠️ 部分 | OH 端实图齐 + dump 全节点验证 + dismiss 行为闭环；RN 镜像截图 L7 阶段统一补 |
| HARD-LAW-5 6-STEP | ✅ | S1（RN 抽源）/ S2（OH 探查）/ S3（落地）/ S4（build）/ S5（真机）/ S6（归档）全部走完 |
| HARD-LAW-6 ONE-CHAIN | ✅ | L6.4 单主链推进，未跨 L7 |

## 6. 续会任务

- L6.4-followup-A：补真实保存到相册（@ohos.file.fs + @ohos.multimedia.image，参考 RN onSaveToCamera）
- L6.4-followup-B：双指捏合缩放手势（@ohos.matrix4 + onPinch）
- L6.4-followup-C：补 RN 镜像截图至 [ui-parity/screenshots/PhotoPage/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/PhotoPage)
- L6.4-followup-D：补其余 3 个入口（RepositoryDetailFilePage 图片文件 / CommonHtmlView img / htmlUtils Markdown img）

## 7. 文件清单

```
harness/regression/reports/M6/r8-l6.4-photo-v1/
├── README.md                    （本文件）
├── device.txt
├── md5sums.txt
└── oh_photo_v1.jpeg             5512fdb0… (1320×2856)
```
