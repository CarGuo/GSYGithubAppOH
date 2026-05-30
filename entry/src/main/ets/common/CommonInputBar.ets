// RN 源对照: GSYGithubApp/app/components/common/CommonInputBar.js L1-L87
// 注意：RN 真实形态为水平滚动的 icon 快捷键栏 (dataList + ScrollView)，
// 不含 TextArea 与发送 Button；本文件按 HARD-LAW-1 严格对齐 RN 实际结构。
import { GSYColor, GSYFontSize, GSYIconSize, GSYSpacing } from '../style/Theme';

export interface CommonInputBarItem {
  icon?: ResourceStr;
  iconText?: string;
  iconColor?: ResourceColor;
  iconSize?: number;
  itemClick?: (data: CommonInputBarItem) => void;
}

@Component
export struct CommonInputBar {
  dataList: CommonInputBarItem[] = [];
  barHeight: number = GSYIconSize.normal;

  @Builder
  buildItem(data: CommonInputBarItem): void {
    Button() {
      if (data.icon) {
        Image(data.icon)
          .width(data.iconSize ?? GSYIconSize.tab)
          .height(data.iconSize ?? GSYIconSize.tab)
          .fillColor(data.iconColor ?? GSYColor.primary);
      } else if (data.iconText && data.iconText.length > 0) {
        Text(data.iconText)
          .fontSize(GSYFontSize.small)
          .fontColor(data.iconColor ?? GSYColor.primary);
      }
    }
    .type(ButtonType.Normal)
    .backgroundColor(GSYColor.transparent)
    .width(GSYIconSize.normal)
    .height(GSYIconSize.normal)
    .onClick((): void => {
      if (data.itemClick) {
        data.itemClick(data);
      }
    });
  }

  build(): void {
    Row() {
      Scroll() {
        Row() {
          ForEach(this.dataList, (data: CommonInputBarItem, idx: number): void => {
            this.buildItem(data);
          }, (data: CommonInputBarItem, idx: number): string => 'cib_' + idx.toString());
        }
        .alignItems(VerticalAlign.Center);
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(this.barHeight);
    }
    .width('100%')
    .height(this.barHeight)
    .padding({ left: GSYSpacing.halfEdge, right: GSYSpacing.halfEdge })
    .backgroundColor(GSYColor.cardBackground);
  }
}
