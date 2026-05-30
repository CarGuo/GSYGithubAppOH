# R8 全链回归报告 — 2026-05-27

> 本报告承接 R8 主链 7 条（L1..L7）的真机回归，按 **三尺度（功能 / UI / log）** 逐页勾叉。
> 所有 ✅ 项均附 hilog 关键字 + dump 关键字段 + 截图 md5 三件套证据。

## 一、设备 / 环境

| 项 | 值 |
|---|---|
| 设备 | hdc target `127.0.0.1:5555` |
| Bundle | `cn.gsy.githubapp` |
| 屏幕 | 1320×2856 |
| 编译 | hvigorw assembleHap BUILD SUCCESSFUL ~10s / 0 ERROR / 仅 3 deprecated WARN（CodeService 195 `decodeWithStream` / CodeDetailPage 179 `getContext` / PersonInfoPage 128 `showDialog`，全部历史长尾，非本批） |
| Hap | [entry-default-signed.hap](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/build/default/outputs/default/entry-default-signed.hap) |
| GetDiagnostics | 0 个 error 跨全部本批改动文件 |

## 二、本轮代码改动清单

| 文件 | 改动 | 关联 KI |
|---|---|---|
| [PushDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PushDetailPage.ets) | 加 `Logger`/`BOOT_PUSH_KEY` import；onReady 加诊断埋点 + BOOT_PUSH_KEY 兜底解析 `fullName\|sha` | KI-045 |
| [IssueDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets) | 加 `Logger`/`BOOT_ISSUE_KEY` import；onReady 兜底解析 `fullName\|number` | KI-045 |
| [HomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets) | scheduleBootPush / scheduleBootIssue：BOOT_KEY 清空时机延后 1500ms（避免兜底失效） | KI-045 |
| [UserDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets) | 抽 [UserCountsRow @Component](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L606-L661)（@ObjectLink store）替代旧 `buildCountColumn @Builder`；删值参冻结 | KI-044 |
| [LoginPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/LoginPage.ets) | 在 component scope 自管 [tokenDialogController](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/LoginPage.ets#L78-L98) + Logger 埋点；不再走挂掉的 `CommonModal.prompt` | KI-046 |
| [CommonModal.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonModal.ets) | `PromptDialog` 改 `export struct` 以便 LoginPage 内 new 自己的 controller | KI-046 |
| [known-issues.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) | 新增 KI-043（@Builder 值参冻结根因）/ KI-044（UserDetail counts）/ KI-045（NavDest ctx 取参失败 BOOT_KEY 兜底）/ KI-046（LoginPage token CustomDialog 必须 component scope） | — |

## 三、三尺度逐页勾叉

| 链 | 页 | 功能 | UI（dump） | log（hilog） | 截图 md5 |
|---|---|---|---|---|---|
| L1 | [RepositoryDetailPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryDetailPage.ets) | ✅ counts 4 cell（star=2477 / fork=431 / watch=60 / issue=8） | ✅ RepositoryHeader 子组件 @ObjectLink 修复（KI-043） | ✅ `boot/ts` 链路完整 | `e55f3c467bd3bfb6ebbd8e48f8669f41`（R-2 报告） |
| L2 | [PushDetailPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PushDetailPage.ets) | ✅ commit=true / files=9 | ✅ dump 命中 commit header + files list | ✅ `boot/ts PushDetailPage.onReady bootKey-fallback fullName='CarGuo/GSYGithubApp' sha='f0926073...'` | [push_v2.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/push_v2.jpeg) `914ea40d5fb6e21563ec4b183b98be74` |
| L3 | [IssueDetailPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets) | ✅ state='关闭' / #155 / title='Bump fast-xml-parser' | ✅ dump 命中 state pill + 标题 + body | ✅ `boot/ts IssueDetailPage.onReady bootKey-fallback fullName='CarGuo/GSYGithubApp' number=155` | [issue.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/issue.jpeg) `36a6f63c0ecc254805a1f5638636b3dd` |
| L4 | [CodeDetailPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets) | ✅ htmlLen=8271 | ✅ dump 命中 webview content | ✅ 已有 BOOT_CODE_KEY 兜底（无需改动） | [code.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/code.jpeg) `f33d52e6bd4686e1e9c753f9e94c4a02` |
| L5 | [UserDetailPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets)（头部） | ✅ name='Shuyu Guo' + bio | ✅ dump 命中 user_detail_name / login / bio | ✅ 已有 tryAdoptBootUser BOOT_USER_KEY 兜底 | [user.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/user.jpeg) `db7ee75b876a217855e80d82b4a1df35` |
| L5 | UserDetailPage（counts 修复） | ⏳ R-5 时点：代码层 closed；真机三件套留 R8-L7 一次性补 | — | — | 代码层 closed → R8-L7 闭环 |
| Login | [LoginPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/LoginPage.ets) Token 弹窗 | ✅ 点击有反应 + 弹窗内 TextInput / 取消 / 确定按钮命中 | ✅ dump 命中 `Text '使用 Token 登录' [454,1199][866,1265]` + `TextInput [205,1307][1115,1461]` + `Button '取消'/'确定'` | ✅ hilog `[login/token] openTokenPrompt clicked` + `[login/token] prompt onCancel` 双向 | [login_dialog.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/login_dialog.jpeg) `55f115ae45f35b4360d6725223b65345` |

## 三-补、R8-L7 全链回归（2026-05-27 登录后补回归）

> 用户已登录 → force-stop + `aa start --ps bootXxx` 单链路冷启 → 各页逐一 dump + 截图。

### KI-044 二次根因发现 + 二次修复（**重要**）

R-4 把 `buildCountColumn @Builder` 改成 `UserCountsRow @Component` 仍 `---`。**二次根因**：[UserCountsRow.build](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L628-L746) 内部又用 `@Builder buildCell(value: string, ...)` 接 `string` 值参 → @Builder 值参冻结复发（KI-043/044 同款陷阱第三次出现）。**根治**：把 5 个 cell 全部 inline 内联到 `build()` 里，不再走 @Builder 中间层，让 `this.fmt(this.store.user.public_repos)` 在 @ObjectLink store 触发的 build 重渲染中真正重新求值。BUILD SUCCESSFUL 9s 553ms / 0 ERROR / GetDiagnostics 0。

### 三件套（hilog + dump + 截图 md5）

| 链 | 页 | 功能（dump 真值） | log（hilog 关键字） | 截图 md5 |
|---|---|---|---|---|
| L7-bootUser | [UserDetailPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets) | ✅ `user_detail_repos_count='61'` / `followers_count='8003'` / `following_count='2'` / name='Shuyu Guo' / login='CarGuo' / bio='Flutter & Dart GDE...'；stared/be_stared='---'（异步分页接口未到，与 RN 同款合理） | `[boot/ts] HomePage.scheduleBootUser` + `[user/boot] UserDetailPage.tryAdoptBootUser adopted login=CarGuo` | [user_l7.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/user_l7.jpeg) `4fe88d6bf6cc43e6dbfd958275a4782e` / [dump_user_l7.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/dump_user_l7.json) `0a0d74b09d153447b54635b9e7999f0c` |
| L7-bootRepo | [RepositoryDetailPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/RepositoryDetailPage.ets) | ✅ owner='CarGuo' / name='GSYGithubApp' / language='JavaScript' / size='17.31M' / license='Apache License 2.0' / star=' 2477' / fork=' 431' / watch=' 60' / issue=' 8' / topics=github,react-native,weex / 4 底栏 cell 齐 | `[boot/ts] RepositoryDetailPage.aboutToAppear fullName='CarGuo/GSYGithubApp'` + `.onReady previous='CarGuo/GSYGithubApp'` | [repo_l7.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/repo_l7.jpeg) `14812ecba30ee9e0721f893569891617` / [dump_repo_l7.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/dump_repo_l7.json) `13da6022487a8830305d8d12b06858f6` |
| L7-bootPush | [PushDetailPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/PushDetailPage.ets) | ✅ author='AI Solo' / email='ai@solo.local' / message='Merge feat/realm-20.2.0 -> master: realm root-cause upgrade + close KI-013/016' / additions='+136' / deletions='-210779' / files=9 / date='2026-05-21T09:19:20Z' | `[boot/ts] PushDetailPage.onReady bootKey-fallback fullName='CarGuo/GSYGithubApp' sha='f0926073'` + `loadAll done result=true code=200 commit=true files=9` | [push_l7.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/push_l7.jpeg) `196caab84029114ed71b34560a101f86` / [dump_push_l7.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/dump_push_l7.json) `bd97fa436ac6f33da01a2893ab37077a` |
| L7-bootIssue | [IssueDetailPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets) | ✅ state='关闭' / number='#155' / title='Bump fast-xml-parser from 4.5.3 to 4.5.4' / user='dependabot[bot]  03-01 05:41' / comment_count='1' | `[boot/ts] IssueDetailPage.onReady bootKey-fallback fullName='CarGuo/GSYGithubApp' number=155` | [issue_l7.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/issue_l7.jpeg) `7c494300d97a634b668a22220e0a96a8` / [dump_issue_l7.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/dump_issue_l7.json) `d27cf75c65793dbe9d2d07d6236a84af` |
| L7-bootCode | [CodeDetailPage](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets) | ✅ webview 挂载（code_detail_web）+ htmlLen=8271 README.md | `[CodeDetail] aboutToAppear adoptBootCode fullName=CarGuo/GSYGithubApp branch=master path=README.md` + `tryLoadHtml ok len=8271` | [code_l7.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/code_l7.jpeg) `23cd95cc25d3c8f934ebaa5e3182e189` / [dump_code_l7.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/dump_code_l7.json) `913622fb9ce5188bcca772566c7e1e18` |

## 四、未结清遗留

| ID | 严重度 | 描述 | 处理 |
|---|---|---|---|
| KI-035 | P1 | IssueDetailPage Δ8 全功能（编辑 / 删除 / 锁 / 编辑评论） | Open，留 R8-L3 拆分批 |
| ~~KI-044 真机三件套补充~~ | ~~P1~~ | ~~UserDetail counts 代码已修，真机三件套需登录态再 boot bootUser 回归~~ | ✅ R8-L7 已闭环，二次修复（cell inline）+ 真机 dump 命中 `61/8003/2` |
| CommonModal.prompt static 实现 | P2 | 全工程虽仅 LoginPage 一处生产用 + ohosTest 测试页 | 候选 KI-047，留长尾重构 |
| @Builder 值参冻结模式登记 | P1 | KI-043/044 三连暴露：sub @Component 不够，内部 @Builder 也不能接 string 值参 | 候选 KI-048：守则——@ObjectLink/@State 直接 inline 求值，禁止经 @Builder 值参中转 |

## 五、HARD-LAW 自检（含 L7）

- HARD-LAW-1 RN-FIRST：本批主体修复均为代码态/SDK 行为类（@Builder 冻结 / CustomDialog 上下文要求），未涉及 RN UI 比对偏差 ✅
- HARD-LAW-2 TOKEN-ONLY：本批改动 0 字面量颜色/字号/间距 ✅（5 个 cell inline 全部走 GSYColor/GSYFontSize/GSYSpacing）
- HARD-LAW-3 NO-DEBUG-PROBE：所有诊断走 hilog domain `0x0666` / tag `boot/ts`、`login/token`、`user/count/click` ✅
- HARD-LAW-4 TRIPLE-EVIDENCE：每页 hilog + dump + 截图 md5 三件套齐 ✅（KI-044 R8-L7 闭环补齐）
- HARD-LAW-5 6/7-step 拆分：todo R-1..R-5 + L7-1..L7-3 ✅
- HARD-LAW-6 ONE-CHAIN-AT-A-TIME：本会话仅推进 R-2..R-5 + L7 一条链 ✅

## 六、文件 md5 总表

详见 [md5sums.txt](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-regression-20260527/md5sums.txt)。
