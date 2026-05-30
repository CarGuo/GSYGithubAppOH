# R8 主链推进 — 单一权威入口

> 2026-05-25 立项。之前 R6.x / R7.x 反复多轮自评 ✅、用户红牌驳回的历史已彻底归档清理。
> 本目录 `harness/R8/` 是本轮**唯一权威文档源**，任何冲突文档以本目录为准。

---

## 文档地图

| 文档 | 用途 | 何时读 |
|---|---|---|
| [README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/README.md) | 本文，目录索引 | 进入 R8 第一份 |
| [00-rules.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/00-rules.md) | 硬约束 + 6 步流程 + DoD + 反作弊纪律 | 写代码前 |
| [01-status.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/01-status.md) | 实时进度状态板（每 Step 更新）| 接续会话 / 提交前 |
| [L1-RepositoryDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L1-RepositoryDetail.md) | L1 主链全档（RN 基准 + 偏差 + 截图对照）| 推进 L1 时 |
| [L2-PushDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L2-PushDetail.md) | L2 PushDetail 主链 | 推进 L2 时 |
| [L3-IssueDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L3-IssueDetail.md) | L3 IssueDetail 主链 | 推进 L3 时 |
| [L4-CodeDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L4-CodeDetail.md) | L4 CodeDetail 主链 | 推进 L4 时 |
| [L5-UserDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L5-UserDetail.md) | L5 UserDetail 主链 | 推进 L5 时 |
| [L6-missing-pages.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L6-missing-pages.md) | L6 RN 缺失 6 页补齐计划 | 推进 L6 时 |
| [L7-regression.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L7-regression.md) | L7 全链回归 | 推进 L7 时 |

---

## 主链清单（执行顺序固定）

| 主链 | 页 | 状态 | 详档 |
|---|---|---|---|
| L1 | RepositoryDetailPage（4 tab）| 🔄 in-progress | [L1-RepositoryDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L1-RepositoryDetail.md) |
| L2 | PushDetailPage | ⏳ pending | [L2-PushDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L2-PushDetail.md) |
| L3 | IssueDetailPage | ⏳ pending | [L3-IssueDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L3-IssueDetail.md) |
| L4 | CodeDetailPage | ⏳ pending | [L4-CodeDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L4-CodeDetail.md) |
| L5 | UserDetailPage | ⏳ pending | [L5-UserDetail.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L5-UserDetail.md) |
| L6 | RN 缺失 6 页（含 RecommendPage 复活）| ⏳ pending | [L6-missing-pages.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L6-missing-pages.md) |
| L7 | 全链 scenario-tour 回归 | ⏳ pending | [L7-regression.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L7-regression.md) |

实时状态（含 6 步进度）见 [01-status.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/01-status.md)。

---

## 执行铁律（违反即回滚）

详见 [00-rules.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/00-rules.md)。摘要：

1. **RN-FIRST**：动 ArkTS 前必须先读 RN 源 + 写本主链 RN 基准节
2. **TOKEN-ONLY**：0 字面量颜色/字号/间距，全走 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets)
3. **NO-DEBUG-PROBE**：UI 树 0 调试 Text，需要诊断走 hilog domain `0x0666`
4. **TRIPLE-EVIDENCE**：RN 截图 + OH 截图 + 差异说明，缺一不可
5. **6-STEP**：S1 Read RN → S2 Diff → S3 Fix → S4 Build → S5 RunOnDevice → S6 Compare
6. **ONE-CHAIN-AT-A-TIME**：本主链 DoD 不达标，禁止开下一条

---

## 快速命令

```bash
# 编译 + 装机
export DEVECO_HOME="<DevEco Studio Contents path>"
source scripts/env.sh
hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon
hdc -t 127.0.0.1:5555 install -r entry/build/default/outputs/default/entry-default-signed.hap

# 跑某主链场景（示例 L1 4 tab）
SCENARIOS="repoDetail-activity repoDetail-readme repoDetail-issues repoDetail-files" \
  OUT_DIR=/tmp/r8-l1-$(date +%H%M%S) \
  bash scripts/scenario-tour.sh
```
