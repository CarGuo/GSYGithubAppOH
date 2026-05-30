// CodeFileItem —— 严格对齐 RN 端
// [components/widget/CodeFileItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/CodeFileItem.js)

import { GSYColor, GSYFontSize, GSYSpacing, GSYShadow } from '../style/Theme';

@Component
export struct CodeFileItem {
  itemText: string = '';
  itemTextTitle: string = '';
  needTitle: boolean = true;
  itemIcon: Resource | null = null;
  rowId: string = '';
  onClickFun: () => void = (): void => {};

  build(): void {
    Column() {
      if (this.needTitle && this.itemTextTitle.length > 0) {
        Row() {
          Text(this.itemTextTitle)
            .id(this.rowId.length > 0 ? this.rowId + '_title' : 'code_file_item_title')
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.mainText)
            .layoutWeight(1);
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({
          top: GSYSpacing.normalEdge,
          left: GSYSpacing.normalEdge,
          right: GSYSpacing.normalEdge,
        });
      }

      Row() {
        if (this.itemIcon !== null) {
          Image(this.itemIcon)
            .width(GSYFontSize.small)
            .height(GSYFontSize.small)
            .fillColor(GSYColor.subText)
            .objectFit(ImageFit.Contain);
        }

        Text(this.itemText)
          .id(this.rowId.length > 0 ? this.rowId + '_text' : 'code_file_item_text')
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.mainText)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: GSYSpacing.normalEdge });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding(GSYSpacing.normalEdge)
      .margin({
        left: GSYSpacing.normalEdge,
        right: GSYSpacing.normalEdge,
        top: GSYSpacing.halfEdge,
        bottom: GSYSpacing.halfEdge,
      })
      .borderRadius(3)
      .backgroundColor(GSYColor.cardBackground)
      .shadow({
        radius: GSYShadow.radius,
        color: GSYShadow.cardShadowAlpha,
        offsetX: 1,
        offsetY: 1,
      });
    }
    .id(this.rowId.length > 0 ? this.rowId : 'code_file_item_root')
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .onClick((): void => {
      this.onClickFun();
    });
  }
}
