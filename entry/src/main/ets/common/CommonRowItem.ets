// 对照 RN: app/components/common/CommonRowItem.js#L26-L72

import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';
import { IconFont, FA_CHEVRON_RIGHT } from './IconFont';

@Component
export struct CommonRowItem {
  @Prop itemText: string = '';
  @Prop nameText: string = '';
  @Prop itemIcon: string = '';
  @Prop iconSize: number = 13;
  @Prop showIconNext: boolean = true;
  @Prop topLine: boolean = true;
  @Prop bottomLine: boolean = true;
  onClickFun: () => void = (): void => {};

  build(): void {
    Column() {
      Row() {
        if (this.itemIcon.length > 0) {
          IconFont({
            char: this.itemIcon,
            glyphSize: this.iconSize,
            glyphColor: GSYColor.primary,
          })
            .margin({ right: GSYSpacing.halfEdge });
        }
        if (this.nameText.length > 0) {
          Text(this.nameText)
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.mainText);
        }
        Text(this.itemText)
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.mainText)
          .layoutWeight(1);
        if (this.showIconNext) {
          IconFont({
            char: FA_CHEVRON_RIGHT,
            glyphSize: GSYFontSize.small,
            glyphColor: GSYColor.primary,
          });
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .border({
        width: {
          top: this.topLine ? 0.5 : 0,
          bottom: this.bottomLine ? 0.5 : 0,
        },
        color: GSYColor.line,
      })
      .constraintSize({ minHeight: 50 });
    }
    .margin({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.halfEdge,
      bottom: GSYSpacing.halfEdge,
    })
    .onClick((): void => {
      if (this.onClickFun) {
        this.onClickFun();
      }
    });
  }
}
