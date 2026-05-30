import { ComponentContent } from '@kit.ArkUI';
import { GSYColor, GSYFontSize } from '../style/Theme';

export enum PullLoadMoreFooterState {
  HIDE = 0,
  LOADING = 1,
  END = 2,
}

@Observed
export class PullLoadMoreController {
  refreshing: boolean = false;
  nativeRefreshing: boolean = false;
  loadingMoreActive: boolean = false;
  footerState: PullLoadMoreFooterState = PullLoadMoreFooterState.HIDE;
  scrollerCarrier: Scroller | null = null;

  bindScroller(scroller: Scroller): void {
    this.scrollerCarrier = scroller;
  }

  showRefreshState(): void {
    this.refreshing = true;
    this.nativeRefreshing = false;
    this.loadingMoreActive = false;
  }

  refreshComplete(showLoadMore: boolean = false, scrollToTop: boolean = false): void {
    this.refreshing = false;
    this.nativeRefreshing = false;
    this.loadingMoreActive = false;
    this.footerState = showLoadMore ? PullLoadMoreFooterState.LOADING : PullLoadMoreFooterState.HIDE;
    if (scrollToTop) {
      this.scrollToTop();
    }
  }

  beginLoadMore(): void {
    if (this.footerState === PullLoadMoreFooterState.LOADING) {
      this.loadingMoreActive = true;
    }
  }

  loadMoreComplete(showLoadMore: boolean = false): void {
    this.loadingMoreActive = false;
    this.footerState = showLoadMore ? PullLoadMoreFooterState.LOADING : PullLoadMoreFooterState.END;
  }

  setFooterState(state: PullLoadMoreFooterState): void {
    this.footerState = state;
    if (state !== PullLoadMoreFooterState.LOADING) {
      this.loadingMoreActive = false;
    }
  }

  scrollToTop(): void {
    if (this.scrollerCarrier) {
      this.scrollerCarrier.scrollToIndex(0);
    }
  }
}

class RefreshIndicatorParams {
  color: string = GSYColor.primary;
  backgroundColor: string = GSYColor.white;
}

@Builder
function refreshIndicatorContent(params: RefreshIndicatorParams): void {
  Row()
    .id('pull_refresh_drag_overlay')
    .width('100%')
    .height(0)
    .opacity(0);
}

@Component
export struct PullLoadMoreList {
  @Prop dataSource: Object[] = [];
  @ObjectLink controller: PullLoadMoreController;
  enableRefresh: boolean = true;
  refresh: () => void = (): void => {};
  loadMore: () => void = (): void => {};
  @BuilderParam renderRow: (item: Object, index: number) => void = this.defaultRow;
  @BuilderParam renderHeader: () => void = this.defaultEmptyBuilder;
  @BuilderParam renderEmpty: () => void = this.defaultEmptyState;
  loadingMoreText: string = 'Loading more…';
  loadEndText: string = 'No more data';
  refreshingText: string = 'Refreshing…';
  emptyText: string = 'No content yet, tap to retry';
  tailPadding: number = 0;

  private listScroller: Scroller = new Scroller();
  private refreshIndicatorParams: RefreshIndicatorParams = new RefreshIndicatorParams();
  private refreshContentNode?: ComponentContent<RefreshIndicatorParams> = undefined;

  aboutToAppear(): void {
    this.controller.bindScroller(this.listScroller);
    this.refreshContentNode = new ComponentContent(
      this.getUIContext(),
      wrapBuilder(refreshIndicatorContent),
      this.refreshIndicatorParams,
    );
  }

  @Builder
  defaultRow(_item: Object, _index: number): void {
    Row().height(0);
  }

  @Builder
  defaultEmptyBuilder(): void {
  }

  @Builder
  defaultEmptyState(): void {
    Column() {
      Text(this.emptyText)
        .fontSize(15) // TODO: 字号 15 暂无 token 映射
        .fontColor(GSYColor.mediumText);
    }
    .width('100%')
    .height(240)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  buildFooter(): void {
    if (this.controller.footerState === PullLoadMoreFooterState.LOADING) {
      Row() {
        if (this.controller.loadingMoreActive) {
          LoadingProgress()
            .id('pull_load_more_indicator')
            .width(24)
            .height(24)
            .color(GSYColor.primary);
        }
        Text(this.loadingMoreText)
          .id('pull_load_more_text')
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.mediumDarkText)
          .margin({ left: this.controller.loadingMoreActive ? 8 : 0 });
      }
      .width('100%')
      .height(50)
      .justifyContent(FlexAlign.Center);
    } else if (this.controller.footerState === PullLoadMoreFooterState.END
      && this.dataSource && this.dataSource.length > 0) {
      Row() {
        Text(this.loadEndText)
          .id('pull_load_more_end_text')
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.lightText);
      }
      .width('100%')
      .height(50)
      .justifyContent(FlexAlign.Center);
    }
  }

  @Builder
  buildRefreshIndicator(): void {
    refreshIndicatorContent(this.refreshIndicatorParams);
  }

  build(): void {
    Stack({ alignContent: Alignment.Top }) {
      Refresh({
        refreshing: $$this.controller.nativeRefreshing,
        refreshingContent: this.refreshContentNode,
      }) {
        List({ space: 0, scroller: this.listScroller }) {
          ListItem() {
            this.renderHeader();
          }

          if (this.dataSource && this.dataSource.length > 0) {
            ForEach(this.dataSource, (item: Object, index: number): void => {
              ListItem() {
                this.renderRow(item, index);
              }
            }, (item: Object, index: number): string => {
              // 修复「下拉切换不刷新列表」：ForEach 用 index 当 key 时，长度相同/重叠
              // 范围内的 ListItem 会被 ArkUI 复用，renderRow 不重跑。改用 item 内容
              // 的 JSON 摘要 + index 作 key，保证 dataSource 引用变化后整体重建。
              const tag: string = JSON.stringify(item);
              return index.toString() + '_' + (tag.length > 96 ? tag.substring(0, 96) : tag);
            });
          } else {
            ListItem() {
              this.renderEmpty();
            }
          }

          ListItem() {
            this.buildFooter();
          }

          if (this.tailPadding > 0) {
            ListItem() {
              Row().height(this.tailPadding);
            }
          }
        }
        .width('100%')
        .height('100%')
        .edgeEffect(EdgeEffect.Spring)
        .onReachEnd((): void => {
          if (this.controller.refreshing) {
            return;
          }
          if (this.controller.loadingMoreActive) {
            return;
          }
          if (this.controller.footerState !== PullLoadMoreFooterState.LOADING) {
            return;
          }
          if (!this.dataSource || this.dataSource.length === 0) {
            return;
          }
          this.controller.beginLoadMore();
          try {
            this.loadMore();
          } catch (_e) {
            this.controller.loadingMoreActive = false;
          }
        });
      }
      .onStateChange((state: RefreshStatus): void => {
        if (state === RefreshStatus.Refresh) {
          this.controller.nativeRefreshing = false;
          if (!this.enableRefresh) {
            this.controller.refreshing = false;
            return;
          }
          this.controller.refreshing = true;
          this.controller.setFooterState(PullLoadMoreFooterState.HIDE);
          this.refresh();
        }
      });

      if (this.controller.refreshing) {
        Stack({ alignContent: Alignment.Center }) {
          LoadingProgress()
            .id('pull_refresh_indicator')
            .width(20)
            .height(20)
            .color(GSYColor.primary);
        }
        .id('pull_refresh_overlay')
        .width('100%')
        .height(40)
        .hitTestBehavior(HitTestMode.Transparent);
      }
    }
    .width('100%')
    .height('100%');
  }
}
