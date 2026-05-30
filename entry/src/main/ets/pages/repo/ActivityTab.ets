/**
 * ActivityTab —— RepositoryDetail Info body，对齐 Compose 版 Info Screen
 * [RepoDetailInfoScreen.kt](https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/detail/src/main/java/com/shuyu/gsygithubappcompose/feature/detail/info/RepoDetailInfoScreen.kt)
 *
 * 结构（PullLoadMoreList renderHeader 模板）：
 *   ┌─ RepositoryHeader  （仓库元数据卡片）
 *   ├─ CommonBottomBar   （Events / Commits 二选一）
 *   └─ ListItem * N      （Events 使用 EventItem；Commits 使用 Compose-style CommitItem）
 *
 * 所有 token 走 [Theme.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/style/Theme.ets)，
 * 严禁字面量颜色 / 字号 / 间距（HARD-LAW-2）。
 */

import { I18n } from '../../i18n/I18n';
import { TimeUtil } from '../../utils/TimeUtil';
import { GSYColor, GSYFontSize, GSYSpacing, GSYIconSize, GSYShadow } from '../../style/Theme';
import { PullLoadMoreList, PullLoadMoreController } from '../../common/PullLoadMoreList';
import {
  RepositoryDetail,
  RepositoryDetailStore,
  RepositoryEventItem,
  RepositoryCommitItem,
  RepositoryCommitUser,
} from '../../store/RepositoryDetailStore';
import { RepositoryHeader } from '../../widget/RepositoryHeader';
import { UserImage } from '../../widget/UserImage';
import { CommonBottomBar, CommonBottomBarItem } from '../../common/CommonBottomBar';
import { FA_CHECK } from '../../common/IconFont';
import { EventItem } from '../../widget/EventItem';
import {
  EventActionUtil,
  EventActionResult,
} from '../../utils/EventActionUtil';
import { EventActionDispatcher } from '../../utils/EventActionDispatcher';
import { ExternalUrlUtil } from '../../utils/ExternalUrlUtil';
import { NavigationService } from '../../navigation/NavigationService';
import { RouteName } from '../../navigation/Routes';
import {
  DynamicEvent,
  DynamicActor,
  DynamicRepo,
} from '../../store/DynamicStore';

const ACTIVITY_SELECT_ACTIVITY: number = 0;
const ACTIVITY_SELECT_PUSH: number = 1;
const HEADER_AVATAR_SIZE: number = 28;

@Component
export struct ActivityTab {
  // 列表数据全部走 @ObjectLink store 直接读，保证 store 内字段更新立即触发 build 重渲。
  @Prop activity: RepositoryEventItem[] = [];
  @Link controller: PullLoadMoreController;
  @ObjectLink store: RepositoryDetailStore;
  ownerName: string = '';
  repositoryName: string = '';
  refresh: () => void = (): void => {};
  loadMore: () => void = (): void => {};
  onTapStar: () => void = (): void => {};
  onTapFork: () => void = (): void => {};
  onTapWatch: () => void = (): void => {};
  onTapIssue: () => void = (): void => {};
  onTapForkSource: () => void = (): void => {};
  onTapOwner: () => void = (): void => {};
  onTapTopic: (topic: string) => void = (_topic: string): void => {};
  onSelectChange: (sel: number) => void = (_sel: number): void => {};

  @State select: number = ACTIVITY_SELECT_ACTIVITY;

  private formatSize(size: number | undefined): string {
    if (size === undefined || size === null) {
      return '---';
    }
    return (size / 1024).toFixed(2) + 'M';
  }

  private resolveLicense(): string {
    const d: RepositoryDetail | null = this.store.detail;
    if (d === null || d.license === null || d.license === undefined) {
      return '';
    }
    return d.license.name;
  }

  private resolveParentName(): string {
    const d: RepositoryDetail | null = this.store.detail;
    if (d === null || d.parent === null || d.parent === undefined) {
      return '---';
    }
    return d.parent.full_name;
  }

  private resolveTimeText(value: string | undefined): string {
    if (value === undefined || value === null || value.length === 0) {
      return '';
    }
    return TimeUtil.resolveTime(value);
  }

  private buildBottomItems(): CommonBottomBarItem[] {
    const items: CommonBottomBarItem[] = [];

    const activityItem: CommonBottomBarItem = new CommonBottomBarItem();
    activityItem.itemId = 'activity';
    activityItem.itemName = I18n('reposEvents');
    activityItem.itemTextColor = this.select === ACTIVITY_SELECT_ACTIVITY
      ? GSYColor.primary : GSYColor.subText;
    activityItem.icon = this.select === ACTIVITY_SELECT_ACTIVITY ? FA_CHECK : '';
    activityItem.iconColor = GSYColor.primary;
    activityItem.itemClick = (): void => {
      if (this.select === ACTIVITY_SELECT_ACTIVITY) {
        return;
      }
      this.select = ACTIVITY_SELECT_ACTIVITY;
      this.onSelectChange(ACTIVITY_SELECT_ACTIVITY);
      this.refresh();
    };
    items.push(activityItem);

    const pushItem: CommonBottomBarItem = new CommonBottomBarItem();
    pushItem.itemId = 'push';
    pushItem.itemName = I18n('reposCommits');
    pushItem.itemTextColor = this.select === ACTIVITY_SELECT_PUSH
      ? GSYColor.primary : GSYColor.subText;
    pushItem.icon = this.select === ACTIVITY_SELECT_PUSH ? FA_CHECK : '';
    pushItem.iconColor = GSYColor.primary;
    pushItem.itemClick = (): void => {
      if (this.select === ACTIVITY_SELECT_PUSH) {
        return;
      }
      this.select = ACTIVITY_SELECT_PUSH;
      this.onSelectChange(ACTIVITY_SELECT_PUSH);
    };
    items.push(pushItem);

    return items;
  }

  /**
   * 当前 select 下要展示的列表数据：
   * - select=0（动态）：store.activity（RepositoryEventItem[]）
   * - select=1（提交）：store.commits（RepositoryCommitItem[]）
   * 与 Compose RepoDetailInfoScreen 的 Events / Commits 切换语义一致。
   */
  private currentDataSource(): Object[] {
    if (this.select === ACTIVITY_SELECT_ACTIVITY) {
      return this.activity as Object[];
    }
    if (this.select === ACTIVITY_SELECT_PUSH) {
      return this.store.commits as Object[];
    }
    return [];
  }

  @Builder
  rowBuilder(item: Object, index: number): void {
    if (this.select === ACTIVITY_SELECT_ACTIVITY) {
      this.eventRowBuilder(item as RepositoryEventItem, index);
    } else {
      this.commitRowBuilder(item as RepositoryCommitItem, index);
    }
  }

  @Builder
  eventRowBuilder(item: RepositoryEventItem, index: number): void {
    EventItem({
      actionTime: item.created_at,
      actionUser: item.actor !== null && item.actor !== undefined
        ? item.actor.login
        : '',
      actionUserPic: item.actor !== null && item.actor !== undefined
        ? item.actor.avatar_url
        : '',
      actionTarget: EventActionUtil.getComposeActionText(this.toDynamicEvent(item)),
      des: '',
      rowId: 'repo_event_row_' + index.toString(),
      onPressItem: (): void => {
        this.dispatchEventTap(item);
      },
      onPressUser: (): void => {
        const login: string = item.actor !== null && item.actor !== undefined ? item.actor.login : '';
        EventActionDispatcher.dispatchUser(login);
      },
    });
  }

  // ---- commitRowBuilder 字段安全归一（@Builder 内只能写 UI 语法，故 helper 抽到外面）----
  private resolveCommitSha(item: RepositoryCommitItem): string {
    if (item === null || item === undefined) {
      return '';
    }
    if (item.sha === null || item.sha === undefined) {
      return '';
    }
    return item.sha;
  }

  private resolveCommitDate(item: RepositoryCommitItem): string {
    if (item === null || item === undefined
      || item.commit === null || item.commit === undefined
      || item.commit.committer === null || item.commit.committer === undefined
      || item.commit.committer.date === null || item.commit.committer.date === undefined) {
      return '';
    }
    return item.commit.committer.date;
  }

  private resolveCommitName(item: RepositoryCommitItem): string {
    if (item === null || item === undefined) {
      return 'Unknown';
    }
    if (item.author !== null && item.author !== undefined && item.author.login.length > 0) {
      return item.author.login;
    }
    if (item.committer !== null && item.committer !== undefined && item.committer.login.length > 0) {
      return item.committer.login;
    }
    return 'Unknown';
  }

  private resolveCommitAvatar(item: RepositoryCommitItem): string {
    if (item === null || item === undefined) {
      return '';
    }
    const author: RepositoryCommitUser | null | undefined = item.author;
    if (author !== null && author !== undefined && author.avatar_url.length > 0) {
      return author.avatar_url;
    }
    const committer: RepositoryCommitUser | null | undefined = item.committer;
    if (committer !== null && committer !== undefined && committer.avatar_url.length > 0) {
      return committer.avatar_url;
    }
    return '';
  }

  private resolveCommitMessage(item: RepositoryCommitItem): string {
    if (item === null || item === undefined
      || item.commit === null || item.commit === undefined
      || item.commit.message === null || item.commit.message === undefined) {
      return '';
    }
    return item.commit.message;
  }

  private resolveRepoFullName(): string {
    if (this.ownerName.length > 0 && this.repositoryName.length > 0) {
      return this.ownerName + '/' + this.repositoryName;
    }
    const d: RepositoryDetail | null = this.store.detail;
    if (d !== null && d !== undefined && d.full_name !== null && d.full_name !== undefined) {
      return d.full_name;
    }
    return '';
  }

  private openCommit(item: RepositoryCommitItem): void {
    const fullName: string = this.resolveRepoFullName();
    const sha: string = this.resolveCommitSha(item);
    if (fullName.length === 0 || sha.length === 0) {
      return;
    }
    NavigationService.push(RouteName.PushDetail, {
      'fullName': fullName,
      'sha': sha,
    } as Record<string, Object>);
  }

  @Builder
  commitRowBuilder(item: RepositoryCommitItem, index: number): void {
    Column() {
      Row() {
        UserImage({
          uri: this.resolveCommitAvatar(item),
          loginUser: this.resolveCommitName(item),
          imageSize: GSYIconSize.normal,
          imageId: 'repo_commit_row_' + index.toString() + '_avatar',
        });

        Column() {
          Text(this.resolveCommitMessage(item))
            .id('repo_commit_row_' + index.toString() + '_message')
            .fontSize(GSYFontSize.middleWhite)
            .fontWeight(FontWeight.Bold)
            .fontColor(GSYColor.mainText)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Text(this.resolveCommitName(item))
            .id('repo_commit_row_' + index.toString() + '_author')
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.textSubtle)
            .margin({ top: GSYSpacing.halfEdge });

          if (this.resolveCommitDate(item).length > 0) {
            Text(TimeUtil.resolveTime(this.resolveCommitDate(item)))
              .id('repo_commit_row_' + index.toString() + '_time')
              .fontSize(GSYFontSize.min)
              .fontColor(GSYColor.subText)
              .margin({ top: GSYSpacing.halfEdge });
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: GSYSpacing.normalEdge });
      }
      .id('repo_commit_row_' + index.toString() + '_content')
      .width('100%')
      .padding({
        left: GSYSpacing.normalEdge,
        right: GSYSpacing.normalEdge,
        top: GSYSpacing.padding12,
        bottom: GSYSpacing.padding12,
      })
      .alignItems(VerticalAlign.Center);
    }
    .id('repo_commit_row_' + index.toString())
    .width('auto')
    .margin({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.halfEdge,
      bottom: GSYSpacing.halfEdge,
    })
    .border({
      width: GSYSpacing.dividerThickness,
      color: GSYColor.divider,
    })
    .borderRadius(GSYSpacing.cardRadius * 2)
    .backgroundColor(GSYColor.cardBackground)
    .shadow({
      radius: GSYShadow.radius,
      color: GSYShadow.cardShadowAlpha,
      offsetX: 0,
      offsetY: GSYShadow.elevation,
    })
    .onClick((): void => {
      this.openCommit(item);
    });
  }

  private toDynamicEvent(item: RepositoryEventItem): DynamicEvent {
    const actor: DynamicActor = {
      id: 0,
      login: item.actor !== null && item.actor !== undefined ? item.actor.login : '',
      display_login: item.actor !== null && item.actor !== undefined ? item.actor.login : '',
      avatar_url: item.actor !== null && item.actor !== undefined ? item.actor.avatar_url : '',
    } as DynamicActor;
    const repo: DynamicRepo = {
      id: item.repo !== null && item.repo !== undefined ? item.repo.id : 0,
      name: item.repo !== null && item.repo !== undefined ? item.repo.name : '',
      url: '',
    } as DynamicRepo;
    const event: DynamicEvent = {
      id: item.id,
      type: item.type,
      actor: actor,
      repo: repo,
      created_at: item.created_at,
      payload: item.payload !== null && item.payload !== undefined
        ? item.payload : ({} as Record<string, Object>),
    } as DynamicEvent;
    return event;
  }

  private dispatchEventTap(item: RepositoryEventItem): void {
    const currentRepo: string = this.ownerName + '/' + this.repositoryName;
    EventActionDispatcher.dispatch(this.toDynamicEvent(item), currentRepo, (url: string): boolean => {
      return ExternalUrlUtil.openUrlInBrowser(this, url, 'ActivityTab');
    });
  }

  @Builder
  headerBuilder(): void {
    Column() {
      RepositoryHeader({
        store: this.store,
        ownerName: this.ownerName,
        repositoryName: this.repositoryName,
        createdAtText: this.resolveTimeText(this.store.detail !== null ? this.store.detail.created_at : ''),
        pushAtText: this.resolveTimeText(this.store.detail !== null ? this.store.detail.pushed_at : ''),
        parentName: this.resolveParentName(),
        onTapOwner: (): void => {
          this.onTapOwner();
        },
        onTapStar: (): void => {
          this.onTapStar();
        },
        onTapFork: (): void => {
          this.onTapFork();
        },
        onTapWatch: (): void => {
          this.onTapWatch();
        },
        onTapIssue: (): void => {
          this.onTapIssue();
        },
        onTapForkSource: (): void => {
          this.onTapForkSource();
        },
        onTapTopic: (topic: string): void => {
          this.onTapTopic(topic);
        },
      });

      CommonBottomBar({
        rootId: 'repo_activity_select_bar',
        dataList: this.buildBottomItems(),
      })
        .margin({
          left: GSYSpacing.normalEdge,
          right: GSYSpacing.normalEdge,
          top: GSYSpacing.normalEdge,
        });
    }
    .id('repo_activity_header')
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  emptyBuilder(): void {
    Column() {
      Text(I18n('reposEvents'))
        .id('repo_event_empty_title')
        .fontSize(GSYFontSize.middleWhite)
        .fontColor(GSYColor.subText);
      Text(I18n('userInfoNoting'))
        .id('repo_event_empty_desc')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.subText)
        .margin({ top: GSYSpacing.halfEdge });
    }
    .id('repo_event_empty_root')
    .width('100%')
    .height(GSYIconSize.normal * 8)
    .justifyContent(FlexAlign.Center);
  }

  build(): void {
    Column() {
      PullLoadMoreList({
        dataSource: this.currentDataSource(),
        controller: this.controller,
        renderHeader: (): void => this.headerBuilder(),
        renderRow: (item: Object, index: number): void =>
          this.rowBuilder(item, index),
        renderEmpty: (): void => this.emptyBuilder(),
        refresh: (): void => {
          this.refresh();
        },
        loadMore: (): void => {
          this.loadMore();
        },
        tailPadding: GSYSpacing.tabBarHeight + GSYSpacing.normalEdge * 2,
      })
        .id('repo_event_list')
        .layoutWeight(1);
    }
    .id('repo_event_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.white);
  }
}
