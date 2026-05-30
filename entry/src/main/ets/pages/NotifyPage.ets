import { I18n } from '../i18n/I18n';
import { TimeUtil } from '../utils/TimeUtil';
import { PullLoadMoreList, PullLoadMoreController } from '../common/PullLoadMoreList';
import { AppBar, AppBarAction } from '../common/AppBar';
import { LoadingModal } from '../common/LoadingModal';
import { GSYColor, GSYFontSize, GSYShadow, GSYSpacing } from '../style/Theme';
import {
  NotifyStore,
  NotifyThread,
  NotifyFilter,
  NOTIFY_FILTER_UNREAD,
  NOTIFY_FILTER_PARTICIPATING,
  NOTIFY_FILTER_ALL,
} from '../store/NotifyStore';
import {
  NotifyService,
  FetchNotifyResult,
  MarkNotifyResult,
} from '../service/NotifyService';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { Logger } from '../ai-debug/Logger';
import { BOOT_NOTIFY_ISSUE_KEY } from '../entryability/EntryAbility';

interface IssueDetailRouteParam {
  owner: string;
  name: string;
  fullName: string;
  number: number;
  htmlUrl: string;
}

class NotifyTab {
  filter: NotifyFilter;
  label: string;

  constructor(filter: NotifyFilter, label: string) {
    this.filter = filter;
    this.label = label;
  }
}

const SUBJECT_ISSUE: string = 'Issue';

function parseNumberFromUrl(url: string): number {
  if (!url || url.length === 0) {
    return 0;
  }
  const lastSlash: number = url.lastIndexOf('/');
  if (lastSlash < 0) {
    return 0;
  }
  const tail: string = url.substring(lastSlash + 1);
  const num: number = Number.parseInt(tail, 10);
  return Number.isNaN(num) ? 0 : num;
}

function parseOwnerFromFullName(fullName: string): string {
  if (!fullName || fullName.length === 0) {
    return '';
  }
  const slash: number = fullName.indexOf('/');
  if (slash < 0) {
    return fullName;
  }
  return fullName.substring(0, slash);
}

function parseNameFromFullName(fullName: string): string {
  if (!fullName || fullName.length === 0) {
    return '';
  }
  const slash: number = fullName.indexOf('/');
  if (slash < 0) {
    return '';
  }
  return fullName.substring(slash + 1);
}

@Component
export struct NotifyPage {
  @State store: NotifyStore = new NotifyStore();
  @State plmController: PullLoadMoreController = new PullLoadMoreController();
  @State currentTabIndex: number = 0;
  @State initialPageLoading: boolean = true;
  @State initialLoadFinished: boolean = false;
  private service: NotifyService = new NotifyService(this.store);
  private pathStack: NavPathStack = new NavPathStack();
  private tabs: NotifyTab[] = [
    new NotifyTab(NOTIFY_FILTER_UNREAD, I18n('notifyUnread')),
    new NotifyTab(NOTIFY_FILTER_PARTICIPATING, I18n('notifyParticipating')),
    new NotifyTab(NOTIFY_FILTER_ALL, I18n('notifyAll')),
  ];

  aboutToAppear(): void {
    this.service = new NotifyService(this.store);
    this.triggerRefresh();
  }

  private currentFilter(): NotifyFilter {
    if (this.currentTabIndex < 0 || this.currentTabIndex >= this.tabs.length) {
      return NOTIFY_FILTER_UNREAD;
    }
    return this.tabs[this.currentTabIndex].filter;
  }

  private async triggerRefresh(): Promise<void> {
    const isInitialEmptyLoad: boolean = !this.initialLoadFinished && this.store.list.length === 0;
    if (isInitialEmptyLoad) {
      this.initialPageLoading = true;
    }
    this.plmController.showRefreshState();
    if (this.applyBootNotifyIssue()) {
      this.initialPageLoading = false;
      this.initialLoadFinished = true;
      this.plmController.refreshComplete(false, false);
      return;
    }
    const res: FetchNotifyResult = await this.service.getNotifications(this.currentFilter(), 1);
    this.initialPageLoading = false;
    this.initialLoadFinished = true;
    const showLoadMore: boolean = res.result && this.store.list.length > 0 && this.store.hasMore;
    this.plmController.refreshComplete(showLoadMore, false);
    if (!res.result && res.data.length === 0) {
      return;
    }
  }

  private async triggerLoadMore(): Promise<void> {
    if (!this.store.hasMore) {
      this.plmController.loadMoreComplete(false);
      return;
    }
    const next: number = this.store.page + 1;
    await this.service.getNotifications(this.currentFilter(), next);
    this.plmController.loadMoreComplete(this.store.hasMore);
  }

  private async onTabChanged(index: number): Promise<void> {
    if (index === this.currentTabIndex) {
      return;
    }
    this.currentTabIndex = index;
    await this.triggerRefresh();
  }

  private async markAllRead(): Promise<void> {
    LoadingModal.show(I18n('loading'), false);
    try {
      if (this.isBootOnlyNotificationList()) {
        this.store.markAllRead();
        Logger.i('notify/markAll', 'boot notification list marked read locally');
        return;
      }
      const res: MarkNotifyResult = await this.service.markAllAsRead();
      Logger.i('notify/markAll', `result=${res.result} code=${res.code}`);
      if (res.result) {
        await this.triggerRefresh();
      }
    } finally {
      LoadingModal.hide();
    }
  }

  private isBootOnlyNotificationList(): boolean {
    if (this.store.list.length === 0) {
      return false;
    }
    for (let i = 0; i < this.store.list.length; i++) {
      if (this.store.list[i].id.indexOf('boot-notify-issue-') !== 0) {
        return false;
      }
    }
    return true;
  }

  private async onThreadClick(item: NotifyThread): Promise<void> {
    this.openSubjectDetail(item);
    if (item.id.indexOf('boot-notify-issue-') === 0) {
      Logger.i('notify/click', `skip markAsRead for boot issue id=${item.id}`);
      return;
    }
    if (item.unread) {
      this.service.markAsRead(item.id).then((res: MarkNotifyResult): void => {
        Logger.i('notify/click', `markAsRead id=${item.id} result=${res.result} code=${res.code}`);
      });
    }
  }

  private applyBootNotifyIssue(): boolean {
    const value: string | undefined = AppStorage.get<string>(BOOT_NOTIFY_ISSUE_KEY);
    const raw: string = (value || '').trim();
    if (raw.length === 0) {
      return false;
    }
    const sep: number = raw.indexOf('|');
    if (sep <= 0 || sep >= raw.length - 1) {
      AppStorage.setOrCreate<string>(BOOT_NOTIFY_ISSUE_KEY, '');
      return false;
    }
    const fullName: string = raw.substring(0, sep);
    const numberStr: string = raw.substring(sep + 1);
    const issueNumber: number = Number.parseInt(numberStr, 10);
    if (fullName.length === 0 || Number.isNaN(issueNumber) || issueNumber <= 0) {
      AppStorage.setOrCreate<string>(BOOT_NOTIFY_ISSUE_KEY, '');
      return false;
    }
    const slash: number = fullName.indexOf('/');
    const owner: string = slash > 0 ? fullName.substring(0, slash) : '';
    const name: string = slash > 0 ? fullName.substring(slash + 1) : fullName;
    const issueApiUrl: string = `https://api.github.com/repos/${fullName}/issues/${issueNumber}`;
    const thread: NotifyThread = {
      'id': `boot-notify-issue-${fullName}-${issueNumber}`,
      'unread': true,
      'reason': 'manual',
      'updated_at': new Date().toISOString(),
      'last_read_at': '',
      'url': issueApiUrl,
      'subject': {
        'title': `Issue #${issueNumber}`,
        'url': issueApiUrl,
        'latest_comment_url': issueApiUrl,
        'type': SUBJECT_ISSUE,
      },
      'repository': {
        'id': 0,
        'name': name,
        'full_name': fullName,
        'owner_login': owner,
        'html_url': `https://github.com/${fullName}`,
      },
    } as NotifyThread;
    this.store.applyRefresh([thread], 100);
    this.store.hasMore = false;
    AppStorage.setOrCreate<string>(BOOT_NOTIFY_ISSUE_KEY, '');
    Logger.i('notify/boot', `applied bootNotifyIssue fullName=${fullName} number=${issueNumber}`);
    return true;
  }

  private openSubjectDetail(item: NotifyThread): void {
    const subjectType: string = item.subject.type;
    const fullName: string = item.repository.full_name;
    const owner: string = item.repository.owner_login.length > 0
      ? item.repository.owner_login : parseOwnerFromFullName(fullName);
    const name: string = item.repository.name.length > 0
      ? item.repository.name : parseNameFromFullName(fullName);

    if (subjectType === SUBJECT_ISSUE) {
      const number: number = parseNumberFromUrl(item.subject.url);
      const issueParam: IssueDetailRouteParam = {
        'owner': owner,
        'name': name,
        'fullName': fullName,
        'number': number,
        'htmlUrl': item.subject.url,
      } as IssueDetailRouteParam;
      Logger.i('notify/click', `open issue fullName=${fullName} number=${number} subjectUrl=${item.subject.url}`);
      NavigationService.push(RouteName.IssueDetail, issueParam as Object);
      return;
    }
    Logger.i('notify/click', `mark-read only subjectType=${subjectType} fullName=${fullName}`);
  }

  @Builder
  buildTabBar(): void {
    Row() {
      ForEach(this.tabs, (tab: NotifyTab, index: number): void => {
        Button(tab.label)
          .id('notify_tab_' + index.toString())
          .type(ButtonType.Normal)
          .height(56)
          .layoutWeight(1)
          .backgroundColor(this.currentTabIndex === index ? GSYColor.primary : GSYColor.white)
          .fontColor(this.currentTabIndex === index ? GSYColor.white : GSYColor.subText)
          .fontSize(GSYFontSize.normal)
          .borderRadius(index === 0 || index === this.tabs.length - 1 ? 8 : 0)
          .border({ width: 1, color: GSYColor.primary })
          .onClick((): void => {
            this.onTabChanged(index);
          });
      }, (tab: NotifyTab, index: number): string => 'notify_tab_key_' + index.toString());
    }
    .id('notify_tab_bar')
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(GSYColor.white);
  }

  private buildStatusText(item: NotifyThread): string {
    const status: string = item.unread ? I18n('notifyStatusUnread') : I18n('notifyStatusRead');
    return I18n('notifyType') + ': ' + item.subject.type + ', '
      + I18n('notifyStatus') + ': ' + status;
  }

  @Builder
  rowBuilder(item: NotifyThread, index: number): void {
    Row() {
      Column() {
        Row() {
          Text(item.repository.full_name)
            .id('notify_row_repo_' + index.toString())
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.primary)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Text(TimeUtil.resolveTime(item.updated_at))
            .id('notify_row_time_' + index.toString())
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.mediumText)
            .margin({ left: GSYSpacing.halfEdge });
        }
        .id('notify_row_meta_' + index.toString())
        .width('100%')
        .alignItems(VerticalAlign.Center);

        Text(item.subject.title)
          .id('notify_row_title_' + index.toString())
          .fontSize(GSYFontSize.middleWhite)
          .fontColor(GSYColor.mainText)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: GSYSpacing.halfEdge });

        Text(this.buildStatusText(item))
          .id('notify_row_status_' + index.toString())
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.mediumText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: GSYSpacing.halfEdge });
      }
      .id('notify_row_card_' + index.toString())
      .width('100%')
      .padding({ left: 10, right: 10, top: 10, bottom: 10 })
      .borderRadius(8)
      .border({ width: 1, color: GSYColor.borderSubtle })
      .backgroundColor(GSYColor.cardBackground)
      .shadow({
        radius: GSYShadow.radius,
        color: GSYColor.cardShadow,
        offsetX: 1,
        offsetY: 1,
      })
      .alignItems(HorizontalAlign.Start);
    }
    .id('notify_row_' + index.toString())
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .onClick((): void => {
      this.onThreadClick(item);
    });
  }

  @Builder
  emptyBuilder(): void {
    Column() {
      Text(I18n('notifyEmpty'))
        .id('notify_empty_text')
        .fontSize(15) // TODO: 字号 15 暂无 token 映射
        .fontColor(GSYColor.subText);
    }
    .id('notify_empty_root')
    .width('100%')
    .height(240)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  buildInitialLoading(): void {
    Column() {
      LoadingProgress()
        .id('notify_initial_loading_indicator')
        .width(36)
        .height(36)
        .color(GSYColor.primary);
    }
    .id('notify_initial_loading')
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  buildInitialError(): void {
    Column() {
      Text(this.store.error.length > 0 ? this.store.error : I18n('unknown'))
        .id('notify_initial_error_text')
        .fontSize(GSYFontSize.middleWhite)
        .fontColor(GSYColor.subText)
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 });
    }
    .id('notify_initial_error')
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  buildNotifyContent(): void {
    this.buildTabBar();

    PullLoadMoreList({
      dataSource: this.store.list,
      controller: this.plmController,
      renderRow: (item: Object, index: number): void => this.rowBuilder(item as NotifyThread, index),
      renderEmpty: (): void => this.emptyBuilder(),
      refresh: (): void => {
        this.triggerRefresh();
      },
      loadMore: (): void => {
        this.triggerLoadMore();
      },
    })
      .id('notify_pull_list')
      .layoutWeight(1);
  }

  build(): void {
    NavDestination() {
      Column() {
        AppBar({
          title: I18n('notify'),
          showBack: true,
          onBack: (): void => {
            NavigationService.pop();
          },
          rightActions: [
            {
              iconKey: 'done_all',
              onAction: (): void => {
                this.markAllRead();
              },
            } as AppBarAction,
          ],
        })
          .id('notify_app_bar');

        if (this.initialPageLoading && this.store.list.length === 0) {
          this.buildInitialLoading();
        } else if (this.store.error.length > 0 && this.store.list.length === 0) {
          this.buildInitialError();
        } else {
          this.buildNotifyContent();
        }
      }
      .id('notify_root')
      .width('100%')
      .height('100%')
      .backgroundColor(GSYColor.white);
    }
    .onReady((ctx: NavDestinationContext): void => {
      const stack: NavPathStack | undefined = ctx.pathStack;
      if (stack !== undefined && stack !== null) {
        this.pathStack = stack;
      }
    });
  }
}
