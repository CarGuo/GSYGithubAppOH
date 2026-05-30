# Page Build Checklist（每页 7 步建造流程）

每个 ArkTS 页面/可见组件必须按此 7 步流水建造，**不得跳步**。

---

## Step 1 — 打开 RN 源
1. 在 [GSYGithubApp/app/components/](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components) 找到对应 RN 文件
2. 用 公开 GitHub 链接或项目相对路径记录到 [INDEX.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/INDEX.md) 对应行
3. 同时找到所有依赖 widget（在 [widget/](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget) 或 [common/](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/common)）

## Step 2 — 抽布局骨架
逐层列出：根容器 → 一级子容器 → 二级 → 控件。
使用纯文本树形：
```
View(mainBox)
├─ StatusBar
└─ PullListView
   ├─ Header(UserHeadItem)
   │  ├─ View(primaryColor 卡片)
   │  └─ NameValueItem × 5
   └─ Row → EventItem
```

## Step 3 — 抽样式 token
对照 [constant.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js) 与 [style/index.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/index.js)，
列出本页用到的 token 集合（颜色、字号、间距、圆角、阴影），全部映射到
[entry/src/main/ets/style/Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets)。

页面文件**禁止**出现 `#xxx` / `12vp` / `30fp` 这类硬编码（除非是 Theme 内部）。

## Step 4 — 抽交互序列
按事件 → 数据 → 路由的顺序，列时序：
```
点击 GitHub 登录按钮
  → Linking.openURL(authUrl)
  → DeviceEventEmitter on `LoginPage`
  → loginActions.doLogin(code)
  → Actions.reset("MainTabs")
```

## Step 5 — ArkTS 落地
- 复制 RN 结构骨架，逐节点对应 ArkUI 组件
- 颜色/字号/间距引用 Theme，不允许内联硬编码
- 调试输出走 hilog domain `0x0666`，**禁止**写到 UI
- **R-UI-05 自检**（KI-048 守则）：依赖响应式字段（@State/@Prop/@ObjectLink/@StorageLink/@Provide/@Consume/@Link）渲染的子节点必须 inline 求值；
  本页 grep 扫描 `rg -n '@Builder' -A 1 entry/src/main/ets/<your-page>.ets | rg -E '\((string|number|boolean)\)|: (string|number|boolean)[,)]'`
  命中 → 对照 [R-UI-05 豁免清单](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/rules/ui-parity-with-rn.md)（路由分发/静态文案/天然 immutable），不在豁免内必须重构

## Step 6 — 真机截图对照
1. `bash scripts/device-smoke.sh` 抓 `oh-<PageName>.png`
2. 同场景下 RN 端运行抓 `rn-<PageName>.png`（一次性整理留底）
3. 把两张图横向并排到 `harness/regression/ui-parity/<PageName>.md`

## Step 7 — 写入 ui-parity 报告
模板：
```markdown
# <PageName> UI Parity Report

## 1. RN 基准清单
- 源：[<PageName>.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/<PageName>.js)
- 顶层容器：...
- 核心结构：...
- 样式 token：...
- 交互序列：...

## 2. ArkUI 落地
- 源：[<PageName>.ets](../../entry/src/main/ets/pages/<PageName>.ets)
- 偏差点：...

## 3. 截图对照
| RN | ArkUI |
|---|---|
| ![rn](screenshots/rn-<PageName>.png) | ![oh](screenshots/oh-<PageName>.png) |

## 4. 差异处理
- 已修齐：...
- OH 增强：...
- 平台豁免：...
```

---

完成 Step 1-7 后，在 INDEX.md 把该行状态置为 `✅ aligned`；任一步缺失置为 `🚧 partial` 或 `❌ off-spec`。
