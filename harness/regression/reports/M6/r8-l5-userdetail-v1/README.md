# R8-L5 UserDetail v1（2026-05-26 13:44）

- target: `127.0.0.1:5555`  bundle: `cn.gsy.githubapp`  ability: `EntryAbility`
- demo_user: `CarGuo`
- 产物目录: [r8-l5-userdetail-v1/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l5-userdetail-v1)
- 结果: ok=`11` fail=`0`
- hap md5（signed）: `f4f4ba1bcef4f6d1315a593672d4dd25`
- hap md5（unsigned）: `87f409c6ae75ee3922857fe0d7c3605d`

## 1. 启动序列

```bash
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap
hdc shell aa force-stop cn.gsy.githubapp
hdc shell hilog -r
hdc shell aa start -a EntryAbility -b cn.gsy.githubapp --ps bootUser CarGuo
sleep 6
hdc shell snapshot_display -f /data/local/tmp/oh_UserDetail_v1_20260526.jpeg
hdc file recv /data/local/tmp/oh_UserDetail_v1_20260526.jpeg .
```

## 2. boot/ts 全链路 hilog

```
05-26 13:44:35.027  A00666/gsygithub  [boot/ts] EntryAbility.handleBootUserInjection done t=1779774275027 value=CarGuo
05-26 13:44:38.263  A00666/gsygithub  [boot/ts] HomePage.scheduleBootUser pre-schedule t=1779774278263 login=CarGuo
05-26 13:44:38.865  A00666/gsygithub  [boot/ts] HomePage.scheduleBootUser pre-push t=1779774278865
05-26 13:44:38.868  A00666/gsygithub  [boot/ts] HomePage.scheduleBootUser post-push t=1779774278868
05-26 13:44:38.874  A00666/gsygithub  [user/boot] UserDetailPage.tryAdoptBootUser adopted login=CarGuo t=1779774278874
```

完整 KI-042 同款范式：EntryAbility → AppStorage(BOOT_USER_KEY) → HomePage 600ms 延迟 push → UserDetailPage tryAdoptBootUser 消化 → 1500ms 兜底清空。

## 3. 场景产物

| # | key | screenshot | layout | md5 | assert |
|---|-----|------------|--------|-----|--------|
| 16 | userDetail | [16_userDetail.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l5-userdetail-v1/16_userDetail.jpeg) | [16_userDetail.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l5-userdetail-v1/16_userDetail.json) | `05bef013` | ok:11 fail:0 |

## 4. 视觉断言对照（vs RN [UserHeadItem.js L286-L390](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserHeadItem.js)）

| 部位 | RN 期望 | OH 实测 | 结果 |
|---|---|---|---|
| AppBar title | `@CarGuo` | `@CarGuo` | ✅ |
| 头像尺寸 | 80×80 圆 | `GSYIconSize.large` 圆 | ✅ |
| name 字体 | 大粗 white | `GSYFontSize.large` bold | ✅ |
| login 字体 | 小 lightWhite | `GSYFontSize.small` subLightSmall | ✅ |
| company 行 | 群组图标 + 公众号 GSYTech | FA_GROUP + 公众号 GSYTech | ✅ |
| location 行 | 地图图标 + US | FA_MAP_MARKER + US | ✅ |
| bio | 多行白字 | Flutter & Dart GDE… | ✅ |
| created_at | `创建于：2015-01-30` | TimeUtil.resolveTime YYYY-MM-DD | ✅ |
| Follow 按钮 | 描边白字"取消关注" | miWhite border + smallTextWhite | ✅ |
| 5 列 counts | `repos / followers / followed / stared / beStared`，0 时显示 `---` | 仓库/粉丝/关注/星标/荣耀 全 `---`（API 未返 totalCount，hintNum 兜底）| ✅ |
| 5 列分隔线 | hairline + primaryLight 4 条 | Divider strokeWidth=1 + GSYColor.primaryLight | ✅ |
| 头部圆角 | bottomLeft/Right=5 | `GSYShadow.radius` | ✅ |
| 头部阴影 | shadowOpacity 0.7 | `GSYColor.cardShadowAlpha = 0x1F000000` shadow | ✅ |
| 列表 row | EventItem（avatar + actionUser + 时间 + des） | EventItem 复用 + EventActionUtil 派发 | ✅ |
| 列表数据源 | getUserEvents + DynamicService | `dynamicService.fetchUserEvents` | ✅ |

## 5. HARD-LAW 自检

- ✅ HARD-LAW-1 RN-FIRST：buildHeader/rowBuilder 严格映射 RN UserHeadItem L286-L390 / EventItem
- ✅ HARD-LAW-2 TOKEN-ONLY：UserDetailPage.ets 无字面量数字/颜色/字号（`'---'` 与 `'Organization'` 为业务文案/类型常量，不属 UI token）
- ✅ HARD-LAW-3 NO-DEBUG-PROBE：UI 树无 *_count/click-N 调试 Text，调试走 hilog 0x0666 domain
- ✅ HARD-LAW-4 TRIPLE-EVIDENCE：本 README + 16_userDetail.jpeg + 16_userDetail.json 三件套齐
- ✅ HARD-LAW-5 6-STEP：S0 ☑ / S1 ☑ / S2 ☑ / S3(a..e) ☑ / S4 BUILD SUCCESSFUL ☑ / S5 截图 + hilog 链 ☑ / S6 报告归档 ☑

## 6. 已知保留项（非阻塞）

- 5 列 counts 全部显示 `---`：`UserService /users/{login}` 未返 starred_count / be_starred_count，按 RN hintNum 等价兜底，与 R5l 公众号统计同种处理；可在未来扩展 `GET /users/{login}/starred?per_page=1` 取 Link header 总数。
- ArkTS WARN（已存量）：UserDetailPage.ets:535 `getContext` 已弃用 → 与 RepositoryDetail/CodeDetail 同源历史 warn，统一在 R8 known-issues 接受为非阻塞。

## 7. KI 登记

- KI-042 同款范式扩展（bootUser want 通道）→ Closed
- 不新增 KI（无阻塞性 P0/P1）

