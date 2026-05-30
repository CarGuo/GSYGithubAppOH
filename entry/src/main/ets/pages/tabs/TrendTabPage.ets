/**
 * TrendTabPage —— 对齐 Android Compose TrendingScreen。
 *
 * Compose 版固定加载 daily + all-language 趋势仓库，不渲染 RN 版的
 * daily/weekly/monthly 与 language 双下拉过滤条，也不支持 load more。
 */
import { I18n } from '../../i18n/I18n';
import { PullLoadMoreList, PullLoadMoreController } from '../../common/PullLoadMoreList';
import { NavigationService } from '../../navigation/NavigationService';
import { RouteName } from '../../navigation/Routes';
import {
  TrendRepo,
  TrendStore,
  TREND_SINCE_DAILY,
  TREND_LANGUAGE_ALL,
  fullNameOf,
} from '../../store/TrendStore';
import { TrendService, FetchTrendingResult } from '../../service/TrendService';
import { GSYColor, GSYFontSize, GSYIconSize, GSYShadow, GSYSpacing } from '../../style/Theme';
import { UserImage } from '../../widget/UserImage';
import { HTMLView } from '../../common/HTMLView';
import { CommonIconButton } from '../../common/CommonIconButton';
import { FA_CODE_FORK, FA_STAR_O } from '../../common/IconFont';

@Component
export struct TrendTabPage {
  @State store: TrendStore = new TrendStore();
  @State plmController: PullLoadMoreController = new PullLoadMoreController();
  // page 直接持有数组快照，每次 fetch 完整体替换。
  // 原因：@State store 这个整对象引用未变 → build 不重跑 → PullLoadMoreList 一直
  // 拿的是首次 build 时的 store.list 引用，store 内部 this.list = repos.slice()
  // 改动检测不到。
  @State displayList: TrendRepo[] = [];
  private service: TrendService = new TrendService(this.store);

  aboutToAppear(): void {
    this.service = new TrendService(this.store);
    this.triggerRefresh();
  }

  private async triggerRefresh(): Promise<void> {
    this.plmController.showRefreshState();
    const res: FetchTrendingResult = await this.service.fetchTrending(TREND_SINCE_DAILY, TREND_LANGUAGE_ALL);
    this.plmController.refreshComplete(false, false);
    this.displayList = this.store.list.slice();
    if (!res.result && res.data.length === 0) {
      return;
    }
  }

  private onRowClick(item: TrendRepo): void {
    const fullName: string = fullNameOf(item);
    if (fullName.length === 0) {
      return;
    }
    const idx: number = fullName.indexOf('/');
    const ownerName: string = idx > 0 ? fullName.substring(0, idx) : '';
    const repoName: string = idx > 0 ? fullName.substring(idx + 1) : fullName;
    const repoParam: Record<string, Object> = {
      'ownerName': ownerName,
      'repositoryName': repoName,
      'owner': ownerName,
      'name': repoName,
      'fullName': fullName,
    };
    NavigationService.push(RouteName.RepositoryDetail, repoParam);
  }

  @Builder
  rowBuilder(item: TrendRepo, index: number): void {
    Column() {
      Row() {
        UserImage({
          uri: item.avatar,
          loginUser: item.author,
          imageSize: 40,
          imageId: 'trend_row_avatar_' + index.toString(),
        })
          .margin({ right: GSYSpacing.normalEdge });

        Column() {
          Text(fullNameOf(item))
            .id('trend_row_full_' + index.toString())
            .width('100%')
            .fontSize(GSYFontSize.normal)
            .fontColor(GSYColor.primary)
            .fontWeight(FontWeight.Medium)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          if (item.language && item.language.length > 0) {
            Text(item.language)
              .id('trend_row_lang_' + index.toString())
              .fontSize(GSYFontSize.small)
              .fontColor(GSYColor.subText)
              .margin({ top: 2 });
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      if (item.description && item.description.length > 0) {
        HTMLView({
          value: item.description,
          fontSize: GSYFontSize.middleWhite,
          fontColor: GSYColor.mainText,
          maxLines: 2,
          viewId: 'trend_row_desc_' + index.toString(),
        })
          .width('100%')
          .margin({ top: GSYSpacing.halfEdge });
      }

      Row() {
        Row() {
          CommonIconButton({
            icon: FA_STAR_O,
            iconColor: GSYColor.subText,
            iconSize: GSYIconSize.minIcon,
            text: item.stars.toString(),
            textColor: GSYColor.subText,
            textFontSize: GSYFontSize.small,
          });
        }
        .id('trend_row_star_' + index.toString());

        Row() {
          CommonIconButton({
            icon: FA_CODE_FORK,
            iconColor: GSYColor.subText,
            iconSize: GSYIconSize.minIcon,
            text: item.forks.toString(),
            textColor: GSYColor.subText,
            textFontSize: GSYFontSize.small,
          });
        }
        .id('trend_row_fork_' + index.toString())
        .margin({ left: GSYSpacing.normalEdge });
      }
      .width('100%')
      .margin({ top: GSYSpacing.halfEdge });
    }
    .id('trend_row_' + index.toString())
    .width('auto')
    .padding(GSYSpacing.normalEdge)
    .margin({
      left: GSYSpacing.halfEdge,
      right: GSYSpacing.halfEdge,
      top: GSYSpacing.halfEdge,
      bottom: GSYSpacing.halfEdge,
    })
    .borderRadius(4)
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
    .alignItems(HorizontalAlign.Start)
    .onClick((): void => {
      this.onRowClick(item);
    });
  }

  @Builder
  emptyBuilder(): void {
    Column() {
      Text(I18n('listEmpty'))
        .id('trend_empty_text')
        .fontSize(GSYFontSize.middleWhite)
        .fontColor(GSYColor.subText);
    }
    .id('trend_empty_root')
    .width('100%')
    .height(240)
    .justifyContent(FlexAlign.Center);
  }

  build(): void {
    Column() {
      PullLoadMoreList({
        dataSource: this.displayList,
        controller: this.plmController,
        renderRow: (item: Object, index: number): void => this.rowBuilder(item as TrendRepo, index),
        renderEmpty: (): void => this.emptyBuilder(),
        refresh: (): void => {
          this.triggerRefresh();
        },
        loadMore: (): void => {
          this.plmController.loadMoreComplete(false);
        },
        refreshingText: I18n('refreshing'),
        loadingMoreText: I18n('loadMoreing'),
        loadEndText: I18n('loadMoreEnd'),
        emptyText: I18n('listEmpty'),
      })
        .id('trend_pull_list')
        .layoutWeight(1);
    }
    .id('tab_page_root_trend')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.mainBackground);
  }
}
