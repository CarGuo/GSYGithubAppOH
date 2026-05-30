# 需求文档索引（ArkUI / HarmonyOS）

按业务域拆分，每个域一份独立 Markdown，便于 AI 单文件聚焦。结构与 RN 端蓝本对齐：[https://github.com/CarGuo/GSYGithubApp/blob/master/harness/requirements/README.md](https://github.com/CarGuo/GSYGithubApp/blob/master/harness/requirements/README.md)。

| 文件 | 域 | 关键页面（计划） |
|---|---|---|
| [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/auth.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/auth.md) | 登录与会话 | LoginPage / LoginWebPage / WelcomePage |
| [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/dynamic.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/dynamic.md) | 动态 / 通知 | DynamicPage / NotifyPage |
| [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/trending.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/trending.md) | Trending / 推荐 | TrendPage / RecommendPage |
| [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/repository.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/repository.md) | 仓库相关 | RepositoryDetailPage 系列 |
| [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/search.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/search.md) | 搜索 | SearchPage |
| [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/profile.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/profile.md) | 个人主页 / 设置 | MyPage / PersonPage / SettingPage |
| [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/infra.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/infra.md) | 基础设施 | i18n / 主题 / 缓存 / 日志 / 深链 / AI debug |

## 维护规范
- 每条需求 = 一段"用户故事 + 关键路径与文件 + 验收标准 + 测试矩阵"四节结构。
- 验收标准必须可被 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/) 中的某条用例覆盖。
- 调整需求时务必同步 ADR（[https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/)）与 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md)。
- 引用 RN 端实现时统一使用公开 GitHub 链接或项目相对路径，display name 不带反引号。
