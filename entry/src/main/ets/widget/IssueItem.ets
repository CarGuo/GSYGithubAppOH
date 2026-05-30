/**
 * IssueItem —— 严格对齐 RN 端
 * [components/widget/IssueItem.js#L22-L127](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/IssueItem.js#L22-L127)
 *
 * 视觉结构（自上而下，shadowCard 白底卡）：
 *   Row(top, alignItems=Top)
 *     ├─ UserImage(normalIconSize=40, 圆)
 *     └─ Column(layoutWeight=1, marginLeft=normalEdge)
 *          ├─ Row 顶行：actionUser(bold, normal) + TimeText(subSmall, 右)
 *          ├─ Row body：HTMLView(issueCommentHtml) 或 Text(issueComment, subSmall)
 *          └─ Row 底行（issueTag 存在时）：
 *                IconC(state) + Text(state, 绿/红) + Text(issueTag, layoutWeight=1, maxLines=4)
 *                + Icon(comment) + Text(commentCount, min)
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
export struct IssueItem {
  @Prop actionTime: string = '';
  @Prop actionUser: string = '';
  @Prop actionUserPic: string = '';
  @Prop issueComment: string = '';
  @Prop issueCommentHtml: string = '';
  @Prop issueTag: string = '';
  @Prop state: string = '';
  @Prop commentCount: string = '';
  @Prop markdownBody: boolean = false;
  @Prop rowId: string = '';

  onPressItem: () => void = (): void => {};
  onLongPressItem: () => void = (): void => {};

  private resolveStateColor(): string {
    return this.state === STATE_OPEN ? GSYColor.issueOpenGreen : GSYColor.issueClosedRed;
  }

  private id(suffix: string): string {
    return this.rowId.length > 0 ? this.rowId + '_' + suffix : 'issue_item_' + suffix;
  }

  @Builder
  buildBody(): void {
    if (this.markdownBody) {
      HTMLView({
        html: this.issueCommentHtml,
        textColor: GSYColor.subText,
        textFontSize: GSYFontSize.small,
      });
    } else {
      Text(this.issueComment)
        .id(this.id('body_text'))
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.subText);
    }
  }

  @Builder
  buildBottom(): void {
    if (this.issueTag && this.issueTag.length > 0) {
      Row() {
        IconFont({
          char: this.state === STATE_OPEN ? FA_EXCLAMATION_CIRCLE : FA_TIMES,
          glyphSize: ISSUE_STATE_ICON_SIZE,
          glyphColor: this.resolveStateColor(),
        });
        Text(this.state + ' ')
          .id(this.id('state_text'))
          .fontSize(GSYFontSize.small)
          .fontColor(this.resolveStateColor());
        Text(this.issueTag)
          .id(this.id('tag'))
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.subLightText)
          .layoutWeight(1)
          .maxLines(GSYSpacing.normalNumberOfLine)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        IconFont({
          char: FA_COMMENT,
          glyphSize: COMMENT_ICON_SIZE,
          glyphColor: GSYColor.subLightText,
        })
          .margin({ right: 3 });
        Text(this.commentCount)
          .id(this.id('comment_count'))
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.subLightText);
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);
    }
  }

  build(): void {
    Row() {
      UserImage({
        uri: this.actionUserPic,
        loginUser: this.actionUser,
        imageSize: GSYIconSize.normal,
        imageId: this.id('avatar'),
      })
        .margin({ top: 5 });

      Column() {
        Row() {
          Text(this.actionUser)
            .id(this.id('user'))
            .fontSize(GSYFontSize.normal)
            .fontWeight(FontWeight.Bold)
            .fontColor(GSYColor.mainText)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
          Text(TimeUtil.resolveTime(this.actionTime))
            .id(this.id('time'))
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.subText);
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);

        Row() {
          this.buildBody();
        }
        .width('100%')
        .margin({ top: GSYSpacing.halfEdge });

        this.buildBottom();
      }
      .layoutWeight(1)
      .margin({
        left: GSYSpacing.normalEdge,
        bottom: this.issueTag && this.issueTag.length > 0 ? 0 : GSYSpacing.normalEdge,
      })
      .alignItems(HorizontalAlign.Start);
    }
    .id(this.rowId.length > 0 ? this.rowId : 'issue_item_root')
    .width('auto')
    .padding({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.normalEdge,
    })
    .margin({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.halfEdge,
      bottom: GSYSpacing.halfEdge,
    })
    .borderRadius(CARD_RADIUS)
    .backgroundColor(GSYColor.cardBackground)
    .shadow({
      radius: 4,
      color: GSYShadow.cardShadowAlpha,
      offsetX: 1,
      offsetY: 1,
    })
    .alignItems(VerticalAlign.Top)
    .onClick((): void => {
      this.onPressItem();
    });
  }
}
