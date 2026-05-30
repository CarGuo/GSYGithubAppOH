# scenario-tour 全 App 场景测试沉淀流程

> **总入口文档**：把 `hdc + hilog + 截图 + UITest` 组合成一套可维护、可复跑、可归档的全 App 场景巡检流程。
>
> 本流程不替代 [device-smoke.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/device-smoke.md) 的"装机冒烟"，也不替代 [page-build-checklist.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/page-build-checklist.md) 的"逐页 RN-FIRST 比对"，定位是**前两者之间的回归层**：在每个 RN/OH 双端对齐节点（M5/M6/M7…）跑一次，沉淀完整 12 场景截图 + hilog + layout dump，作为里程碑级"App 当前可用性"快照。

---

## 1. 设计目标

| 目标 | 实现方式 |
|---|---|
| **可重复**：换设备 / 换里程碑都能照单全收 | [scripts/scenario-tour.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh) 单命令驱动；[FullTourUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/FullTourUiTest.ets) 单 spec 跑 12 场景 |
| **可定位**：每个截图能找到对应的 hilog 切片 | hilog domain `0x0666` + `GSY_TOUR` / `FullTour` BEGIN/END 标记 |
| **可归档**：产物结构与 M6 既有报告一致 | 复用 [reports/M6/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6) 目录约定 `<scenario>-<ts>/{*.png,*.json,README.md,device.txt}` |
| **可裁剪**：只跑感兴趣场景 | `SCENARIOS="login dynamic"` 环境变量过滤 |
| **可对齐 RN**：每场景与 RN 端 Maestro / 真机截图对位 | 与 [ui-parity-with-rn.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/rules/ui-parity-with-rn.md) HARD-LAW-4 三件套约束兼容 |

---

## 2. 三层架构

```
┌────────────────────────────────────────────────────────────────────┐
│  L3 文档层  harness/playbooks/scenario-tour.md（本文件，总入口）    │
│            harness/regression/reports/M6/scenario-tour-<ts>/README.md（每次跑产物）│
└────────────────────────────────────────────────────────────────────┘
                               ▲
                               │ 沉淀
                               │
┌──────────────────────────┐  ┌─────────────────────────────────────┐
│ L2 驱动层  hdc + 截图 + hilog│  L2 验证层  UITest hypium Driver     │
│  scripts/scenario-tour.sh │  │  entry/.../FullTourUiTest.ets       │
│  - hdc 探活 / install -r   │  │  - 12 场景 × startAbility(targetPage)│
│  - aa start EntryAbility   │  │  - key root id 断言                  │
│  - hilog -T 0x0666 后台抓取 │  │  - Logger.i('FullTour', BEGIN/END)  │
│  - 12 场景 dwell + screenCap│  │                                      │
│  - dumpLayout              │  │                                      │
│  - 汇总 README.md           │  │                                      │
└──────────────────────────┘  └─────────────────────────────────────┘
                               ▲
                               │
┌────────────────────────────────────────────────────────────────────┐
│  L1 设施层  既有资产复用                                              │
│  - [Logger.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/ai-debug/Logger.ets) domain 0x0666 / 环形缓冲 500              │
│  - [TestAbility.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/testability/TestAbility.ets) targetPage 参数路由     │
│  - 19 个 Host 页面（[test_pages.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/resources/base/profile/test_pages.json)）│
│  - hdc / hvigorw 工具链（[device-smoke.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/device-smoke.md) 已说明）         │
└────────────────────────────────────────────────────────────────────┘
```

---

## 3. 12 个核心场景矩阵

每个场景同时被 **scenario-tour.sh ALL_SCENARIOS** 和 **FullTourUiTest.SCENARIOS** 引用，key 严格一致。

| # | key | 场景标题 | UITest targetPage | 期望 root id | dwell |
|---|---|---|---|---|---|
| 01 | `launch` | 启动 / Common 组件清单 | `pages/CommonComponentsPage` | `common_components_root` | 3s |
| 02 | `login` | 登录页（未登录态） | `pages/LoginPage` | `login_root` | 3s |
| 03 | `dynamic` | 动态流（DynamicTab 列表） | `pages/DynamicTabListHostPage` | `dynamic_host_list_root` | 5s |
| 04 | `trend` | 趋势榜（TrendTab 列表） | `pages/TrendTabListHostPage` | `trend_host_list_root` | 5s |
| 05 | `my` | 个人中心（MyTab） | `pages/MyTabPageHost` | `my_host_root` | 4s |
| 06 | `search` | 搜索页（输入 + 分段 + 结果） | `pages/SearchHostPage` | `search_host_root` | 6s |
| 07 | `repoDetail` | 仓库详情（4 Tab） | `pages/RepositoryDetailHostPage` | `repo_detail_host_root` | 8s |
| 08 | `issueDetail` | Issue 详情 | `pages/IssueDetailHostPage` | `issue_detail_host_root` | 6s |
| 09 | `userDetail` | 用户详情 | `pages/UserDetailHostPage` | `user_detail_host_root` | 5s |
| 10 | `notify` | 通知中心 | `pages/NotifyHostPage` | `notify_host_root` | 4s |
| 11 | `readHistory` | 阅读历史 | `pages/ReadHistoryHostPage` | `read_history_host_root` | 3s |
| 12 | `setting` | 设置页（语言/主题/登出） | `pages/SettingPage` | `setting_root` | 3s |

> **新增 / 修改场景** → 必须**两处同步**改：
> 1. [scripts/scenario-tour.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh) 中的 `ALL_SCENARIOS` 数组
> 2. [FullTourUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/FullTourUiTest.ets) 中的 `SCENARIOS` 数组
> 不同步会导致 hilog 切片 README 表与 UITest 实际跑的对不上号（流程会校验失败但不强制 abort）。

---

## 4. 三种运行模式

### 模式 A：仅脚本（人工模式 / 快速冒烟）

最低门槛，**不需要打 UITest hap**，只需要 release/debug HAP 装机：

```bash
# 1. DevEco Build > Build Hap(s)
# 2. 终端：
hdc list targets                                         # 确认 127.0.0.1:5555
bash scripts/scenario-tour.sh                             # 默认全 12 场景
# 3. 在脚本运行期间手动操作 App，dwell 时间内切到对应场景页
# 4. 看产物：
open harness/regression/reports/M6/scenario-tour-*/
```

适用：
- 非开发机抽查（只装机不编译 ohosTest）
- 与 RN 端 Maestro 对照截屏
- 故障复现快照（按 `SCENARIOS="repoDetail"` 反复跑同一场景）

### 模式 B：仅 UITest（自动模式 / CI 化基准）

不依赖人工操作，但也不出截图（截图由模式 C 解决）：

```bash
# 1. DevEco：Build > Build Hap(s) and Test Hap(s)
# 2. 终端：
hvigorw test --filter FullTourUiTest                      # 12 场景全跑
# 3. 看 hilog（设备未连可在 DevEco 控制台过滤 GSY_TOUR）：
hdc shell hilog -T 0x0666 | grep -E 'FullTour|GSY_TOUR'
```

适用：
- 每次 PR 跑一遍验证 12 场景的 root id 没有 regression
- M6→M7 升级前的"是否还能拉起每页"快测

### 模式 C：脚本 + UITest 双开（自动模式 / 完整里程碑沉淀，**推荐**）

两个终端同时跑，UITest 推页 + 脚本截图，5 分钟内出齐 12 张截图 + 12 段 hilog 切片：

```bash
# 终端 1（脚本驱动 + 截图）：
HDC_TARGET=127.0.0.1:5555 \
  bash scripts/scenario-tour.sh
# 提示：脚本启动后会先 install -r 主 HAP 再 aa start EntryAbility，
# 然后开始 12 个 dwell 循环。在终端 2 同步启动 UITest：

# 终端 2（UITest 推页）：
hvigorw test --filter FullTourUiTest

# 4. 等到两个终端都 DONE，看产物：
open harness/regression/reports/M6/scenario-tour-*/README.md
```

> **dwell 余量**：脚本的 dwell（3-8s）已包含 UITest startAbility（~1.5s）+ delayMs(800) + 渲染稳定（1-3s）。
> 若网络慢导致仓库详情/搜索结果未加载完，调大：`SCENARIO_DELAY=8 bash scripts/scenario-tour.sh`。

---

## 5. 产物结构（每次跑生成一个目录）

```
harness/regression/reports/M6/scenario-tour-20260525-143012/
├── README.md                         ← 总览（场景表 + hilog 切片提示 + UITest 模式说明）
├── device.txt                        ← target / 系统版本 / TS / BUNDLE
├── install.log                       ← hdc install -r 输出
├── start.log                         ← aa start 输出
├── hilog_business.log                ← 全程 domain=0x0666 业务日志
├── 01_launch.png        / 01_launch_layout.json
├── 02_login.png         / 02_login_layout.json
├── 03_dynamic.png       / 03_dynamic_layout.json
├── 04_trend.png         / 04_trend_layout.json
├── 05_my.png            / 05_my_layout.json
├── 06_search.png        / 06_search_layout.json
├── 07_repoDetail.png    / 07_repoDetail_layout.json
├── 08_issueDetail.png   / 08_issueDetail_layout.json
├── 09_userDetail.png    / 09_userDetail_layout.json
├── 10_notify.png        / 10_notify_layout.json
├── 11_readHistory.png   / 11_readHistory_layout.json
└── 12_setting.png       / 12_setting_layout.json
```

---

## 6. hilog 切片协议

`scenario-tour.sh` 在每个场景前后通过 `hdc shell hilog -t info GSY_TOUR "BEGIN/END"` 在 hilog 流中插入分隔符；
`FullTourUiTest.ets` 在 `beforeAll/afterAll/it()` 中通过 `Logger.i('FullTour', 'BEGIN scenario=...')` 插入业务侧分隔符。

切片命令（在 `hilog_business.log` 上）：

```bash
# 1. 看所有边界
grep -nE 'GSY_TOUR|\[FullTour\]' harness/regression/reports/M6/scenario-tour-*/hilog_business.log

# 2. 看某个场景内的业务日志
awk '/\[FullTour\] BEGIN scenario=repoDetail/,/\[FullTour\] END   scenario=repoDetail/' \
  harness/regression/reports/M6/scenario-tour-*/hilog_business.log
```

---

## 7. 维护规则（必须遵守）

1. **新增场景** → 同步改 [scenario-tour.sh ALL_SCENARIOS](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh) + [FullTourUiTest.ets SCENARIOS](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/FullTourUiTest.ets) + 本文档第 3 节场景矩阵 + 必要时新增 Host 页 + 注册 [test_pages.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/resources/base/profile/test_pages.json)
2. **改 root id** → 必须同步改 [FullTourUiTest.ets SCENARIOS.expectId](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/FullTourUiTest.ets) 与对应 Host 页的 `.id(...)`
3. **截图归档** → 直接 `git add harness/regression/reports/M6/scenario-tour-<ts>/`，每个里程碑节点保留 1 份即可（避免历史截图爆仓库）
4. **失败处理** → 任一场景的 root id 找不到 / 截图为空 → 在 [known-issues.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) 登记 KI-XXX，附 `scenario-tour-<ts>/<NN>_<key>.png` 路径与 hilog 切片
5. **不得在 UI 树中新增调试探针**（HARD-LAW-3）：UITest 断言用 root id 即可，不允许在 Host 页里加 `xxx-count:N` Text 等调试控件

---

## 8. 与其他 playbook 的关系

| 文档 | 何时用 | 与本流程关系 |
|---|---|---|
| [device-smoke.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/device-smoke.md) | 一次装机后的最小冒烟 | scenario-tour 是其超集；冒烟通过后再跑全场景 |
| [page-build-checklist.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/page-build-checklist.md) | 逐页 RN-FIRST 7 步建造 | 单页改动后跑 scenario-tour 看是否影响其他 11 页 |
| [ai-auto-debug.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/ai-auto-debug.md) | AI 拉 Logger 环形缓冲 + DebugDumper | 共享 hilog domain 0x0666；scenario-tour 的 hilog 切片直接作为 ai-auto-debug 的输入素材 |
| [testing/e2e/README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/e2e/README.md) | 单页 E2E spec | scenario-tour 是 E2E 的"巡检合订本"，不替代单页深度断言 |
| [rules/ui-parity-with-rn.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/rules/ui-parity-with-rn.md) | RN 端对照（HARD-LAW-1/4） | scenario-tour 截图作为 OH 端基准，配合 RN Maestro 截图组成 R-UI-04 三件套 |

---

## 9. 退出码 / 错误码

| Code | 含义 | 处理 |
|---|---|---|
| 0 | 12 场景全成功（含被忽略的非关键失败） | 归档目录 + 提交 |
| 2 | 设备探活失败 | `hdc list targets` / `hdc tconn 127.0.0.1:5555` |
| 3 | HAP 不存在 | DevEco Build > Build Hap(s) 后重跑 |
| 4 | 场景执行异常（保留位） | 看 `hilog_business.log` 末尾 + `start.log` |

---

## 10. 一次完整跑通 Checklist

```
☐ DevEco Build > Build Hap(s) and Test Hap(s)
☐ hdc list targets 看到设备
☐ 终端 1：bash scripts/scenario-tour.sh
☐ 终端 2：hvigorw test --filter FullTourUiTest
☐ 两端 DONE 后，open harness/regression/reports/M6/scenario-tour-<ts>/README.md
☐ 12 张 PNG 全部非空（ls -lh ）
☐ hilog_business.log 中 grep 'FullTour' 至少 24 行（12 BEGIN + 12 END）
☐ 任一异常场景 → 追加到 known-issues.md
☐ 通过则 git add + git commit "M6 scenario-tour <ts>"
```
