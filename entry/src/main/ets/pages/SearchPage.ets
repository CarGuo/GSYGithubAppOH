/**
 * SearchPage follows the Compose SearchScreen:
 * top app bar, GitHub search input, search history for an empty query,
 * Repository/User type buttons, and a pull list for the selected result type.
 */

import { I18n } from '../i18n/I18n';
import { PullLoadMoreList, PullLoadMoreController } from '../common/PullLoadMoreList';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { RecommendRepo } from '../store/RecommendStore';
import {
  SearchStore,
  SearchTab,
  SEARCH_TAB_REPO,
  SEARCH_TAB_USER,
  SearchUserItem,
} from '../store/SearchStore';
import { SearchService } from '../service/SearchService';
import { IconFont, FA_SEARCH, FA_TIMES } from '../common/IconFont';
import { AppBar } from '../common/AppBar';
import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';
import { RepositoryItem } from '../widget/RepositoryItem';
import { UserItem, UserItemData } from '../widget/UserItem';
import { SearchHistory, SearchHistoryManager } from '../utils/SearchHistory';

interface RepositoryDetailRouteParam {
  reposOwner: string;
  reposName: string;
  fullName: string;
}

interface UserDetailRouteParam {
  login: string;
}

const SEARCH_HEADER_HEIGHT: number = 56;
const SEARCH_INPUT_HEIGHT: number = 52;
const SEGMENT_BAR_RADIUS: number = 4;
const SPACER_HEIGHT: number = 2;
const SEARCH_ICON_SIZE: number = 24;
const SEARCH_PAGE_PADDING: number = 16;
const SEARCH_TYPE_BUTTON_HEIGHT: number = 40;

export class SearchPageDeps {
  private static storeImpl: SearchStore = new SearchStore();
  private static serviceImpl: SearchService | null = null;
  private static historyImpl: SearchHistoryManager = SearchHistory;

  static setStore(store: SearchStore): void {
    SearchPageDeps.storeImpl = store;
    SearchPageDeps.serviceImpl = null;
  }

  static setService(service: SearchService): void {
    SearchPageDeps.serviceImpl = service;
  }

  static setHistory(history: SearchHistoryManager): void {
    SearchPageDeps.historyImpl = history;
  }

  static getStore(): SearchStore {
    return SearchPageDeps.storeImpl;
  }

  static getService(): SearchService {
    if (SearchPageDeps.serviceImpl === null) {
      SearchPageDeps.serviceImpl = new SearchService(SearchPageDeps.storeImpl);
    }
    return SearchPageDeps.serviceImpl;
  }

  static getHistory(): SearchHistoryManager {
    return SearchPageDeps.historyImpl;
  }

  static reset(): void {
    SearchPageDeps.storeImpl = new SearchStore();
    SearchPageDeps.serviceImpl = null;
    SearchPageDeps.historyImpl = SearchHistory;
  }
}

@Component
export struct SearchPage {
  @State store: SearchStore = SearchPageDeps.getStore();
  @State plmController: PullLoadMoreController = new PullLoadMoreController();
  @State queryText: string = '';
  @State currentTab: SearchTab = SEARCH_TAB_REPO;
  @State submittedQuery: string = '';
  @State historyItems: string[] = [];
  @State searchFocused: boolean = false;
  private service: SearchService = SearchPageDeps.getService();
  private history: SearchHistoryManager = SearchPageDeps.getHistory();

  aboutToAppear(): void {
    this.service = SearchPageDeps.getService();
    this.history = SearchPageDeps.getHistory();
    this.loadSearchHistory();
  }

  private isEmptyQuery(): boolean {
    return this.submittedQuery === null || this.submittedQuery.length === 0;
  }

  private async loadSearchHistory(): Promise<void> {
    this.historyItems = await this.history.list();
  }

  private hasTypedQuery(): boolean {
    return this.queryText.trim().length > 0;
  }

  private clearSearchInput(): void {
    this.queryText = '';
    this.submittedQuery = '';
    this.currentTab = SEARCH_TAB_REPO;
    this.store.reset();
    this.plmController.refreshComplete(false, false);
  }

  private async submitSearch(text: string): Promise<void> {
    const trimmed: string = text !== null && text !== undefined ? text.trim() : '';
    if (trimmed.length === 0) {
      this.submittedQuery = '';
      this.store.setQuery('');
      this.plmController.refreshComplete(false, false);
      return;
    }
    this.queryText = trimmed;
    this.submittedQuery = trimmed;
    this.store.setQuery(trimmed);
    this.plmController.showRefreshState();
    const ok: boolean = await this.service.searchByTab(this.currentTab, trimmed, null, 1);
    if (ok) {
      this.historyItems = await this.history.add(trimmed);
    }
    this.plmController.refreshComplete(this.store.hasMore, true);
  }

  private async switchTab(tab: SearchTab): Promise<void> {
    if (tab !== this.currentTab) {
      this.currentTab = tab;
      this.store.setTab(tab);
    }
    if (!this.hasTypedQuery()) {
      return;
    }
    await this.submitSearch(this.queryText);
  }

  private async loadMore(): Promise<void> {
    if (this.isEmptyQuery()) {
      this.plmController.loadMoreComplete(false);
      return;
    }
    if (!this.store.hasMore) {
      this.plmController.loadMoreComplete(false);
      return;
    }
    const next: number = this.store.page + 1;
    await this.service.searchByTab(this.currentTab, this.submittedQuery, null, next);
    this.plmController.loadMoreComplete(this.store.hasMore);
  }

  private async refresh(): Promise<void> {
    if (this.isEmptyQuery()) {
      this.plmController.refreshComplete(false, false);
      return;
    }
    await this.service.searchByTab(this.currentTab, this.submittedQuery, null, 1);
    this.plmController.refreshComplete(this.store.hasMore, true);
  }

  private onRepoRowTap(item: RecommendRepo): void {
    const ownerLogin: string = item.owner !== null && item.owner !== undefined ? item.owner.login : '';
    const param: RepositoryDetailRouteParam = {
      reposOwner: ownerLogin,
      reposName: item.name,
      fullName: item.full_name,
    };
    NavigationService.push(RouteName.RepositoryDetail, param as Object);
  }

  private onUserRowTap(item: SearchUserItem): void {
    const param: UserDetailRouteParam = { login: item.login };
    NavigationService.push(RouteName.UserDetail, param as Object);
  }

  @Builder
  buildRepoRow(item: RecommendRepo, index: number): void {
    RepositoryItem({
      ownerName: item.owner.login,
      ownerPic: item.owner.avatar_url,
      repositoryName: item.full_name !== null && item.full_name !== undefined && item.full_name.length > 0
        ? item.full_name
        : item.name,
      repositoryStar: item.stargazers_count.toString(),
      repositoryFork: item.forks_count.toString(),
      repositoryWatch: item.watchers_count.toString(),
      repositoryType: item.language !== null && item.language !== undefined && item.language.length > 0
        ? item.language
        : '---',
      repositoryDes: item.description !== null && item.description !== undefined && item.description.length > 0
        ? item.description
        : '---',
      rowId: 'search_repo_' + index.toString(),
      onPressItem: (): void => this.onRepoRowTap(item),
    });
  }

  @Builder
  buildUserRow(item: SearchUserItem, index: number): void {
    UserItem({
      data: {
        login: item.login,
        avatar_url: item.avatar_url,
        html_url: item.html_url,
        desc: '',
      } as UserItemData,
      rowId: 'search_user_' + index.toString(),
      onPress: (): void => this.onUserRowTap(item),
    });
  }

  @Builder
  buildEmpty(): void {
    Column() {
      Text(I18n('listEmpty'))
        .id('search_empty_text')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.subText);
    }
    .id('search_empty_root')
    .width('100%')
    .padding({ top: GSYSpacing.tabBarHeight, bottom: GSYSpacing.tabBarHeight })
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  buildHistory(): void {
    Column() {
      Text(I18n('searchHistory'))
        .id('search_history_title')
        .fontSize(GSYFontSize.normal)
        .fontWeight(FontWeight.Bold)
        .fontColor(GSYColor.mainText)
        .width('100%')
        .margin({ bottom: GSYSpacing.halfEdge });
      ForEach(this.historyItems, (item: string, index: number): void => {
        Column() {
          Text(item)
            .id('search_history_text_' + index.toString())
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.mainText)
            .width('100%')
            .padding({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge });
          Divider()
            .color(GSYColor.line)
            .strokeWidth(0.5);
        }
        .id('search_history_row_' + index.toString())
        .width('100%')
        .onClick((): void => {
          this.queryText = item;
          this.submitSearch(item);
        });
      }, (item: string): string => item);
    }
    .id('search_history_list')
    .width('100%')
    .padding({
      left: SEARCH_PAGE_PADDING,
      right: SEARCH_PAGE_PADDING,
      top: GSYSpacing.normalEdge,
    });
  }

  @Builder
  buildTypeButtons(): void {
    Row() {
      Button(I18n('searchRepos'))
        .id('search_type_repo_btn')
        .layoutWeight(1)
        .height(SEARCH_TYPE_BUTTON_HEIGHT)
        .fontSize(GSYFontSize.small)
        .fontColor(this.hasTypedQuery() && this.currentTab === SEARCH_TAB_REPO
          ? GSYColor.textWhite : GSYColor.subText)
        .backgroundColor(this.hasTypedQuery() && this.currentTab === SEARCH_TAB_REPO
          ? GSYColor.primary : GSYColor.surfacePill)
        .enabled(this.hasTypedQuery())
        .onClick((): void => {
          this.switchTab(SEARCH_TAB_REPO);
        });

      Blank()
        .width(GSYSpacing.normalEdge);

      Button(I18n('searchUser'))
        .id('search_type_user_btn')
        .layoutWeight(1)
        .height(SEARCH_TYPE_BUTTON_HEIGHT)
        .fontSize(GSYFontSize.small)
        .fontColor(this.hasTypedQuery() && this.currentTab === SEARCH_TAB_USER
          ? GSYColor.textWhite : GSYColor.subText)
        .backgroundColor(this.hasTypedQuery() && this.currentTab === SEARCH_TAB_USER
          ? GSYColor.primary : GSYColor.surfacePill)
        .enabled(this.hasTypedQuery())
        .onClick((): void => {
          this.switchTab(SEARCH_TAB_USER);
        });
    }
    .id('search_type_button_row')
    .width('100%')
    .padding({
      left: SEARCH_PAGE_PADDING,
      right: SEARCH_PAGE_PADDING,
      top: GSYSpacing.normalEdge,
    });
  }

  @Builder
  buildSearchHeader(): void {
    Row() {
      TextInput({ text: this.queryText, placeholder: I18n('searchHint') })
        .id('search_input')
        .layoutWeight(1)
        .height(SEARCH_INPUT_HEIGHT)
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.primary)
        .placeholderColor(GSYColor.subText)
        .placeholderFont({ size: GSYFontSize.small })
        .caretColor(GSYColor.primary)
        .backgroundColor(GSYColor.white)
        .borderRadius(3)
        .padding({
          left: GSYSpacing.halfEdge,
          right: GSYSpacing.halfEdge,
        })
        .margin({
          left: GSYSpacing.halfEdge,
          right: GSYSpacing.halfEdge,
        })
        .enterKeyType(EnterKeyType.Search)
        .onChange((value: string): void => {
          this.queryText = value;
          if (value === null || value.length === 0) {
            this.clearSearchInput();
          }
        })
        .onFocus((): void => {
          this.searchFocused = true;
        })
        .onBlur((): void => {
          this.searchFocused = false;
        })
        .onSubmit((): void => {
          this.submitSearch(this.queryText);
        });

      Column() {
        IconFont({
          char: this.hasTypedQuery() ? FA_TIMES : FA_SEARCH,
          glyphSize: SEARCH_ICON_SIZE,
          glyphColor: GSYColor.mainText,
        })
          .id(this.hasTypedQuery() ? 'search_clear_icon' : 'search_submit_icon');
      }
      .id('search_submit_btn')
      .margin({
        left: GSYSpacing.normalEdge,
        right: GSYSpacing.normalEdge,
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick((): void => {
        if (this.hasTypedQuery()) {
          this.clearSearchInput();
        }
      });
    }
    .id('search_header_row')
    .width('auto')
    .height(SEARCH_HEADER_HEIGHT)
    .margin({
      left: SEARCH_PAGE_PADDING,
      right: SEARCH_PAGE_PADDING,
      top: GSYSpacing.normalEdge,
    })
    .backgroundColor(GSYColor.white)
    .border({
      width: GSYSpacing.dividerThickness,
      color: GSYColor.divider,
    })
    .borderRadius(SEGMENT_BAR_RADIUS)
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  buildContent(): void {
    Column() {
      AppBar({
        title: I18n('search'),
        showBack: true,
        immersive: true,
        useTheme: true,
        titleStart: true,
        onBack: (): void => {
          NavigationService.pop();
        }
      });

      this.buildSearchHeader();

      if (this.queryText.trim().length === 0) {
        if (this.searchFocused && this.historyItems.length > 0) {
          this.buildHistory();
        } else {
          this.buildTypeButtons();
        }
      } else {
        this.buildTypeButtons();

        Row()
          .id('search_segment_spacer')
          .width('100%')
          .height(SPACER_HEIGHT)
          .opacity(0.3);

        if (this.currentTab === SEARCH_TAB_REPO) {
          PullLoadMoreList({
            dataSource: this.store.repos,
            controller: this.plmController,
            renderRow: (item: Object, index: number): void => this.buildRepoRow(item as RecommendRepo, index),
            renderEmpty: (): void => this.buildEmpty(),
            refresh: (): void => {
              this.refresh();
            },
            loadMore: (): void => {
              this.loadMore();
            },
          })
            .id('search_pull_list_repo')
            .layoutWeight(1);
        } else {
          PullLoadMoreList({
            dataSource: this.store.users,
            controller: this.plmController,
            renderRow: (item: Object, index: number): void => this.buildUserRow(item as SearchUserItem, index),
            renderEmpty: (): void => this.buildEmpty(),
            refresh: (): void => {
              this.refresh();
            },
            loadMore: (): void => {
              this.loadMore();
            },
          })
            .id('search_pull_list_user')
            .layoutWeight(1);
        }
      }
    }
    .id('search_main_column')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.mainBackground);
  }

  build(): void {
    Column() {
      this.buildContent();
    }
    .id('search_page_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.mainBackground);
  }
}
