/**
 * UserHeadItem —— 当前 My/Profile 头部以 Android Compose ProfileHeader 为准。
 * [ProfileShared.kt](https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/profile/src/main/java/com/shuyu/gsygithubappcompose/feature/profile/ProfileShared.kt)
 *
 *  primaryColor 卡片
 *   ├─ Row(头像 + 名字列)
 *   │   ├─ Image(largeIconSize=80, 圆)
 *   │   └─ Column
 *   │       ├─ Row: userDisPlayName(largeWhite, bold) + 通知铃铛(setting=true 时显示，
 *   │       │       unRead=true 时 actionBlue, 否则 miWhite)
 *   │       ├─ userName(subLightSmallText)
 *   │       ├─ IconText: 'group' + groupName
 *   │       └─ IconText: 'map-marker' + location
 *   ├─ Text: bio（有值才显示）
 *   ├─ Text: location/company（有值才显示）
 *   ├─ Text: joined date
 *   ├─ 4 格指标：repositories / followers / following / stars
 *   └─ Text: Activity Feed — 数据列表上方分类标题
 *
 * 颜色：
 *   - primary 背景：GSYColor.primary (#24292e)
 *   - 主字白：GSYColor.titleText / GSYColor.textWhite
 *   - 副字浅：GSYColor.subLightText (#c4c4c4)
 *   - 铃铛 unRead：GSYColor.actionBlue
 *   - 铃铛 已读：GSYColor.miWhite
 *
 * UserDetailPage 有自己的 Compose 头部实现；本组件主要用于 MyTabPage。
 */

import { GSYColor, GSYFontSize, GSYIconSize, GSYSpacing } from '../style/Theme';
import { I18n } from '../i18n/I18n';
import { IconFont, FA_BELL, FA_GROUP, FA_LOCATION, FA_LINK, FA_QUESTION } from '../common/IconFont';

export interface UserHeadCounter {
  key: string;
  label: string;
  value: string;
  onTap?: () => void;
}

export interface UserHeadOrgItem {
  login: string;
  avatar_url: string;
}

@Component
export struct UserHeadItem {
  @Prop userDisplayName: string = '';
  @Prop userName: string = '';
  @Prop userPic: string = '';
  @Prop groupName: string = '';
  @Prop location: string = '';
  @Prop link: string = '';
  @Prop des: string = '';
  @Prop joinedText: string = '';

  @Prop star: string = '---';
  @Prop follower: string = '---';
  @Prop followed: string = '---';
  @Prop repos: string = '---';
  @Prop beStared: string = '---';

  @Prop setting: boolean = false;
  @Prop settingNeed: boolean = false;
  @Prop unRead: boolean = false;
  @Prop isOrganizations: boolean = true;
  @Prop needFollow: boolean = false;
  @Prop hadFollowed: boolean = false;
  @Prop userType: string = '';

  @Prop orgsList: UserHeadOrgItem[] = [];

  onAvatarTap: () => void = (): void => {};
  onSettingTap: () => void = (): void => {};
  onNotifyTap: () => void = (): void => {};
  onFollowTap: () => void = (): void => {};
  onCounterTap: (key: string) => void = (_k: string): void => {};

  private resolveBellColor(): string {
    return this.unRead ? GSYColor.actionBlue : GSYColor.miWhite;
  }

  /**
   * 内嵌矢量图标 —— 替代 RN 端 react-native-vector-icons/FontAwesome。
   * OpenHarmony SDK 未自带 FontAwesome.ttf，sys.symbol 资源在当前 SDK 也未提供，
   * 因此用 ArkUI 矢量基元（Circle / Path / Line / Polyline）绘制相近形态。
   *
   * 支持 key（与 RN 端一一对应）：
   *   - 'bell'      RN: FontAwesome bell（钟形）
   *   - 'group'     RN: FontAwesome group（公司/组织 ≈ 楼宇形）
   *   - 'location'  RN: FontAwesome map-marker（地图标点）
   *   - 'link'      RN: FontAwesome link（两个相扣链环）
   */
  /**
   * 4 个矢量 icon —— 使用 FontAwesome 4.x 字体族（与 RN 端 react-native-vector-icons 同源 ttf）。
   * 字体已在 WelcomePage.registerIconFonts() 全局注册，familyName='FontAwesome'。
   * Unicode 码点严格对齐 RN 端 [FontAwesome.json](https://github.com/CarGuo/GSYGithubApp/blob/master/node_modules/react-native-vector-icons/glyphmaps/FontAwesome.json)：
   *   - 'bell'      \uf0f3   ← RN: bell
   *   - 'group'     \uf0c0   ← RN: group
   *   - 'location'  \uf041   ← RN: map-marker
   *   - 'link'      \uf0c1   ← RN: link
   *
   * 尺寸说明：RN 端 IconText 字号约 14 px，OH 端 GSYIconSize.small=30 偏大，
   * fontSize 按 size * 0.5 计（约 15 px），与 RN 视觉一致。
   *
   * 实现：内部委托给通用组件 [IconFont](../common/IconFont.ets)，
   * 保留本 builder 仅用作 key→码点映射的本地适配层（外部调用方仍以 key 为参数）。
   */
  @Builder
  buildVectorIcon(key: string, color: string, size: number): void {
    Stack() {
      IconFont({
        char: key === 'bell' ? FA_BELL
          : key === 'group' ? FA_GROUP
          : key === 'location' ? FA_LOCATION
          : key === 'link' ? FA_LINK
          : FA_QUESTION,
        glyphSize: size * 0.5,
        glyphColor: color,
      });
    }
      .width(size)
      .height(size)
      .alignContent(Alignment.Center);
  }

  /**
   * R-UI-05 inline 直读：buildIconLine 不再接收 text 值参（旧版 `text: string`
   * 触发 ArkTS @Builder 值参冻结陷阱）。lineKey 仅用作 cellId 路由 + 三元
   * 内部直接读 this.groupName / this.location / this.link（@Prop string），
   * 让 @Prop 响应式订阅链路在父 build 重渲染时自然驱动 cell 文案刷新。
   * 参考已有 inline 范式：[buildCounterCell](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/UserHeadItem.ets#L153-L184)（key+三元 inline 读 this.repos 等）
   * KI-048 / R-UI-05 守则参考：[ui-parity-with-rn.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/rules/ui-parity-with-rn.md)
   */
  @Builder
  buildInfoLine(prefix: string, text: string, lineId: string): void {
    Row() {
      Text(prefix + ' ' + text)
        .id(lineId + '_text')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.subLightText)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1);
    }
    .id(lineId)
    .margin({ top: GSYSpacing.halfEdge })
    .alignItems(VerticalAlign.Center)
    .width('100%');
  }

  @Builder
  buildCounterCell(key: string, label: string, value: string, leftBorder: boolean, rightBorder: boolean): void {
    Column() {
      Text(key === 'repos' ? (this.repos && this.repos.length > 0 ? this.repos : '---')
        : key === 'follower' ? (this.follower && this.follower.length > 0 ? this.follower : '---')
        : key === 'followed' ? (this.followed && this.followed.length > 0 ? this.followed : '---')
        : key === 'star' ? (this.star && this.star.length > 0 ? this.star : '---')
        : key === 'beStared' ? (this.beStared && this.beStared.length > 0 ? this.beStared : '---')
        : (value && value.length > 0 ? value : '---'))
        .id('user_head_counter_value_' + key)
        .fontSize(GSYFontSize.middleWhite)
        .fontWeight(FontWeight.Bold)
        .fontColor(GSYColor.titleText);
      Text(label)
        .id('user_head_counter_label_' + key)
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.subLightText)
        .margin({ top: 2 });
    }
    .id('user_head_counter_cell_' + key)
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge })
    .border({
      width: { left: leftBorder ? 0.5 : 0, right: rightBorder ? 0.5 : 0 },
      color: GSYColor.primaryLight,
    })
    .onClick((): void => {
      this.onCounterTap(key);
    });
  }

  @Builder
  buildFollowButton(): void {
    if (this.needFollow && !this.isOrganizations) {
      Row() {
        Text(this.hadFollowed ? I18n('unFollowed') : I18n('doFollowed'))
          .id('user_head_follow_text')
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.textWhite);
      }
      .id('user_head_follow_btn')
      .padding({
        left: GSYSpacing.normalEdge,
        right: GSYSpacing.normalEdge,
        top: GSYSpacing.halfEdge,
        bottom: GSYSpacing.halfEdge,
      })
      .border({
        width: 1,
        color: GSYColor.miWhite,
        radius: 4,
      })
      .alignItems(VerticalAlign.Center)
      .onClick((): void => {
        this.onFollowTap();
      });
    }
  }

  @Builder
  buildOrgsBar(): void {
    if (this.orgsList && this.orgsList.length > 0) {
      Row() {
        ForEach(this.orgsList, (org: UserHeadOrgItem, idx: number): void => {
          if (org.avatar_url && org.avatar_url.length > 0) {
            Image(org.avatar_url)
              .width(GSYIconSize.small)
              .height(GSYIconSize.small)
              .borderRadius(GSYIconSize.small / 2)
              .margin({ right: GSYSpacing.halfEdge });
          } else {
            Text(org.login.substring(0, 1).toUpperCase())
              .width(GSYIconSize.small)
              .height(GSYIconSize.small)
              .borderRadius(GSYIconSize.small / 2)
              .textAlign(TextAlign.Center)
              .fontColor(GSYColor.white)
              .backgroundColor(GSYColor.primaryDark)
              .margin({ right: GSYSpacing.halfEdge });
          }
        }, (org: UserHeadOrgItem, idx: number): string => 'org_' + idx.toString() + '_' + org.login);
      }
      .id('user_head_orgs_bar')
      .width('100%')
      .margin({ top: GSYSpacing.halfEdge });
    }
  }

  build(): void {
    Column() {
      Column() {
        Row() {
          if (this.userPic && this.userPic.length > 0) {
            Image(this.userPic)
              .id('user_head_avatar')
              .alt($r('app.media.app_icon'))
              .width(GSYIconSize.large)
              .height(GSYIconSize.large)
              .borderRadius(GSYIconSize.large / 2)
              .objectFit(ImageFit.Cover);
          } else {
            Text(this.userName.length > 0 ? this.userName.substring(0, 1).toUpperCase() : '?')
              .id('user_head_avatar_placeholder')
              .width(GSYIconSize.large)
              .height(GSYIconSize.large)
              .borderRadius(GSYIconSize.large / 2)
              .fontSize(GSYFontSize.big)
              .fontWeight(FontWeight.Bold)
              .fontColor(GSYColor.white)
              .backgroundColor(GSYColor.primaryDark)
              .textAlign(TextAlign.Center);
          }

          Column() {
            Text(this.userDisplayName && this.userDisplayName.length > 0 ? this.userDisplayName : this.userName)
              .id('user_head_display_name')
              .fontSize(GSYFontSize.big)
              .fontWeight(FontWeight.Bold)
              .fontColor(GSYColor.white)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });

            Text(this.userName && this.userName.length > 0 ? this.userName : '---')
              .id('user_head_login')
              .fontSize(GSYFontSize.middleWhite)
              .fontColor(GSYColor.subLightText)
              .margin({ top: 2 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: GSYSpacing.normalEdge });

          if (this.setting) {
            Stack() {
              this.buildVectorIcon('bell', this.resolveBellColor(), GSYIconSize.small);
            }
            .id('user_head_bell')
            .width(GSYIconSize.small + GSYSpacing.normalEdge)
            .height(GSYIconSize.small + GSYSpacing.normalEdge)
            .alignContent(Alignment.Center)
            .onClick((): void => {
              this.onNotifyTap();
            });
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);

        if (this.des && this.des.length > 0) {
          Text(this.des)
            .id('user_head_des')
            .width('100%')
            .fontSize(GSYFontSize.middleWhite)
            .fontColor(GSYColor.miWhite)
            .margin({ top: GSYSpacing.padding12 })
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }

        if (this.location && this.location.length > 0) {
          this.buildInfoLine('📍', this.location, 'user_head_location');
        }

        if (this.groupName && this.groupName.length > 0) {
          this.buildInfoLine('🏢', this.groupName, 'user_head_group');
        }

        if (this.joinedText && this.joinedText.length > 0) {
          Text(this.joinedText)
            .id('user_head_joined')
            .width('100%')
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.subLightText)
            .margin({ top: GSYSpacing.halfEdge });
        }
      }
      .id('user_head_profile_block')
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge, top: GSYSpacing.normalEdge, bottom: GSYSpacing.normalEdge });

      Row() {
        this.buildCounterCell('repos', I18n('repositoryText'), this.repos, false, false);
        this.buildCounterCell('follower', I18n('FollowersText'), this.follower, true, true);
        this.buildCounterCell('followed', I18n('FollowedText'), this.followed, false, false);
        this.buildCounterCell('star', I18n('staredText'), this.star, true, false);
      }
      .id('user_head_counter_row')
      .width('100%')
      .padding({ top: GSYSpacing.normalEdge, bottom: GSYSpacing.normalEdge })
      .backgroundColor(GSYColor.primary);

      Row() {
        Text(I18n('personDynamic'))
          .id('user_head_dynamic_title')
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Medium)
          .fontColor(GSYColor.white);
      }
      .id('user_head_dynamic_title_bar')
      .width('100%')
      .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge, top: GSYSpacing.halfEdge, bottom: GSYSpacing.normalEdge })
      .backgroundColor(GSYColor.primary);
    }
    .id('user_head_root')
    .width('100%')
    .backgroundColor(GSYColor.primary)
    .borderRadius(0);
  }
}
