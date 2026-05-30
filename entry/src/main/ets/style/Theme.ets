// Theme.ets — 与 RN 端 [constant.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js) 严格对齐
// 任何页面/组件的颜色、字号、间距、圆角必须经此暴露，禁止直接硬编码。

export class GSYColor {
  static readonly miWhite: string = '#ececec';
  static readonly white: string = '#FFFFFF';
  static readonly white80: string = '#CCFFFFFF';
  static readonly transparent: string = '#00000000';

  static readonly mainBackground: string = GSYColor.miWhite;
  static readonly tabBackground: string = '#ffffff';
  static readonly cardBackground: string = '#FFFFFF';
  static readonly cardShadow: string = '#000000';
  static readonly actionBlue: string = '#267aff';

  static readonly line: string = '#42464b';

  static readonly primary: string = '#24292e';
  static readonly primaryDark: string = '#121917';
  static readonly primaryLight: string = '#42464b';
  // RN 端 RepositoryHeader 卡片内 backgroundColor=primary opacity=0.5
  // 对照 [RepositoryHeader.js#L133-L137](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/RepositoryHeader.js#L133-L137)
  // alpha 0x80 ≈ 0.5；走 token 而非 inline rgba()，以遵守 HARD-LAW-2
  static readonly primaryHalf: string = '#8024292e';
  static readonly repositoryHeaderScrim: string = '#66000000';
  static readonly repositoryHeaderLine: string = '#66FFFFFF';

  static readonly webDraculaBackground: string = '#282a36';

  static readonly selected: string = GSYColor.primaryDark;

  static readonly titleText: string = GSYColor.miWhite;
  static readonly mainText: string = GSYColor.primaryDark;
  static readonly subText: string = '#959595';
  static readonly subLightText: string = '#c4c4c4';
  static readonly textWhite: string = '#FFFFFF';
  static readonly textMiWhite: string = GSYColor.miWhite;

  static readonly tabSelected: string = GSYColor.primary;
  static readonly tabUnSelect: string = '#a6aaaf';
  static readonly hdsFloatingTabLight: string = '#E6FFFFFF';
  static readonly hdsFloatingTabMask: string = '#E6FFFFFF';

  // GitHub Issue 业务色（OH 增强：RN 端用 RN 平台关键字 'green'/'red'，
  // OH 改用 GitHub Primer 官方调色板 #2cbe4e/#cb2431 视觉更精确，登记 OH 增强 token）
  // 对照 [IssueHead.js#L82-L87](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/IssueHead.js#L82-L87)
  static readonly issueOpenGreen: string = '#2cbe4e';
  static readonly issueClosedRed: string = '#cb2431';

  // GitHub 官方 Contribution Graph 标准色（OH 增强：RN 端无对应组件，
  // [ContributionHeatmap.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/ContributionHeatmap.ets) 用于 HonorPage 贡献热力图）
  // 色值来源：https://github.com/github/feedback graph 官方调色板
  static readonly heatmapLevel0: string = '#EBEDF0';
  static readonly heatmapLevel1: string = '#9BE9A8';
  static readonly heatmapLevel2: string = '#40C463';
  static readonly heatmapLevel3: string = '#30A14E';
  static readonly heatmapLevel4: string = '#216E39';

  // ThemeManager Light palette 衍生 token（OH 增强：RN 端无主题系统，
  // [ThemeManager.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/theme/ThemeManager.ets) 多主题切换 R2 引入）
  // 6 项与 GitHub Primer 调色板对齐
  static readonly pageBackground: string = '#F5F7FA';
  static readonly composeBackgroundLight: string = '#FAFBFC';
  static readonly composePrimaryContainer: string = GSYColor.composeBackgroundLight;
  static readonly textSubtle: string = '#6E7681';
  static readonly divider: string = '#E1E4E8';
  static readonly dangerRed: string = '#CD2130';
  static readonly linkBlue: string = '#0969DA';

  // R7-L 第三批：GitHub Primer 调色板 + 中性灰阶 + Material 主题色
  // RN 端 [constant.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/constant.js)
  // 仅声明 primary/subText/cardBg 等少量基础色；OH 增强补齐 Primer 衍生 + 业务半成品调色板
  // 17 token 一次性闭环 22 业务文件 ~70 字面量（HARD-LAW-2 THEME-TOKEN-ONLY）
  // Compose MaterialTheme.colorScheme.outline maps to GitHub BorderColor (#E1E4E8).
  static readonly borderSubtle: string = '#E1E4E8';
  static readonly surfaceSubtle: string = '#F6F8FA';
  static readonly unreadBg: string = '#FFF8E5';
  static readonly lightDivider: string = '#EEEEEE';
  static readonly surfaceGray: string = '#F5F5F5';
  static readonly surfacePill: string = '#ECECEC';
  // RN PR/Issue/Honor 状态绿（#2DA44E 与 #2EA44F 同语义合一为 successGreen）
  static readonly successGreen: string = '#2DA44E';
  static readonly warningOrange: string = '#FB8C00';
  static readonly materialBlue: string = '#2196F3';
  static readonly darkText: string = '#222222';
  static readonly mediumText: string = '#666666';
  static readonly mediumDarkText: string = '#333333';
  static readonly lightText: string = '#999999';
  static readonly pillDivider: string = '#E0E0E0';
  static readonly darkSurfaceText: string = '#C9D1D9';
  static readonly imageMaskBg: string = '#000000A0';
  static readonly solidBlack: string = '#000000';
  // HtmlUtil 行高亮链接色（OH 增强）
  static readonly actionEmphasis: string = '#3398DB';
  // LoadingModal 全屏遮罩（80% alpha 黑底）
  static readonly loadingMaskBg: string = '#CC000000';
  static readonly loadingLightMaskBg: string = '#33000000';
}

// R7-N：暗色主题 9 项调色板 token（OH 增强：RN 端无主题切换系统）
// 服务于 [ThemeManager.DARK_PALETTE](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/theme/ThemeManager.ets)
// 色值来源：GitHub Dark Mode 官方调色板（https://primer.style/foundations/color/base-scale）
// primary 与 navBackground 同语义合一为 darkPagePrimary（#0D1117）
// 测试期望严格匹配 [ThemeManagerTest.ets#L69-L70](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/ohosTest/ets/test/ThemeManagerTest.ets#L69-L70)
// 字面量大写 hex 保留，不可转 lowercase 或改 alpha
export class GSYDarkColor {
  static readonly darkPagePrimary: string = '#0D1117';
  static readonly darkPrimaryDark: string = '#010409';
  static readonly darkBackground: string = '#161B22';
  static readonly darkCard: string = '#21262D';
  static readonly darkPaletteText: string = '#F0F6FC';
  static readonly darkTextSecondary: string = '#8B949E';
  static readonly darkDivider: string = '#30363D';
  static readonly darkDanger: string = '#F85149';
  static readonly darkAccent: string = '#58A6FF';
}

export class GSYFontSize {
  static readonly large: number = 30;
  static readonly big: number = 23;
  static readonly normal: number = 18;
  static readonly middleWhite: number = 16;
  // R7-M：CustomPage item 标题字号 15（介于 middleWhite=16 与 small=14 之间）
  static readonly middleNormal: number = 15;
  static readonly small: number = 14;
  static readonly min: number = 12;
}

export class GSYIconSize {
  static readonly nav: number = 70;
  static readonly tab: number = 20;
  static readonly normal: number = 40;
  static readonly big: number = 50;
  static readonly large: number = 80;
  static readonly small: number = 30;
  static readonly minIcon: number = 20;
  static readonly cardIcon: number = 24;
  static readonly little: number = 10;
}

export class GSYSpacing {
  static readonly normalEdge: number = 10;
  static readonly halfEdge: number = 5;
  static readonly padding12: number = 12;
  static readonly composeCardHorizontal: number = 16;
  static readonly composeCardVertical: number = 8;
  static readonly tabBarHeight: number = 56;
  static readonly hdsFloatingTabSideMargin: number = 16;
  static readonly hdsFloatingTabBottomMargin: number = 12;
  static readonly hdsFloatingTabMaskHeight: number = 108;
  static readonly normalNumberOfLine: number = 4;
  // 系统状态栏 + LiveCapsule(metaball) 高度容纳；
  // 真机 dump LiveMetaBallBaseVm bounds=[380,19][940,136]，胶囊到 y=136
  // 取 28vp（≈84px @3x）兜底，避免 NavDestination tab bar 与系统胶囊视觉粘连（D1/D2）
  static readonly statusBarInset: number = 28;
  // RN tabBarIndicatorStyle 高度 3，对照
  // [RepositoryDetailPage.js#L322-L335](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/RepositoryDetailPage.js#L322-L335)
  static readonly tabIndicatorThickness: number = 3;
  // CommonBottomBar 默认高度（对齐 RN [components/common/CommonBottomBar.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/common/CommonBottomBar.js)
  // paddingVertical=normalMarginEdge*2 + 一行图标文字 ~ 50）
  static readonly bottomBarDefault: number = 56;
  // 卡片圆角 / 分隔线粗细（对齐 RN [style/index.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/index.js)
  // borderRadius:4 / hairlineWidth ≈ 0.5；OH 增强 token，避免页面字面量违反 HARD-LAW-2）
  static readonly cardRadius: number = 4;
  static readonly dividerThickness: number = 0.5;
}

export class GSYShadow {
  static readonly radius: number = 5;
  static readonly elevation: number = 2;
  // 卡片阴影色：RN 端 cardShadowColor=#000000 + shadowOpacity 0.12（约 1F=31/255）
  // 对照 [style/index.js#L155-L162](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/index.js)
  // OH ArkUI ShadowOptions.color 不支持 alpha 单独字段，用 8 位带 alpha 颜色字面量
  static readonly cardShadowAlpha: string = '#1F000000';

  // 文字阴影：对齐 RN [style/index.js#L164-L168](https://github.com/CarGuo/GSYGithubApp/blob/master/app/style/index.js#L164-L168)
  // styles.shadowText: { textShadowColor: '#000000', textShadowOffset: {0, 0.4}, textShadowRadius: 0.4 }
  static readonly textRadius: number = 0.4;
  static readonly textOffsetX: number = 0;
  static readonly textOffsetY: number = 0.4;
  static readonly textColor: string = '#000000';
  static readonly headerTextRadius: number = 4;
  static readonly headerTextOffsetX: number = 0;
  static readonly headerTextOffsetY: number = 1;
  static readonly headerTextColor: string = '#E6000000';
}
