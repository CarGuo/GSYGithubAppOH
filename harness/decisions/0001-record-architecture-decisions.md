# ADR-0001：使用 ADR 记录架构决策

- **状态**：Accepted
- **日期**：2026-05-24
- **背景**：GSYGithubAppOH 是 GSYGithubApp 的 ArkUI / HarmonyOS 移植版，技术栈与 RN 端差异大（Realm→relationalStore、Redux→@Observed、fetch→@ohos.net.http、WebView→Web、AsyncStorage→preferences、react-navigation→Navigation+NavPathStack 等）。所有"难逆转 / 影响多模块"的决策必须沉淀，避免重复探查。
- **决策**：所有架构决策落入 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/) 目录，编号递增，命名 `NNNN-kebab-title.md`。
- **结果**：
  - 提供给 AI 协作工具与新成员一份"项目大脑"。
  - 与 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md) 共同形成时间线。
  - 与 RN 端 [https://github.com/CarGuo/GSYGithubApp/blob/master/harness/decisions/0001-record-architecture-decisions.md](https://github.com/CarGuo/GSYGithubApp/blob/master/harness/decisions/0001-record-architecture-decisions.md) 风格一致，跨平台决策可互相引用。

## ADR 模板
```
# ADR-NNNN: 标题

- 状态：Proposed | Accepted | Superseded by ADR-XXXX
- 日期：YYYY-MM-DD
- 背景：...
- 决策：...
- 备选方案：...
- 影响：...
```

## 当前 ADR 索引
| 编号 | 标题 | 状态 |
|---|---|---|
| 0001 | 使用 ADR 记录架构决策 | Accepted |
| 0002 | ArkUI 状态管理选型（@Observed/@ObjectLink + AppStorage） | Accepted |
| 0003 | RN → ArkUI 技术栈映射 | Accepted |
| 0004 | 持久化方案选 relationalStore（24 张表 schema） | Accepted |
| 0005 | DevEco 自动签名流程 | Accepted |
