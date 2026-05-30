# ADR-0002：ArkUI 状态管理选型（@Observed/@ObjectLink + AppStorage）

- **状态**：Accepted
- **日期**：2026-05-24

## 背景
- RN 端使用经典 Redux + redux-thunk，按域拆 reducer。ArkUI 没有官方 Redux 等价物，强行移植反而会丢掉 ArkTS 的响应式优势。
- compatibleSdkVersion 6.1.0(23) 提供成熟的 `@Observed/@ObjectLink/@State/@Prop/@Link` 装饰器与 `AppStorage`，原生支持组件级精细订阅。
- 全局共享但跨页只读为主的数据（当前用户、语言、主题）适合 `AppStorage`；可写状态适合 `@Observed` 类。

## 决策
1. **按域拆 store 类**：`EventStore / IssueStore / LoginStore / RepositoryStore / UserStore / SettingStore` 等，存放在 `entry/src/main/ets/store/`。
2. **每个 store 类用 `@Observed` 装饰**，对外暴露纯方法（`fetchPage`、`star`、`logout`），内部维护 `@Track` 字段。
3. **页面通过 `@ObjectLink` 引用单一 store 实例**：以单例形式由 `StoreProvider.ets` 统一注册并传入根组件。
4. **轻量全局态走 `AppStorage`**：`AppStorage.SetOrCreate('userInfo', xxx)` + `@StorageProp('userInfo')`；典型 key：`userInfo / language / themeMode`。
5. **跨页事件总线**：复杂联动（语言切换、登出广播）走 `@ohos.events.emitter`，不挤进 store。

## 备选方案
- **mobx-miniprogram**：与 ArkUI 装饰器机制重叠，引入额外心智负担，否决。
- **简单 redux 移植 (rxjs/store-like)**：失去 `@ObjectLink` 的精细订阅，性能不如原生方案，否决。
- **全局单一大 store**：变更扩散广，违背"按域拆"原则，否决。

## 影响
- 新增页面只需 `@ObjectLink store: EventStore` 即可订阅；无需 connect / mapStateToProps。
- 测试 store：直接 new + 调方法 + 读字段，hypium 测试零成本。
- AI 协作时只需读对应 store 类即可理解一域全部状态。
- 与 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0003-rn-to-arkui-mapping.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0003-rn-to-arkui-mapping.md) 中"Redux→Observed"行配套。
