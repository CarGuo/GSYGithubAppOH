/**
 * ReleasePage —— 严格对齐 RN 端
 * [components/ReleasePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ReleasePage.js)
 *
 * 双 Tab：reposRelease / reposTag。
 * 列表项 [ReleaseItem.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/widget/ReleaseItem.ets)
 *   - actionTitle = name || tag_name
 *   - actionTime  = published_at
 *   - actionTarget / actionTargetHtml = body / body_html
 * 数据源 [RepositoryService.fetchRepositoryRelease/fetchRepositoryTag](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/service/RepositoryService.ets)
 */

import { I18n } from '../i18n/I18n';
import { AppBar } from '../common/AppBar';
import { NavigationService } from '../navigation/NavigationService';
import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';
import { PullLoadMoreController, PullLoadMoreList } from '../common/PullLoadMoreList';
import { ReleaseItem } from '../widget/ReleaseItem';
import {
  RepositoryService,
  ReleaseListItem,
  FetchReleaseListResult,
} from '../service/RepositoryService';
import { Logger } from '../ai-debug/Logger';

interface ReleaseRouteParam {
  ownerName?: string;
  repositoryName?: string;
  reposOwner?: string;
  reposName?: string;
}

interface ReleaseTabItem {
  key: string;
  title: string;
  index: number;
}

const TAB_BAR_HEIGHT: number = 48;
const PAGE_SIZE: number = 30;

@Component
export struct ReleasePage {
  @State ownerName: string = '';
  @State repositoryName: string = '';
  @State currentIndex: number = 0;
  @State releaseItems: ReleaseListItem[] = [];
  @State tagItems: ReleaseListItem[] = [];
  @State releasePage: number = 1;
  @State tagPage: number = 1;
  @State releaseHasMore: boolean = true;
  @State tagHasMore: boolean = true;
  @State releaseController: PullLoadMoreController = new PullLoadMoreController();
  @State tagController: PullLoadMoreController = new PullLoadMoreController();

  private tabsController: TabsController = new TabsController();
  private tabs: ReleaseTabItem[] = [
    { key: 'release', title: I18n('reposRelease'), index: 0 },
    { key: 'tag', title: I18n('reposTag'), index: 1 },
  ];

  private resolveParam(ctx: NavDestinationContext): void {
    const info: NavPathInfo | undefined = ctx.pathInfo;
    if (info === undefined || info === null) {
      return;
    }
    const param: Object | undefined = info.param as Object | undefined;
    if (param === undefined || param === null) {
      return;
    }
    const obj: ReleaseRouteParam = param as ReleaseRouteParam;
    if (obj.ownerName !== undefined && obj.ownerName !== null && obj.ownerName.length > 0) {
      this.ownerName = obj.ownerName;
    } else if (obj.reposOwner !== undefined && obj.reposOwner !== null) {
      this.ownerName = obj.reposOwner;
    }
    if (obj.repositoryName !== undefined && obj.repositoryName !== null && obj.repositoryName.length > 0) {
      this.repositoryName = obj.repositoryName;
    } else if (obj.reposName !== undefined && obj.reposName !== null) {
      this.repositoryName = obj.reposName;
    }
    Logger.i('ReleasePage', 'param resolved owner=' + this.ownerName + ' repo=' + this.repositoryName);
  }

  private async refreshRelease(): Promise<void> {
    if (this.ownerName.length === 0 || this.repositoryName.length === 0) {
      return;
    }
    this.releaseController.showRefreshState();
    const res: FetchReleaseListResult = await RepositoryService.fetchRepositoryRelease(
      this.ownerName, this.repositoryName, 1);
    if (res.result) {
      this.releaseItems = res.data.slice();
      this.releasePage = 1;
      this.releaseHasMore = res.data.length >= PAGE_SIZE;
    } else {
      Logger.w('ReleasePage', 'refreshRelease failed code=' + res.code + ' msg=' + res.msg);
    }
    this.releaseController.refreshComplete(this.releaseHasMore, false);
  }

  private async loadMoreRelease(): Promise<void> {
    if (!this.releaseHasMore) {
      this.releaseController.loadMoreComplete(false);
      return;
    }
    const next: number = this.releasePage + 1;
    const res: FetchReleaseListResult = await RepositoryService.fetchRepositoryRelease(
      this.ownerName, this.repositoryName, next);
    if (res.result) {
      const merged: ReleaseListItem[] = this.releaseItems.slice();
      for (let i: number = 0; i < res.data.length; i++) {
        merged.push(res.data[i]);
      }
      this.releaseItems = merged;
      this.releasePage = next;
      this.releaseHasMore = res.data.length >= PAGE_SIZE;
    }
    this.releaseController.loadMoreComplete(this.releaseHasMore);
  }

  private async refreshTag(): Promise<void> {
    if (this.ownerName.length === 0 || this.repositoryName.length === 0) {
      return;
    }
    this.tagController.showRefreshState();
    const res: FetchReleaseListResult = await RepositoryService.fetchRepositoryTag(
      this.ownerName, this.repositoryName, 1);
    if (res.result) {
      this.tagItems = res.data.slice();
      this.tagPage = 1;
      this.tagHasMore = res.data.length >= PAGE_SIZE;
    } else {
      Logger.w('ReleasePage', 'refreshTag failed code=' + res.code + ' msg=' + res.msg);
    }
    this.tagController.refreshComplete(this.tagHasMore, false);
  }

  private async loadMoreTag(): Promise<void> {
    if (!this.tagHasMore) {
      this.tagController.loadMoreComplete(false);
      return;
    }
    const next: number = this.tagPage + 1;
    const res: FetchReleaseListResult = await RepositoryService.fetchRepositoryTag(
      this.ownerName, this.repositoryName, next);
    if (res.result) {
      const merged: ReleaseListItem[] = this.tagItems.slice();
      for (let i: number = 0; i < res.data.length; i++) {
        merged.push(res.data[i]);
      }
      this.tagItems = merged;
      this.tagPage = next;
      this.tagHasMore = res.data.length >= PAGE_SIZE;
    }
    this.tagController.loadMoreComplete(this.tagHasMore);
  }

  @Builder
  buildTabBar(item: ReleaseTabItem): void {
    Column() {
      Text(item.title)
        .fontSize(GSYFontSize.small)
        .fontColor(this.currentIndex === item.index ? GSYColor.primary : GSYColor.subText)
        .fontWeight(this.currentIndex === item.index ? FontWeight.Bold : FontWeight.Normal)
        .layoutWeight(1);
      Divider()
        .strokeWidth(GSYSpacing.tabIndicatorThickness)
        .color(this.currentIndex === item.index ? GSYColor.primary : Color.Transparent)
        .width('100%');
    }
    .id('release_tab_bar_' + item.key)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End);
  }

  @Builder
  buildReleaseRow(item: Object, index: number): void {
    ReleaseItem({
      actionTime: (item as ReleaseListItem).publishedAt,
      actionTitle: (item as ReleaseListItem).resolveTitle(),
      actionTarget: (item as ReleaseListItem).bodyHtml,
      actionTargetHtml: (item as ReleaseListItem).bodyHtml,
      rowId: 'release_item_release_' + index.toString(),
    });
  }

  @Builder
  buildTagRow(item: Object, index: number): void {
    ReleaseItem({
      actionTime: (item as ReleaseListItem).publishedAt,
      actionTitle: (item as ReleaseListItem).resolveTitle(),
      actionTarget: (item as ReleaseListItem).bodyHtml,
      actionTargetHtml: (item as ReleaseListItem).bodyHtml,
      rowId: 'release_item_tag_' + index.toString(),
    });
  }

  build(): void {
    NavDestination() {
      Column() {
        AppBar({
          title: this.repositoryName.length > 0 ? this.repositoryName : I18n('reposRelease'),
          showBack: true,
          onBack: (): void => {
            NavigationService.pop();
          },
        });
        Tabs({
          barPosition: BarPosition.Start,
          index: this.currentIndex,
          controller: this.tabsController,
        }) {
          TabContent() {
            PullLoadMoreList({
              dataSource: this.releaseItems,
              controller: this.releaseController,
              refresh: (): void => {
                this.refreshRelease();
              },
              loadMore: (): void => {
                this.loadMoreRelease();
              },
              renderRow: (item: Object, index: number): void => {
                this.buildReleaseRow(item, index);
              },
            })
              .id('release_page_release_list');
          }
          .tabBar(this.buildTabBar(this.tabs[0]));

          TabContent() {
            PullLoadMoreList({
              dataSource: this.tagItems,
              controller: this.tagController,
              refresh: (): void => {
                this.refreshTag();
              },
              loadMore: (): void => {
                this.loadMoreTag();
              },
              renderRow: (item: Object, index: number): void => {
                this.buildTagRow(item, index);
              },
            })
              .id('release_page_tag_list');
          }
          .tabBar(this.buildTabBar(this.tabs[1]));
        }
        .id('release_page_tabs')
        .barHeight(TAB_BAR_HEIGHT)
        .barMode(BarMode.Fixed)
        .scrollable(true)
        .layoutWeight(1)
        .onChange((index: number): void => {
          this.currentIndex = index;
          if (index === 1 && this.tagItems.length === 0) {
            this.refreshTag();
          }
        });
      }
      .id('release_page_root')
      .width('100%')
      .height('100%')
      .backgroundColor(GSYColor.mainBackground);
    }
    .hideTitleBar(true)
    .onBackPressed((): boolean => {
      NavigationService.pop();
      return true;
    })
    .onReady((ctx: NavDestinationContext): void => {
      this.resolveParam(ctx);
      this.refreshRelease();
    });
  }
}
