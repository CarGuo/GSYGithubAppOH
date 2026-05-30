import { ThemePalette, LIGHT_PALETTE, THEME_PALETTE_KEY } from '../theme/ThemeManager';
import { SAFE_AREA_TOP_KEY } from '../utils/SafeAreaInsets';
import { GSYColor, GSYFontSize, GSYIconSize, GSYSpacing } from '../style/Theme';

const APP_BAR_SIDE_WIDTH: number = 64;
const APP_BAR_TITLE_LINE_HEIGHT: number = 28;
const APP_BAR_SUBTITLE_LINE_HEIGHT: number = 18;

export interface AppBarAction {
  text?: string;
  icon?: ResourceStr;
  /** 矢量 icon 关键字：search/menu/filter/more/done_all 等。优先于 icon。 */
  iconKey?: string;
  onAction?: () => void;
}

@Component
export struct AppBar {
  @Prop title: string = '';
  @Prop titleId: string = 'appbar_title';
  @Prop subtitle: string = '';
  showBack: boolean = true;
  backgroundColorValue: ResourceColor = GSYColor.primary;
  titleColor: ResourceColor = GSYColor.white;
  subtitleColor: ResourceColor = GSYColor.subLightText;
  actionColor: ResourceColor = GSYColor.white;
  barHeight: number = 64;
  useTheme: boolean = true;
  titleStart: boolean = true;
  /** 是否让 AppBar 背景延伸到状态栏区域并自动让出 statusBar 高度（沉浸式） */
  immersive: boolean = true;
  onBack: () => void = (): void => {};
  leftActions: AppBarAction[] = [];
  rightActions: AppBarAction[] = [];

  @StorageProp(THEME_PALETTE_KEY) palette: ThemePalette = LIGHT_PALETTE;
  @StorageProp(SAFE_AREA_TOP_KEY) safeAreaTop: number = 0;

  private resolveBackground(): ResourceColor {
    if (this.useTheme && this.palette) {
      return this.palette.navBackground;
    }
    return this.backgroundColorValue;
  }

  private resolveTitleColor(): ResourceColor {
    if (this.useTheme && this.palette) {
      return GSYColor.white;
    }
    return this.titleColor;
  }

  private resolveSubtitleColor(): ResourceColor {
    if (this.useTheme && this.palette) {
      return this.palette.textSecondary;
    }
    return this.subtitleColor;
  }

  private resolveActionColor(): ResourceColor {
    if (this.useTheme && this.palette) {
      return GSYColor.white;
    }
    return this.actionColor;
  }

  private resolveActionMaterialBackground(): ResourceColor {
    return this.useTheme ? GSYColor.hdsMaterialSurfaceDark : GSYColor.transparent;
  }

  @Builder
  buildSearchVectorIcon(color: ResourceColor, size: number): void {
    Stack() {
      // 放大镜圆环：用宽度 1.6 的 Circle 描边
      Circle({ width: size * 0.62, height: size * 0.62 })
        .stroke(color)
        .strokeWidth(1.8)
        .fillOpacity(0)
        .position({ x: size * 0.08, y: size * 0.08 });
      // 把手：从圆环右下角延伸到右下
      Line()
        .width(size)
        .height(size)
        .startPoint([size * 0.62, size * 0.62])
        .endPoint([size * 0.88, size * 0.88])
        .stroke(color)
        .strokeWidth(2.0);
    }
    .width(size)
    .height(size);
  }

  @Builder
  buildFilterVectorIcon(color: ResourceColor, size: number): void {
    Stack() {
      // 漏斗顶部横边
      Line()
        .width(size)
        .height(size)
        .startPoint([size * 0.10, size * 0.20])
        .endPoint([size * 0.90, size * 0.20])
        .stroke(color)
        .strokeWidth(2.0);
      // 漏斗左斜边
      Line()
        .width(size)
        .height(size)
        .startPoint([size * 0.10, size * 0.20])
        .endPoint([size * 0.42, size * 0.55])
        .stroke(color)
        .strokeWidth(2.0);
      // 漏斗右斜边
      Line()
        .width(size)
        .height(size)
        .startPoint([size * 0.90, size * 0.20])
        .endPoint([size * 0.58, size * 0.55])
        .stroke(color)
        .strokeWidth(2.0);
      // 漏斗左茎
      Line()
        .width(size)
        .height(size)
        .startPoint([size * 0.42, size * 0.55])
        .endPoint([size * 0.42, size * 0.90])
        .stroke(color)
        .strokeWidth(2.0);
      // 漏斗右茎
      Line()
        .width(size)
        .height(size)
        .startPoint([size * 0.58, size * 0.55])
        .endPoint([size * 0.58, size * 0.90])
        .stroke(color)
        .strokeWidth(2.0);
      // 漏斗底端封口
      Line()
        .width(size)
        .height(size)
        .startPoint([size * 0.42, size * 0.90])
        .endPoint([size * 0.58, size * 0.90])
        .stroke(color)
        .strokeWidth(2.0);
    }
    .width(size)
    .height(size);
  }

  @Builder
  buildMoreVectorIcon(color: ResourceColor, size: number): void {
    Row() {
      Circle({ width: size * 0.18, height: size * 0.18 })
        .fill(color)
        .margin({ right: size * 0.08 });
      Circle({ width: size * 0.18, height: size * 0.18 })
        .fill(color)
        .margin({ right: size * 0.08 });
      Circle({ width: size * 0.18, height: size * 0.18 })
        .fill(color);
    }
    .width(size)
    .height(size)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  buildMenuVectorIcon(color: ResourceColor, size: number): void {
    Stack() {
      ForEach([0, 1, 2], (idx: number): void => {
        Line()
          .width(size)
          .height(size)
          .startPoint([size * 0.18, size * (0.28 + idx * 0.22)])
          .endPoint([size * 0.82, size * (0.28 + idx * 0.22)])
          .stroke(color)
          .strokeWidth(2.2);
      }, (idx: number): string => idx.toString());
    }
    .width(size)
    .height(size);
  }

  @Builder
  buildDoneAllVectorIcon(color: ResourceColor, size: number): void {
    Stack() {
      Line()
        .width(size)
        .height(size)
        .startPoint([size * 0.10, size * 0.54])
        .endPoint([size * 0.30, size * 0.74])
        .stroke(color)
        .strokeWidth(2.4);
      Line()
        .width(size)
        .height(size)
        .startPoint([size * 0.30, size * 0.74])
        .endPoint([size * 0.56, size * 0.36])
        .stroke(color)
        .strokeWidth(2.4);
      Line()
        .width(size)
        .height(size)
        .startPoint([size * 0.42, size * 0.68])
        .endPoint([size * 0.86, size * 0.26])
        .stroke(color)
        .strokeWidth(2.4);
    }
    .width(size)
    .height(size);
  }

  @Builder
  buildAction(action: AppBarAction, side: string, idx: number): void {
    Button() {
      Row() {
        if (action.iconKey === 'search') {
          this.buildSearchVectorIcon(this.resolveActionColor(), 22);
        } else if (action.iconKey === 'menu') {
          this.buildMenuVectorIcon(this.resolveActionColor(), 22);
        } else if (action.iconKey === 'done_all') {
          this.buildDoneAllVectorIcon(this.resolveActionColor(), 24);
        } else if (action.iconKey === 'filter') {
          this.buildFilterVectorIcon(this.resolveActionColor(), 20);
        } else if (action.iconKey === 'more') {
          this.buildMoreVectorIcon(this.resolveActionColor(), 22);
        } else if (action.icon) {
          Image(action.icon)
            .width(20)
            .height(20)
            .fillColor(this.resolveActionColor());
        }
        if (action.text && action.text.length > 0) {
          Text(action.text)
            .fontSize(GSYFontSize.small)
            .fontColor(this.resolveActionColor())
            .margin({ left: (action.icon || action.iconKey) ? 4 : 0 });
        }
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%');
    }
    .id(action.iconKey && action.iconKey.length > 0
      ? 'appbar_action_' + side + '_' + action.iconKey
      : 'appbar_action_' + side + '_' + idx.toString())
    .type(ButtonType.Normal)
    .backgroundColor(this.resolveActionMaterialBackground())
    .border({
      width: 0.5,
      color: GSYColor.hdsMaterialBorder,
    })
    .borderRadius(GSYSpacing.hdsActionButtonRadius)
    .padding({ left: 8, right: 8 })
    .width(GSYSpacing.hdsActionButtonSize)
    .height(GSYSpacing.hdsActionButtonSize)
    .margin({
      top: (this.barHeight - GSYSpacing.hdsActionButtonSize) / 2,
      bottom: (this.barHeight - GSYSpacing.hdsActionButtonSize) / 2,
      left: 4,
      right: 4,
    })
    // 显式 hit area 与拦截：避免 SideBarContainer 主内容层把点击吞掉
    .hitTestBehavior(HitTestMode.Block)
    .onClick((): void => {
      if (action.onAction) {
        action.onAction();
      }
    });
  }

  @Builder
  buildBack(): void {
    Button() {
      Text('<')
        .fontSize(GSYIconSize.minIcon)
        .fontWeight(FontWeight.Bold)
        .lineHeight(APP_BAR_TITLE_LINE_HEIGHT)
        .fontColor(this.resolveActionColor());
    }
    .type(ButtonType.Normal)
    .backgroundColor(this.resolveActionMaterialBackground())
    .border({
      width: 0.5,
      color: GSYColor.hdsMaterialBorder,
    })
    .borderRadius(GSYSpacing.hdsActionButtonRadius)
    .padding({ left: 12, right: 8 })
    .width(GSYSpacing.hdsActionButtonSize)
    .height(GSYSpacing.hdsActionButtonSize)
    .margin({
      top: (this.barHeight - GSYSpacing.hdsActionButtonSize) / 2,
      bottom: (this.barHeight - GSYSpacing.hdsActionButtonSize) / 2,
      left: 4,
      right: 4,
    })
    .hitTestBehavior(HitTestMode.Block)
    .onClick((): void => {
      this.onBack();
    });
  }

  build(): void {
    Column() {
      if (this.immersive && this.safeAreaTop > 0) {
        Row()
          .id('appbar_status_spacer')
          .width('100%')
          .height(this.safeAreaTop)
          .backgroundColor(this.resolveBackground());
      }
      Row() {
        if (this.titleStart) {
          Row() {
            if (this.showBack) {
              this.buildBack();
            }
            ForEach(this.leftActions, (action: AppBarAction, idx: number): void => {
              this.buildAction(action, 'l', idx);
            }, (action: AppBarAction, idx: number): string => 'l_' + idx.toString());
          }
          .alignItems(VerticalAlign.Center);

          Column() {
            Text(this.title)
              .id(this.titleId)
              .fontSize(GSYFontSize.normal)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.resolveTitleColor())
              .lineHeight(APP_BAR_TITLE_LINE_HEIGHT)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            if (this.subtitle.length > 0) {
              Text(this.subtitle)
                .fontSize(GSYFontSize.min)
                .fontColor(this.resolveSubtitleColor())
                .lineHeight(APP_BAR_SUBTITLE_LINE_HEIGHT)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 2 });
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Center);

          Row() {
            ForEach(this.rightActions, (action: AppBarAction, idx: number): void => {
              this.buildAction(action, 'r', idx);
            }, (action: AppBarAction, idx: number): string => 'r_' + idx.toString());
          }
          .padding({ right: 8 })
          .justifyContent(FlexAlign.End)
          .alignItems(VerticalAlign.Center)
          .hitTestBehavior(HitTestMode.Transparent);
        } else {
          Row() {
            if (this.showBack) {
              this.buildBack();
            }
            ForEach(this.leftActions, (action: AppBarAction, idx: number): void => {
              this.buildAction(action, 'l', idx);
            }, (action: AppBarAction, idx: number): string => 'l_' + idx.toString());
          }
          .width(APP_BAR_SIDE_WIDTH)
          .alignItems(VerticalAlign.Center);

          Column() {
            Text(this.title)
              .id(this.titleId)
              .fontSize(GSYFontSize.normal)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.resolveTitleColor())
              .lineHeight(APP_BAR_TITLE_LINE_HEIGHT)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            if (this.subtitle.length > 0) {
              Text(this.subtitle)
                .fontSize(GSYFontSize.min)
                .fontColor(this.resolveSubtitleColor())
                .lineHeight(APP_BAR_SUBTITLE_LINE_HEIGHT)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 2 });
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center);

          Row() {
            ForEach(this.rightActions, (action: AppBarAction, idx: number): void => {
              this.buildAction(action, 'r', idx);
            }, (action: AppBarAction, idx: number): string => 'r_' + idx.toString());
          }
          .width(APP_BAR_SIDE_WIDTH)
          .padding({ right: 8 })
          .justifyContent(FlexAlign.End)
          .alignItems(VerticalAlign.Center)
          .hitTestBehavior(HitTestMode.Transparent);
        }
      }
      .id('appbar_main_row')
      .width('100%')
      .height(this.barHeight)
      .alignItems(VerticalAlign.Center);
    }
    .id('appbar_root')
    .width('100%')
    .backgroundColor(this.resolveBackground());
  }
}
