# L6 RN 缺失/未对齐页面补齐
说明：原 L6 表把 RecommendPage 列为 high 优先 → **2026-05-26 复核纠正**：[RecommendPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RecommendPage.js#L21-L69) 本身为 demo 死代码（无 componentDidMount 数据请求 / 全部 actionTime / actionUser / des 硬编码），并且 [AppNavigator.js#L88-L111](https://github.com/CarGuo/GSYGithubApp/blob/master/app/navigation/AppNavigator.js#L88-L111) MainTabs 实际只挂 `DynamicPage / TrendPage / MyPage` 三页，TrendPage 标题虽用 I18n('tabRecommended')="推荐"，但 component 是 TrendPage 不是 RecommendPage。**OH 主动 deprecated 是正确判断**，本节永久关闭。

> 状态：🔄 进行中（L5 完成后开工，2026-05-26）

---

## 优先级与清单（2026-05-26 v2）

| # | 页 | 优先级 | RN 源 | OH 现状 | 关键说明 |
|---|---|---|---|---|---|
| 1 | ~~RecommendPage~~ | ⛔ deprecated | [RecommendPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RecommendPage.js) | 已删 | RN 端为死代码 demo，AppNavigator 未注册，**永久关闭** |
| 2 | **ListPage / SubListView** | **highest** | [ListPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ListPage.js) | [SubListView.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/sub/SubListView.ets) 部分功能 | 通用列表（user_repos / user_star / followers / followed / member / repo_star / repo_watcher / repo_fork / user_orgs / repo_release / repo_tag / notify / history / topics）；OH 当前只覆盖 user/repo 模式，且 **HARD-LAW-2 字面量违规 8 处**（fontSize 15×3 / padding 12 / padding 16,16,10,10 / 头像 36 / glyphSize 12 / margin top:4 / margin top:6） |
| 3 | PersonInfoPage | medium | [PersonInfoPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PersonInfoPage.js) | 缺 | 用户编辑信息（name/email/blog/company/location/bio）|
| 4 | ReleasePage | medium | [ReleasePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ReleasePage.js) | 缺 | 仓库 release 列表（实际是 ListPage dataType=repo_release 的入口包装）|
| 5 | PhotoPage | low | [PhotoPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PhotoPage.js) | 缺 | 图片放大查看 |
| 6 | WebPage | low | [WebPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WebPage.js) | 缺 | 通用 webview |

---

## 推进策略

- 每页一个独立子节（6.1 SubListView token 清零 / 6.2 PersonInfoPage / ...）
- 每页严格走 S1..S6 + DoD 10 项
- 每页完成 1 个 commit
- 高优先级先做（SubListView token 清零 → PersonInfoPage → ReleasePage），低优先级（Photo / Web）可在 L7 回归前最后批量收尾

---

## 6.1 SubListView token 清零 + RN-aligned（**最高优先级**）

### S1 RN 基准（[ListPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ListPage.js)）

**14 dataType × 7 showType 矩阵**：

| dataType | showType | service action | rowItem |
|---|---|---|---|
| follower / followed | user | userActions.getFollowerList/getFollowedList | UserItem |
| user_repos / user_star | repository | repositoryActions.getUserRepository/getStarRepository | RepositoryItem |
| repo_star / repo_watcher | user | repositoryActions.getRepositoryStar/getRepositoryWatcher | UserItem |
| repo_fork | repository | repositoryActions.getRepositoryForks | RepositoryItem |
| repo_release / repo_tag | release | repositoryActions.getRepositoryRelease/getRepositoryTag | ReleaseItem |
| user_orgs | org | userActions.getUserOrgs | UserItem (description) |
| user_be_stared | repository | localData | RepositoryItem |
| notify | notify | userActions.getNotifation | EventItem |
| history | repository (rowData.data) | repositoryActions.getRepositoryLocalRead | RepositoryItem |
| topics | repository | repositoryActions.searchTopicRepository | RepositoryItem |
| issue | issue | (search 路径) | IssueItem |

### S2 OH 现状 Diff

[SubListView.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/sub/SubListView.ets) 当前：
- 仅 SubListMode.USER / REPO 两态（缺 release/notify/issue/org 4 类）
- buildUserRow 缺 location / des(bio) → 与 RN [UserItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserItem.js) 不对齐
- buildRepoRow 自绘 → 应直接复用 [RepositoryItem.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/RepositoryItem.ets)
- HARD-LAW-2 字面量违规 8 处：
  - L29/L50/L69 `fontSize(15)`（应 GSYFontSize.middle）
  - L35 `padding(12)`（应 GSYSpacing.normalEdge）
  - L57/L95 `padding({ left: 16, right: 16, top: 10, bottom: 10 })`（应 GSYSpacing.normalEdge / GSYSpacing.smallEdge）
  - L44-46 `width(36).height(36).borderRadius(18)`（应 GSYIconSize.normal/2 圆）
  - L78/L83 `glyphSize: 12`（应 GSYIconSize.minSize）
  - L52 `margin({ left: 12 })`（应 GSYSpacing.normalEdge）
  - L76/L91 `margin({ top: 4/6 })`（应 GSYSpacing.miniEdge）

### S3 Fix（本轮范围）

**第一阶段（本轮，最小可闭环）**：
- L6.1.a 字面量清零（HARD-LAW-2 立即达标）
- L6.1.b buildUserRow 加 location / des 字段对齐 RN UserItem
- L6.1.c buildRepoRow 复用现成 [RepositoryItem.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/RepositoryItem.ets) 替换自绘

**第二阶段（后续）**：
- L6.1.d 扩 SubListMode：RELEASE / NOTIFY / ISSUE / ORG 4 模式
- L6.1.e 5 个 caller 页面（RepositoryStarPage / RepositoryWatcherPage / RepositoryForkPage / UserFollowedPage / UserFollowerPage）批量切换

---

## 6.2 PersonInfoPage（次优先级，待 6.1 闭环后开工）

### S1 RN 基准（已抽：[PersonInfoPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PersonInfoPage.js)）

#### 6 项 CommonRowItem（统一样式：borderRadius:4 + marginTop:normalMarginEdge + paddingLeft:normalMarginEdge + shadowCard）

| # | itemIcon | nameText I18n | itemText 字段 | postChange 字段 |
|---|---|---|---|---|
| 1 | info | infoName | userInfo.name | name |
| 2 | mention | infoEmail | userInfo.email | email |
| 3 | link | infoBlog | userInfo.blog | blog |
| 4 | organization | infoCompany | userInfo.company | company |
| 5 | pin | infoLocation | userInfo.location | location |
| 6 | note | infoBio | userInfo.bio | bio |

#### 共用属性
- iconSize=20 / showIconNext=true / topLine=false / bottomLine=false
- 空值显示 `---`
- 点击触发 TextInputModal → text 回调 → userActions.updateUser({field:text}) → 500ms 后 Actions.pop()

#### 关键依赖
- [CommonRowItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/common/CommonRowItem.js)
- TextInputModal 弹层（[TextInputModal.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/TextInputModal.js)）
- userActions.updateUser → POST /user PATCH（[user.js action](https://github.com/CarGuo/GSYGithubApp/blob/master/app/store/actions/user.js)）

### S2 OH 现状 Diff

| 资源 | 状态 | 说明 |
|---|---|---|
| [CommonRowItem.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/CommonRowItem.ets) | ✅ 已有 | 签名兼容（itemText/nameText/itemIcon/iconSize/showIconNext/topLine/bottomLine/onClickFun）；样式 token 已就位（GSYColor/GSYFontSize/GSYSpacing） |
| PersonInfoPage.ets | ❌ 缺 | 待写 |
| TextInputModal | ❌ 缺等价物 | 可用 promptAction.showDialog 或自实现 CustomDialog（M-pattern） |
| UserService.updateUser | ❓ 待查 | 需扩 service 端 PATCH /user |
| RouteName.PersonInfo | ❓ 待查 | 需在 [Routes.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/Routes.ets) 注册 |
| Routes 注册 | ❓ | [AppNavigator.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/AppNavigator.ets) 添加 NavDestination |
| MyPage 入口 | ❓ | RN MyPage 中点击「编辑信息」跳到 PersonInfoPage，OH 当前 PersonPage 是否有此入口 |
| I18n key 6 项 | ❓ | infoName/infoEmail/infoBlog/infoCompany/infoLocation/infoBio |
| FA icon 6 个 | ❓ | info / mention / link / organization / pin / note |

### S3 计划（按 6 步）

| Step | 动作 |
|---|---|
| S1 | ☑ 已读 RN 源 + 已写差异表（本节） |
| S2 | 探 OH：UserService 是否有 updateUser / RouteName 是否定义 / I18n 6 key 是否存在 / FA icon 6 个是否在 IconFont.ets |
| S3 | 写 PersonInfoPage.ets（6 CommonRowItem + AppBar + onClick 触发编辑流） + UserService.updateUser PATCH 实现 + RouteName 注册 + AppNavigator NavDestination + MyPage 入口跳转 |
| S4 | hvigorw assembleHap |
| S5 | 真机：MyPage 入口 → PersonInfoPage 渲染 → 6 行可见 → 点击 1 行触发编辑（先用 promptAction.showDialog） |
| S6 | 三件套（OH 截图 + RN 截图 + diff） + INDEX 升级 |

---

## 6.3 ReleasePage（次优先级）

### S1 待读 RN
- [ReleasePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ReleasePage.js)
- 实际是 ListPage(dataType=repo_release) 的入口包装

### S2 OH 现状
缺，可在 L6.1 第二阶段 SubListMode.RELEASE 完成后顺势加入口。

---

## 6.4+ 其余 2 页（PhotoPage / WebPage）

low 优先级，每页推进时在本文档新增小节（结构与 6.1/6.2 同模板），不再赘述。

