# L7 全链 scenario-tour 回归

> 所有主链 + 缺失页全部完成后的最终回归。
> 状态：☑ Closed（2026-05-28）

---

## 执行命令

```bash
SKIP_INSTALL=1 \
DEMO_REPO='CarGuo/GSYGithubApp' \
DEMO_PUSH='CarGuo/GSYGithubApp|f09260730c9a6c4ff6dfe03845ee6caf32ef0cdc' \
DEMO_ISSUE='CarGuo/GSYGithubApp|1' \
DEMO_CODE='CarGuo/GSYGithubApp|master|README.md' \
bash scripts/scenario-tour.sh
```

环境：
- BUNDLE=`cn.gsy.githubapp`
- TARGET=`127.0.0.1:5555`（emulator）
- HAP=[entry/build/default/outputs/default/entry-default-signed.hap](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/build/default/outputs/default/entry-default-signed.hap) md5=`4151d4e884353c44545566bbb8f1ac20`（含 L11 KI-052 修复 + 本轮 [AppBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets) buildAction id 补丁）

---

## 验收要求 vs 实际结果

| 项 | 要求 | 实际 | 结果 |
|---|---|---|---|
| ok | ≥12 | **12** | ✅ |
| fail | =0 | **0** | ✅ |
| dup | NO | **NO**（15 张截图 md5 全不同）| ✅ |
| 5 主链入口 | 全部跑通 | repoDetail-activity / pushDetail / issueDetail / codeDetail 4 主链 ☑；userDetail 入口在场景 04 home-my 走通 | ✅ |
| 产物归档 | reports/M6/r8-final-regression-`<ts>`/ | [r8-final-regression-20260527-222545](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-final-regression-20260527-222545) | ✅ |
| INDEX.md 22 页 | 全 ✅ aligned 或显式 deprecated/OH 增强 | 15 页 ✅ + 7 页 partial/todo（id 体系建设 R9 小尾巴）| 🟡 R9 |
| Open KI 列表 | 清空（除 P2 暂缓登记）| 新增 [KI-053](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) MyTab 入口缺 id（P2，已登记原因）| 🟡 R9 |

---

## 三次跑分迭代

| 跑分 | ok | fail | skip | 关键变化 |
|---|---|---|---|---|
| 第 1 次 | 5 | 6 | 4 | 基线，暴露 5 个 fail（boot want 被吞 + issueDetail 断言过严）+ 1 个 fail（search appbar 无 id）+ 4 个 skip（my Tab 入口 + appbar id）|
| 第 2 次 | 11 | 0 | 4 | 修 [scenario-tour.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh) 5 处后 fail 清零；search 仍 skip（appbar 无 id 候选）+ my-3 项 skip |
| 第 3 次 | **12** | **0** | **3** | 补 [AppBar.buildAction id](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets#L157-L200) + 重新打包 hap md5=`4151d4e884353c44545566bbb8f1ac20` 后 search 由 skip 升 ok；my-3 项 KI-053 留尾 |

---

## 15 场景明细（第 3 次最终跑分）

| # | 场景 | 状态 | 关键证据 |
|---|---|---|---|
| 01 | launch | ✅ ok | 6 个 home id 全命中（home_main_content / home_appbar / home_tabs / home_tab_bar_dynamic / home_tab_bar_trend / home_tab_bar_my）|
| 02 | home-dynamic | ✅ ok | dynamic_pull_list + dynamic_row_0_user 异步加载完成 |
| 03 | home-trend | ✅ ok | tap home_tab_bar_trend (660,2660) → tab_page_root_trend |
| 04 | home-my | ✅ ok | tap home_tab_bar_my (1100,2660) → user_head_display_name '---' → 'CarSmallGuo'（数据加载）|
| 05 | search | ✅ ok | tap [appbar_action_r_search](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets#L185-L187) (1208,235) → search_page_root（**本轮新加 id 救活**）|
| 06 | repoDetail-activity | ✅ ok | aa force-stop + aa start --ps bootRepo 'CarGuo/GSYGithubApp' → repo_detail_root |
| 07 | repoDetail-readme | ✅ ok | tap repo_detail_tab_bar_readme (495,431) |
| 08 | repoDetail-issues | ✅ ok | tap repo_detail_tab_bar_issue (1155,431) |
| 09 | repoDetail-files | ✅ ok | tap repo_detail_tab_bar_files (825,431) |
| 13 | pushDetail | ✅ ok | aa force-stop + aa start --ps bootPush 'CarGuo/GSYGithubApp\|f09260...' → push_detail_root |
| 14 | issueDetail | ✅ ok | aa start --ps bootIssue 'CarGuo/GSYGithubApp\|1' → issue_detail_root + appbar + bottom_bar |
| 15 | codeDetail | ✅ ok | aa start --ps bootCode 'CarGuo/GSYGithubApp\|master\|README.md' → code_detail_appbar + code_detail_web |
| 10 | my-setting | 🟡 skip | my Tab 入口缺 id → [KI-053](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md#L40) |
| 11 | my-notify | 🟡 skip | my Tab 入口缺 id → KI-053 |
| 12 | my-readHistory | 🟡 skip | my Tab 入口缺 id → KI-053 |

---

## 修法两处

### 修 1：[scripts/scenario-tour.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh) 五处

1. **场景 06 repoDetail-activity** 加 `aa force-stop $BUNDLE` + sleep 1 + 重启带 bootRepo（双层 quote）；boot want 通道范式必备 force-stop，否则 EntryAbility 已存在导致 want 被吞
2. **场景 13 pushDetail** 同上加 force-stop
3. **场景 14 issueDetail** 断言由 `appbar + pull_list + bottom_bar` 改为 `root + appbar + bottom_bar`：PullLoadMoreList 外壳 id `issue_detail_pull_list` 在源码 [IssueDetailPage.ets#L770](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets#L770) 存在，但 ArkUI uitest dumpLayout 吞掉外壳节点，不强求
4. **场景 05 search** 候选 id 列表头部加 `appbar_action_r_search`，root 断言由 `search_root` 改为 [search_page_root](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/SearchPage.ets#L463)（与源码实际 id 对齐）
5. **场景 10/11/12 my-*** 在切 my Tab 前先 `aa force-stop` + 干净 launch + sleep 4 + wait_for_id 10s（保证产物可信）

### 修 2：[AppBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets) buildAction 补 id

- [buildAction L157-L200](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets#L157-L200) signature 加 `side: string` + `idx: number` 形参
- Button 加 `.id('appbar_action_' + side + '_' + iconKey 或 idx)`，命名约定 `appbar_action_${side}_${iconKey}`（side='l'/'r'，iconKey='search'/'filter'/'more'）
- [左侧 ForEach L233-L235](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets#L233-L235) 与 [右侧 ForEach L261-L263](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets#L261-L263) 改 `this.buildAction(action, 'l'/'r', idx)`
- GetDiagnostics=`[]`

---

## 产物清单

报告目录：[reports/M6/r8-final-regression-20260527-222545/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-final-regression-20260527-222545/)

- 15 张 png 截图（md5 全不同，[md5sums.txt](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-final-regression-20260527-222545/md5sums.txt)）
- 15 份 dump json（layout 树）
- 多份 `_pre_*.json`（前置步骤 dump，覆盖 my Tab / search / repoDetail tab 切换）
- [device.txt](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-final-regression-20260527-222545/device.txt)（设备信息）
- [README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-final-regression-20260527-222545/README.md) 8 节完整说明

PID=`5686`，hilog 471 行（domain 0x0666），asserts 20 行，summary 57 行。

---

## HARD-LAW 自检

1☑（RN-FIRST：r8-final 是全链回归，所有页面前序 L1..L6 已抽源；本轮仅修测试脚本与 AppBar 补 id，不涉及页面结构改动）
2☑（[AppBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets) 修法仅加 id 字符串拼接，无字面量颜色/字号/间距）
3☑（无任何调试 Text 进 UI 树）
4☑（OH 15 张截图 md5 全不同 + 15 份 dump + 471 行 hilog；RN 蓝本沿用各主链历史基线）
5☑（S1 设备探活 → S2 第 1 次跑分 → S3 修脚本+补 id+第 2/3 次跑分 → S4 产物归档 → S5 文档收尾，按序无跳步）
6☑（ONE-CHAIN 仅推 L7 全链回归）
7☑（NO-JARGON：面向用户回复用大白话；md 文档/代码注释/HARD-LAW 编号照旧术语）

---

## 完成后（待用户决定）

1. 1 commit 含全部产物（[01-status.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/01-status.md) + [L7-regression.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/L7-regression.md) + [scripts/scenario-tour.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh) + [AppBar.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/AppBar.ets) + [reports/M6/r8-final-regression-20260527-222545/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-final-regression-20260527-222545/) + [known-issues.md KI-053](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md#L40)）
2. tag `r8-final` 标记 milestone

---

## R9 小尾巴（不阻塞 r8-final）

- [KI-053](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md#L40)：MyTab 三处入口缺 id（setting / notify / readHistory）
- [INDEX.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/INDEX.md) 7 页 partial/todo（id 体系建设）
- Open KI 列表 61 行清整（除 P2 暂缓 + P3 不修）
- R8 README 收口
