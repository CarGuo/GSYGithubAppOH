# 手工回归 — Trending / 推荐

### MC-TRD-01：Trending 默认页
- 前置：已登录或匿名（Trending 不强依赖登录）。
- 步骤：
  1. 切到 Trend Tab。
  2. 等待页面加载。
- 期望：默认显示 today + All Languages；列表 ≥ 10 条；首项可见仓库名 / 描述 / Star/Fork。

### MC-TRD-02：切换时间维度
- 步骤：
  1. 在 Trend 顶部切换 today → weekly → monthly。
  2. 每次切换观察列表刷新。
- 期望：列表立即更新；loading 期间不阻塞 UI；缓存后再次切回 today 不重新拉取（命中 TrendRepositoryV2）。

### MC-TRD-03：切换语言
- 步骤：
  1. 点击"语言"筛选 → 选 TypeScript。
  2. 等待列表刷新。
  3. 再切到 ArkTS / 全部。
- 期望：列表内容随语言变化；空语言时显示空态 + 重试按钮。

### MC-TRD-04：抓取失败兜底
- 前置：开飞行模式。
- 步骤：刷新 TrendPage。
- 期望：显示空态 + 重试按钮；点击重试在恢复网络后重新加载。

### MC-TRD-05：推荐位（RecommendPage）
- 步骤：
  1. 进入 RecommendPage（入口位置随设计而定，可能在 Trend 顶部 Tab 或 My 页面）。
  2. 点击任一条推荐项。
- 期望：跳到对应 RepositoryDetailPage；返回后页面 scroll 位置保留。

### MC-TRD-06：切语言重渲染
- 步骤：在 SettingPage 切中英文 → 返回 Trend。
- 期望：筛选条 / 列表项 UI 文案随语言变化。
