// RN 行号映射: [components/widget/UserItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserItem.js) L36-L72

import { GSYColor, GSYFontSize, GSYIconSize, GSYSpacing, GSYShadow } from '../style/Theme';
import { UserImage } from './UserImage';
import { IconFont, FA_CHEVRON_RIGHT } from '../common/IconFont';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';

export interface UserItemData {
  login: string;
  avatar_url: string;
  desc?: string;
  html_url?: string;
}

interface UserDetailRouteParam {
  login: string;
}

@Component
export struct UserItem {
  @Prop data: UserItemData = { login: '', avatar_url: '' };
  rowId: string = '';
  onPress?: () => void;

  private handleClick(): void {
    if (this.onPress) {
      this.onPress();
      return;
    }
    const param: UserDetailRouteParam = { login: this.data.login };
    NavigationService.push(RouteName.UserDetail, param);
  }

  build(): void {
    Row() {
      UserImage({
        uri: this.data.avatar_url,
        loginUser: this.data.login,
        imageSize: GSYIconSize.normal,
        imageId: this.rowId.length > 0 ? this.rowId + '_avatar' : 'user_item_avatar',
      })
        .margin({ right: GSYSpacing.normalEdge });

      Column() {
        Text(this.data.login && this.data.login.length > 0 ? this.data.login : '---')
          .id(this.rowId.length > 0 ? this.rowId + '_login' : 'user_item_login')
          .fontSize(GSYFontSize.small)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.mainText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        if (this.data.desc && this.data.desc.length > 0) {
          Text(this.data.desc)
            .id(this.rowId.length > 0 ? this.rowId + '_desc' : 'user_item_desc')
            .fontSize(GSYFontSize.min)
            .fontColor(GSYColor.subText)
            .margin({ top: GSYSpacing.halfEdge / 2 })
            .maxLines(GSYSpacing.normalNumberOfLine)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1);

      Stack() {
        IconFont({
          char: FA_CHEVRON_RIGHT,
          glyphSize: GSYFontSize.small,
          glyphColor: GSYColor.subLightText,
        });
      }
        .id(this.rowId.length > 0 ? this.rowId + '_chevron' : 'user_item_chevron')
        .margin({ left: GSYSpacing.halfEdge });
    }
    .id(this.rowId.length > 0 ? this.rowId : 'user_item_root')
    .width('auto')
    .alignItems(VerticalAlign.Center)
    .padding(16)
    .margin({
      left: 16,
      right: 16,
      top: 8,
      bottom: 8,
    })
    .borderRadius(8)
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
    .onClick((): void => {
      this.handleClick();
    });
  }
}
