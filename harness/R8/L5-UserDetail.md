# L5 UserDetailPage（PersonPage）主链

> 入口：dynamic 头像 onTap / search user 结果 onTap → UserDetail。
> 含子页：followers / following 列表。
> 状态：🔄 进行中（2026-05-26）；S0 ☑（防御复核完成），S1..S6 待执行
> 主文件：[UserDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets)（513 行）

---

## § 0 jscrash 防御复核（S0 ✅ 完成 2026-05-26）

### 0.1 onReady 防御链路（与 R7-G KI-022 闭环一致）

| 防御点 | 位置 | 现状 |
|---|---|---|
| ctx.pathInfo.param 优先 | [UserDetailPage.ets#L488-L511](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L488-L511) | ✅ 已具备 |
| try/catch 包裹 stack 兜底 | [UserDetailPage.ets#L488-L511](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L488-L511) | ✅ 已具备 |
| resolveLoginFromStack 内部 try/catch | [UserDetailPage.ets#L75-L89](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L75-L89) | ✅ 已具备 |
| FALLBACK_LOGIN 兜底常量 | [UserDetailPage.ets#L67-L73](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L67-L73) | ✅ 已具备 |

**结论**：onReady 同款 jscrash 防御已与 KI-022 / KI-029 / KI-042 长期范式对齐，**S0 不需要补任何代码**，相关修复直接进入 S3 阶段处理新发现隐患。

### 0.2 S3 待修字面量隐患清单（HARD-LAW-2 违规预登记）

| ID | 位置 | 字面量 | 待替换为 |
|---|---|---|---|
| L5-LIT-01 | [UserDetailPage.ets#L173-L177](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L173-L177) | width(72)/height(72)/borderRadius(36) | GSYIconSize.userAvatar / GSYSpacing.* |
| L5-LIT-02 | [UserDetailPage.ets#L191-L194](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L191-L194) | margin({top:4})/margin({left:16}) | GSYSpacing.tinyTop / GSYSpacing.normalLeft |
| L5-LIT-03 | [UserDetailPage.ets#L202-L203](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L202-L203) | height(32)/padding({left:12,right:12}) | GSYSpacing.btnHeight / GSYSpacing.* |
| L5-LIT-04 | [UserDetailPage.ets#L216-L269](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L216-L269) | margin({top:12/16}) | GSYSpacing.normalTop / GSYSpacing.middleTop |
| L5-LIT-05 | [UserDetailPage.ets#L273](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L273) | padding(16) | GSYSpacing.contentNormal |
| L5-LIT-06 | [UserDetailPage.ets#L300](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L300) | Text('private') 硬编码英文 | I18n key（参考 RN constant.js） |
| L5-LIT-07 | [UserDetailPage.ets#L320-L325](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L320-L325) | '★ ' / '⑂ ' 字面 emoji | RN UserItem 同款 Image 资源或 token |
| L5-LIT-08 | [UserDetailPage.ets#L353](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L353) | height(240) 头部高度 | GSYSpacing.userHeaderHeight |

### 0.3 S3 待补 bootUser want 通道（KI-029/042 同款 AppStorage 兜底范式）

| 步骤 | 文件 | 待加内容 |
|---|---|---|
| EntryAbility 写 BOOT_USER_KEY | [EntryAbility.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets) | want.parameters.bootUser → AppStorage.SetOrCreate('BOOT_USER_KEY', login) |
| HomePage scheduleBootUser | [HomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets) | push('UserDetail', {login}) 后延迟 1500ms 清空 BOOT_USER_KEY |
| UserDetailPage tryAdoptBootUser | [UserDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets) | aboutToAppear 直读 BOOT_USER_KEY、解析、立即清空 |

---

## § 1 RN 基准清单（S1 ✅ 完成 2026-05-26）

### 1.1 RN 源结构（已 Read 5 文件 / 1100+ 行）

| RN 文件 | 行数 | 角色 |
|---|---|---|
| [PersonPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PersonPage.js) | 99 | 入口外壳，extends BasePersonPage；持 userInfo + needFollow + hadFollowed 三 state |
| [BasePersonPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/BasePersonPage.js) | 313 | 基类：PullListView + UserHeadItem + EventItem 列表（user 模式）/ UserItem 列表（org 模式） |
| [UserHeadItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserHeadItem.js) | 435 | 头部卡片（深色 primary 背景 + 阴影 + 圆角底部）+ 5 列 NameValueItem 底栏 + Activity WebView |
| [UserItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserItem.js) | 85 | org 成员卡片：avatar + login + location + bio |
| [userDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/userDao.js) | 407 | getUserInfoDao（含 starred 数）/ checkFollowDao / doFollowDao / getMember / getUserOrgs / getFollowerListDao / getFollowedListDao |

### 1.2 PersonPage 渲染结构（树状）

```
PersonPage (BasePersonPage)
└── View styles.mainBox
    ├── StatusBar barStyle=light-content / transparent / translucent
    └── PullListView (flex:1)
        ├── renderHeader = UserHeadItem
        │   └── 顶层 View paddingHorizontal=normalMarginEdge(10) paddingTop=2*normalMarginEdge(20)
        │       backgroundColor=primaryColor(#24292e)
        │       shadow{offset:1,2 / opacity:0.7 / radius:5} elevation:2
        │       borderBottomLeftRadius:5 borderBottomRightRadius:5
        │       ├── 1) followView (绝对定位 right:normalMarginEdge top:normalMarginEdge)
        │       │     <TouchableOpacity 外框 borderColor=miWhite borderWidth:1 borderRadius:4>
        │       │       Text smallTextWhite [unFollowed|doFollowed]
        │       ├── 2) row1 [styles.flexDirectionRowNotFlex]
        │       │     ├── avatar TouchableOpacity → SettingPage|PhotoPage
        │       │     │     Image largeIconSize=80×80 borderRadius=40 marginTop:5
        │       │     └── infoBlock marginLeft:normalMarginEdge
        │       │           ├── nameRow [centerH+row]
        │       │           │     ├── Text largeTextWhite bold (login)
        │       │           │     └── (settings) bell IconF size=15 marginLeft:5 padding:10
        │       │           ├── Text subLightSmallText (name)
        │       │           ├── IconTextItem icon=group text=company    marginTop:5
        │       │           └── IconTextItem icon=map-marker text=location marginTop:5 marginLeft:3
        │       ├── 3) IconTextAutoLinkItem icon=link text=blog smallTextSize  marginTop:5
        │       ├── 4) OrgItemBar (orgsList) – 横向小圆头像列表
        │       ├── 5) IconTextItem text=bio + "\n创建于：" + resolveTime(created_at)
        │       │     subLightSmallText marginVertical:normalMarginEdge
        │       ├── 6) bottomItem (5 NameValueItem 等分；纵向竖线分隔；borderTop hairline+primaryLight)
        │       │     ├── repos                → ListPage(user_repos)
        │       │     ├── follower (左右竖线)  → ListPage(follower)
        │       │     ├── followed             → ListPage(followed)
        │       │     ├── stared (左竖线)      → ListPage(user_star)
        │       │     └── beStared (左竖线)    → ListPage(user_be_stared)
        │       ├── 7) View height:5（卡片底部留白）
        │       ├── 8) Text normalText bold (menuTitle = personDynamic|Member)
        │       └── 9) Activity WebView（仅 user 模式）shadowCard 130 高 横向滚动 加载条/错误重试
        └── renderRow:
              showType==1 (Organization) → UserItem(login, avatar, location, bio)
              showType==0 (User)         → EventItem(actor / des / actionStr / time)
```

### 1.3 RN ↔ OH Theme token 映射表

| RN 字面量 | RN token（[constant.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js)） | OH token（[Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets)） | 备注 |
|---|---|---|---|
| `#24292e` 头部背景 | primaryColor=#24292e | [GSYColor.primary](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L17) | ✅ 已对齐 |
| `#42464b` 分隔线 | primaryLightColor | [GSYColor.primaryLight](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L19) | ✅ |
| `#ececec` 边框白 | miWhite | [GSYColor.miWhite](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L5) | ✅ |
| `#267aff` 通知点 | actionBlue | [GSYColor.actionBlue](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L13) | ✅ |
| 80 头像尺寸 | largeIconSize=80 | [GSYIconSize.large=80](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L125) | ⚠️ OH 现状用 72，需改 80 |
| 40 头像圆角 | largeIconSize/2=40 | GSYIconSize.large/2 | ⚠️ OH 现状 36，需改 40 |
| 30 列表小头像 | smallIconSize=30 | [GSYIconSize.small=30](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L126) | ✅ |
| 10 标准外边距 | normalMarginEdge=10 | [GSYSpacing.normalEdge=10](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L132) | ✅ |
| 5 半外边距 | normalMarginEdge/2 | [GSYSpacing.halfEdge=5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L133) | ✅ |
| 14 小字号 | smallTextSize=14 | [GSYFontSize.small=14](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L116) | ✅ |
| 18 普通字号 | normalTextSize=18 | [GSYFontSize.normal=18](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L112) | ✅ |
| 4 行 numberOfLines | normalNumberOfLine=4 | [GSYSpacing.normalNumberOfLine=4](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L135) | ✅ |
| 阴影 elevation:2/radius:5 | — | [GSYShadow.elevation=2 / radius=5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets#L146-L147) | ✅ |

**结论**：Theme.ets 已具备 PersonPage 全部 RN 蓝本 token，**S3 阶段 OH 端只需做"字面量替换"，无需新增 token**。OH 现状 width(72)/borderRadius(36) 与 RN 80/40 不一致，是字面量违规之外的"数值不准"，纳入 S3 一并修。

### 1.4 RN I18n key 字典（[i18n.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/i18n.js)）

| key | en | zh | OH 落点 |
|---|---|---|---|
| repositoryText | repository | 仓库 | bottomItem 第 1 列 |
| FollowersText | follower | 粉丝 | bottomItem 第 2 列 |
| FollowedText | followed | 关注 | bottomItem 第 3 列 |
| staredText | stared | 星标 | bottomItem 第 4 列 |
| beStaredText | honour | 荣耀 | bottomItem 第 5 列 |
| userInfoNoting | nothing | Ta什么都没留下 | 占位文案（company/location/blog/bio） |
| userCreate | Created At： | 创建于： | bio 后拼接 created_at |
| unFollowed | unFollow | 取消关注 | followView 已关注态文案 |
| doFollowed | Follow | 关注 | followView 未关注态文案 |
| personDynamic | Activity | 个人动态 | 列表区分组标题（user 模式） |
| Member | Member | 成员 | 列表区分组标题（org 模式） |

S3 阶段需在 OH 增量补 key（若 [I18nUtil.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/utils/I18nUtil.ets) 缺）。

### 1.5 RN 交互序列（伪代码）

```
componentDidMount(PersonPage):
    _refreshInfo:
        userActions.getPersonUserInfo(login)        // local realm → next() net
            .then(res) setState userInfo + Actions.refresh({titleData, showType: user|Organization})
            .next()    setState userInfo
        userActions.checkFollow(login)
            .then(res) setState hadFollowed + needFollow=true
    BasePersonPage.componentDidMount:
        InteractionManager.runAfterInteractions:
            pullListRef.showRefreshState
            _refresh                                  // showType=-1 不进任何分支
            _getMoreInfo                              // 取 user_repository100 → beStaredCount + beStaredList

componentDidUpdate(BasePersonPage):
    showType 切换：
        Organization → showType=1 → _refresh (getMember 1)
        user         → showType=0 → _getOrgsList (getUserOrgs) + _refresh (getEvent 1)

doFollowLogic (UserHeadItem 中 Follow 按钮回调):
    Actions.LoadingModal({backExit:false})
    userActions.doFollow(login, !hadFollowed)
        .then(_refreshInfo)                            // 重拉 user info + status
        setTimeout 500 → Actions.pop()                 // 关闭 LoadingModal

bottomItem onItemPress 5 项跳子页：
    repos    → Actions.ListPage(user_repos / repository, filter=updated)
    follower → Actions.ListPage(follower / user)
    followed → Actions.ListPage(followed / user)
    stared   → Actions.ListPage(user_star / repository, filter=updated)
    beStared → Actions.ListPage(user_be_stared / repository, localData=beStaredList)

avatar onTap：
    settingNeed === true（自己） → Actions.SettingPage()
    其它（他人页） → Actions.PhotoPage({uri: avatar_url})

bell onTap（仅自己页 setting=true）：
    Actions.NotifyPage({backNotifyCall, rightBtnPress: 全部已读 → setAllNotificationAsRead})
```

### 1.6 RN 截图基线候选

[screenshots/rn/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn) 中尚无 PersonPage 命名图；S6 阶段允许以 RN 源代码作"代码真源"，与既有 L4 同步策略；如有真机截图后续登记 [INDEX.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/INDEX.md) 第 8 行。

---

## § 2 OH 偏差清单（S2 ✅ 完成 2026-05-26）

OH 现状：[UserDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets)（513 行）

### 2.1 OH 现状结构（树状）

```
NavDestination
└── Column id=user_detail_root
    ├── AppBar title='@<login>' showBack rightActions=[more]   ⚠️ RN 无 AppBar，PersonPage 头部即标题
    └── PullLoadMoreList id=user_detail_pull_list
        ├── renderHeader = buildHeaderWithHeatmap
        │   ├── buildHeader (Column id=user_detail_header_card padding(16) backgroundColor=primary)
        │   │   ├── Row id=user_detail_head_row
        │   │   │   ├── Image avatar 72×72 borderRadius(36)        ⚠️ RN 是 80×80 borderRadius(40)
        │   │   │   ├── Column [name + login]  margin({left:16})    ⚠️ RN 用 normalMarginEdge(10)
        │   │   │   └── Button(unFollowed|doFollowed) actionBlue 实心 height(32)  ⚠️ RN 是 miWhite 描边 padding=10/halfEdge
        │   │   ├── Text bio ｜ userInfoNoting  margin({top:12})    ⚠️ RN 用 IconTextItem subLightSmallText 行高 marginVertical:10
        │   │   └── Row counts 3 列 (repos / followers / following) margin({top:16})
        │   │       ⚠️ RN 5 列 (repos / follower / followed / stared / beStared)，缺 stared/beStared
        │   │       ⚠️ RN 列间用 hairline+primaryLight 竖线分隔；OH 等分无分隔线
        │   │       ⚠️ RN borderTop hairline+primaryLight；OH 无
        │   └── ContributionHeatmap (OH 增强：GitHub 贡献热力图)    ⚠️ RN 无原生热力图，是 Activity WebView graphicHost
        ├── rowBuilder = UserRepoItem 列表（full_name + private + description + language + ★ count + ⑂ count）
        │   ⚠️ RN 是 EventItem（actor/des/actionStr/time），不是 repos 列表
        │   ⚠️ RN org 模式才走 UserItem（avatar/login/location/bio）
        └── emptyBuilder height(240) Text(userInfoNoting)

外加：
  - OH 有 showMoreMenu / browserOpen / copy / share（RN 无）
  - OH 缺 OrgItemBar 横向组织头像列表
  - OH 缺 IconTextItem (group / map-marker / link) 行（公司/位置/blog）
  - OH 缺 bell 通知图标（仅自己页用，他人页不需要）
  - OH 缺 personDynamic / Member 分组标题
```

### 2.2 4 字段差异表（OH 现状 vs RN 蓝本 vs 根因 vs 涉及文件）

| Δ# | OH 现状 | RN 蓝本 | 根因 | 涉及文件 / 修改面 | 优先级 |
|---|---|---|---|---|---|
| **Δ1** | 头像 width(72)/height(72)/borderRadius(36) 字面量 | largeIconSize=80 / borderRadius=40 | HARD-LAW-2 字面量 + 数值偏离 RN | [UserDetailPage.ets#L173-L177](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L173-L177) → GSYIconSize.large | P1 |
| **Δ2** | Follow Button = actionBlue 实心 height(32) padding(left:12,right:12) | miWhite 描边 borderWidth:1 borderRadius:4 padding=halfEdge/normalEdge Text smallTextWhite | UI 不一致 + 字面量 | [UserDetailPage.ets#L197-L206](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L197-L206) → 改为描边样式 + GSYSpacing | P0 |
| **Δ3** | counts 3 列（repos/followers/following）等分无分隔线 | counts 5 列（repos/follower/followed/stared/beStared）+ 列竖线 + borderTop hairline | 缺字段 + 缺 RN 视觉 | [UserDetailPage.ets#L218-L269](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L218-L269) → 加 stared/beStared 列 + Divider | P0 |
| **Δ4** | bio 简单 Text margin({top:12}) | IconTextItem subLightSmallText + bio + "\n" + "创建于：" + resolveTime(created_at) marginVertical=normalEdge | 缺 created_at 拼接 + 缺 hint | [UserDetailPage.ets#L212-L216](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L212-L216) → 拼接 + 用 GSYSpacing | P1 |
| **Δ5** | 列表渲染 user_repos 仓库 | user 模式：EventItem 动态；org 模式：UserItem 成员 | 列表数据源/组件错误（RN 用 events/members，非 repos） | rowBuilder + store.repos 替换为 events 列表 | P0（重） |
| **Δ6** | 缺 IconTextItem 行（company / location / blog） | UserHeadItem 内 IconTextItem icon=group/map-marker/link | 缺字段 | buildHeader 内补 3 行 | P1 |
| **Δ7** | 头部背景 padding(16) | RN 头部 paddingHorizontal=normalEdge paddingTop=2*normalEdge + 阴影 + 圆角底部 5 | 字面量 + 缺阴影/圆角底部 | [UserDetailPage.ets#L271-L274](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L271-L274) | P1 |
| **Δ8** | 调试隐患：Text('private') 硬编码英文 + '★ '/'⑂ ' emoji 字面量 | RN 无 emoji 字面量 + private 走 RN 平台 | HARD-LAW-2 + HARD-LAW-3 | [UserDetailPage.ets#L300/L320/L325](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets#L300) | P1 |
| **Δ9** | bootUser want 通道未接（HomePage push UserDetail 时 NavPathStack 时序竞争） | — | KI-029/042 同款时序 bug，需 AppStorage 兜底 | [EntryAbility.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets) + [HomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets) + [UserDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets) aboutToAppear | P0 |
| **Δ10** | 字面量散布：margin({top:4/12/16})、margin({left:16})、padding(16)、height(240) | normalMarginEdge=10 / 5 等 RN token | HARD-LAW-2 全文清零 | [UserDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/UserDetailPage.ets) 全文 ~12 处 | P0 |

### 2.3 scope A/B/C 候选评估（待用户决策）

| scope | 范围 | 工作量 | 风险 | 收益 |
|---|---|---|---|---|
| **A 最小修复** | Δ1+Δ2+Δ8+Δ9+Δ10（jscrash 已 ☑ + 字面量清零 + Follow 描边样式 + bootUser want + 移除 'private'/emoji 字面量；保留 OH 现状 3 列 counts + ContributionHeatmap + repos 列表） | 小（~80 行 ArkTS）| 低；不动业务列表数据源；与 L4-CodeDetail scope 类似 | 法规合规 + 路由稳定 + 字面量 ☑；视觉与 RN 对齐 50% |
| **B 中等对齐** | A + Δ3（5 列 counts + 列分隔线 + borderTop） + Δ4（bio + created_at 拼接） + Δ7（头部阴影 + 圆角底部）；保留 repos 列表 + 增强 ContributionHeatmap | 中（~150 行 ArkTS + I18n key 补 5 个）| 中；新增 stared/beStared 列需用户接口数据（getUserStaredCountNet 同款）| 视觉与 RN 对齐 80%；列表保留 OH 增强 |
| **C 全功能 RN-aligned** | B + Δ5（rowBuilder 改为 EventItem + getUserEvents 接口）+ Δ6（IconTextItem company/location/blog 3 行 + OrgItemBar） | 大（~280 行 ArkTS + 新接口 getUserEvents/getUserOrgs + EventItem 组件复用 [DynamicPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/DynamicPage.ets) 的 EventItem）| 较高；列表数据源切换；旧 repos 列表入口需改走 user_repos 子页（ListPage 占位 L6）| 视觉/功能与 RN 100% 对齐；接近完整 PersonPage 体验 |

**建议默认 scope=B**：A 工作量太小（视觉差距太大，与 L1/L3/L4 节奏不协调）；C 引入新列表接口和 EventItem 复用，跨 L5/L6 边界，宜留到 L6 ListPage 主链时一并落地。B 在 OH 端已具备 ContributionHeatmap（OH 增强）+ user_repos 列表（OH 增强）的基础上，仅做"头部 RN 对齐"，工作面收敛、风险可控、跑分稳定。

**用户拍板（2026-05-26）：scope=C 全功能 RN-aligned**。S3 范围最终锁定为 Δ1..Δ10 + Δ5（rowBuilder→EventItem 列表 + getUserEvents 接口）+ Δ6（IconTextItem company/location/blog 3 行 + OrgItemBar）。约 280 行 ArkTS + 新 net 接口 + EventItem 跨 L5/L6 边界复用（[DynamicPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/DynamicPage.ets) 已有 EventItem 候选）。

⚠️ **scope=C 已锁定，S3 起手按此范围执行。**

---

## § 3 截图对照（S5+S6 待执行）

RN 基准：本轮缺 UserDetail 截图，需在 RN 端补抓后归档至 [screenshots/rn/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/ui-parity/screenshots/rn)。

---

## § 4 DoD 检查表（见 [00-rules.md § 三](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/R8/00-rules.md)）

---

## § 5 入口路径验证

dynamic 头像 onTap / search user result onTap → NavigationService.push('UserDetail') → followers/following 跳子列表。
