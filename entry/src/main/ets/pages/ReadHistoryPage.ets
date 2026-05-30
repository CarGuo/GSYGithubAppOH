import { I18n } from '../i18n/I18n';
import { AppBar } from '../common/AppBar';
import { PullLoadMoreList, PullLoadMoreController } from '../common/PullLoadMoreList';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { GSYColor } from '../style/Theme';
import { RepositoryItem } from '../widget/RepositoryItem';
import {
  ReadHistoryStore,
  ReadHistoryItem,
  READ_HISTORY_TYPE_REPO,
  READ_HISTORY_TYPE_USER
} from '../store/ReadHistoryStore';
import {
  ReadHistoryService,
  READ_HISTORY_PAGE_SIZE
} from '../service/ReadHistoryService';

export const READ_HISTORY_TAB_ALL: string = 'all';
export const READ_HISTORY_TAB_REPO: string = 'repo';
export const READ_HISTORY_TAB_USER: string = 'user';

export type ReadHistoryServiceFactory = (uiStore: ReadHistoryStore) => ReadHistoryService;

let readHistoryServiceFactory: ReadHistoryServiceFactory | null = null;

export function setReadHistoryServiceFactory(factory: ReadHistoryServiceFactory | null): void {
  readHistoryServiceFactory = factory;
}

function buildReadHistoryService(uiStore: ReadHistoryStore): ReadHistoryService {
  if (readHistoryServiceFactory !== null) {
    return (readHistoryServiceFactory as ReadHistoryServiceFactory)(uiStore);
  }
  return new ReadHistoryService(uiStore);
}

interface ReadHistoryRepoNavParam {
  fullName: string;
  owner: string;
  name: string;
}

interface ReadHistoryUserNavParam {
  login: string;
}

interface ReadHistoryTabItem {
  key: string;
  title: string;
  filterType: string;
}

interface ReadHistoryRepoPayloadOwner {
  login?: string;
  avatar_url?: string;
}

interface ReadHistoryRepoPayload {
  full_name?: string;
  name?: string;
  description?: string;
  language?: string;
  stargazers_count?: number;
  watchers_count?: number;
  forks_count?: number;
  owner?: ReadHistoryRepoPayloadOwner | null;
}

@Component
export struct ReadHistoryPage {
  @State store: ReadHistoryStore = new ReadHistoryStore();
  @State plmController: PullLoadMoreController = new PullLoadMoreController();
  private service: ReadHistoryService = buildReadHistoryService(this.store);
  private pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.service = buildReadHistoryService(this.store);
  }

  setServiceForTest(service: ReadHistoryService): void {
    this.service = service;
    this.service.bindStore(this.store);
  }

  private currentFilterType(): string {
    return READ_HISTORY_TYPE_REPO;
  }

  private async refreshList(): Promise<void> {
    this.plmController.showRefreshState();
    const filterType: string = this.currentFilterType();
    const res = await this.service.list(filterType.length > 0 ? filterType : undefined, 1,
      READ_HISTORY_PAGE_SIZE);
    const showLoadMore: boolean = res.result && this.store.list.length > 0 && this.store.hasMore;
    this.plmController.refreshComplete(showLoadMore, false);
  }

  private async loadMore(): Promise<void> {
    if (!this.store.hasMore) {
      this.plmController.loadMoreComplete(false);
      return;
    }
    const next: number = this.store.page + 1;
    const filterType: string = this.currentFilterType();
    await this.service.list(filterType.length > 0 ? filterType : undefined, next,
      READ_HISTORY_PAGE_SIZE);
    this.plmController.loadMoreComplete(this.store.hasMore);
  }

  private async onClearTap(): Promise<void> {
    const filterType: string = this.currentFilterType();
    await this.service.clear(filterType.length > 0 ? filterType : undefined);
    await this.refreshList();
  }

  private onRowTap(item: ReadHistoryItem): void {
    if (item.type === READ_HISTORY_TYPE_REPO) {
      const idx: number = item.key.indexOf('/');
      const owner: string = idx > 0 ? item.key.substring(0, idx) : '';
      const name: string = idx > 0 ? item.key.substring(idx + 1) : item.key;
      const param: ReadHistoryRepoNavParam = {
        'fullName': item.key,
        'owner': owner,
        'name': name,
      } as ReadHistoryRepoNavParam;
      NavigationService.push(RouteName.RepositoryDetail, param as Object);
    } else if (item.type === READ_HISTORY_TYPE_USER) {
      const param: ReadHistoryUserNavParam = {
        'login': item.key,
      } as ReadHistoryUserNavParam;
      NavigationService.push(RouteName.UserDetail, param as Object);
    }
  }

  private ownerNameOf(item: ReadHistoryItem): string {
    const idx: number = item.key.indexOf('/');
    return idx > 0 ? item.key.substring(0, idx) : '';
  }

  private repoNameOf(item: ReadHistoryItem): string {
    const idx: number = item.key.indexOf('/');
    return idx > 0 ? item.key.substring(idx + 1) : item.key;
  }

  private safeText(value: string | null | undefined): string {
    return value !== null && value !== undefined ? value : '';
  }

  private safeCount(value: number | null | undefined): string {
    return value !== null && value !== undefined ? value.toString() : '0';
  }

  private repoPayloadOf(item: ReadHistoryItem): ReadHistoryRepoPayload | null {
    if (item.payloadJson === null || item.payloadJson === undefined || item.payloadJson.length === 0) {
      return null;
    }
    try {
      return JSON.parse(item.payloadJson) as ReadHistoryRepoPayload;
    } catch (_e) {
      return null;
    }
  }

  private repoFullNameOf(item: ReadHistoryItem): string {
    const payload: ReadHistoryRepoPayload | null = this.repoPayloadOf(item);
    if (payload !== null) {
      const fullName: string = this.safeText((payload as ReadHistoryRepoPayload).full_name);
      if (fullName.length > 0) {
        return fullName;
      }
    }
    return item.key.length > 0 ? item.key : this.repoNameOf(item);
  }

  private repoOwnerNameOf(item: ReadHistoryItem): string {
    const payload: ReadHistoryRepoPayload | null = this.repoPayloadOf(item);
    if (payload !== null) {
      const owner = (payload as ReadHistoryRepoPayload).owner;
      if (owner !== null && owner !== undefined) {
        const login: string = this.safeText((owner as ReadHistoryRepoPayloadOwner).login);
        if (login.length > 0) {
          return login;
        }
      }
    }
    return this.ownerNameOf(item);
  }

  private repoOwnerPicOf(item: ReadHistoryItem): string {
    const payload: ReadHistoryRepoPayload | null = this.repoPayloadOf(item);
    if (payload !== null) {
      const owner = (payload as ReadHistoryRepoPayload).owner;
      if (owner !== null && owner !== undefined) {
        const avatar: string = this.safeText((owner as ReadHistoryRepoPayloadOwner).avatar_url);
        if (avatar.length > 0) {
          return avatar;
        }
      }
    }
    return item.avatar;
  }

  private repoDescriptionOf(item: ReadHistoryItem): string {
    const payload: ReadHistoryRepoPayload | null = this.repoPayloadOf(item);
    if (payload !== null) {
      const des: string = this.safeText((payload as ReadHistoryRepoPayload).description);
      if (des.length > 0) {
        return des;
      }
    }
    return item.subtitle.length > 0 ? item.subtitle : item.key;
  }

  private repoLanguageOf(item: ReadHistoryItem): string {
    const payload: ReadHistoryRepoPayload | null = this.repoPayloadOf(item);
    if (payload !== null) {
      const lang: string = this.safeText((payload as ReadHistoryRepoPayload).language);
      if (lang.length > 0) {
        return lang;
      }
    }
    return '---';
  }

  private repoStarOf(item: ReadHistoryItem): string {
    const payload: ReadHistoryRepoPayload | null = this.repoPayloadOf(item);
    return payload !== null ? this.safeCount((payload as ReadHistoryRepoPayload).stargazers_count) : '0';
  }

  private repoForkOf(item: ReadHistoryItem): string {
    const payload: ReadHistoryRepoPayload | null = this.repoPayloadOf(item);
    return payload !== null ? this.safeCount((payload as ReadHistoryRepoPayload).forks_count) : '0';
  }

  private repoWatchOf(item: ReadHistoryItem): string {
    const payload: ReadHistoryRepoPayload | null = this.repoPayloadOf(item);
    return payload !== null ? this.safeCount((payload as ReadHistoryRepoPayload).watchers_count) : '0';
  }

  @Builder
  rowBuilder(item: ReadHistoryItem, index: number): void {
    RepositoryItem({
      ownerName: this.repoOwnerNameOf(item),
      ownerPic: this.repoOwnerPicOf(item),
      repositoryName: this.repoFullNameOf(item),
      repositoryStar: this.repoStarOf(item),
      repositoryFork: this.repoForkOf(item),
      repositoryWatch: this.repoWatchOf(item),
      repositoryType: this.repoLanguageOf(item),
      repositoryDes: this.repoDescriptionOf(item),
      rowId: 'read_history_row_' + index.toString(),
      onPressItem: (): void => {
        this.onRowTap(item);
      },
    });
  }

  @Builder
  emptyBuilder(): void {
    Column()
    .id('read_history_empty_root')
    .width('100%')
    .height(1);
  }

  build(): void {
    NavDestination() {
      Column() {
        AppBar({
          title: I18n('history'),
          showBack: true,
          onBack: (): void => {
            NavigationService.pop();
          },
        })
          .id('read_history_appbar');

        PullLoadMoreList({
          dataSource: this.store.list,
          controller: this.plmController,
          renderRow: (item: Object, index: number): void =>
            this.rowBuilder(item as ReadHistoryItem, index),
          renderEmpty: (): void => this.emptyBuilder(),
          refresh: (): void => {
            this.refreshList();
          },
          loadMore: (): void => {
            this.loadMore();
          },
        })
          .id('read_history_pull_list')
          .layoutWeight(1);
      }
      .id('read_history_root')
      .width('100%')
      .height('100%')
      .backgroundColor(GSYColor.white);
    }
    .onReady((ctx: NavDestinationContext): void => {
      const stack: NavPathStack | undefined = ctx.pathStack;
      if (stack !== undefined && stack !== null) {
        this.pathStack = stack;
      }
      this.refreshList();
    });
  }
}
