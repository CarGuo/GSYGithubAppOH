// TagGroup —— 严格对齐 RN 端
// [components/widget/TagGroup.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/TagGroup.js)

import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';

@Component
export struct TagGroup {
  tagList: string[] = [];
  rowId: string = '';
  onPressTag: (tag: string) => void = (_tag: string): void => {};

  build(): void {
    if (!this.tagList || this.tagList.length === 0) {
      Row().width(0).height(0);
    } else {
      Flex({
        direction: FlexDirection.Row,
        wrap: FlexWrap.Wrap,
        justifyContent: FlexAlign.Start,
        alignItems: ItemAlign.Center,
      }) {
        ForEach(this.tagList, (data: string) => {
          Text(data)
            .id(this.rowId.length > 0 ? this.rowId + '_tag_' + data : 'tag_' + data)
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.mainText)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .height(24)
            .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge })
            .margin({
              top: GSYSpacing.halfEdge,
              bottom: GSYSpacing.halfEdge,
              right: GSYSpacing.normalEdge,
            })
            .borderRadius(4)
            .backgroundColor(GSYColor.white)
            .clip(true)
            .onClick((): void => {
              this.onPressTag(data);
            });
        }, (data: string) => '_' + data);
      }
      .width('100%');
    }
  }
}
