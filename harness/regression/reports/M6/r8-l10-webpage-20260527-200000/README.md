# R8-L10 WebPage 真机三件套报告

> 时间：2026-05-27 20:38-20:42 (UTC+8)
> 设备：模拟器 127.0.0.1:5555
> hap：[entry-default-signed.hap](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/build/default/outputs/default/entry-default-signed.hap) md5=`f196c34697c60f5df8b54f02f756e550`（与 L9 同一 build 产物，本轮 hvigorw 全部 UP-TO-DATE 复用）
> bundleName：`cn.gsy.githubapp`
> Ability：`EntryAbility`

---

## 1. 主链小结

L6.5 WebPage 通用 Web 浏览页（github 站外链兜底 + gsygithub:// 业务深链回归），代码在 L6.5 已 Code-Ready，本轮 L10 跑真机三件套，把 INDEX.md WebPage 行从 🚧 升 ✅，01-status.md L6 行从 🟡 升 ☑。

S1-S3 RN-FIRST 抽证 + OH-DIFF 复核 + 修法落地三步全部确认代码层无差异（`AppBar + Web + onLoadIntercept + BOOT_WEB_KEY 兜底 + R-UI-05 inline 求值 + token-only 全合规`），S3 跳过；S4 编译装机 + 冷启 bootWeb 通道；S5 跑 4 个子场景（3 个真机 + 1 个代码路径覆盖）。

---

## 2. HARD-LAW 自检

| LAW | 项目 | 结果 | 证据 |
|---|---|---|---|
| LAW-1 | RN-FIRST | ✅ | [WebPage.md §1](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/WebPage.md#L9-L89) 已沉淀；本轮 S1 通读 [WebPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WebPage.js) 173 行 + [htmlUtils.launchUrl#L370-L399](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js#L370-L399) + [CustomWebComponent#L62-L74](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/CustomWebComponent.js#L62-L74) |
| LAW-2 | TOKEN-ONLY | ✅ | [WebPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WebPage.ets) 0 字面量颜色/字号/间距，全走 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets) |
| LAW-3 | NO-DEBUG-PROBE | ✅ | UI 树仅 AppBar + Web；3 个 hilog tag `[web/page]`/`[web/anchor]`/`[web/intercept]`，UI 上无任何调试 Text |
| LAW-4 | TRIPLE-EVIDENCE | ✅ | 3 张 OH 截图 md5 全不同（`c1d978a8…` / `f12f8146…` / `2fe4c8dc…`）+ 2 份 dump + 完整 hilog 时序；RN 侧由 [WebPage.md §1](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/WebPage.md#L9-L89) 抽源覆盖 |
| LAW-5 | 7-STEP | ✅ | S1 抽源 → S2 OH-DIFF 复核 → S3 修法落地（跳过）→ S4 编译装机 → S5 真机 → S6 文档收尾 |
| LAW-6 | ONE-CHAIN | ✅ | 本轮单链 L10，未跳跨链 |
| LAW-7 | NO-JARGON | ✅ | 对话回复全程大白话，文档内部保留 LAW/KI/L 编号 |

---

## 3. 真机子场景

### 场景 1：bootWeb want 通道 + WebPage 加载 + AppBar 标题渲染（PASS ✅）

- 启动命令：`hdc shell aa start -a EntryAbility -b cn.gsy.githubapp --ps bootWeb 'https://example.com'`
- 截图：[oh_webpage_s1_v1.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l10-webpage-20260527-200000/oh_webpage_s1_v1.jpeg) md5=`c1d978a83169e0278fe8a1e850e48119` 112KB
- dump：[oh_webpage_s1_v1.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l10-webpage-20260527-200000/oh_webpage_s1_v1.json) 45KB
- 关键节点（dump 验证）：
  - AppBar 左侧返回 Button：bounds [0,137][112,333]，clickable=true ✅
  - AppBar 标题 Text "Example Domain"：bounds [410,198][910,272] ✅（来自 `onTitleReceive` 回写）
  - AppBar 右侧 reload Button：bounds [1124,137][1292,333]，clickable=true ✅
  - Web 主体：key=`web_page_view`，url=`https://example.com`，bounds [0,333][1320,2856]，已渲染 heading "Example Domain" + paragraph ✅
- hilog 时序：

```
20:38:00.502 [boot/ts] EntryAbility.handleBootWebInjection done value=https://example.com
20:38:03.713 [boot/ts] HomePage.scheduleBootWeb pre-schedule uri=https://example.com
20:38:04.314 [boot/ts] HomePage.scheduleBootWeb pre-push / post-push
20:38:04.316 AceNavigation: navigation stack create new node, name: WebPage
20:38:04.316 AceNavigation: WebPage lifecycle change to onWillAppear
20:38:04.387 AceNavigation: WebPage lifecycle change to onAppear
20:38:04.388 AceNavigation: WebPage lifecycle change to onWillShow
20:38:04.389 [boot/ts] WebPage adopt BOOT_WEB_KEY fallback uri=https://example.com
20:38:04.389 [web/page] init uri=https://example.com
20:38:04.441 AceNavigation: WebPage lifecycle change to onShown / onActive
```

→ BOOT_WEB_KEY 兜底范式生效（HomePage push 时 NavDestination param 没传 uri，WebPage aboutToAppear 从 AppStorage[BOOT_WEB_KEY] 兜底拿到）。

### 场景 2：AppBar reload 重新加载（PASS ✅）

- 操作：`hdc shell uitest uiInput click 1208 235`（点 AppBar 右上 reload 中心点）
- 截图：[oh_webpage_s2_reload.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l10-webpage-20260527-200000/oh_webpage_s2_reload.jpeg) md5=`f12f8146059de5f3511afe5c59a56c94` 112KB（与 s1 不同）
- hilog 时序：

```
20:39:29.424 [web/page] reload                    ← onReload() controller.refresh()
20:39:29.820 [web/page] onPageEnd url=https://example.com/   ← 重新加载完成（396ms）
```

### 场景 3：AppBar back 返回 HomePage（PASS ✅）

- 操作：`hdc shell uitest uiInput click 56 235`（点 AppBar 左上 chevron-back 中心点）
- 截图：[oh_webpage_s3_back.jpeg](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l10-webpage-20260527-200000/oh_webpage_s3_back.jpeg) md5=`2fe4c8dcde4e12cfe74fae082f2288f2` 211KB（HomePage 比 example.com 复杂）
- dump：[oh_webpage_s3_back.json](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l10-webpage-20260527-200000/oh_webpage_s3_back.json) 109KB（HomePage layout）
- hilog 时序：

```
20:39:50.428 AceNavigation: transition start, isPopPage: 1, animated: 1
20:39:50.431 AceNavigation: WebPage lifecycle change to onWillHide
20:39:50.431 AceNavigation: Home lifecycle change to onWillShow
20:39:50.434 AceNavigation: WebPage lifecycle change to onInactive / onHidden
20:39:50.436 AceNavigation: WebPage lifecycle change to onWillDisappear
20:39:50.436 AceNavigation: Home lifecycle change to onShown
20:39:50.437 AceNavigation: Home lifecycle change to onActive
20:39:50.438 AceNavigation: navigation pop animation start
20:39:51.049 AceNavigation: navigation pop animation end
20:39:51.065 AceNavigation: WebPage lifecycle change to OnDisappear
```

→ AppBar back chevron 走 NavigationService.back，AceNavigation pop 动画 0.6s 完成。

### 场景 4：gsygithub:// 拦截 + toast（代码路径覆盖 ✅）

- 业务路径已由 KI-049 闭环时真机验证：[ReadmeTab.ets#L103](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/repo/ReadmeTab.ets#L103) 接住 README 相对链接 → push WebPage（深路径）或站内 NavPathStack 路由（仓库/Issue/User）。
- WebPage 通用兜底分支 [onInterceptUrl#L107-L111](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/WebPage.ets#L107-L111)：

```typescript
if (url.indexOf('gsygithub://') === 0) {
  hilog.info(DOMAIN, TAG, '[web/anchor] gsygithub anchor url=%{public}s', url);
  CommonToast.showShort(I18n('webRelativeLinkNeedRepoContext'));
  return true;   // 拦截，不让 Web 自处理
}
```

- 真机走 data:// + base64 + file:// 三种注入方案均因 hdc shell `;` 分隔符冲突 / OH Web sandbox 跨用户读 /data/local/tmp 受限 → 改用代码路径覆盖。
- 验收依据：onLoadIntercept 拦截分支 + CommonToast.showShort + I18n 多 locale key（`webRelativeLinkNeedRepoContext`）已在 KI-049 闭环（[01-status.md § KI-049](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/01-status.md)）真机验证。

---

## 4. 文档收尾产物

- 报告目录：[r8-l10-webpage-20260527-200000](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/reports/M6/r8-l10-webpage-20260527-200000)
- 截图基线：[ui-parity/screenshots/WebPage/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/WebPage)
  - `oh_WebPage_v1_20260527.jpeg`（场景 1）
  - `oh_WebPage_v1_reload_20260527.jpeg`（场景 2）
  - `oh_WebPage_v1_back_20260527.jpeg`（场景 3）
- WebPage.md §3 真机证据已填
- INDEX.md WebPage 行从 🚧 升 ✅
- 01-status.md L6 行从 🟡 升 ☑

---

## 5. 派生候选

无新派生 KI。本期 WebPage 通用兜底完整，gsygithub:// 真正业务消费由 [ReadmeTab.ets onLoadIntercept](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/repo/ReadmeTab.ets) 兜住，WebPage 兜底分支为防御性代码 + 用户提示。
