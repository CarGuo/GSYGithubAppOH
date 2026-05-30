# SOP — 新增功能

> 蓝本：[https://github.com/CarGuo/GSYGithubApp/blob/master/harness/playbooks/add-feature.md](https://github.com/CarGuo/GSYGithubApp/blob/master/harness/playbooks/add-feature.md)。

## 1. 立项 / 读 RN 蓝本
- 在 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/) 找到对应 Page 与 dao，理解输入 / 输出。
- 在 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/requirements/) 对应域文件追加用户故事 / 验收标准。

## 2. 设计 / 写 ADR（如有重大变更）
- 跨多域 / 改 API / 引入新 ohpm 包 → 在 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/) 加 ADR。
- 在 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/data-flow.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/data-flow.md) 中描绘新数据流。

## 3. 实现
- 数据访问统一通过 `dao/` 抽象，禁止 Page 内直接 `@ohos.net.http`。
- 状态走 store 类（@Observed），全局只读走 AppStorage，跨页广播走 emitter。
- 复用 `components/common` / `components/widget` 已有控件；新增控件先评估通用性归类。

## 4. 测试（必须 ≥ 1 + 1 + 1）
- 至少 1 条 hypium 单测（utils / dao / store 纯逻辑）。
- 至少 1 条 hypium 组件测（关键 ETS 组件交互）。
- 关键链路（登录 / 仓库 / 搜索）补 1 条 E2E。
- 详见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/strategy.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/strategy.md)。

## 5. 收尾
- 更新对应 requirements 验收标准与测试矩阵。
- 在 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md) 追加一行（日期 / 里程碑 / 范围 / 描述 / 关联 / 测试结果）。
- 跑 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/checklist.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/checklist.md) 对应章节。
