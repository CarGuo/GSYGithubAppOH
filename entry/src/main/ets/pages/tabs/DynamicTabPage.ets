/**
 * DynamicTabPage —— 以 Android Compose DynamicScreen/EventItem 为准。
 */
import { I18n } from '../../i18n/I18n';
import { PullLoadMoreList, PullLoadMoreController } from '../../common/PullLoadMoreList';
import { DynamicEvent, DynamicStore } from '../../store/DynamicStore';
import { DynamicService, FetchReceivedResult } from '../../service/DynamicService';
import { EventItem } from '../../widget/EventItem';
import { EventActionUtil } from '../../utils/EventActionUtil';
import { EventActionDispatcher } from '../../utils/EventActionDispatcher';
import { ExternalUrlUtil } from '../../utils/ExternalUrlUtil';
import { GSYColor, GSYFontSize, GSYSpacing } from '../../style/Theme';
import { GlobalAuthStore } from '../../store/AuthStore';

const FALLBACK_USER: string = 'octocat';

@Component
export struct DynamicTabPage {
  @State store: DynamicStore = new DynamicStore();
  @State plmController: PullLoadMoreController = new PullLoadMoreController();
  private service: DynamicService = new DynamicService(this.store);

  aboutToAppear(): void {
    this.service = new DynamicService(this.store);
    this.triggerRefresh();
  }

  private resolveUser(): string {
    const u: string | null = GlobalAuthStore.userInfo !== null && GlobalAuthStore.userInfo !== undefined
      ? GlobalAuthStore.userInfo.login
      : null;
    if (u !== null && u !== undefined && u.length > 0) {
      return u;
    }
    return FALLBACK_USER;
  }

  private async triggerRefresh(): Promise<void> {
    this.plmController.showRefreshState();
    const res: FetchReceivedResult = await this.service.fetchReceivedEvents(this.resolveUser(), 1);
    this.plmController.refreshComplete(this.store.hasMore, false);
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
    await this.service.fetchReceivedEvents(this.resolveUser(), next);
    this.plmController.loadMoreComplete(this.store.hasMore);
  }

  private dispatchEventTap(event: DynamicEvent): void {
    EventActionDispatcher.dispatch(event, '', (url: string): boolean => {
      return ExternalUrlUtil.openUrlInBrowser(this, url, 'DynamicTabPage');
    });
  }

  @Builder
  rowBuilder(item: DynamicEvent, index: number): void {
    EventItem({
      actionTime: item.created_at,
      actionUser: item.actor !== null && item.actor !== undefined
        ? (item.actor.display_login !== undefined && item.actor.display_login !== null && item.actor.display_login.length > 0
          ? item.actor.display_login
          : item.actor.login)
        : '',
      actionUserPic: item.actor !== null && item.actor !== undefined ? item.actor.avatar_url : '',
      actionTarget: EventActionUtil.getComposeActionText(item),
      des: '',
      rowId: 'dynamic_row_' + index.toString(),
      onPressItem: (): void => {
        this.dispatchEventTap(item);
      },
      onPressUser: (): void => {
        const login: string = item.actor !== null && item.actor !== undefined ? item.actor.login : '';
        EventActionDispatcher.dispatchUser(login);
      },
    });
  }

  @Builder
  emptyBuilder(): void {
    Column() {
      Text(I18n('listEmpty'))
        .id('dynamic_empty_text')
        .fontSize(GSYFontSize.middleWhite)
        .fontColor(GSYColor.subText);
    }
    .id('dynamic_empty_root')
    .width('100%')
    .height(240)
    .justifyContent(FlexAlign.Center);
  }

  build(): void {
    Column() {
      PullLoadMoreList({
        dataSource: this.store.list,
        controller: this.plmController,
        renderRow: (item: Object, index: number): void => this.rowBuilder(item as DynamicEvent, index),
        renderEmpty: (): void => this.emptyBuilder(),
        refresh: (): void => {
          this.triggerRefresh();
        },
        loadMore: (): void => {
          this.triggerLoadMore();
        },
        refreshingText: I18n('refreshing'),
        loadingMoreText: I18n('loadMoreing'),
        loadEndText: I18n('loadMoreEnd'),
        emptyText: I18n('listEmpty'),
      })
        .id('dynamic_pull_list')
        .layoutWeight(1);
    }
    .id('tab_page_root_dynamic')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.mainBackground);
  }
}
