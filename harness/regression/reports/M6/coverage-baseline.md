# M6 覆盖基线（手工）

> **生成时间**：2026-05-24
> **基线方式**：人工逐文件统计 `^\s*it\(` 行数；状态由 AI 静态扫描确认。
> **数据源**：[List.test.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/List.test.ets) 顶层 `testsuite()` 实际挂载的套件。
>
> **状态语义**：
> - `已通过静态诊断`：通过 IDE 类型检查 + 编译期诊断 0 error；尚未在真机/模拟器运行。
> - `待装机回归`：UiTest 类，需 hdc 设备或模拟器才能跑；当前仅静态校验过。
>
> 三列空白字段（`last_run_date` / `last_run_pass` / `last_run_fail`）由 [run-tests.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/run-tests.sh) 在装机执行后回填，**禁止手工填写**。

## 套件 → 用例数（手工计数 it 块）

| # | 套件 | 用例数 | 状态 | 负责人 | last_run_date | last_run_pass | last_run_fail |
|---:|---|---:|---|---|---|---|---|
| 1 | [I18nTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/I18nTest.ets) | 14 | 已通过静态诊断 | AI | | | |
| 2 | [HttpManagerTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/HttpManagerTest.ets) | 10 | 已通过静态诊断 | AI | | | |
| 3 | [RdbAndEventBusTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/RdbAndEventBusTest.ets) | 24 | 已通过静态诊断 | AI | | | |
| 4 | [LoggerAndRoutesTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/LoggerAndRoutesTest.ets) | 13 | 已通过静态诊断 | AI | | | |
| 5 | [CommonComponentsTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/CommonComponentsTest.ets) | 7 | 已通过静态诊断 | AI | | | |
| 6 | [HomeUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/HomeUiTest.ets) | 8 | 待装机回归 | AI | | | |
| 7 | [UtilsTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/UtilsTest.ets) | 15 | 已通过静态诊断 | AI | | | |
| 8 | [DynamicServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/DynamicServiceTest.ets) | 9 | 已通过静态诊断 | AI | | | |
| 9 | [DynamicUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/DynamicUiTest.ets) | 7 | 待装机回归 | AI | | | |
| 10 | [AuthStoreTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/AuthStoreTest.ets) | 19 | 已通过静态诊断 | AI | | | |
| 11 | [LoginUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/LoginUiTest.ets) | 7 | 待装机回归 | AI | | | |
| 12 | [TrendServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/TrendServiceTest.ets) | 8 | 已通过静态诊断 | AI | | | |
| 13 | [TrendUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/TrendUiTest.ets) | 5 | 待装机回归 | AI | | | |
| 14 | [RecommendServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/RecommendServiceTest.ets) | 9 | 已通过静态诊断 | AI | | | |
| 15 | [RecommendUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/RecommendUiTest.ets) | 8 | 待装机回归 | AI | | | |
| 16 | [MyServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/MyServiceTest.ets) | 13 | 已通过静态诊断 | AI | | | |
| 17 | [MyUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/MyUiTest.ets) | 9 | 待装机回归 | AI | | | |
| 18 | [RepositoryServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/RepositoryServiceTest.ets) | 10 | 已通过静态诊断 | AI | | | |
| 19 | [RepositoryDetailUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/RepositoryDetailUiTest.ets) | 8 | 待装机回归 | AI | | | |
| 20 | [RepoTabsServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/RepoTabsServiceTest.ets) | 10 | 已通过静态诊断 | AI | | | |
| 21 | [RepoTabsUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/RepoTabsUiTest.ets) | 6 | 待装机回归 | AI | | | |
| 22 | [UserServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/UserServiceTest.ets) | 10 | 已通过静态诊断 | AI | | | |
| 23 | [UserDetailUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/UserDetailUiTest.ets) | 7 | 待装机回归 | AI | | | |
| 24 | [IssueServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/IssueServiceTest.ets) | 8 | 已通过静态诊断 | AI | | | |
| 25 | [IssueDetailUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/IssueDetailUiTest.ets) | 7 | 待装机回归 | AI | | | |
| 26 | [CommitServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/CommitServiceTest.ets) | 16 | 已通过静态诊断 | AI | | | |
| 27 | [CodeDetailUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/CodeDetailUiTest.ets) | 4 | 待装机回归 | AI | | | |
| 28 | [PushDetailUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/PushDetailUiTest.ets) | 6 | 待装机回归 | AI | | | |
| 29 | [SearchServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/SearchServiceTest.ets) | 20 | 已通过静态诊断 | AI | | | |
| 30 | [SearchUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/SearchUiTest.ets) | 6 | 待装机回归 | AI | | | |
| 31 | [NotifyServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/NotifyServiceTest.ets) | 16 | 已通过静态诊断 | AI | | | |
| 32 | [NotifyUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/NotifyUiTest.ets) | 8 | 待装机回归 | AI | | | |
| 33 | [SubListServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/SubListServiceTest.ets) | 7 | 已通过静态诊断 | AI | | | |
| 34 | [SubListUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/SubListUiTest.ets) | 5 | 待装机回归 | AI | | | |
| 35 | [SettingUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/SettingUiTest.ets) | 6 | 待装机回归 | AI | | | |
| 36 | [EmojiKeyboardTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/EmojiKeyboardTest.ets) | 9 | 已通过静态诊断 | AI | | | |
| 37 | [ImagePreviewUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ImagePreviewUiTest.ets) | 3 | 待装机回归 | AI | | | |
| 38 | [OauthServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/OauthServiceTest.ets) | 16 | 已通过静态诊断 | AI | | | |
| 39 | [OauthDeepLinkUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/OauthDeepLinkUiTest.ets) | 4 | 待装机回归 | AI | | | |
| 40 | [LoginExpiredFlowTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/LoginExpiredFlowTest.ets) | 3 | 已通过静态诊断 | AI | | | |
| 41 | [OfflineFallbackTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/OfflineFallbackTest.ets) | 6 | 已通过静态诊断 | AI | | | |
| 42 | [ContributionServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ContributionServiceTest.ets) | 9 | 已通过静态诊断 | AI | | | |
| 43 | [ContributionHeatmapUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ContributionHeatmapUiTest.ets) | 3 | 待装机回归 | AI | | | |
| 44 | [DrawerHeaderTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/DrawerHeaderTest.ets) | 8 | 已通过静态诊断 | AI | | | |
| 45 | [DrawerMenuUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/DrawerMenuUiTest.ets) | 6 | 待装机回归 | AI | | | |
| 46 | [Ability.test.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/Ability.test.ets) | 1 | 待装机回归 | AI | | | |
| 47 | [ThemeManagerTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ThemeManagerTest.ets) | 10 | 已通过静态诊断 | AI | | | |
| 48 | [ThemeUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ThemeUiTest.ets) | 2 | 待装机回归 | AI | | | |
| 49 | [DaoTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/DaoTest.ets) | 36 | 已通过静态诊断 | AI | | | |
| 50 | [ReadHistoryServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ReadHistoryServiceTest.ets) | 16 | 已通过静态诊断 | AI | | | |
| 51 | [ReadHistoryUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ReadHistoryUiTest.ets) | 6 | 待装机回归 | AI | | | |

## 汇总

| 指标 | 值 |
|---|---:|
| 套件总数 | 51 |
| 用例总数（it 块累计） | 466 |
| ServiceTest 套件 | 29 |
| UiTest 套件 | 22 |
| 已通过静态诊断 | 29 |
| 待装机回归 | 22 |

### M6 新增（首次纳入基线）

| 套件 | 用例数 | 状态 | 负责人 |
|---|---:|---|---|
| [DrawerHeaderTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/DrawerHeaderTest.ets) | 8 | 已通过静态诊断 | AI |
| [DrawerMenuUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/DrawerMenuUiTest.ets) | 6 | 待装机回归 | AI |
| [ReadHistoryServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ReadHistoryServiceTest.ets)（M6 收尾已挂载）| 16 | 已通过静态诊断 | AI |
| [ReadHistoryUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ReadHistoryUiTest.ets)（M6 收尾已挂载）| 6 | 待装机回归 | AI |
| [ContributionServiceTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ContributionServiceTest.ets) | 9 | 已通过静态诊断 | AI |
| [ContributionHeatmapUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ContributionHeatmapUiTest.ets) | 3 | 待装机回归 | AI |
| [ThemeManagerTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ThemeManagerTest.ets)（M6 收尾已挂载）| 10 | 已通过静态诊断 | AI |
| [ThemeUiTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ThemeUiTest.ets)（M6 收尾已挂载）| 2 | 待装机回归 | AI |
| [DaoTest.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/DaoTest.ets)（M6 收尾已挂载）| 36 | 已通过静态诊断 | AI |

> **遗留项**：无；以上 5 个 M5 阶段遗留未挂载的套件（Theme/Dao + ReadHistory）已在 M6-T6 收尾时全部补挂到 [List.test.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/List.test.ets)。

## run-tests 回填约定

执行 `bash harness/regression/run-tests.sh` 后，脚本应按 `套件名 → 用例数 / pass / fail / 时间戳` 的格式回填本表的最后三列：

```
last_run_date    yyyy-MM-dd HH:mm:ss（UTC+8）
last_run_pass    通过用例数
last_run_fail    失败用例数（含 error / blocked）
```

回填策略：
- 仅修改"已存在套件"对应的三列空白。
- 若新增套件，需先在本基线手工登记一行（用例数 + 状态 + 负责人），再由脚本回填。
- 若用例数与基线不一致，脚本应在 stderr 输出 diff，但**不应**自动改写"用例数"列。
