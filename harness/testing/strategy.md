# 测试策略（hypium）

## 金字塔

```
        ┌─────────────────┐
        │   Manual         │ 少量、覆盖端到端关键链路（不可自动化）
        ├─────────────────┤
        │   E2E (hypium UI)│ ~20 用例：登录 / 主流程 / 仓库 / 搜索
        ├─────────────────┤
        │  Component (ETS) │ 关键 Page 组件交互
        ├─────────────────┤
        │   Unit (hypium)  │ utils / dao / store 纯逻辑
        └─────────────────┘
```

## 范围与覆盖

| 层 | 工具 | 路径 | 触发命令 |
|---|---|---|---|
| 单测 | hypium | `entry/src/ohosTest/ets/test/unit/` | `hvigorw test` |
| 组件 | hypium UI Test | `entry/src/ohosTest/ets/test/component/` | `hvigorw test` |
| E2E | hypium Driver + hdc | `entry/src/ohosTest/ets/test/e2e/` | `hvigorw test --filter e2e` |
| 手工 | Markdown | [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/) | 人工 |

## 接入指南
- **hypium 单测**：DevEco 自带模板，新增文件在 `ohosTest/ets/test/unit/<域>.test.ets`，遵循 `describe / it / expect` 风格。
- **hypium 组件测**：使用 `loader` 加载 ETS 组件 + `Driver` 模拟点击 / 输入。
- **E2E**：基于 `Driver.create()` 控制真机 / 模拟器，配合 `hdc shell`、`hdc file recv`。

## 测试 ID 约定
- 关键交互元素 `id="domain-page-element"`，例如 `id="login-page-token-input"`。
- 列表项稳定 key（仓库 fullName、issue id），避免 index。

## 命名规范
- 文件名：`<被测模块>.test.ets`，与 src 路径同名（不重复目录层级）。
- 一个 describe 对一个被测函数 / 组件；嵌套 describe 按"分支 / 边界"组织。
- E2E spec：`flows/<flow-name>.spec.ets`（可复用）+ 顶层 `<feature>.spec.ets`。

## 取舍原则
- 不为追求覆盖率写测试；优先保护"高频回归点"与"高风险路径"。
- 一处测试只验证一件事；快照仅用于稳定 UI（避免大块文本快照）。
- 任何线上 bug 回归时必须先补一条最小可复现测试。

## CI（占位）
- 当前未接入 CI；后续可在 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/upgrade-deveco.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/upgrade-deveco.md) 中补 hvigor + hdc 远端构建脚本。

## 维护节奏
- 每次发布前在 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/checklist.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/checklist.md) 中执行整套用例。
- 每季度回顾测试矩阵，淘汰过期用例。

---

## 分层策略（M6 追加）

> 本节明确"哪一层用什么测、靠什么注入"，作为后续新增模块的硬约束。

### 纯逻辑层 → 必须 ServiceTest

适用对象：
- `entry/src/main/ets/service/*Service.ets`
- `entry/src/main/ets/store/*Store.ets`
- `entry/src/main/ets/utils/*Util*.ets` / `EmojiText.ets` / `SearchHistory.ets` / `EventBus.ets`
- `entry/src/main/ets/dao/*Dao.ets` 与 `dao/db/*.ets`

约束：
- **禁止**直接依赖真实 `@ohos.net.http`、真实 RDB、真实 Navigation、真实 NetworkMonitor。
- 通过 **Provider 接口注入 Fake 实现**（FakeHttp / FakeRdb / FakeNavigation / FakeNetworkMonitor），保证 logic-only 模式下可在无设备环境通过。
- 套件命名：`<域>ServiceTest.ets` / `<域>StoreTest.ets` / `<域>DaoTest.ets`。

### UI 层 → 必须 UiTest

适用对象：
- `entry/src/main/ets/pages/**/*.ets`（Page）
- `entry/src/main/ets/common/*.ets` 中带 `@Component` 的 UI 组件
- `entry/src/main/ets/pages/repo/*.ets` / `pages/sub/*.ets` / `pages/tabs/*.ets`

约束：
- 使用 `entry/src/ohosTest/ets/pages/*HostPage.ets` 作为宿主载入被测组件。
- **必须通过 Provider 注入 Fake**：避免真实网络 / RDB / 导航 / 网络监听依赖；UiTest 只断言 UI 行为，不验证业务接口实现。
- 使用 hypium `Driver` + `.id()` 选择器；列表项 key 使用稳定字段（fullName / id），不允许 index。
- 套件命名：`<域>UiTest.ets`。

### Provider 注入清单

| Provider | Fake 实现 | 替换的真实依赖 |
|---|---|---|
| HttpProvider | FakeHttp（录制 URL + 请求体 + Mock 响应） | `@ohos.net.http` |
| RdbProvider | FakeRdb（内存 Map） | `@ohos.data.relationalStore` + Preferences |
| NavigationProvider | FakeNavigation（记录 push/pop + params） | `Router` / `NavPathStack` |
| NetworkProvider | FakeNetworkMonitor（手动 emit online/offline） | `@ohos.net.connection` |

**新增模块 PR 自检**：纯逻辑必须有 ServiceTest，UI 必须有 UiTest；任何一项缺失需在 PR 描述中显式说明原因。

---

## 等价类与边界（M6 追加）

> 每个域至少覆盖以下等价类与边界，缺失项视为漏测。

| 类别 | 输入条件 | 期望行为 | 适用面 |
|---|---|---|---|
| **HTTP 401** | 服务端返回 401 | 清空 token / 跳转登录页 / 携带 redirect 参数 | 所有调用 GitHub API 的 Service |
| **网络错** | http error / timeout / DNS 失败 | toast 提示 + 缓存兜底（如有 Dao） + 不污染 Store | 所有 Service / NetworkMonitor |
| **空 list** | 接口返回 `[]` 或 RDB 查询 0 行 | 空态文案 / 空态控件 .id() / 不卡 loading | 所有 List 类 Page / Tab |
| **空字符串** | 输入框 q='' / 评论 body='' | 短路不发请求 / 按钮 disabled / Store 不变更 | Search / Issue 评论 / 鉴权输入 |
| **超长字符串** | URL 参数超长 / Repo 名超长 / 评论超长 | 正确编码（encodeURIComponent）/ UI 不溢出 / 不截断关键字段 | Url / SearchService / IssueService |
| **page=0** | 首屏分页 | 走刷新流程，覆盖现有 list；page 参数不出现负数 | 所有 PullLoadMoreList 接入页 |
| **page>1** | 上拉加载更多 | append 到现有 list；URL 携带 `page=N` 参数；末页停止 | 所有 PullLoadMoreList 接入页 |

---

## 断言粒度（M6 追加）

> 一次 it 块只验证一件事，但断言粒度必须穿透到以下层级，避免"通过测试但实际接口/状态错误"的伪绿。

1. **URL 命中**：断言 FakeHttp 收到的 method + path + query 参数；不接受"只断言被调用次数"。
2. **请求体**：POST/PUT/PATCH 必须断言 body 关键字段（如 `{ title, body, state }`）；不允许只断言 body 非空。
3. **Store 字段**：断言 Store 的具体字段（如 `store.list.length` / `store.user.login`）；不允许只断言"Store 被更新"。
4. **控件 .id()**：UiTest 必须通过稳定 id（`<domain>-<page>-<element>`）选中节点并断言文案 / 可见性 / 启用状态；不允许只断言"组件已挂载"。
5. **路由参数**：跳转类断言必须包含目标路由 name + params（如 `{ owner, name }`）；不允许只断言"调用了 push"。

满足以上 5 项粒度，才视为对一个域形成"端到端"保护。

