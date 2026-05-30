# Playbook — CI（GitHub Actions）

> 适用：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/.github/workflows/oh-ci.yml](https://github.com/CarGuo/GSYGithubAppOH/blob/main/.github/workflows/oh-ci.yml)

## 1. 现状与限制
- OpenHarmony SDK 当前**未在 Linux 官方支持** hvigor / hvigorw / DevEco 工具链；ubuntu-latest runner 上无法 `./hvigorw test`。
- 因此 GitHub Actions CI **仅做静态校验 + 套件清单核对**，不跑真机 / 模拟器测试：
  1. 触发：`push` / `pull_request` 到 `main`。
  2. 静态 lint：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/.github/workflows/oh-ci.yml](https://github.com/CarGuo/GSYGithubAppOH/blob/main/.github/workflows/oh-ci.yml) 中 `ETS 静态 lint（ripgrep）` 步骤，校验所有 `*.ets` 不含 `// @ts-ignore`、`any`、`console.log`，产物落地 `.ci-report/lint-report.txt`。
  3. 套件清单核对：跑 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/ci-logic-only.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/ci-logic-only.sh)，列出 `*ServiceTest.ets` / `*Test.ets`（排除 `*UiTest.ets`），核对 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/List.test.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/List.test.ets) 中已 import + 调用 + 套件内 `describe('xxx', ...)`。
  4. 占位安装 `npm i -g @ohos/hpm-cli`，失败不阻断（OH SDK Linux 限制）。

## 2. 真机 / 模拟器测试
- Linux runner 上**不可** `./hvigorw test`。完整 hvigor 测试仍需：
  - 平台：macOS / Windows + DevEco Studio。
  - 入口：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/run-tests.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/run-tests.sh)。
  - 全量：`bash harness/regression/run-tests.sh`。
  - 仅逻辑套件（跳过 `*UiTest`）：`bash harness/regression/run-tests.sh --logic-only`，会 `export LOGIC_ONLY=1`，[https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/List.test.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/List.test.ets) 在 `testsuite()` 起始读 `globalThis.LOGIC_ONLY` / `process.env.LOGIC_ONLY` 决定是否跳过 `*UiTest()` 调用。
  - 帮助：`bash harness/regression/run-tests.sh --help`。

## 3. CI 失败排查
- ripgrep 命中 `// @ts-ignore` / `any` / `console.log`：见 `oh-ci-lint-report` artifact，按文件清理。
- 套件清单不一致：检查 `List.test.ets` 是否漏 import / 漏调用，或某 `*ServiceTest.ets` / `*Test.ets` 缺 `describe('xxx', ...)`。
- `WARN: 套件文件 X.ets 未在 List.test.ets 中 import`：磁盘存在但未注册的套件，仅警告（避免破坏现有未注册的本地实验文件）；如需启用，到 `List.test.ets` 中追加默认 import + 调用。

## 4. 后续切换
当 huawei 提供 Linux SDK / Linux 端 hvigor 后：
1. 在 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/.github/workflows/oh-ci.yml](https://github.com/CarGuo/GSYGithubAppOH/blob/main/.github/workflows/oh-ci.yml) 中：
   - 移除占位 `Install hpm-cli` 注释，改为真实安装。
   - 增加 `setup OpenHarmony SDK` 步骤（`OHOS_SDK_HOME` / `HOS_SDK_HOME`）。
   - 在 `跑逻辑套件清单核对` 之后追加 `./hvigorw test --mode module -p product=default --no-daemon`，即可与 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/run-tests.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/run-tests.sh) 在本地的行为对齐。
2. 仍保留 lint + 套件清单核对作为快速门禁。

## 5. 相关文件
- [https://github.com/CarGuo/GSYGithubAppOH/blob/main/.github/workflows/oh-ci.yml](https://github.com/CarGuo/GSYGithubAppOH/blob/main/.github/workflows/oh-ci.yml)
- [https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/ci-logic-only.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/ci-logic-only.sh)
- [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/run-tests.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/run-tests.sh)
- [https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/List.test.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/List.test.ets)
- [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/checklist.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/checklist.md)
