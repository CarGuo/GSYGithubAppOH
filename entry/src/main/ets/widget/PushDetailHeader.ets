/**
 * PushDetailHeader —— 严格对齐 RN 端
 * [components/widget/PushDetailHeader.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/PushDetailHeader.js)
 *
 * 结构：
 *  shadowCard（marginTop/Left/Right=normalEdge, paddingH=normalEdge, paddingTop=normalEdge,
 *             radius=4, backgroundColor=primary）
 *  └─ Row
 *     ├─ UserImage(bigIconSize=GSYIconSize.big=50, 圆, marginTop=5)
 *     └─ Column(layoutWeight=1, marginLeft=normalEdge)
 *        ├─ Row(centerH, marginVertical=halfEdge): edit + addCount  diff-added + addCount(注：RN原文 add)
 *        │                                          minus-square-o + deleteCount   icons size=13 miWhite
 *        ├─ Row(marginBottom=normalEdge, marginTop=halfEdge): TimeText(pushTime, miLightSmallText)
 *        └─ Row(marginBottom=normalEdge): pushDes(miLightSmallText)
 *
 * 颜色：背景 GSYColor.primary，全文字 GSYColor.subLightText（miLightSmallText 等价）。
 */

import { GSYColor, GSYFontSize, GSYIconSize, GSYSpacing } from '../style/Theme';
import { UserImage } from './UserImage';
import { TimeText } from './TimeText';
import { IconFont } from '../common/IconFont';

const FA_EDIT: string = '\uf044';
const OCT_DIFF_ADDED: string = '\uf06b';
const FA_MINUS_SQUARE_O: string = '\uf147';

@Component
export struct PushDetailHeader {
  actionUser: string = '';
  actionUserPic: string = '';
  pushTime: string = '';
  pushDes: string = '';
  editCount: string = '';
  addCount: string = '';
  deleteCount: string = '';
  rowId: string = '';
  onPressItem: () => void = (): void => {};

  build(): void {
    Column() {
      Row() {
        UserImage({
          uri: this.actionUserPic,
          loginUser: this.actionUser,
          imageSize: GSYIconSize.big,
          imageId: this.rowId.length > 0 ? this.rowId + '_avatar' : 'push_header_avatar',
        })
          .margin({ top: 5 });

        Column() {
          Row() {
            IconFont({
              char: FA_EDIT,
              glyphSize: 13,
              glyphColor: GSYColor.miWhite,
            });
            Text('  ' + this.editCount + '  ')
              .fontSize(GSYFontSize.small)
              .fontColor(GSYColor.subLightText);

            IconFont({
              char: OCT_DIFF_ADDED,
              glyphSize: 13,
              glyphColor: GSYColor.miWhite,
            });
            Text(' ' + this.addCount + '  ')
              .fontSize(GSYFontSize.small)
              .fontColor(GSYColor.subLightText);

            IconFont({
              char: FA_MINUS_SQUARE_O,
              glyphSize: 13,
              glyphColor: GSYColor.miWhite,
            });
            Text('   ' + this.deleteCount)
              .fontSize(GSYFontSize.small)
              .fontColor(GSYColor.subLightText);
          }
          .alignItems(VerticalAlign.Center)
          .margin({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge });

          Row() {
            TimeText({
              time: this.pushTime,
              textId: this.rowId.length > 0 ? this.rowId + '_time' : 'push_header_time',
            });
          }
          .margin({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.normalEdge });

          Row() {
            Text(this.pushDes)
              .id(this.rowId.length > 0 ? this.rowId + '_des' : 'push_header_des')
              .fontSize(GSYFontSize.small)
              .fontColor(GSYColor.subLightText)
              .layoutWeight(1)
              .copyOption(CopyOptions.LocalDevice);
          }
          .margin({ bottom: GSYSpacing.normalEdge });
        }
        .layoutWeight(1)
        .margin({ left: GSYSpacing.normalEdge })
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);
    }
    .id(this.rowId.length > 0 ? this.rowId : 'push_header_root')
    .width('auto')
    .margin({
      top: GSYSpacing.normalEdge,
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
    })
    .padding({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.normalEdge,
    })
    .borderRadius(4)
    .backgroundColor(GSYColor.primary)
    .shadow({
      radius: 4,
      color: GSYColor.cardShadow,
      offsetX: 1,
      offsetY: 1,
    })
    .onClick((): void => {
      this.onPressItem();
    });
  }
}
