// 对照 RN: app/components/common/CommonNameValueItem.js#L12-L33

import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';

@Component
export struct CommonNameValueItem {
  @Prop itemName: string = '';
  @Prop itemValue: string = '';
  onItemPress: () => void = (): void => {};

  build(): void {
    Column() {
      Text(this.itemName)
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.subText)
        .margin({ top: GSYSpacing.halfEdge });
      Text(this.itemValue)
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.subLightText)
        .margin({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge });
    }
    .alignItems(HorizontalAlign.Start)
    .onClick((): void => {
      if (this.onItemPress) {
        this.onItemPress();
      }
    });
  }
}
