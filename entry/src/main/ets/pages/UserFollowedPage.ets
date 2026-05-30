import { PullLoadMoreController } from '../common/PullLoadMoreList';
import { SubUserItem } from '../service/RepositoryService';
import { GSYColor } from '../style/Theme';
import { AppBar } from '../common/AppBar';
import {
  UserService,
  FetchSubUserListResult
} from '../service/UserService';
import { UserDetailStore } from '../store/UserDetailStore';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { SubListView, SubListMode } from './sub/SubListView';

interface UserFollowedRouteParam {
  login: string;
}

interface UserDetailRouteParam {
  login: string;
}

const FALLBACK_LOGIN: string = '';

@Component
export struct UserFollowedPage {
  @State login: string = FALLBACK_LOGIN;
  @State items: SubUserItem[] = [];
  @State page: number = 1;
  @State hasMore: boolean = true;
  @State error: string = '';
  @State plmController: PullLoadMoreController = new PullLoadMoreController();
  private store: UserDetailStore = new UserDetailStore();
  private service: UserService = new UserService(this.store);
  private pageSize: number = 30;

  aboutToAppear(): void {
    this.service = new UserService(this.store);
    this.pageSize = this.service.getPageSize();
  }

  private resolveLoginFromCtx(ctx: NavDestinationContext): string {
    const info: NavPathInfo | undefined = ctx.pathInfo;
    if (info === undefined || info === null) {
      return FALLBACK_LOGIN;
    }
    const param: Object | undefined = info.param as Object | undefined;
    if (param === undefined || param === null) {
      return FALLBACK_LOGIN;
    }
    const obj: UserFollowedRouteParam = param as UserFollowedRouteParam;
    return obj.login !== undefined && obj.login !== null ? obj.login : FALLBACK_LOGIN;
  }

  private async refreshList(): Promise<void> {
    if (this.login.length === 0) {
      return;
    }
    this.plmController.showRefreshState();
    const res: FetchSubUserListResult = await this.service.getUserFollowed(this.login, 1);
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
    const res: FetchSubUserListResult = await this.service.getUserFollowed(this.login, next);
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
          title: 'Following',
          showBack: true,
          onBack: (): void => {
            NavigationService.pop();
          },
        });
        SubListView({
          title: 'Following',
          mode: SubListMode.USER,
          users: this.items,
          repos: [],
          controller: this.plmController,
          idPrefix: 'user_followed',
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
          .id('user_followed_sub_list')
          .layoutWeight(1);
      }
      .id('user_followed_root')
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
      const resolved: string = this.resolveLoginFromCtx(ctx);
      if (resolved.length > 0) {
        this.login = resolved;
      }
      this.refreshList();
    });
  }
}
