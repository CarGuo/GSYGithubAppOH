/**
 * TabIcon —— 严格对齐 RN 端
 * [components/widget/TabIcon.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/TabIcon.js)
 *
 * RN 端 TabIcon render 同时输出图标 + 文字（L52-L55）：
 *   <View style={styles.centered}>
 *     <Icon name={iconPath} size={tabIconSize=20} color={selectedColor}/>
 *     <Text style={[{color}, {fontSize: smallTextSize=14}]}>{title}</Text>
 *   </View>
 * 颜色：focused → primaryColor (#24292e)；否则 #a6aaaf
 *
 * iconPath 映射（RN 端使用 react-native-vector-icons/Feather）：
 *   tabDynamic    -> aperture
 *   tabRecommended -> activity
 *   tabMy         -> user
 *
 * OpenHarmony 当前 SDK 未提供 sys.symbol 资源，这里走 ArkUI 矢量绘制：
 *   - aperture：外圆 + 内圆 + 三条放射隔膜（圆 + 三条 line，强识别度）
 *   - activity：折线（心跳/曲线）—— Feather activity 形态
 *   - user：上头部圆 + 下肩部 Path —— Feather user 形态
 *
 * R5l 修复点：
 *   1. selected 字段必须 @Prop，否则父级 @State 切换不会触发本组件 rebuild（点击没选中态）
 *   2. RN TabIcon 内部其实有 Text(title)，对齐 RN 加上 title 文字行
 */

import { GSYColor, GSYFontSize, GSYIconSize } from '../style/Theme';

export type TabIconKey = 'aperture' | 'activity' | 'user';

@Component
export struct TabIcon {
  @Prop iconKey: TabIconKey = 'aperture';
  @Prop selected: boolean = false;
  @Prop title: string = '';
  iconSize: number = GSYIconSize.tab;

  private resolveColor(): string {
    return this.selected ? GSYColor.tabSelected : GSYColor.tabUnSelect;
  }

  @Builder
  buildAperture(): void {
    Stack() {
      Circle({ width: this.iconSize, height: this.iconSize })
        .stroke(this.resolveColor())
        .strokeWidth(1.6)
        .fillOpacity(0);
      Circle({ width: this.iconSize * 0.45, height: this.iconSize * 0.45 })
        .stroke(this.resolveColor())
        .strokeWidth(1.4)
        .fillOpacity(0);
      Line()
        .width(this.iconSize)
        .height(this.iconSize)
        .startPoint([this.iconSize * 0.5, this.iconSize * 0.05])
        .endPoint([this.iconSize * 0.5, this.iconSize * 0.27])
        .stroke(this.resolveColor())
        .strokeWidth(1.4);
      Line()
        .width(this.iconSize)
        .height(this.iconSize)
        .startPoint([this.iconSize * 0.83, this.iconSize * 0.66])
        .endPoint([this.iconSize * 0.95, this.iconSize * 0.5])
        .stroke(this.resolveColor())
        .strokeWidth(1.4);
      Line()
        .width(this.iconSize)
        .height(this.iconSize)
        .startPoint([this.iconSize * 0.17, this.iconSize * 0.66])
        .endPoint([this.iconSize * 0.05, this.iconSize * 0.5])
        .stroke(this.resolveColor())
        .strokeWidth(1.4);
    }
    .width(this.iconSize)
    .height(this.iconSize);
  }

  @Builder
  buildActivity(): void {
    Polyline()
      .width(this.iconSize)
      .height(this.iconSize)
      .points([
        [0, this.iconSize * 0.55],
        [this.iconSize * 0.25, this.iconSize * 0.55],
        [this.iconSize * 0.40, this.iconSize * 0.20],
        [this.iconSize * 0.60, this.iconSize * 0.85],
        [this.iconSize * 0.75, this.iconSize * 0.55],
        [this.iconSize, this.iconSize * 0.55],
      ])
      .stroke(this.resolveColor())
      .strokeWidth(1.8)
      .fillOpacity(0);
  }

  @Builder
  buildUser(): void {
    Stack() {
      Circle({ width: this.iconSize * 0.5, height: this.iconSize * 0.5 })
        .stroke(this.resolveColor())
        .strokeWidth(1.6)
        .fillOpacity(0)
        .position({ x: this.iconSize * 0.25, y: this.iconSize * 0.05 });
      Path()
        .width(this.iconSize)
        .height(this.iconSize)
        .commands('M ' + (this.iconSize * 0.15) + ' ' + (this.iconSize * 0.95)
          + ' Q ' + (this.iconSize * 0.5) + ' ' + (this.iconSize * 0.55)
          + ' ' + (this.iconSize * 0.85) + ' ' + (this.iconSize * 0.95))
        .stroke(this.resolveColor())
        .strokeWidth(1.6)
        .fillOpacity(0);
    }
    .width(this.iconSize)
    .height(this.iconSize);
  }

  build(): void {
    Column() {
      Stack() {
        if (this.iconKey === 'aperture') {
          this.buildAperture();
        } else if (this.iconKey === 'activity') {
          this.buildActivity();
        } else {
          this.buildUser();
        }
      }
      .width(this.iconSize)
      .height(this.iconSize);
      Text(this.title)
        .id('tab_icon_title_' + this.iconKey)
        .fontSize(GSYFontSize.small)
        .fontColor(this.resolveColor())
        .margin({ top: 3 })
        .maxLines(1);
    }
    .id('tab_icon_root_' + this.iconKey)
    .width('100%')
    .height('100%')
    .padding({ top: 4, bottom: 4 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}
