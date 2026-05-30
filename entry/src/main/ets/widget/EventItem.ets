/**
 * EventItem —— 对齐 Android Compose core/ui/components/EventItem.kt。
 *
 * 结构：卡片内横排头像和内容列；内容列依次是用户名、动作描述、相对时间。
 * Issue/Push 的详情文本不在列表卡片中展开，点击仍由 EventActionDispatcher 处理。
 */

import { GSYColor, GSYFontSize, GSYSpacing, GSYShadow } from '../style/Theme';
import { TimeUtil } from '../utils/TimeUtil';
import { UserImage } from './UserImage';

@Component
export struct EventItem {
  actionTime: string = '';
  actionUser: string = '';
  actionUserPic: string = '';
  actionTarget: string = '';
  des: string = '';
  rowId: string = '';
  onPressItem: () => void = (): void => {};
  onPressUser: () => void = (): void => {};

  build(): void {
    Column() {
      Row() {
        UserImage({
          uri: this.actionUserPic,
          loginUser: this.actionUser,
          imageSize: 40,
          imageId: this.rowId.length > 0 ? this.rowId + '_avatar' : 'event_item_avatar',
          onAvatarTap: (): void => {
            this.onPressUser();
          },
        })
          .margin({ right: GSYSpacing.normalEdge });

        Column() {
          Text(this.actionUser)
            .id(this.rowId.length > 0 ? this.rowId + '_user' : 'event_item_user')
            .fontSize(GSYFontSize.small)
            .fontWeight(FontWeight.Medium)
            .fontColor(GSYColor.mainText)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Text(this.actionTarget)
            .id(this.rowId.length > 0 ? this.rowId + '_target' : 'event_item_target')
            .fontSize(GSYFontSize.middleWhite)
            .fontColor(GSYColor.subText)
            .margin({ top: 4 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Text(TimeUtil.resolveTime(this.actionTime))
            .id(this.rowId.length > 0 ? this.rowId + '_time' : 'event_item_time')
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.subText)
            .margin({ top: 4 });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);
    }
    .id(this.rowId.length > 0 ? this.rowId : 'event_item_root')
    .width('auto')
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12,
    })
    .borderRadius(8)
    .backgroundColor(GSYColor.cardBackground)
    .border({
      width: 1,
      color: GSYColor.borderSubtle,
    })
    .shadow({
      radius: 6,
      color: GSYShadow.cardShadowAlpha,
      offsetX: 0,
      offsetY: 2,
    })
    .alignItems(HorizontalAlign.Start)
    .onClick((): void => {
      this.onPressItem();
    })
    .margin({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.halfEdge,
      bottom: GSYSpacing.halfEdge,
    });
  }
}
