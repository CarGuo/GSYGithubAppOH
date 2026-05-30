/**
 * RepositoryItem —— 对齐 Android Compose shared `RepositoryItem` / `GSYCardItem`.
 */

import { GSYColor, GSYFontSize, GSYIconSize, GSYShadow, GSYSpacing } from '../style/Theme';
import { UserImage } from './UserImage';
import { IconTextItem } from './IconTextItem';
import { HTMLView } from '../common/HTMLView';
import { CommonIconButton } from '../common/CommonIconButton';
import { FA_STAR_O, FA_CODE_FORK, FA_USER } from '../common/IconFont';

@Component
export struct RepositoryItem {
  ownerName: string = '';
  ownerPic: string = '';
  repositoryName: string = '';
  repositoryStar: string = '---';
  repositoryFork: string = '---';
  repositoryWatch: string = '---';
  repositoryType: string = '---';
  repositoryDes: string = '---';
  hideWatchIcon: boolean = false;
  rowId: string = '';
  onPressItem: () => void = (): void => {};

  build(): void {
    Column() {
      Row() {
        UserImage({
          uri: this.ownerPic,
          loginUser: this.ownerName,
          imageSize: GSYIconSize.normal,
          imageId: this.rowId.length > 0 ? this.rowId + '_avatar' : 'repo_item_avatar',
        })
          .margin({ right: GSYSpacing.normalEdge, top: 2 });

        Column() {
          Text(this.repositoryName)
            .id(this.rowId.length > 0 ? this.rowId + '_name' : 'repo_item_name')
            .width('100%')
            .fontSize(GSYFontSize.normal)
            .fontWeight(FontWeight.Bold)
            .fontColor(GSYColor.mainText)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          if (this.repositoryType.length > 0 && this.repositoryType !== '---') {
            Text(this.repositoryType)
              .id(this.rowId.length > 0 ? this.rowId + '_type' : 'repo_item_type')
              .fontSize(GSYFontSize.min)
              .fontColor(GSYColor.subText)
              .maxLines(1)
              .margin({ top: 2 });
          }

          IconTextItem({
            text: this.ownerName,
            iconChar: FA_USER,
            iconColor: GSYColor.subLightText,
            iconSize: GSYFontSize.small,
            textColor: GSYColor.subLightText,
            textFontSize: GSYFontSize.small,
            rowId: this.rowId.length > 0 ? this.rowId + '_owner' : 'repo_item_owner',
          });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);

      HTMLView({
        value: this.repositoryDes && this.repositoryDes.length > 0 ? this.repositoryDes : '---',
        fontSize: GSYFontSize.small,
        fontColor: GSYColor.subText,
        maxLines: GSYSpacing.normalNumberOfLine,
        viewId: this.rowId.length > 0 ? this.rowId + '_des' : 'repo_item_des',
      })
        .width('100%')
        .margin({ top: GSYSpacing.halfEdge });

      Row() {
        Column() {
          CommonIconButton({
            icon: FA_STAR_O,
            iconColor: GSYColor.subText,
            iconSize: GSYIconSize.minIcon,
            text: this.repositoryStar,
            textColor: GSYColor.subText,
            textFontSize: GSYFontSize.small,
            textId: this.rowId.length > 0 ? this.rowId + '_star_text' : '',
          });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center);

        Column() {
          CommonIconButton({
            icon: FA_CODE_FORK,
            iconColor: GSYColor.subText,
            iconSize: GSYIconSize.minIcon,
            text: this.repositoryFork,
            textColor: GSYColor.subText,
            textFontSize: GSYFontSize.small,
            textId: this.rowId.length > 0 ? this.rowId + '_fork_text' : '',
          });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center);

        Column() {
          CommonIconButton({
            icon: FA_USER,
            iconColor: GSYColor.subText,
            iconSize: this.hideWatchIcon ? 1 : GSYIconSize.minIcon,
            text: this.repositoryWatch,
            textColor: GSYColor.subText,
            textFontSize: GSYFontSize.small,
            textId: this.rowId.length > 0 ? this.rowId + '_watch_text' : '',
          });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center);
      }
      .width('100%')
      .margin({ top: GSYSpacing.halfEdge });
    }
    .id(this.rowId.length > 0 ? this.rowId : 'repo_item_root')
    .width('auto')
    .padding({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.normalEdge,
      bottom: 0,
    })
    .margin({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.halfEdge,
      bottom: GSYSpacing.halfEdge,
    })
    .borderRadius(4)
    .border({
      width: 1,
      color: GSYColor.borderSubtle,
    })
    .backgroundColor(GSYColor.cardBackground)
    .shadow({
      radius: GSYShadow.radius,
      color: GSYShadow.cardShadowAlpha,
      offsetX: 1,
      offsetY: 1,
    })
    .alignItems(HorizontalAlign.Start)
    .onClick((): void => {
      this.onPressItem();
    });
  }
}
