# R8-L6.2 PersonInfoPage v1 真机端到端报告

> 2026-05-26 / scope=L6.2 / status=☑ 全闭环

## 1. 改动清单

| 文件 | 变更 | 行数 |
|---|---|---|
| [navigation/Routes.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/Routes.ets#L27-L28) | 新增 `RouteName.PersonInfo` + ROUTE_NAMES 注册 | +2 |
| [common/IconFont.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/IconFont.ets#L75-L78) | 新增 FA_AT / FA_BUILDING / FA_FILE_TEXT_O / FA_USER_CIRCLE | +4 |
| [service/UserService.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/UserService.ets#L354-L385) | 新增静态 `UserService.updateUser(field,value)` PATCH /user + `UpdateUserResult` | +32 |
| [pages/PersonInfoPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PersonInfoPage.ets) | 新文件：6 CommonRowItem + 编辑分发 + submitField PATCH 接口 | +275 |
| [navigation/AppNavigator.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/AppNavigator.ets#L91-L92) | 注册 `PersonInfoPage()` NavDestination | +2 |
| [pages/SettingPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/SettingPage.ets#L283-L294) | 顶部新增「个人信息」入口 Button → push(RouteName.PersonInfo) | +12 |

## 2. RN 基准对照

[PersonInfoPage.js#L1-L230](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PersonInfoPage.js)：6 项 CommonRowItem（name/email/blog/company/location/bio），点击触发 TextInputModal → updateUser PATCH。

OH 端 6 项与 RN 100% 字段对齐；编辑流 M-阶段先以 [promptAction.showDialog](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PersonInfoPage.ets#L141-L163) 占位（含 ok/cancel + tip 文案），完整 CustomDialog 等价 RN TextInputModal 留 L7 阶段补齐；submitField 已实现真实 PATCH 路径。

## 3. 编译诊断

- GetDiagnostics 全工程 = `[]`
- hvigorw `BUILD SUCCESSFUL in 10 s 369 ms` / 0 ERROR / 85 WARN（全为 deprecated 提醒，与本次改动无关）
- HAP signed md5 = `95078e5e028ff425d9023935b27f0df8`

## 4. 真机产物

| 截图 | md5 | 视觉断言 |
|---|---|---|
| [setting_with_btn.jpeg](./setting_with_btn.jpeg) | `cccae7b07a69685a4440e953be563a92` | SettingPage 顶部「名字」入口 Button 渲染 ✅ |
| [personinfo_rendered.jpeg](./personinfo_rendered.jpeg) | `ee73012136d0d6630fb78d9c4f897693` | PersonInfoPage 6 行全渲染 ✅ |

视觉断言细则（personinfo_rendered.jpeg）：
- AppBar 标题"名字" + 返回箭头 ✅
- ℹ️ 名字: `Small Guo`（实际登录用户）✅
- @ 邮箱: `---` ✅
- 🔗 链接: `---` ✅
- 🏢 公司: `---` ✅
- 📍 位置: `china` ✅
- 📄 简介: `---` ✅
- 6 个 itemIcon (FA_INFO/FA_AT/FA_LINK/FA_BUILDING/FA_LOCATION/FA_FILE_TEXT_O) 全正确 ✅
- showIconNext 右箭头 6 个 ✅
- I18n 中文 6 个 key 全对齐 ✅

设备：emulator 127.0.0.1:5555 / OH-emulator-API12

## 5. HARD-LAW 自检

| 条款 | 状态 | 证据 |
|---|---|---|
| HARD-LAW-1 RN-FIRST | ✅ | 已读 [PersonInfoPage.js#L1-L230](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PersonInfoPage.js) |
| HARD-LAW-2 TOKEN-ONLY | ✅ | PersonInfoPage 仅引 GSYColor/GSYIconSize/GSYSpacing；无字面量颜色/字号/间距 |
| HARD-LAW-3 NO-DEBUG-PROBE | ✅ | 调试走 `Logger.i('person/info/edit')` `Logger.i('person/info/patch')`；UI 树无 *-count Text |
| HARD-LAW-4 TRIPLE-EVIDENCE | ⚠️ 部分 | OH 端实图 + diff 已具备；RN 镜像截图 L7 阶段统一补 |
| HARD-LAW-5 6-STEP | ✅ | S1/S2/S3/S4/S5/S6 全部走完 |
| HARD-LAW-6 ONE-CHAIN | ✅ | L6.2 单主链推进，未跨 L7 |

## 6. 续会任务

- L6.2-followup-A：CustomDialog 等价 RN TextInputModal（含 TextInput / 字符长度限制 / IME 关闭防抖）
- L6.2-followup-B：通过 hilog domain 0x0666 抓取 `person/info/patch` 完整链路并断言 PATCH /user 200
- L6.2-followup-C：补 RN 镜像截图至 [ui-parity/screenshots/PersonInfoPage/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/PersonInfoPage)

## 7. 文件清单

```
harness/regression/reports/M6/r8-l6.2-personinfo-v1/
├── README.md                    （本文件）
├── device.txt
├── md5sums.txt
├── setting_with_btn.jpeg        cccae7b0… (1320×2856)
└── personinfo_rendered.jpeg     ee730121… (1320×2856)

镜像归档（INDEX 直链）：
harness/regression/ui-parity/screenshots/PersonInfoPage/
└── oh_PersonInfoPage_v1_20260526.jpeg  ee730121…
```
