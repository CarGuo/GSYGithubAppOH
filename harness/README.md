# harness/ — GSYGithubAppOH AI 工程化沉淀

本目录是 AI 协作的"项目大脑"，沉淀 ArkUI / HarmonyOS 端的架构、需求、决策、测试、回归与升级 SOP。
蓝本对照：[https://github.com/CarGuo/GSYGithubApp/blob/master/harness/README.md](https://github.com/CarGuo/GSYGithubApp/blob/master/harness/README.md)（RN 端同名工程）。

## 目录结构

```
harness/
├── README.md                          # 本文件
├── architecture/                      # 系统架构沉淀
│   ├── overview.md                    # 分层 / 关键依赖 / 启动流程
│   ├── modules.md                     # 模块清单：pages / components / store / dao / net / utils …
│   ├── data-flow.md                   # 登录、列表、MD 渲染、刷新桥、i18n、缓存
│   └── native-bridges.md              # Web / 文件下载 / 分享 / 图片选择 / 剪贴板
├── requirements/                      # 按域拆分的功能需求
│   ├── README.md
│   ├── auth.md                        # 登录、Token、OAuth
│   ├── dynamic.md                     # 动态、通知
│   ├── trending.md                    # Trending 与推荐
│   ├── repository.md                  # 仓库详情、文件、提交、Issue
│   ├── search.md                      # 搜索与过滤
│   ├── profile.md                     # 个人主页与设置
│   └── infra.md                       # i18n / 主题 / 缓存 / 日志 / 深链 / AI debug
├── decisions/                         # ADR
│   ├── 0001-record-architecture-decisions.md
│   ├── 0002-arkui-state-mgmt-choice.md
│   ├── 0003-rn-to-arkui-mapping.md
│   ├── 0004-persistence-choice.md
│   └── 0005-debug-signing-config.md
├── iteration/                         # 迭代节奏与变更日志
│   ├── CHANGELOG-AI.md                # AI 改动累积日志
│   └── release-cadence.md             # 里程碑 M0..M9
├── testing/                           # 测试沉淀（hypium）
│   ├── strategy.md
│   ├── unit/README.md
│   ├── component/README.md
│   ├── e2e/README.md
│   └── manual/{auth,dynamic,trending,repository,search,profile,infra}.md
├── regression/                        # 发版前回归
│   ├── checklist.md
│   └── known-issues.md
└── playbooks/                         # SOP / 操作手册
    ├── add-feature.md
    ├── ai-auto-debug.md
    ├── upgrade-deveco.md
    └── debug-signing.md
```

## 使用方式（AI 与人类协同）

1. **接到任务** → 先在 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/) 与 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/) 找对应章节；同步参考 RN 端蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/harness/](https://github.com/CarGuo/GSYGithubApp/blob/master/harness/)。
2. **下笔之前** → 在 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/) 写 ADR（重大方向变更）。
3. **改代码** → 同步补 hypium 单测 / 组件测 / E2E / 手工用例。
4. **完工** → 在 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md) 追加一行；如影响升级，更新 playbooks/。
5. **发版前** → 跑 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/checklist.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/checklist.md)。

## 维护原则
- **可追溯**：所有改动可在 CHANGELOG-AI 找到时间、动机、影响。
- **可重放**：测试沉淀必须能在 hypium / hdc 流程中重放。
- **小且活**：宁可一篇 50 行的活文档，不要 500 行的死文档；定期复盘删过期内容。
- **AI 友好**：跨文件引用统一使用公开 GitHub 链接或项目相对路径，方便 AI 工具点击跳转。
- **平台对齐**：每篇文档都以 RN 端同名文件为蓝本，迁移时优先继承结构再做 ArkUI 适配。
