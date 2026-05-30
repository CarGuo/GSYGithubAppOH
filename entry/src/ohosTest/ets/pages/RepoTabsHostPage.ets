import http from '@ohos.net.http';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { Address } from '../../../main/ets/net/Address';
import {
  PullLoadMoreController,
} from '../../../main/ets/common/PullLoadMoreList';
import {
  RepositoryDetailStore,
  RepositoryEventItem,
  RepositoryCommitItem,
  RepositoryFileItem,
  RepositoryIssueItem,
  ISSUE_STATE_ALL,
  ISSUE_STATE_OPEN,
  ISSUE_STATE_CLOSED,
} from '../../../main/ets/store/RepositoryDetailStore';
import {
  RepositoryService,
} from '../../../main/ets/service/RepositoryService';
import { IssueTab } from '../../../main/ets/pages/repo/IssueTab';
import { ActivityTab } from '../../../main/ets/pages/repo/ActivityTab';
import { FilesTab } from '../../../main/ets/pages/repo/FilesTab';
import { RouteName } from '../../../main/ets/navigation/Routes';
import { NavigationService } from '../../../main/ets/navigation/NavigationService';

const TARGET_OWNER: string = 'CarGuoUI';
const TARGET_REPO: string = 'GSYTabRepo';
const TARGET_FULL_NAME: string = TARGET_OWNER + '/' + TARGET_REPO;

class RepoTabsHostProvider implements HttpProvider {
  callCount: number = 0;
  issuesCount: number = 0;
  eventsCount: number = 0;
  commitsCount: number = 0;
  filesCount: number = 0;
  lastIssueState: string = '';
  lastFilesPath: string = '';

  private buildIssuesBody(state: string): string {
    const issues: Object[] = [
      {
        'id': 101,
        'number': 101,
        'title': '[' + state + '] tab issue 1',
        'body': 'Issue body from mock one',
        'state': state === ISSUE_STATE_CLOSED ? 'closed' : 'open',
        'user': { 'login': TARGET_OWNER, 'avatar_url': '' },
        'comments': 1,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'html_url': '',
      },
      {
        'id': 102,
        'number': 102,
        'title': '[' + state + '] tab issue 2',
        'body': 'Issue body from mock two',
        'state': state === ISSUE_STATE_CLOSED ? 'closed' : 'open',
        'user': { 'login': TARGET_OWNER, 'avatar_url': '' },
        'comments': 2,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'html_url': '',
      },
    ];
    return JSON.stringify(issues);
  }

  private buildIssueSearchBody(): string {
    const issues: Object[] = [
      {
        'id': 201,
        'number': 201,
        'title': 'search result issue',
        'body': 'Search issue body from mock',
        'state': 'open',
        'user': { 'login': TARGET_OWNER, 'avatar_url': '' },
        'comments': 3,
        'created_at': '2024-01-03T00:00:00Z',
        'updated_at': '2024-01-03T00:00:00Z',
        'html_url': '',
      },
    ];
    return JSON.stringify({
      'total_count': 1,
      'incomplete_results': false,
      'items': issues,
    });
  }

  private buildEventsBody(): string {
    const events: Object[] = [
      {
        'id': 'evt-tab-1',
        'type': 'PushEvent',
        'actor': { 'login': TARGET_OWNER, 'avatar_url': '' },
        'repo': { 'id': 1, 'name': TARGET_FULL_NAME },
        'created_at': '2024-01-01T00:00:00Z',
        'payload': {} as Record<string, Object>,
      },
    ];
    return JSON.stringify(events);
  }

  private buildCommitsBody(): string {
    const commits: Object[] = [
      {
        'sha': 'abc1234567890',
        'author': { 'login': TARGET_OWNER, 'avatar_url': '' },
        'committer': { 'login': TARGET_OWNER, 'avatar_url': '' },
        'commit': {
          'message': 'Compose parity commit item',
          'author': {
            'name': TARGET_OWNER,
            'email': 'owner@example.com',
            'date': '2024-01-02T00:00:00Z',
          },
          'committer': {
            'name': TARGET_OWNER,
            'email': 'owner@example.com',
            'date': '2024-01-02T00:00:00Z',
          },
        },
      },
    ];
    return JSON.stringify(commits);
  }

  private buildFilesRoot(): string {
    const files: Object[] = [
      {
        'name': 'src',
        'path': 'src',
        'sha': 'sha-src',
        'size': 0,
        'type': 'dir',
        'download_url': '',
        'html_url': '',
      },
      {
        'name': 'README.md',
        'path': 'README.md',
        'sha': 'sha-readme',
        'size': 200,
        'type': 'file',
        'download_url': '',
        'html_url': '',
      },
      {
        'name': 'logo.png',
        'path': 'logo.png',
        'sha': 'sha-logo',
        'size': 300,
        'type': 'file',
        'download_url': '',
        'html_url': '',
      },
    ];
    return JSON.stringify(files);
  }

  private buildFilesSrc(): string {
    const files: Object[] = [
      {
        'name': 'main.ts',
        'path': 'src/main.ts',
        'sha': 'sha-main',
        'size': 300,
        'type': 'file',
        'download_url': '',
        'html_url': '',
      },
    ];
    return JSON.stringify(files);
  }

  private extractStateFromUrl(url: string): string {
    const idx: number = url.indexOf('state=');
    if (idx < 0) {
      return ISSUE_STATE_ALL;
    }
    const tail: string = url.substring(idx + 6);
    const ampIdx: number = tail.indexOf('&');
    return ampIdx < 0 ? tail : tail.substring(0, ampIdx);
  }

  private extractFilesPath(url: string): string {
    const marker: string = '/contents/';
    const idx: number = url.indexOf(marker);
    if (idx < 0) {
      return '';
    }
    const tail: string = url.substring(idx + marker.length);
    const qIdx: number = tail.indexOf('?');
    return qIdx < 0 ? tail : tail.substring(0, qIdx);
  }

  async request(url: string,
                _method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    if (url.indexOf('search/issues') >= 0) {
      this.issuesCount = this.issuesCount + 1;
      this.lastIssueState = 'search';
      return new RawResponse(SUCCESS, this.buildIssueSearchBody(), {});
    }
    if (url.indexOf('/issues') >= 0) {
      this.issuesCount = this.issuesCount + 1;
      this.lastIssueState = this.extractStateFromUrl(url);
      return new RawResponse(SUCCESS, this.buildIssuesBody(this.lastIssueState), {});
    }
    if (url.indexOf('/events') >= 0) {
      this.eventsCount = this.eventsCount + 1;
      return new RawResponse(SUCCESS, this.buildEventsBody(), {});
    }
    if (url.indexOf('/commits') >= 0) {
      this.commitsCount = this.commitsCount + 1;
      return new RawResponse(SUCCESS, this.buildCommitsBody(), {});
    }
    if (url.indexOf('/contents') >= 0) {
      this.filesCount = this.filesCount + 1;
      this.lastFilesPath = this.extractFilesPath(url);
      if (this.lastFilesPath === 'src') {
        return new RawResponse(SUCCESS, this.buildFilesSrc(), {});
      }
      return new RawResponse(SUCCESS, this.buildFilesRoot(), {});
    }
    return new RawResponse(SUCCESS, '{}', {});
  }
}

const REPO_TABS_HOST_STUB: RepoTabsHostProvider = new RepoTabsHostProvider();

export function getRepoTabsHostStub(): RepoTabsHostProvider {
  return REPO_TABS_HOST_STUB;
}

@Entry
@Component
struct RepoTabsHostPage {
  @State navStack: NavPathStack = new NavPathStack();
  @State store: RepositoryDetailStore = new RepositoryDetailStore();
  @State currentTab: number = 0;
  @State issueController: PullLoadMoreController = new PullLoadMoreController();
  @State eventController: PullLoadMoreController = new PullLoadMoreController();
  @State filesController: PullLoadMoreController = new PullLoadMoreController();
  private service: RepositoryService = new RepositoryService(this.store);

  aboutToAppear(): void {
    HttpManager.setMockProvider(REPO_TABS_HOST_STUB);
    this.service = new RepositoryService(this.store);
    this.loadInitial();
  }

  aboutToDisappear(): void {
    HttpManager.setMockProvider(null);
  }

  private async loadInitial(): Promise<void> {
    this.store.setIssueState(ISSUE_STATE_ALL);
    await this.service.getIssues(TARGET_FULL_NAME, ISSUE_STATE_ALL, 1);
    await this.service.getEvents(TARGET_FULL_NAME, 1);
    await this.service.getFiles(TARGET_FULL_NAME, null, '');
  }

  private async refreshIssues(): Promise<void> {
    this.issueController.showRefreshState();
    await this.service.getIssues(TARGET_FULL_NAME, this.store.issueState, 1, this.store.issueSearchQuery);
    this.issueController.refreshComplete(this.store.issueHasMore, false);
  }

  private async loadMoreIssues(): Promise<void> {
    if (!this.store.issueHasMore) {
      this.issueController.loadMoreComplete(false);
      return;
    }
    const next: number = this.store.issuePage + 1;
    await this.service.getIssues(TARGET_FULL_NAME, this.store.issueState, next, this.store.issueSearchQuery);
    this.issueController.loadMoreComplete(this.store.issueHasMore);
  }

  private async refreshEvents(): Promise<void> {
    this.eventController.showRefreshState();
    await this.service.getEvents(TARGET_FULL_NAME, 1);
    this.eventController.refreshComplete(this.store.eventHasMore, false);
  }

  private async loadMoreEvents(): Promise<void> {
    if (!this.store.eventHasMore) {
      this.eventController.loadMoreComplete(false);
      return;
    }
    const next: number = this.store.eventPage + 1;
    await this.service.getEvents(TARGET_FULL_NAME, next);
    this.eventController.loadMoreComplete(this.store.eventHasMore);
  }

  private async refreshCommits(): Promise<void> {
    this.eventController.showRefreshState();
    await this.service.getRepositoryCommits(TARGET_FULL_NAME, 1);
    this.eventController.refreshComplete(this.store.commitsHasMore, false);
  }

  private async refreshFiles(): Promise<void> {
    this.filesController.showRefreshState();
    await this.service.getFiles(TARGET_FULL_NAME, null, this.store.currentPath);
    this.filesController.refreshComplete(false, false);
  }

  private async handleStateChange(state: string): Promise<void> {
    this.store.setIssueState(state);
    await this.refreshIssues();
  }

  private async handleIssueSearch(): Promise<void> {
    this.store.resetIssuePage();
    await this.refreshIssues();
  }

  private async handlePathChange(path: string): Promise<void> {
    this.store.setPath(path);
    await this.refreshFiles();
  }

  private async handleBack(): Promise<void> {
    this.store.popPath();
    await this.refreshFiles();
  }

  private handleIssueTap(_item: RepositoryIssueItem): void {
  }

  private handleFileTap(_item: RepositoryFileItem): void {
  }

  @Builder
  tabBarText(label: string, idx: number, idStr: string): void {
    Text(label)
      .id(idStr)
      .fontSize(14)
      .fontColor(this.currentTab === idx ? '#0366D6' : '#586069')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .onClick((): void => {
        this.currentTab = idx;
      });
  }

  @Builder
  tabsBar(): void {
    Row() {
      this.tabBarText('Issues', 0, 'repo_tabs_host_tab_issue');
      this.tabBarText('Activity', 1, 'repo_tabs_host_tab_activity');
      this.tabBarText('Files', 2, 'repo_tabs_host_tab_files');
    }
    .id('repo_tabs_host_tab_bar')
    .width('100%')
    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
    .backgroundColor('#F6F8FA');
  }

  @Builder
  navMap(name: string): void {
    if (name === RouteName.IssueDetail) {
      Column() {
        Text('Issue Detail Mock')
          .id('repo_tabs_host_issue_detail_text')
          .fontSize(16);
      }
      .id('repo_tabs_host_issue_detail_root')
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF');
    }
    if (name === RouteName.CodeDetail) {
      Column() {
        Text('Code Detail Mock')
          .id('repo_tabs_host_code_detail_text')
          .fontSize(16);
      }
      .id('repo_tabs_host_code_detail_root')
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF');
    }
    if (name === RouteName.PushDetail) {
      Column() {
        Text('Push Detail Mock')
          .id('repo_tabs_host_push_detail_text')
          .fontSize(16);
      }
      .id('repo_tabs_host_push_detail_root')
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF');
    }
  }

  build(): void {
    Column() {
      Navigation(this.navStack) {
        Column() {
          this.tabsBar();

          if (this.currentTab === 0) {
            IssueTab({
              issues: this.store.issueList,
              fullName: TARGET_FULL_NAME,
              currentState: this.store.issueState,
              searchQuery: this.store.issueSearchQuery,
              controller: this.issueController,
              refresh: (): void => {
                this.refreshIssues();
              },
              loadMore: (): void => {
                this.loadMoreIssues();
              },
              onIssueClick: (item: RepositoryIssueItem): void => {
                this.handleIssueTap(item);
              },
              onStateChange: (state: string): void => {
                this.handleStateChange(state);
              },
              onSearchQueryChange: (query: string): void => {
                this.store.setIssueSearchQuery(query);
              },
              onSearch: (): void => {
                this.handleIssueSearch();
              },
            })
              .id('repo_tabs_host_issue_tab');
          } else if (this.currentTab === 1) {
            ActivityTab({
              activity: this.store.eventList,
              controller: this.eventController,
              store: this.store,
              ownerName: TARGET_OWNER,
              repositoryName: TARGET_REPO,
              refresh: (): void => {
                this.refreshEvents();
              },
              loadMore: (): void => {
                this.loadMoreEvents();
              },
              onSelectChange: (sel: number): void => {
                if (sel === 1) {
                  this.refreshCommits();
                }
              },
            })
              .id('repo_tabs_host_activity_tab');
          } else {
            FilesTab({
              files: this.store.fileList,
              currentPath: this.store.currentPath,
              fullName: TARGET_FULL_NAME,
              branch: '',
              controller: this.filesController,
              refresh: (): void => {
                this.refreshFiles();
              },
              onFileClick: (item: RepositoryFileItem): void => {
                this.handleFileTap(item);
              },
              onBack: (): void => {
                this.handleBack();
              },
              onPathChange: (path: string): void => {
                this.handlePathChange(path);
              },
            })
              .id('repo_tabs_host_files_tab');
          }
        }
        .id('repo_tabs_host_inner_column')
        .width('100%')
        .height('100%');
      }
      .id('repo_tabs_host_nav')
      .width('100%')
      .height('100%')
      .hideTitleBar(true)
      .navDestination(this.navMap)
      .onAppear((): void => {
        NavigationService.setStack(this.navStack);
      });
    }
    .id('repo_tabs_host_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}

const _repoTabsKeepIssueState: string = ISSUE_STATE_OPEN + '|' + ISSUE_STATE_CLOSED + '|' + ISSUE_STATE_ALL;
const _httpKeepAlive: typeof http = http;
const _addressKeepAlive: typeof Address = Address;
const _eventKeepAlive: RepositoryEventItem | null = null;
const _commitKeepAlive: RepositoryCommitItem | null = null;
