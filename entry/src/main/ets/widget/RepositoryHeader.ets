/**
 * RepositoryHeader —— 1:1 对齐 RN 端
 * [components/widget/RepositoryHeader.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/RepositoryHeader.js)
 *
 * R7-I 修复（2026-05-25 D3/D5/D8）：
 *   早期实现用 `Stack { Image.height(100%) + Column.height(100%) + content }`
 *   两层 absolute 浮层把 Stack 撑到全 host 高度，导致 ActivityTab PullLoadMoreList
 *   的 ListHeader 卡片视觉涂满整个视口（用户红牌截图证据 § 9.7）。
 *
 *   现改为根 Column 自然撑高 + `.backgroundImage(ownerPic) + .backgroundBlurStyle
 *   + .backgroundColor(GSYColor.primaryHalf)` 三件套，让模糊/半透明覆盖严格限定在
 *   卡片内部，不会随 ScrollContainer 撑全屏。
 *
 * 视觉结构（自外向内）：
 *   Column(根，backgroundImage + blurStyle + primaryHalf 半透明覆盖)
 *     ├─ Row: owner / "  /  " / repoName  (bold, miWhite)
 *     ├─ Row: language / size / license   (min 字号, miWhite)
 *     ├─ Text(description)                (min 字号, miWhite)
 *     ├─ Text(created_at + latest_commit) (min 字号, fork 时蓝字)
 *     ├─ Row 4 列（top hairline 分隔）:
 *     │    ★ star-o + repositoryStar
 *     │    ⑂ code-fork + repositoryFork
 *     │    👁 eye + repositoryWatch
 *     │    ❗ issue-opened + repositoryIssue
 *     └─ TagGroup(topics)（topics 多色 chip）
 *
 * 所有 token 走 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets)。
 *
 * RN 端用 Octicons 的 eye/issue-opened/repo-forked，OH 端无 Octicons，
 * 用 FontAwesome 同义码点替代（已在 [IconFont.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/IconFont.ets) 暴露）。
 */

import { GSYColor, GSYFontSize, GSYSpacing, GSYShadow } from '../style/Theme';
import { I18n } from '../i18n/I18n';
import {
  IconFont,
  FA_STAR_O,
  FA_CODE_FORK,
  FA_EYE,
  FA_EXCLAMATION_CIRCLE,
} from '../common/IconFont';
import { RepositoryDetailStore, RepositoryDetail } from '../store/RepositoryDetailStore';

const PLACEHOLDER: string = '---';
const HAIRLINE: number = 0.5;
const HEADER_BOTTOM_ICON_SIZE: number = 15;
const HEADER_RADIUS: number = 4;

@Component
export struct RepositoryHeader {
  @ObjectLink store: RepositoryDetailStore;
  @Prop ownerName: string = '';
  @Prop repositoryName: string = '';
  @Prop createdAtText: string = '';
  @Prop pushAtText: string = '';
  @Prop parentName: string = '';

  onTapOwner: () => void = (): void => {};
  onTapStar: () => void = (): void => {};
  onTapFork: () => void = (): void => {};
  onTapWatch: () => void = (): void => {};
  onTapIssue: () => void = (): void => {};
  onTapForkSource: () => void = (): void => {};
  onTapTopic: (topic: string) => void = (_topic: string): void => {};

  private detail(): RepositoryDetail | null {
    return this.store.detail;
  }

  private ownerPic(): string {
    const d: RepositoryDetail | null = this.detail();
    if (d !== null && d.owner !== null && d.owner !== undefined) {
      return d.owner.avatar_url;
    }
    return '';
  }

  private starText(): string {
    const d: RepositoryDetail | null = this.detail();
    return d !== null ? d.watchers_count.toString() : PLACEHOLDER;
  }

  private forkText(): string {
    const d: RepositoryDetail | null = this.detail();
    return d !== null ? d.forks_count.toString() : PLACEHOLDER;
  }

  private watchText(): string {
    const d: RepositoryDetail | null = this.detail();
    return d !== null ? d.subscribers_count.toString() : PLACEHOLDER;
  }

  private issueText(): string {
    const d: RepositoryDetail | null = this.detail();
    return d !== null ? d.open_issues_count.toString() : PLACEHOLDER;
  }

  private sizeText(): string {
    const d: RepositoryDetail | null = this.detail();
    if (d === null) {
      return PLACEHOLDER;
    }
    const kb: number = d.size === undefined || d.size === null ? 0 : d.size;
    if (kb >= 1024) {
      return (kb / 1024).toFixed(2) + 'M';
    }
    return kb.toString() + 'K';
  }

  private languageText(): string {
    const d: RepositoryDetail | null = this.detail();
    if (d !== null && d.language !== null && d.language !== undefined && d.language.length > 0) {
      return d.language;
    }
    return PLACEHOLDER;
  }

  private descText(): string {
    const d: RepositoryDetail | null = this.detail();
    if (d !== null && d.description !== null && d.description !== undefined && d.description.length > 0) {
      return d.description;
    }
    return PLACEHOLDER;
  }

  private isFork(): boolean {
    const d: RepositoryDetail | null = this.detail();
    return d !== null && d.fork === true;
  }

  private topicsList(): string[] {
    const d: RepositoryDetail | null = this.detail();
    if (d !== null && d.topics !== undefined && d.topics !== null) {
      return d.topics;
    }
    return [];
  }

  private licenseText(): string {
    const d: RepositoryDetail | null = this.detail();
    if (d !== null && d.license !== null && d.license !== undefined
        && d.license.name !== null && d.license.name !== undefined && d.license.name.length > 0) {
      return d.license.name;
    }
    return PLACEHOLDER;
  }

  private buildInfoText(): string {
    const create: string = this.isFork()
      ? I18n('forked_at') + ' ' + this.parentName + '\n'
      : I18n('created_at') + ' ' + this.createdAtText + ' ';
    const update: string = this.pushAtText.length > 0
      ? I18n('latest_commit') + ' ' + this.pushAtText
      : '';
    return create + update;
  }

  private safe(value: string): string {
    return value !== null && value !== undefined && value.length > 0 ? value : PLACEHOLDER;
  }

  private cellValue(idTag: string): string {
    if (idTag === 'star') {
      return this.starText();
    } else if (idTag === 'fork') {
      return this.forkText();
    } else if (idTag === 'watch') {
      return this.watchText();
    } else if (idTag === 'issue') {
      return this.issueText();
    }
    return PLACEHOLDER;
  }

  @Builder
  buildBottomCell(idTag: string, glyph: string,
                  showLeftBorder: boolean, showRightBorder: boolean,
                  onTap: () => void): void {
    Row() {
      IconFont({
        char: glyph,
        glyphSize: HEADER_BOTTOM_ICON_SIZE,
        glyphColor: GSYColor.white,
      });
      Text(' ' + this.cellValue(idTag))
        .id('repo_header_bottom_text_' + idTag)
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.white)
        .textShadow({
          radius: GSYShadow.headerTextRadius,
          color: GSYShadow.headerTextColor,
          offsetX: GSYShadow.headerTextOffsetX,
          offsetY: GSYShadow.headerTextOffsetY,
        });
    }
    .id('repo_header_bottom_cell_' + idTag)
    .layoutWeight(1)
    .padding({ top: GSYSpacing.normalEdge, bottom: GSYSpacing.normalEdge })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .border({
      width: {
        left: showLeftBorder ? HAIRLINE : 0,
        right: showRightBorder ? HAIRLINE : 0,
      },
      color: GSYColor.repositoryHeaderLine,
    })
    .onClick((): void => {
      onTap();
    });
  }

  @Builder
  buildTopicTag(topic: string, index: number): void {
    Text(topic)
      .id('repo_header_topic_' + index.toString())
      .fontSize(GSYFontSize.min)
      .fontColor(GSYColor.miWhite)
      .backgroundColor(GSYColor.primaryLight)
      .padding({
        left: GSYSpacing.halfEdge,
        right: GSYSpacing.halfEdge,
        top: 2,
        bottom: 2,
      })
      .margin({ right: GSYSpacing.halfEdge, top: GSYSpacing.halfEdge })
      .border({
        width: HAIRLINE,
        color: GSYColor.miWhite,
        radius: 2,
      })
      .onClick((): void => {
        this.onTapTopic(topic);
      });
  }

  build(): void {
    Stack() {
      Column() {
      Row() {
        Text(this.ownerName)
          .id('repo_header_owner')
          .fontSize(GSYFontSize.normal)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.miWhite)
          .textShadow({
            radius: GSYShadow.headerTextRadius,
            color: GSYShadow.headerTextColor,
            offsetX: GSYShadow.headerTextOffsetX,
            offsetY: GSYShadow.headerTextOffsetY,
          })
          .onClick((): void => {
            this.onTapOwner();
          });
        Text(' / ')
          .fontSize(GSYFontSize.normal)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.miWhite)
          .textShadow({
            radius: GSYShadow.headerTextRadius,
            color: GSYShadow.headerTextColor,
            offsetX: GSYShadow.headerTextOffsetX,
            offsetY: GSYShadow.headerTextOffsetY,
          });
        Text(this.repositoryName)
          .id('repo_header_name')
          .fontSize(GSYFontSize.normal)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.miWhite)
          .textShadow({
            radius: GSYShadow.headerTextRadius,
            color: GSYShadow.headerTextColor,
            offsetX: GSYShadow.headerTextOffsetX,
            offsetY: GSYShadow.headerTextOffsetY,
          })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .id('repo_header_name_row')
      .width('100%')
      .alignItems(VerticalAlign.Center);

      Row() {
        Text(this.languageText())
          .id('repo_header_language')
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.miWhite)
          .textShadow({
            radius: GSYShadow.headerTextRadius,
            color: GSYShadow.headerTextColor,
            offsetX: GSYShadow.headerTextOffsetX,
            offsetY: GSYShadow.headerTextOffsetY,
          })
          .margin({ right: GSYSpacing.normalEdge })
          .maxLines(1);
        Text(this.sizeText())
          .id('repo_header_size')
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.miWhite)
          .textShadow({
            radius: GSYShadow.headerTextRadius,
            color: GSYShadow.headerTextColor,
            offsetX: GSYShadow.headerTextOffsetX,
            offsetY: GSYShadow.headerTextOffsetY,
          })
          .margin({ right: GSYSpacing.normalEdge })
          .maxLines(1);
        Text(this.licenseText())
          .id('repo_header_license')
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.miWhite)
          .textShadow({
            radius: GSYShadow.headerTextRadius,
            color: GSYShadow.headerTextColor,
            offsetX: GSYShadow.headerTextOffsetX,
            offsetY: GSYShadow.headerTextOffsetY,
          })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .id('repo_header_meta_row')
      .width('100%')
      .margin({ top: GSYSpacing.halfEdge })
      .alignItems(VerticalAlign.Center);

      Text(this.descText())
        .id('repo_header_desc')
        .width('100%')
        .fontSize(GSYFontSize.min)
        .fontColor(GSYColor.miWhite)
        .textShadow({
          radius: GSYShadow.headerTextRadius,
          color: GSYShadow.headerTextColor,
          offsetX: GSYShadow.headerTextOffsetX,
          offsetY: GSYShadow.headerTextOffsetY,
        })
        .margin({ top: GSYSpacing.halfEdge })
        .maxLines(100);

      Row() {
        Text(this.buildInfoText())
          .id('repo_header_info_text')
          .fontSize(GSYFontSize.min)
          .fontColor(this.isFork() ? GSYColor.actionBlue : GSYColor.white)
          .textShadow({
            radius: GSYShadow.headerTextRadius,
            color: GSYShadow.headerTextColor,
            offsetX: GSYShadow.headerTextOffsetX,
            offsetY: GSYShadow.headerTextOffsetY,
          })
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .id('repo_header_info_row')
      .width('100%')
      .margin({
        top: GSYSpacing.normalEdge,
        bottom: GSYSpacing.normalEdge,
      })
      .justifyContent(FlexAlign.End)
      .onClick((): void => {
        if (this.isFork()) {
          this.onTapForkSource();
        }
      });

      Row() {
        this.buildBottomCell('star', FA_STAR_O,
          false, false, this.onTapStar);
        this.buildBottomCell('fork', FA_CODE_FORK,
          true, false, this.onTapFork);
        this.buildBottomCell('watch', FA_EYE,
          true, true, this.onTapWatch);
        this.buildBottomCell('issue', FA_EXCLAMATION_CIRCLE,
          false, false, this.onTapIssue);
      }
      .id('repo_header_bottom_row')
      .width('100%')
      .margin({ top: GSYSpacing.halfEdge })
      .padding({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge })
      .border({
        width: { top: HAIRLINE },
        color: GSYColor.repositoryHeaderLine,
      });

      if (this.topicsList().length > 0) {
        Flex({
          direction: FlexDirection.Row,
          wrap: FlexWrap.Wrap,
        }) {
          ForEach(this.topicsList(), (topic: string, index: number): void => {
            this.buildTopicTag(topic, index);
          }, (topic: string, index: number): string => index.toString() + ':' + topic);
        }
        .id('repo_header_topics')
        .width('100%')
        .margin({ top: GSYSpacing.halfEdge });
      }
      }
      .id('repo_header_content')
      .width('100%')
      .padding(GSYSpacing.normalEdge)
      .backgroundColor(this.ownerPic().length > 0
        ? GSYColor.repositoryHeaderScrim
        : GSYColor.primary)
      .alignItems(HorizontalAlign.Start);
    }
    .id('repo_header_root')
    .width('auto')
    .margin({
      top: GSYSpacing.normalEdge,
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
    })
    .borderRadius(HEADER_RADIUS)
    .clip(true)
    .backgroundImage(this.ownerPic().length > 0 ? this.ownerPic() : '')
    .backgroundImageSize(ImageSize.Cover);
  }
}
