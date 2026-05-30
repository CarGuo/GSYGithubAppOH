import { I18n } from '../i18n/I18n';
import router from '@ohos.router';
import pasteboard from '@ohos.pasteboard';
import { PullLoadMoreController } from '../common/PullLoadMoreList';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { RouteParamStore } from '../navigation/RouteParamStore';
import { BOOT_REPO_KEY } from '../entryability/EntryAbility';
import { AppBar, AppBarAction } from '../common/AppBar';
import { CommonToast } from '../common/CommonToast';
import { CommonModal, CommonOptionItem } from '../common/CommonModal';
import { LoadingModal } from '../common/LoadingModal';
import { Logger } from '../ai-debug/Logger';
import {
  RepositoryDetailStore,
  RepositoryEventItem,
  RepositoryFileItem,
  RepositoryIssueItem
} from '../store/RepositoryDetailStore';
import {
  RepositoryService,
  RepositoryServiceResult
} from '../service/RepositoryService';
import { RepositoryDetail } from '../store/RepositoryDetailStore';
import { ReadmeTab } from './repo/ReadmeTab';
import { IssueTab } from './repo/IssueTab';
import { ActivityTab } from './repo/ActivityTab';
import { FilesTab, isImageOrArchiveFile } from './repo/FilesTab';
import { ReadHistoryService, ReadHistoryAddParam } from '../service/ReadHistoryService';
import { READ_HISTORY_TYPE_REPO } from '../store/ReadHistoryStore';
import { ExternalUrlUtil } from '../utils/ExternalUrlUtil';
import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';
import { CommonBottomBar, CommonBottomBarItem } from '../common/CommonBottomBar';
import { CreateIssueDialog } from '../widget/CreateIssueDialog';
import {
  FA_STAR,
  FA_STAR_O,
  FA_EYE,
  FA_EYE_SLASH,
  FA_CODE_FORK,
  FA_CHEVRON_DOWN,
  FA_PLUS,
  IconFont,
} from '../common/IconFont';

interface RepositoryDetailRouteParam {
  fullName?: string;
  owner?: string;
  name?: string;
  reposOwner?: string;
  reposName?: string;
  ownerName?: string;
  repositoryName?: string;
}

interface RepoTabItem {
  key: string;
  title: string;
  index: number;
}

interface CommonListRouteParam {
  dataType: string;
  showType: string;
  currentUser: string;
  repoName: string;
  title: string;
}

const FALLBACK_FULL_NAME: string = '';
const TAB_BAR_HEIGHT: number = 48;
const BRANCH_MENU_WIDTH: number = 220;
const BRANCH_MENU_MAX_HEIGHT: number = 300;
const COMMON_LIST_SHOW_TYPE_USER: string = 'user';
const COMMON_LIST_SHOW_TYPE_REPOSITORY: string = 'repository';

@Component
export struct RepositoryDetailPage {
  @State fullName: string = FALLBACK_FULL_NAME;
  @State store: RepositoryDetailStore = new RepositoryDetailStore();
  @State currentIndex: number = 0;
  @State activitySelect: number = 0;
  @State activityController: PullLoadMoreController = new PullLoadMoreController();
  @State issueController: PullLoadMoreController = new PullLoadMoreController();
  @State filesController: PullLoadMoreController = new PullLoadMoreController();
  @State currentFilePath: string = '';
  @State filePathStack: string[] = [];
  @State branchMenuVisible: boolean = false;
  private tabsController: TabsController = new TabsController();
  private service: RepositoryService = new RepositoryService(this.store);
  private readHistoryService: ReadHistoryService = new ReadHistoryService();
  private pathStack: NavPathStack = new NavPathStack();
  private createIssueDialogController: CustomDialogController = new CustomDialogController({
    builder: CreateIssueDialog({
      onConfirm: (title: string, body: string): void => {
        this.submitCreateIssue(title, body);
      },
    }),
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center,
  });

  private tabs: RepoTabItem[] = [
    { key: 'info', title: I18n('reposActivity'), index: 0 },
    { key: 'readme', title: I18n('reposReadme'), index: 1 },
    { key: 'issue', title: I18n('reposIssue'), index: 2 },
    { key: 'file', title: I18n('reposFile'), index: 3 },
  ];

  aboutToAppear(): void {
    this.service = new RepositoryService(this.store);
    this.applyRouterParams();
    Logger.i('boot/ts', `RepositoryDetailPage.aboutToAppear t=${Date.now()} fullName='${this.fullName}'`);
    if (this.fullName.length > 0) {
      this.loadAll();
    }
  }

  private resolveFullNameFromObject(raw: Object | undefined | null): string {
    if (raw === undefined || raw === null) {
      return FALLBACK_FULL_NAME;
    }
    const obj: RepositoryDetailRouteParam = raw as RepositoryDetailRouteParam;
    if (obj.fullName !== undefined && obj.fullName !== null && obj.fullName.length > 0) {
      return obj.fullName;
    }
    const owner: string = (obj.owner !== undefined && obj.owner !== null && obj.owner.length > 0)
      ? obj.owner
      : ((obj.reposOwner !== undefined && obj.reposOwner !== null && obj.reposOwner.length > 0)
        ? obj.reposOwner
        : ((obj.ownerName !== undefined && obj.ownerName !== null) ? obj.ownerName : ''));
    const name: string = (obj.name !== undefined && obj.name !== null && obj.name.length > 0)
      ? obj.name
      : ((obj.reposName !== undefined && obj.reposName !== null && obj.reposName.length > 0)
        ? obj.reposName
        : ((obj.repositoryName !== undefined && obj.repositoryName !== null) ? obj.repositoryName : ''));
    if (owner.length > 0 && name.length > 0) {
      return owner + '/' + name;
    }
    return FALLBACK_FULL_NAME;
  }

  private applyRouterParams(): void {
    // 优先级 1：RouteParamStore（NavigationService.push 同步写入，覆盖所有 push 入口）
    const routeRaw: Object | null = RouteParamStore.consume(RouteName.RepositoryDetail);
    if (routeRaw !== null) {
      const resolvedFromRoute: string = this.resolveFullNameFromObject(routeRaw);
      if (resolvedFromRoute.length > 0) {
        this.fullName = resolvedFromRoute;
        Logger.i('repo/route', `RepositoryDetailPage adopted via RouteParamStore fullName=${resolvedFromRoute}`);
        return;
      }
    }
    try {
      const raw: Object | undefined = router.getParams() as Object | undefined;
      const resolved: string = this.resolveFullNameFromObject(raw === undefined ? null : raw);
      if (resolved.length > 0) {
        this.fullName = resolved;
        return;
      }
    } catch (_e) {
    }
    if (this.fullName.length === 0) {
      const bootRepo: string | undefined = AppStorage.get<string>(BOOT_REPO_KEY);
      if (bootRepo !== undefined && bootRepo !== null && bootRepo.length > 0) {
        this.fullName = bootRepo;
      }
    }
  }

  private resolveFullNameFromStack(stack: NavPathStack): string {
    try {
      const all: string[] = stack.getAllPathName();
      if (all === undefined || all === null || all.length === 0) {
        return FALLBACK_FULL_NAME;
      }
      const param: Object | undefined = stack.getParamByIndex(all.length - 1) as Object | undefined;
      return this.resolveFullNameFromObject(param === undefined ? null : param);
    } catch (_e) {
      return FALLBACK_FULL_NAME;
    }
  }

  private resolveOwnerName(): string {
    const idx: number = this.fullName.indexOf('/');
    if (idx <= 0) {
      return '';
    }
    return this.fullName.substring(0, idx);
  }

  private resolveRepositoryName(): string {
    const idx: number = this.fullName.indexOf('/');
    if (idx < 0 || idx >= this.fullName.length - 1) {
      return '';
    }
    return this.fullName.substring(idx + 1);
  }

  private async loadAll(): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    // 首次进入要让用户看到"正在加载"——这一批请求里 README 最慢，
    // 之前没有任何加载提示导致整个详情页空白十几秒。LoadingModal 全屏遮罩 + 自动 hide。
    LoadingModal.show(I18n('loading'), false);
    try {
      await this.service.getReposInfo(this.fullName);
      await this.service.getStarStatus(this.fullName);
      await this.service.getReadme(this.fullName, null);
      await this.refreshActivity();
      await this.refreshIssues();
      await this.refreshFiles('');
      await this.writeReadHistory();
    } finally {
      LoadingModal.hide();
    }
  }

  private async writeReadHistory(): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    const detail: RepositoryDetail | null = this.store.detail;
    let title: string = this.fullName;
    let subtitle: string = '';
    let avatar: string = '';
    let payloadJson: string = '';
    if (detail !== null) {
      const d: RepositoryDetail = detail as RepositoryDetail;
      title = d.full_name.length > 0 ? d.full_name : this.fullName;
      subtitle = d.description.length > 0 ? d.description : d.language;
      avatar = d.owner !== null && d.owner !== undefined ? d.owner.avatar_url : '';
      payloadJson = JSON.stringify(d);
    }
    const param: ReadHistoryAddParam = {
      'type': READ_HISTORY_TYPE_REPO,
      'key': this.fullName,
      'title': title,
      'subtitle': subtitle,
      'avatar': avatar,
      'payloadJson': payloadJson,
      'time': Date.now(),
    } as ReadHistoryAddParam;
    await this.readHistoryService.add(param);
  }

  private async refreshActivity(): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    this.activityController.showRefreshState();
    await this.service.getRepositoryEvents(this.fullName, 1);
    this.activityController.refreshComplete(this.store.activityHasMore, false);
  }

  private async loadMoreActivity(): Promise<void> {
    if (!this.store.activityHasMore) {
      this.activityController.loadMoreComplete(false);
      return;
    }
    const next: number = this.store.activityPage + 1;
    await this.service.getRepositoryEvents(this.fullName, next);
    this.activityController.loadMoreComplete(this.store.activityHasMore);
  }

  /**
   * ActivityTab 子 tab 切换：Compose 版 Info 仅包含 Events / Commits。
   */
  private async handleActivitySelectChange(sel: number): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    if (sel === 1) {
      this.activityController.showRefreshState();
      await this.service.getRepositoryCommits(this.fullName, 1);
      this.activityController.refreshComplete(this.store.commitsHasMore, false);
      return;
    }
  }

  private async refreshCurrentActivityTab(): Promise<void> {
    if (this.activitySelect === 1) {
      await this.handleActivitySelectChange(1);
      return;
    }
    await this.refreshActivity();
  }

  private async loadMoreCurrentActivityTab(): Promise<void> {
    if (this.activitySelect === 1) {
      if (!this.store.commitsHasMore) {
        this.activityController.loadMoreComplete(false);
        return;
      }
      const next: number = this.store.commitsPage + 1;
      await this.service.getRepositoryCommits(this.fullName, next);
      this.activityController.loadMoreComplete(this.store.commitsHasMore);
      return;
    }
    await this.loadMoreActivity();
  }

  private async refreshIssues(): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    this.issueController.showRefreshState();
    await this.service.getIssues(this.fullName, this.store.issueState, 1, this.store.issueSearchQuery);
    this.issueController.refreshComplete(this.store.issuesHasMore, false);
  }

  private async loadMoreIssues(): Promise<void> {
    if (!this.store.issuesHasMore) {
      this.issueController.loadMoreComplete(false);
      return;
    }
    const next: number = this.store.issuesPage + 1;
    await this.service.getIssues(this.fullName, this.store.issueState, next, this.store.issueSearchQuery);
    this.issueController.loadMoreComplete(this.store.issuesHasMore);
  }

  private async handleIssueStateChange(state: string): Promise<void> {
    this.store.issueState = state;
    this.store.resetIssuePage();
    await this.refreshIssues();
  }

  private handleIssueSearchQueryChange(query: string): void {
    this.store.setIssueSearchQuery(query);
  }

  private async handleIssueSearch(): Promise<void> {
    this.store.resetIssuePage();
    await this.refreshIssues();
  }

  private openCreateIssueDialog(): void {
    this.createIssueDialogController.open();
  }

  private async submitCreateIssue(title: string, body: string): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    const res: RepositoryServiceResult<RepositoryIssueItem | null> =
      await this.service.createIssue(this.fullName, title, body);
    if (res.result) {
      CommonToast.showShort(I18n('createIssue'));
    } else {
      const msg: string = (res.msg !== null && res.msg !== undefined && res.msg.length > 0)
        ? res.msg : I18n('netError');
      CommonToast.showShort(msg);
    }
  }

  private async refreshFiles(path: string): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    // 先把 currentFilePath 落到目标路径，避免 PullLoadMoreList 内部
    // refresh 回调把旧路径（root）再带回来覆盖（dir 点进去刷回 root 的根因）。
    this.currentFilePath = path;
    this.filesController.showRefreshState();
    await this.service.getFiles(this.fullName, this.resolveCurrentBranch(), path);
    this.filesController.refreshComplete(false, false);
  }

  private async openFile(item: RepositoryFileItem): Promise<void> {
    if (item.type === 'dir') {
      this.filePathStack.push(this.currentFilePath);
      await this.refreshFiles(item.path);
      return;
    }
    // Compose FileItem 对图片和压缩包禁用点击，其余文件进入 CodeDetail。
    if (isImageOrArchiveFile(item.name)) {
      return;
    }
    const branch: string = this.store.currentBranch.length > 0
      ? this.store.currentBranch : this.resolveDefaultBranch();
    Logger.i('FilesTab', `openFile push CodeDetail fullName=${this.fullName}`
      + ` branch=${branch} path=${item.path}`);
    const codeParam: Record<string, Object> = {
      'fullName': this.fullName,
      'branch': branch,
      'path': item.path,
    };
    NavigationService.push(RouteName.CodeDetail, codeParam as Object);
  }

  private async backFiles(): Promise<void> {
    if (this.filePathStack.length === 0) {
      await this.refreshFiles('');
      return;
    }
    const previous: string = this.filePathStack.pop() as string;
    await this.refreshFiles(previous);
  }

  private async toggleStar(): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    LoadingModal.show(I18n('loading'), false);
    let res: RepositoryServiceResult<boolean>;
    try {
      if (this.store.starred) {
        res = await this.service.unstar(this.fullName);
      } else {
        res = await this.service.star(this.fullName);
      }
    } finally {
      LoadingModal.hide();
    }
    if (res.result) {
      await this.service.getReposInfo(this.fullName);
      CommonToast.showShort(this.store.starred ? I18n('reposStar') : I18n('reposUnStar'));
    } else {
      const msg: string = (res.msg !== null && res.msg !== undefined && res.msg.length > 0)
        ? res.msg : I18n('netError');
      CommonToast.showShort(msg);
    }
  }

  private async toggleWatch(): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    LoadingModal.show(I18n('loading'), false);
    let res: RepositoryServiceResult<boolean>;
    try {
      if (this.store.watching) {
        res = await this.service.unwatch(this.fullName);
      } else {
        res = await this.service.watch(this.fullName);
      }
    } finally {
      LoadingModal.hide();
    }
    if (res.result) {
      await this.service.getReposInfo(this.fullName);
      CommonToast.showShort(this.store.watching ? I18n('reposWatcher') : I18n('reposUnWatcher'));
    } else {
      const msg: string = (res.msg !== null && res.msg !== undefined && res.msg.length > 0)
        ? res.msg : I18n('netError');
      CommonToast.showShort(msg);
    }
  }

  private async doFork(): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    LoadingModal.show(I18n('loading'), false);
    let res: RepositoryServiceResult<boolean>;
    try {
      res = await this.service.forkRepository(this.fullName);
    } finally {
      LoadingModal.hide();
    }
    if (res.result) {
      await this.service.getReposInfo(this.fullName);
    } else {
      CommonToast.showShort(I18n('netError'));
    }
  }

  private async openBranchSelector(): Promise<void> {
    if (this.fullName.length === 0) {
      return;
    }
    if (this.store.branches.length === 0) {
      LoadingModal.show(I18n('loading'), false);
      try {
        await this.service.getBranches(this.fullName);
      } finally {
        LoadingModal.hide();
      }
    }
    const list: string[] = this.store.branches;
    if (list.length === 0) {
      CommonToast.showShort(I18n('netError'));
      return;
    }
    if (list.length === 1) {
      this.applyBranchChange(list[0]);
      return;
    }
    this.branchMenuVisible = true;
  }

  private async applyBranchChange(branch: string): Promise<void> {
    if (branch.length === 0) {
      return;
    }
    this.store.setCurrentBranch(branch);
    Logger.i('RepositoryDetailPage', `applyBranchChange branch=${branch}`);
    // 切换分支后重拉 README + files + commits，对齐 Compose selectedBranch LaunchedEffect。
    LoadingModal.show(I18n('loading'), false);
    try {
      await this.service.getReadme(this.fullName, branch);
      this.currentFilePath = '';
      this.filePathStack = [];
      await this.service.getFiles(this.fullName, branch, '');
      if (this.activitySelect === 1) {
        await this.service.getRepositoryCommits(this.fullName, 1);
      }
    } finally {
      LoadingModal.hide();
    }
    CommonToast.showShort(branch);
  }

  private handleTabTap(index: number): void {
    this.currentIndex = index;
    this.tabsController.changeIndex(index);
  }

  private resolveDefaultBranch(): string {
    const detail: RepositoryDetail | null = this.store.detail;
    if (detail !== null
      && detail.default_branch !== null
      && detail.default_branch !== undefined
      && detail.default_branch.length > 0) {
      return detail.default_branch;
    }
    return 'master';
  }

  private resolveCurrentBranch(): string {
    return this.store.currentBranch.length > 0
      ? this.store.currentBranch : this.resolveDefaultBranch();
  }

  private buildBottomBarItems(): CommonBottomBarItem[] {
    const items: CommonBottomBarItem[] = [];

    const starItem: CommonBottomBarItem = new CommonBottomBarItem();
    starItem.itemId = 'star';
    starItem.itemName = this.store.starred ? I18n('reposUnStar') : I18n('reposStar');
    starItem.icon = this.store.starred ? FA_STAR : FA_STAR_O;
    starItem.iconColor = GSYColor.primary;
    starItem.itemTextColor = GSYColor.primary;
    starItem.itemClick = (): void => {
      this.toggleStar();
    };
    items.push(starItem);

    const watchItem: CommonBottomBarItem = new CommonBottomBarItem();
    watchItem.itemId = 'watch';
    watchItem.itemName = this.store.watching ? I18n('reposUnWatcher') : I18n('reposWatcher');
    watchItem.icon = this.store.watching ? FA_EYE_SLASH : FA_EYE;
    watchItem.iconColor = GSYColor.primary;
    watchItem.itemTextColor = GSYColor.primary;
    watchItem.itemClick = (): void => {
      this.toggleWatch();
    };
    items.push(watchItem);

    const forkItem: CommonBottomBarItem = new CommonBottomBarItem();
    forkItem.itemId = 'fork';
    forkItem.itemName = I18n('reposFork');
    forkItem.icon = FA_CODE_FORK;
    forkItem.iconColor = GSYColor.primary;
    forkItem.itemTextColor = GSYColor.primary;
    forkItem.itemClick = (): void => {
      this.doFork();
    };
    items.push(forkItem);

    const branchItem: CommonBottomBarItem = new CommonBottomBarItem();
    branchItem.itemId = 'branch';
    branchItem.itemName = this.resolveCurrentBranch();
    branchItem.icon = FA_CHEVRON_DOWN;
    branchItem.iconColor = GSYColor.primary;
    branchItem.itemTextColor = GSYColor.primary;
    branchItem.itemClick = (): void => {
      this.openBranchSelector();
    };
    items.push(branchItem);

    return items;
  }

  @Builder
  buildBranchMenu(): void {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
      }
        .id('repo_branch_menu_scrim')
        .width('100%')
        .height('100%')
        .onClick((): void => {
          this.branchMenuVisible = false;
        });

      Scroll() {
        Column() {
          ForEach(this.store.branches, (branch: string, index: number): void => {
            Row() {
              Text(branch)
                .id('repo_branch_menu_item_text_' + index.toString())
                .fontSize(GSYFontSize.small)
                .fontColor(GSYColor.primary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1);
            }
            .id('repo_branch_menu_item_' + index.toString())
            .width('100%')
            .height(44)
            .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge })
            .alignItems(VerticalAlign.Center)
            .onClick((): void => {
              this.branchMenuVisible = false;
              this.applyBranchChange(branch);
            });
            if (index < this.store.branches.length - 1) {
              Divider().color(GSYColor.line).strokeWidth(0.5);
            }
          }, (branch: string, index: number): string => index.toString() + ':' + branch);
        }
        .width('100%');
      }
      .id('repo_branch_menu_root')
      .width(BRANCH_MENU_WIDTH)
      .constraintSize({ maxHeight: BRANCH_MENU_MAX_HEIGHT })
      .backgroundColor(GSYColor.white)
      .borderRadius(6)
      .shadow({
        radius: 10,
        color: '#33000000',
        offsetX: 0,
        offsetY: 2,
      })
      .margin({
        right: GSYSpacing.normalEdge,
        bottom: GSYSpacing.normalEdge,
      });
    }
    .id('repo_branch_menu_overlay')
    .width('100%')
    .height('100%')
    .zIndex(10);
  }

  @Builder
  buildTabBar(item: RepoTabItem): void {
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
    .id('repo_detail_tab_bar_' + item.key)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => {
      this.handleTabTap(item.index);
    });
  }

  private buildAppBarTitle(): string {
    if (this.fullName.length > 0) {
      return this.fullName;
    }
    return '';
  }

  private resolveHtmlUrl(): string {
    if (this.fullName.length === 0) {
      return '';
    }
    return 'https://github.com/' + this.fullName;
  }

  private copyToPasteboard(text: string): void {
    if (text.length === 0) {
      return;
    }
    try {
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const board: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      board.setData(data);
      CommonToast.showShort(I18n('hadCopy'));
    } catch (_e) {
      CommonToast.showShort(I18n('hadCopy'));
    }
  }

  private showMoreMenu(): void {
    const htmlUrl: string = this.resolveHtmlUrl();
    const items: CommonOptionItem[] = [
      { itemName: I18n('browserOpen') } as CommonOptionItem,
      { itemName: I18n('copy') } as CommonOptionItem,
      { itemName: I18n('share') } as CommonOptionItem,
    ];
    CommonModal.options(
      { title: this.fullName, items: items },
      (index: number, _item: CommonOptionItem): void => {
        if (htmlUrl.length === 0) {
          return;
        }
        if (index === 0) {
          ExternalUrlUtil.openUrlInBrowser(this, htmlUrl, 'RepositoryDetailPage');
        } else if (index === 1) {
          this.copyToPasteboard(htmlUrl);
        } else if (index === 2) {
          ExternalUrlUtil.openUrlInBrowser(this, htmlUrl, 'RepositoryDetailPage');
        }
      }
    );
  }

  private buildRightActions(): AppBarAction[] {
    return [
      {
        iconKey: 'more',
        onAction: (): void => {
          this.showMoreMenu();
        },
      } as AppBarAction,
    ];
  }

  @Builder
  buildCreateIssueFab(): void {
    Row() {
      IconFont({
        char: FA_PLUS,
        glyphSize: GSYFontSize.middleWhite,
        glyphColor: GSYColor.miWhite,
      });
    }
    .id('repo_detail_create_issue_fab')
    .width(GSYSpacing.tabBarHeight)
    .height(GSYSpacing.tabBarHeight)
    .borderRadius(GSYSpacing.tabBarHeight / 2)
    .backgroundColor(GSYColor.primary)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .margin({
      right: GSYSpacing.normalEdge,
      bottom: GSYSpacing.normalEdge,
    })
    .onClick((): void => {
      this.openCreateIssueDialog();
    });
  }

  private openRepositoryCommonList(dataType: string, showType: string, titlePrefix: string): void {
    const owner: string = this.resolveOwnerName();
    const repo: string = this.resolveRepositoryName();
    if (owner.length === 0 || repo.length === 0) {
      Logger.w('RepositoryDetailPage', 'openRepositoryCommonList skipped, fullName=' + this.fullName + ' type=' + dataType);
      return;
    }
    const param: CommonListRouteParam = {
      dataType: dataType,
      showType: showType,
      currentUser: owner,
      repoName: repo,
      title: repo + ' ' + titlePrefix,
    };
    Logger.i('RepositoryDetailPage', 'openRepositoryCommonList type=' + dataType + ' owner=' + owner + ' repo=' + repo);
    NavigationService.push(RouteName.CommonList, param as Object);
  }

  private openTopicList(topic: string): void {
    const safeTopic: string = topic !== null && topic !== undefined ? topic.trim() : '';
    if (safeTopic.length === 0) {
      return;
    }
    const param: CommonListRouteParam = {
      dataType: 'topics',
      showType: COMMON_LIST_SHOW_TYPE_REPOSITORY,
      currentUser: safeTopic,
      repoName: '',
      title: I18n('listTopics').replace('%s', safeTopic),
    } as CommonListRouteParam;
    Logger.i('RepositoryDetailPage', 'openTopicList topic=' + safeTopic);
    NavigationService.push(RouteName.CommonList, param as Object);
  }

  build(): void {
    NavDestination() {
      Column() {
        AppBar({
          title: this.buildAppBarTitle(),
          titleStart: true,
          showBack: true,
          rightActions: this.buildRightActions(),
          onBack: (): void => {
            NavigationService.pop();
          },
        });
        Stack({ alignContent: Alignment.BottomEnd }) {
          Tabs({
            barPosition: BarPosition.Start,
            index: this.currentIndex,
            controller: this.tabsController,
          }) {
            TabContent() {
              ActivityTab({
                activity: this.store.activity,
                controller: this.activityController,
                store: this.store,
                ownerName: this.resolveOwnerName(),
                repositoryName: this.resolveRepositoryName(),
                refresh: (): void => {
                  this.refreshCurrentActivityTab();
                },
                loadMore: (): void => {
                  this.loadMoreCurrentActivityTab();
                },
                onSelectChange: (sel: number): void => {
                  this.activitySelect = sel;
                  this.handleActivitySelectChange(sel);
                },
                onTapStar: (): void => {
                  this.openRepositoryCommonList('stargazers', COMMON_LIST_SHOW_TYPE_USER, 'stargazers');
                },
                onTapWatch: (): void => {
                  this.openRepositoryCommonList('watchers', COMMON_LIST_SHOW_TYPE_USER, 'watchers');
                },
                onTapFork: (): void => {
                  this.openRepositoryCommonList('forks', COMMON_LIST_SHOW_TYPE_REPOSITORY, 'forks');
                },
                onTapIssue: (): void => {
                  this.handleTabTap(2);
                },
                onTapForkSource: (): void => {
                },
                onTapOwner: (): void => {
                },
                onTapTopic: (topic: string): void => {
                  this.openTopicList(topic);
                },
              })
                .id('repo_detail_tab_content_info');
            }
            .tabBar(this.buildTabBar(this.tabs[0]));

            TabContent() {
              ReadmeTab({
                store: this.store,
                fullName: this.fullName,
                branch: this.store.currentBranch.length > 0
                  ? this.store.currentBranch : this.resolveDefaultBranch(),
                readmeHtml: this.store.readmeHtml,
                readmeLoading: this.store.readmeLoading,
                readmeError: this.store.readmeError,
              })
                .id('repo_detail_tab_content_readme');
            }
            .tabBar(this.buildTabBar(this.tabs[1]));

            TabContent() {
              IssueTab({
                issues: this.store.issues,
                fullName: this.fullName,
                currentState: this.store.issueState,
                searchQuery: this.store.issueSearchQuery,
                showCreateFab: false,
                controller: this.issueController,
                refresh: (): void => {
                  this.refreshIssues();
                },
                loadMore: (): void => {
                  this.loadMoreIssues();
                },
                onIssueClick: (_item: RepositoryIssueItem): void => {
                },
                onStateChange: (state: string): void => {
                  this.handleIssueStateChange(state);
                },
                onSearchQueryChange: (query: string): void => {
                  this.handleIssueSearchQueryChange(query);
                },
                onSearch: (): void => {
                  this.handleIssueSearch();
                },
                onCreateIssue: (): void => {
                  this.openCreateIssueDialog();
                },
              })
                .id('repo_detail_tab_content_issue');
            }
            .tabBar(this.buildTabBar(this.tabs[2]));

            TabContent() {
              FilesTab({
                files: this.store.files,
                currentPath: this.currentFilePath,
                controller: this.filesController,
                refresh: (): void => {
                  this.refreshFiles(this.currentFilePath);
                },
                onFileClick: (item: RepositoryFileItem): void => {
                  this.openFile(item);
                },
                onBack: (): void => {
                  this.backFiles();
                },
              })
                .id('repo_detail_tab_content_file');
            }
            .tabBar(this.buildTabBar(this.tabs[3]));
          }
          .id('repo_detail_tabs')
          .barHeight(TAB_BAR_HEIGHT)
          .barMode(BarMode.Fixed)
          .scrollable(true)
          .width('100%')
          .height('100%')
          .onChange((index: number): void => {
            this.currentIndex = index;
          });

          if (this.fullName.length > 0) {
            this.buildCreateIssueFab();
          }
          if (this.branchMenuVisible) {
            this.buildBranchMenu();
          }
        }
        .id('repo_detail_content_stack')
        .layoutWeight(1)
        .width('100%');

        if (this.fullName.length > 0) {
          CommonBottomBar({
            rootId: 'repo_detail_bottom_bar',
            dataList: this.buildBottomBarItems(),
            repoActionStyle: true,
            trailingItemId: 'branch',
          });
        }
      }
      .id('repo_detail_root')
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
      const stack: NavPathStack | undefined = ctx.pathStack;
      const previous: string = this.fullName;
      let stackSize: number = -1;
      let resolved: string = FALLBACK_FULL_NAME;
      if (stack !== undefined && stack !== null) {
        this.pathStack = stack;
        try {
          const all: string[] = stack.getAllPathName();
          stackSize = (all === undefined || all === null) ? 0 : all.length;
        } catch (_e) {
          stackSize = -1;
        }
        resolved = this.resolveFullNameFromStack(stack);
        if (resolved.length > 0) {
          this.fullName = resolved;
        }
      }
      if (this.fullName.length === 0 || this.fullName === FALLBACK_FULL_NAME) {
        const info: NavPathInfo | undefined = ctx.pathInfo;
        if (info !== undefined && info !== null) {
          const raw: Object | undefined = info.param as Object | undefined;
          const fromParam: string = this.resolveFullNameFromObject(raw === undefined ? null : raw);
          if (fromParam.length > 0) {
            resolved = fromParam;
            this.fullName = fromParam;
          }
        }
      }
      // KI-045 同款：BOOT_REPO_KEY 旁路优先级最高（dispatcher 路径上 stack/pathInfo
      // 都拿不到 param，必须靠 AppStorage 旁路覆盖上一次残留的 fullName）。
      const bootRepo: string | undefined = AppStorage.get<string>(BOOT_REPO_KEY);
      const bootRepoTrim: string = (bootRepo === undefined || bootRepo === null) ? '' : bootRepo.trim();
      if (bootRepoTrim.length > 0) {
        resolved = bootRepoTrim;
        this.fullName = bootRepoTrim;
      }
      Logger.i('boot/ts',
        `RepositoryDetailPage.onReady t=${Date.now()} stackSize=${stackSize}` +
        ` previous='${previous}' resolved='${resolved}' fullName='${this.fullName}'`);
      if (this.fullName.length > 0 && this.fullName !== previous) {
        this.loadAll();
      } else if (previous.length === 0 && this.fullName.length > 0) {
        this.loadAll();
      }
    });
  }
}
