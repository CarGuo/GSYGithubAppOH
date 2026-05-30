# R-UI-PARITY: ArkUI 版本与 RN 版本视觉/交互对齐规则

**适用范围**：[GSYGithubAppOH](https://github.com/CarGuo/GSYGithubAppOH) 中所有面向用户的 ArkTS 页面与组件。
**单一事实源**：[GSYGithubApp](https://github.com/CarGuo/GSYGithubApp)（React Native 原版）。
**生效日期**：2026-05-24（M7 整改）
**触发原因**：M6 期间 ArkUI 版本登录页/欢迎页等出现"工程自测面板化"，与 RN 端真实视觉差距巨大；本规则用于杜绝再发。

---

## 一、硬性前置（任何页面落地前 MUST 完成）

### R-UI-01 必须先抽取 RN 基准
在创建/重做任何 ArkTS 页面之前，必须先在
[harness/regression/ui-parity/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity)
对应文件中产出"RN 基准清单"，至少包含：

1. **RN 源文件路径**（必须 公开 GitHub 链接或项目相对路径，可点击跳转）
2. **顶层容器**：背景色、布局方向、是否全屏
3. **核心结构**：从外到内逐层列出（容器 → 子容器 → 控件）
4. **样式 token**：颜色（取自 [constant.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js)）、字号、间距、圆角
5. **交互序列**：点击/输入/导航的时序
6. **依赖资产**：图片、Lottie、字体、图标库

无 RN 基准清单 → 不允许写 ArkTS。

### R-UI-02 生产 UI 禁止包含调试探针
生产页面（main_pages.json 中注册的页面、user-facing 组件）**禁止**出现：
- 点击计数器、调用次数显示
- 构建时间、版本哈希明文
- "click:0 / pat-click:0" 类工程自测控件
- 任何只有开发者会看的 raw 文本

调试需求一律走：
- hilog domain `0x0666`（参考 [scripts/device-smoke.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/device-smoke.sh)）
- 截图对照（[harness/regression/ui-parity/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity)）
- 单元测试断言（不得侵入 UI）

### R-UI-03 样式 token 必须从 RN 抽取
所有颜色、字号、间距、图标尺寸、圆角必须经由
[entry/src/main/ets/style/Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets)
统一暴露，且取值与 RN 端 [constant.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js)
**逐字符一致**。

直接硬编码 `#xxx` / `12vp` / `30fp` 在页面/组件文件里 → 禁止。

### R-UI-04 三件套交付
每页落地时必须在
[harness/regression/ui-parity/<PageName>.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity)
同时提交：

1. **RN 截图**：来自真实运行（手机/模拟器），路径 `harness/regression/ui-parity/screenshots/rn-<PageName>.png`
2. **ArkUI 截图**：通过 [scripts/device-smoke.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/device-smoke.sh) 自动抓取，路径 `harness/regression/ui-parity/screenshots/oh-<PageName>.png`
3. **差异说明**：列出剩余视觉/交互差异及处理结论（修齐 / OH 增强 / 平台差异豁免）

无三件套 → 不允许标记"已完成"。

### R-UI-05 @Builder 值参冻结禁令（KI-048 守则）

**生效原因**：M6 R8 期间连发三起同款 bug：
[KI-043 RepositoryHeader counts `---`](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) →
[KI-044 UserDetail counts `---`](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) →
[KI-044 二次根因 + KI-048 守则](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md)。
根因都是 `@Builder method(value: string)` 这类**值类型形参**对响应式字段做了"按值冻结"——
ArkTS 编译器对 string/number/boolean 形参做缓存优化，
父组件 build 重 render 时**不重新求值**值参，
导致依赖 @State / @Prop / @ObjectLink / @StorageLink 字段的 cell 永远显示首次值。

**强制守则**：

1. **inline 求值**：凡是依赖响应式字段（@State / @Prop / @ObjectLink / @StorageLink / @Provide / @Consume / @Link）渲染的子节点，
   **必须在 build() 主体内 inline 求值**，禁止经 `@Builder method(value: string)` / `@Builder method(count: number)` / `@Builder method(flag: boolean)` 中转。

2. **样式复用走 sub @Component**：真要复用样式 → 抽 `@Component sub` + `@ObjectLink store: SomeStore`（或 `@Prop`）下沉响应式订阅；
   sub @Component 内部仍要 inline 读 `this.store.xxx`，**禁止**在 sub 内部再用 `@Builder method(value: string)` 中转层（KI-044 二次根因正是 sub 内部 @Builder 复发）。

3. **无值参 @Builder 安全**：`@Builder method(): void` 形态可用，
   但内部读响应式字段时仍要直接读 `this.xxx` 而不是从外面传入（与 1 闭环一致）。

**唯一豁免清单**（其它一律违规）：

| 豁免类型 | 说明 | 实证 |
|---|---|---|
| 路由分发 builder | NavPathStack push 时新建 builder 实例，name/param 是路由值非响应式字段 | [AppNavigator.routerMap(name: string, _param: Object)](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/AppNavigator.ets#L48-L49) ✅ |
| 静态文案/i18n key | 形参全是 `I18n('xxx')` 调用结果或字面量常量，不依赖响应式字段 | [SettingPage.buildLanguageOption(idValue, label, option)](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/SettingPage.ets#L242-L243) ✅ / [SettingPage.buildThemeOption](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/SettingPage.ets#L257-L258) ✅ |
| 数据天然 immutable | 形参来自 BuildConfig / 应用启动时一次性确定不再变化的字段 | [AboutPage.buildRow(idValue, label, value)](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/AboutPage.ets#L27-L28)（应用版本号、bundle 名）✅ |

> ⚠️ 即便落入豁免，注释里要写明豁免理由（防止后续误用）。

**反例（必须修齐）**：

| 文件:行 | 形参 | caller 传值 | 风险 |
|---|---|---|---|
| [DrawerHeader.buildCounter(idSuffix, label, value)](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/DrawerHeader.ets#L128-L129) | value: string | `DrawerHeaderLogic.buildTexts(this.resolveUser()).followersText`，[resolveUser()](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/DrawerHeader.ets#L78) 读 `@StorageLink userInfoRaw` | 🔴 KI-048 范式：用户信息更新后 followers/following 不刷新 |
| [UserHeadItem.buildIconLine(iconKey, text, lineId)](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/UserHeadItem.ets#L134-L135) | text: string | `this.groupName` / `this.location` / `this.link`（全部 [@Prop string](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/UserHeadItem.ets) ）| 🔴 KI-048 范式：UserDetail 切换用户后 group/location/link 卡死首值 |

> 这些反例是 **K48 守则落地时的扫描基线**，已登记 KI-048 followup 列表，等下次主链单独修复。

**正例（守则典范）**：

```ts
// ✅ 正例 1：inline 求值（IssueDetailPage.buildCommentRow 同款）
build(): void {
  Text(this.fmt(this.store.user.public_repos))   // ← 直接读 store
    .fontSize(GSYFontSize.middle);
}

// ✅ 正例 2：sub @Component + @ObjectLink + 内部 inline
@Component
struct UserCountsRow {
  @ObjectLink store: UserDetailStore;
  build(): void {
    // sub 内部 inline 读 store，不再用 @Builder buildCell(value:string) 中转
    Text(this.fmt(this.store.user.public_repos))
      .fontSize(GSYFontSize.middle);
  }
}

// ✅ 正例 3：无值参 @Builder + 内部 this.xxx
@Builder
buildCounter(): void {
  Text(this.fmt(this.store.user.followers))   // ← 内部直接读 this
    .fontSize(GSYFontSize.middle);
}
```

```ts
// ❌ 反例：@Builder method(value: string) 中转（KI-043/044/044 二次根因 同款）
@Builder
buildCell(value: string): void {
  Text(value)            // ← value 在父 build 触发后不会重新求值，永远显示首次值
    .fontSize(GSYFontSize.middle);
}
build(): void {
  this.buildCell(this.fmt(this.store.user.public_repos));  // ← caller 求值，但传给 builder 后冻结
}
```

**自检**：每次 commit 前，对当前页面 grep：
```sh
rg -n '@Builder' -A 1 entry/src/main/ets/<your-page>.ets | rg -E '\((string|number|boolean)\)|: (string|number|boolean)[,)]'
```
若命中 → 逐条对照豁免清单，若不在豁免清单内必须重构。

---

## 二、OH 增强允许的边界

允许在以下情况下偏离 RN：

| 类型 | 允许 | 不允许 |
|---|---|---|
| 平台特性 | 鸿蒙 ArkUI 标准 NavBar/StatusBar 适配 | 改变页面信息架构 |
| 设备能力 | OH 没有的库（如 Lottie 用 ArkUI 动效替代） | 增加 RN 没有的主页 |
| 增强按钮 | RN 不可见入口（如 Token 登录）做成 OH 的次要按钮 | 把次要按钮做成主视觉 |
| 性能优化 | List 虚拟化、缓存策略 | 改变列表项视觉 |

PAT 登录在 RN 是**小字链接**，OH 增强后可做"次要按钮"但**不得**：
- 与"GitHub 登录"主按钮等大并列
- 出现"基本登录 / PAT / OAuth"三按钮并列布局
- 把工程调试计数器留在 UI 上

---

## 三、违规处理

发现违规 → 立即在
[harness/iteration/CHANGELOG-AI.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md)
登记 KI 条目，并在下个迭代回滚。

---

## 四、关联文档

- [harness/playbooks/page-build-checklist.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/page-build-checklist.md) — 每页 7 步建造流程
- [harness/regression/ui-parity/INDEX.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/INDEX.md) — 全部页面对照矩阵
- [entry/src/main/ets/style/Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets) — 样式 token 来源
