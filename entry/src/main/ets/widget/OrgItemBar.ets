/**
 * OrgItemBar —— 严格对齐 RN 端
 * [components/widget/OrgItemBar.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/OrgItemBar.js)
 *
 * 结构：
 *  Row（height=35, marginTop=halfEdge）
 *  ├─ 标题槽: I18n('userOrg')，仅当 dataList 非空才插入
 *  ├─ 头像列表: UserImage(size=smallIconSize=GSYIconSize.small=30, 圆)
 *  └─ 当 dataList.length > 5 时，截前 4 个并追加 "more" 圆按钮（ellipsis-h，颜色 primary）
 *
 * 颜色：标题 subLightText（miLightSmallText），more 图标 GSYColor.primary，背景透明。
 */

import { GSYColor, GSYFontSize, GSYIconSize, GSYSpacing } from '../style/Theme';
import { UserImage } from './UserImage';
import { IconFont, FA_ELLIPSIS_H } from '../common/IconFont';
import { I18n } from '../i18n/I18n';

const ITEM_SIZE: number = 35;

export interface OrgBarData {
  login: string;
  avatar_url: string;
}

@Component
export struct OrgItemBar {
  dataList: OrgBarData[] = [];
  ownerName: string = '';
  itemClick: (data: OrgBarData) => void = (): void => {};
  onMoreClick: (ownerName: string) => void = (): void => {};

  private buildVisible(): OrgBarData[] {
    if (this.dataList.length > 5) {
      return this.dataList.slice(0, 4);
    }
    return this.dataList;
  }

  build(): void {
    Row() {
      Row() {
        if (this.dataList.length > 0) {
          Column() {
            Text(I18n('userOrg'))
              .fontSize(GSYFontSize.min)
              .fontColor(GSYColor.subLightText);
          }
          .width(ITEM_SIZE)
          .height(ITEM_SIZE)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);
        }

        ForEach(this.buildVisible(), (data: OrgBarData): void => {
          Column() {
            UserImage({
              uri: data.avatar_url,
              loginUser: data.login,
              imageSize: GSYIconSize.small,
              imageId: 'org_bar_' + data.login,
            });
          }
          .width(ITEM_SIZE)
          .height(ITEM_SIZE)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick((): void => {
            this.itemClick(data);
          });
        }, (data: OrgBarData): string => data.login);

        if (this.dataList.length > 5) {
          Column() {
            IconFont({
              char: FA_ELLIPSIS_H,
              glyphSize: 16,
              glyphColor: GSYColor.primary,
            });
          }
          .width(GSYIconSize.small)
          .height(GSYIconSize.small)
          .margin(GSYSpacing.halfEdge)
          .padding(GSYSpacing.halfEdge)
          .borderRadius(GSYIconSize.small / 2)
          .backgroundColor(GSYColor.cardBackground)
          .shadow({
            radius: 4,
            color: GSYColor.subLightText,
            offsetX: 1,
            offsetY: 1,
          })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick((): void => {
            this.onMoreClick(this.ownerName);
          });
        }
      }
      .alignItems(VerticalAlign.Center);
    }
    .id('org_item_bar_root')
    .height(ITEM_SIZE)
    .width('100%')
    .margin({ top: GSYSpacing.halfEdge });
  }
}
