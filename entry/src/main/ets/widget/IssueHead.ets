/**
 * IssueHead —— 严格对齐 RN 端
 * [components/widget/IssueHead.js#L23-L136](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/IssueHead.js#L23-L136)
 *
 * 视觉结构（IssueDetailPage 头部，主色 primary 卡片）：
 *   Row(top, alignItems=Top)
 *     ├─ UserImage(bigIconSize=50, 圆)
 *     └─ Column(layoutWeight=1, marginLeft=normalEdge)
 *          ├─ Row 顶行：actionUser(bold, normalTextWhite) + TimeText(miLightSmall, 右)
 *          ├─ Row 中行：issueTag(maxLines=4) + state badge(open=绿/closed=红)
 *          │            + comment icon + commentCount
 *          └─ Text issueComment(miLightSmall)
 *   HTMLView(issueDesHtml)（<br> 替换为 \n）
 *   stateText: closed_by 存在时显示 "Closed by xxx"
 *
 * Token：颜色/字号/间距走 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets)。
 */

import { GSYColor, GSYFontSize, GSYIconSize, GSYShadow, GSYSpacing } from '../style/Theme';
import { TimeUtil } from '../utils/TimeUtil';
import { UserImage } from './UserImage';
import { HTMLView } from '../common/HTMLView';
import {
  IconFont,
  FA_EXCLAMATION_CIRCLE,
  FA_TIMES,
  FA_COMMENT,
} from '../common/IconFont';

const STATE_OPEN: string = 'open';
const ISSUE_STATE_ICON_SIZE: number = 13;
const COMMENT_ICON_SIZE: number = 11;
const CARD_RADIUS: number = 3;

@Component
export struct IssueHead {
  @Prop actionTime: string = '';
  @Prop actionUser: string = '';
  @Prop actionUserPic: string = '';
  @Prop issueComment: string = '';
  @Prop issueTag: string = '';
  @Prop issueDes: string = '';
  @Prop issueDesHtml: string = '';
  @Prop state: string = '';
  @Prop commentCount: string = '';
  @Prop closedByLogin: string = '';
  @Prop rowId: string = '';

  onPressItem: () => void = (): void => {};

  private resolveStateColor(): string {
    return this.state === STATE_OPEN ? GSYColor.issueOpenGreen : GSYColor.issueClosedRed;
  }

  private id(suffix: string): string {
    return this.rowId.length > 0 ? this.rowId + '_' + suffix : 'issue_head_' + suffix;
  }

  private normalizeHtml(): string {
    if (!this.issueDesHtml || this.issueDesHtml.length === 0) {
      return '';
    }
    return this.issueDesHtml.replace(/<br>/g, '\n');
  }

  build(): void {
    Column() {
      Row() {
        UserImage({
          uri: this.actionUserPic,
          loginUser: this.actionUser,
          imageSize: GSYIconSize.big,
          imageId: this.id('avatar'),
        })
          .margin({ top: 5 });

        Column() {
          Row() {
            Text(this.actionUser)
              .id(this.id('user'))
              .fontSize(GSYFontSize.normal)
              .fontWeight(FontWeight.Bold)
              .fontColor(GSYColor.textWhite)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            Text(TimeUtil.resolveTime(this.actionTime))
              .id(this.id('time'))
              .fontSize(GSYFontSize.small)
              .fontColor(GSYColor.miWhite);
          }
          .width('100%')
          .alignItems(VerticalAlign.Center);

          Row() {
            Text(this.issueTag)
              .id(this.id('tag'))
              .fontSize(GSYFontSize.small)
              .fontColor(GSYColor.miWhite)
              .layoutWeight(1)
              .maxLines(GSYSpacing.normalNumberOfLine)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ right: GSYSpacing.halfEdge });

            IconFont({
              char: this.state === STATE_OPEN ? FA_EXCLAMATION_CIRCLE : FA_TIMES,
              glyphSize: ISSUE_STATE_ICON_SIZE,
              glyphColor: this.resolveStateColor(),
            });
            Text(' ' + this.state + '  ')
              .id(this.id('state_text'))
              .fontSize(GSYFontSize.small)
              .fontColor(this.resolveStateColor());

            IconFont({
              char: FA_COMMENT,
              glyphSize: COMMENT_ICON_SIZE,
              glyphColor: GSYColor.miWhite,
            })
              .margin({ right: 3 });
            Text(this.commentCount)
              .id(this.id('comment_count'))
              .fontSize(GSYFontSize.min)
              .fontColor(GSYColor.miWhite);
          }
          .width('100%')
          .margin({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge })
          .alignItems(VerticalAlign.Center);

          Text(this.issueComment)
            .id(this.id('comment'))
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.miWhite)
            .width('100%')
            .margin({ bottom: GSYSpacing.normalEdge });
        }
        .layoutWeight(1)
        .margin({ left: GSYSpacing.normalEdge })
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);

      Column() {
        HTMLView({
          html: this.normalizeHtml(),
          textColor: GSYColor.miWhite,
          textFontSize: GSYFontSize.small,
        });
        if (this.closedByLogin && this.closedByLogin.length > 0) {
          Text('Closed by ' + this.closedByLogin)
            .id(this.id('closed_by'))
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.miWhite)
            .margin({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge });
        }
      }
      .width('100%')
      .margin({
        bottom: this.issueDes && this.issueDes.length > 0 ? GSYSpacing.normalEdge : 0,
      })
      .alignItems(HorizontalAlign.Start);
    }
    .id(this.rowId.length > 0 ? this.rowId : 'issue_head_root')
    .width('100%')
    .padding({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.normalEdge,
    })
    .margin({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.normalEdge,
    })
    .borderRadius(CARD_RADIUS)
    .backgroundColor(GSYColor.primary)
    .shadow({
      radius: 4,
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
