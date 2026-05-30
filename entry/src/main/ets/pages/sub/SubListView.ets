/**
 * SubListView —— 通用列表（user_repos / user_star / followers / followed / member / repo_star / repo_watcher / repo_fork）
 * 严格对照 RN [ListPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ListPage.js) +
 * RN [UserItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserItem.js) +
 * RN [RepositoryItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/RepositoryItem.js)
 * HARD-LAW-2 token-only：所有字面量 fontSize/padding/iconSize/borderRadius 已迁移至 Theme.ets
 */
import { PullLoadMoreList, PullLoadMoreController } from '../../common/PullLoadMoreList';
import { SubUserItem, SubRepositoryItem } from '../../service/RepositoryService';
import { RepositoryItem } from '../../widget/RepositoryItem';
import { UserItem } from '../../widget/UserItem';
import { GSYColor, GSYFontSize, GSYSpacing } from '../../style/Theme';

export enum SubListMode {
  USER = 0,
  REPO = 1,
}

@Component
export struct SubListView {
  @Prop title: string = '';
  @Prop mode: SubListMode = SubListMode.USER;
  @Prop users: SubUserItem[] = [];
  @Prop repos: SubRepositoryItem[] = [];
  @ObjectLink controller: PullLoadMoreController;
  @Prop idPrefix: string = 'sub_list';
  refresh: () => void = (): void => {};
  loadMore: () => void = (): void => {};
  onUserClick: (item: SubUserItem) => void = (_item: SubUserItem): void => {};
  onRepoClick: (item: SubRepositoryItem) => void = (_item: SubRepositoryItem): void => {};

  @Builder
  buildHeader(): void {
    Row() {
      Text(this.title)
        .id(this.idPrefix + '_title')
        .fontSize(GSYFontSize.middleNormal)
        .fontColor(GSYColor.primary)
        .fontWeight(FontWeight.Bold);
    }
    .id(this.idPrefix + '_header')
    .width('100%')
    .padding(GSYSpacing.normalEdge)
    .backgroundColor(GSYColor.surfaceSubtle);
  }

  @Builder
  buildUserRow(item: SubUserItem, index: number): void {
    UserItem({
      data: {
        login: item.login,
        avatar_url: item.avatar_url,
        html_url: item.html_url,
      },
      rowId: this.idPrefix + '_user_' + index.toString(),
      onPress: (): void => {
        this.onUserClick(item);
      },
    });
  }

  @Builder
  buildRepoRow(item: SubRepositoryItem, index: number): void {
    RepositoryItem({
      ownerName: item.owner_login !== undefined && item.owner_login !== null ? item.owner_login : '',
      ownerPic: this.safeOwnerPic(item),
      repositoryName: this.safeRepoTitle(item),
      repositoryStar: item.stargazers_count !== undefined && item.stargazers_count !== null ? item.stargazers_count.toString() : '0',
      repositoryFork: item.forks_count !== undefined && item.forks_count !== null ? item.forks_count.toString() : '0',
      repositoryWatch: item.watchers_count !== undefined && item.watchers_count !== null ? item.watchers_count.toString() : '0',
      repositoryType: this.safeRepoLang(item),
      repositoryDes: this.safeRepoDes(item),
      rowId: this.idPrefix + '_repo_' + index.toString(),
      onPressItem: (): void => {
        this.onRepoClick(item);
      },
    });
  }

  private safeOwnerPic(item: SubRepositoryItem): string {
    const v: string | null | undefined = item.owner_avatar_url;
    if (v !== undefined && v !== null && v.length > 0) {
      return v;
    }
    return '';
  }

  private safeRepoTitle(item: SubRepositoryItem): string {
    const full: string | null | undefined = item.full_name;
    if (full !== undefined && full !== null && full.length > 0) {
      return full;
    }
    const n: string | null | undefined = item.name;
    return n !== undefined && n !== null ? n : '';
  }

  private safeRepoLang(item: SubRepositoryItem): string {
    const v: string | null | undefined = item.language;
    if (v !== undefined && v !== null && v.length > 0) {
      return v;
    }
    return '---';
  }

  private safeRepoDes(item: SubRepositoryItem): string {
    const v: string | null | undefined = item.description;
    if (v !== undefined && v !== null && v.length > 0) {
      return v;
    }
    return '---';
  }

  @Builder
  buildUserList(): void {
    PullLoadMoreList({
      dataSource: this.users,
      controller: this.controller,
      renderRow: (item: Object, index: number): void => this.buildUserRow(item as SubUserItem, index),
      renderHeader: (): void => this.buildHeader(),
      refresh: (): void => {
        this.refresh();
      },
      loadMore: (): void => {
        this.loadMore();
      },
    })
      .id(this.idPrefix + '_pull_list');
  }

  @Builder
  buildRepoList(): void {
    PullLoadMoreList({
      dataSource: this.repos,
      controller: this.controller,
      renderRow: (item: Object, index: number): void => this.buildRepoRow(item as SubRepositoryItem, index),
      renderHeader: (): void => this.buildHeader(),
      refresh: (): void => {
        this.refresh();
      },
      loadMore: (): void => {
        this.loadMore();
      },
    })
      .id(this.idPrefix + '_pull_list');
  }

  build(): void {
    Column() {
      if (this.mode === SubListMode.USER) {
        this.buildUserList();
      } else {
        this.buildRepoList();
      }
    }
    .id(this.idPrefix + '_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.pageBackground);
  }
}
