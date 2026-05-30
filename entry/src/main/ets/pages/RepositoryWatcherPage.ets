import { PullLoadMoreController } from '../common/PullLoadMoreList';
import { GSYColor } from '../style/Theme';
import { AppBar } from '../common/AppBar';
import {
  RepositoryService,
  SubUserItem,
  SubListResult
} from '../service/RepositoryService';
import { RepositoryDetailStore } from '../store/RepositoryDetailStore';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { SubListView, SubListMode } from './sub/SubListView';

interface RepositoryWatcherRouteParam {
  fullName: string;
}

interface UserDetailRouteParam {
  login: string;
}

const FALLBACK_FULL_NAME: string = '';

@Component
export struct RepositoryWatcherPage {
  @State fullName: string = FALLBACK_FULL_NAME;
  @State items: SubUserItem[] = [];
  @State page: number = 1;
  @State hasMore: boolean = true;
  @State error: string = '';
  @State plmController: PullLoadMoreController = new PullLoadMoreController();
  private store: RepositoryDetailStore = new RepositoryDetailStore();
  private service: RepositoryService = new RepositoryService(this.store);
  private pageSize: number = 30;

  aboutToAppear(): void {
    this.service = new RepositoryService(this.store);
    this.pageSize = this.service.getPageSize();
  }

  private resolveFullNameFromCtx(ctx: NavDestinationContext): string {
    const info: NavPathInfo | undefined = ctx.pathInfo;
    if (info === undefined || info === null) {
      return FALLBACK_FULL_NAME;
    }
    const param: Object | undefined = info.param as Object | undefined;
    if (param === undefined || param === null) {
      return FALLBACK_FULL_NAME;
    }
    const obj: RepositoryWatcherRouteParam = param as RepositoryWatcherRouteParam;
    return obj.fullName !== undefined && obj.fullName !== null ? obj.fullName : FALLBACK_FULL_NAME;
  }

  private async refreshList(): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    this.plmController.showRefreshState();
    const res: SubListResult<SubUserItem> = await this.service.getWatchers(this.fullName, 1);
    if (res.result) {
      this.items = res.data.slice();
      this.page = 1;
      this.hasMore = res.data.length >= this.pageSize;
      this.error = '';
    } else {
      this.error = res.msg;
    }
    this.plmController.refreshComplete(this.hasMore, false);
  }

  private async loadMoreList(): Promise<void> {
    if (!this.hasMore) {
      this.plmController.loadMoreComplete(false);
      return;
    }
    const next: number = this.page + 1;
    const res: SubListResult<SubUserItem> = await this.service.getWatchers(this.fullName, next);
    if (res.result) {
      const merged: SubUserItem[] = this.items.slice();
      for (let i: number = 0; i < res.data.length; i++) {
        merged.push(res.data[i]);
      }
      this.items = merged;
      this.page = next;
      this.hasMore = res.data.length >= this.pageSize;
    }
    this.plmController.loadMoreComplete(this.hasMore);
  }

  private openUser(item: SubUserItem): void {
    const param: UserDetailRouteParam = { 'login': item.login } as UserDetailRouteParam;
    NavigationService.push(RouteName.UserDetail, param as Object);
  }

  build(): void {
    NavDestination() {
      Column() {
        AppBar({
          title: 'Watchers',
          showBack: true,
          onBack: (): void => {
            NavigationService.pop();
          },
        });
        SubListView({
          title: 'Watchers',
          mode: SubListMode.USER,
          users: this.items,
          repos: [],
          controller: this.plmController,
          idPrefix: 'repo_watcher',
          refresh: (): void => {
            this.refreshList();
          },
          loadMore: (): void => {
            this.loadMoreList();
          },
          onUserClick: (item: SubUserItem): void => {
            this.openUser(item);
          },
        })
          .id('repo_watcher_sub_list')
          .layoutWeight(1);
      }
      .id('repo_watcher_root')
      .width('100%')
      .height('100%')
      .backgroundColor(GSYColor.white);
    }
    .hideTitleBar(true)
    .onBackPressed((): boolean => {
      NavigationService.pop();
      return true;
    })
    .onReady((ctx: NavDestinationContext): void => {
      const resolved: string = this.resolveFullNameFromCtx(ctx);
      if (resolved.length > 0) {
        this.fullName = resolved;
      }
      this.refreshList();
    });
  }
}
