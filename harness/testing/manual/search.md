# 手工回归 — 搜索

### MC-SCH-01：基础搜索 — 仓库
- 步骤：
  1. 切到 Search Tab。
  2. 默认类型 Repositories。
  3. 输入 `react-native`。
  4. 触发搜索。
- 期望：列表 ≤ 2s 出现；至少 10 项；每项含名称 / 描述 / Star / 语言。

### MC-SCH-02：切换类型 — 用户
- 步骤：
  1. 在 Search 顶部切到 Users。
  2. 输入 `carguo`。
- 期望：列表显示用户卡片；点击进 PersonPage。

### MC-SCH-03：Drawer 过滤 — 排序
- 步骤：
  1. 打开右侧 Drawer（SideBarContainer position End）。
  2. 选 sort = stars。
  3. 关闭 Drawer 触发刷新。
- 期望：列表按 Star 倒序；Drawer 关闭流畅。

### MC-SCH-04：Drawer 过滤 — 语言 + 时间
- 步骤：在 Drawer 选 language = TypeScript + created > 2024-01-01 → 关闭。
- 期望：URL 拼接正确（FilterUtils）；列表只显示 TS 仓库；分页持续生效。

### MC-SCH-05：清空与历史
- 步骤：
  1. 清空输入框 → 列表清空 / 提示空态。
  2. 重新输入 → 列表恢复。
  3. 退出 App → 重启 → 进 Search Tab。
- 期望：上次搜索词不会自动触发请求；输入框为空。

### MC-SCH-06：分页加载
- 步骤：连续上拉加载至少 3 页。
- 期望：每页拼接到尾部；不出现重复项；底部 Loading 正确显示。

### MC-SCH-07：网络错误兜底
- 前置：飞行模式。
- 步骤：触发搜索。
- 期望：Toast 提示离线；空态可点重试。
