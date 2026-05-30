# 版本节奏与里程碑

> 蓝本：[https://github.com/CarGuo/GSYGithubApp/blob/master/harness/iteration/release-cadence.md](https://github.com/CarGuo/GSYGithubApp/blob/master/harness/iteration/release-cadence.md)。

## 节奏建议
- **小版本**（patch）：bug 修复 / 文案 / 小改动 — 双周节奏。
- **中版本**（minor）：新需求 / UI 调整 — 每月一次。
- **大版本**（major）：DevEco / SDK 升级、ArkUI 范式调整 — 每年 1-2 次。

## 当前里程碑（M0..M9）
| 里程碑 | 主题 | 判定标准 | 状态 |
|---|---|---|---|
| M0 | 工程骨架 + harness 落地 | 项目可被 DevEco 打开、签名生成、harness 全 31 个文档可读 | ✅ 完成 |
| M1 | 基础设施（HttpClient / Logger / I18n / preferences） | utils + net + i18n 可被任意 Page 引用，单测覆盖 ≥ 60% | 进行中 |
| M2 | 状态管理 + relationalStore 24 表 | 24 张表 CREATE 通过；EventStore / UserStore / RepositoryStore 等核心 store 类落地 | 计划中 |
| M3 | 登录闭环（PAT + OAuth Web） | LoginPage + LoginWebPage + AuthDeepLinkBus + UserDao loginIn/loginOut；E2E login.spec ✓ | 计划中 |
| M4 | 动态 + 通知 | DynamicPage / NotifyPage / EventDao 完成；下拉刷新 + 上拉加载 ✓；离线缓存可读 | 计划中 |
| M5 | 仓库详情体系 | RepositoryDetailPage / FilePage / ActivityPage / CodeDetailPage / Issue 列表 + 详情 ✓ | 计划中 |
| M6 | 搜索 + 个人中心 | SearchPage + Drawer + MyPage / PersonPage / SettingPage ✓ | 计划中 |
| M7 | Trending + Release + About | TrendPage + RecommendPage + AboutPage 检查更新跳转 ✓ | 计划中 |
| M8 | AI Debug 自动化 | DebugDumper（长按 logo / 摇一摇）触发 dump，hdc file recv 闭环；CHANGELOG-AI 接 dump 引用 | 计划中 |
| M9 | 上架准备 | Release Profile 签名 + 隐私清单 + 包大小预算 + 全量回归 [checklist](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/checklist.md) 通过 | 计划中 |

## Freeze 窗口
- 每次 DevEco / SDK 升级期间：除 P0 修复外，主干禁止 merge 大功能。
- 发版前 3 天进入 code freeze，仅允许回归用 fix。
