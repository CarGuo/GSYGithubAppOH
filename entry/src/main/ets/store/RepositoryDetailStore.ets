export interface RepositoryOwner {
  login: string;
  avatar_url: string;
  html_url: string;
}

export interface RepositoryParent {
  full_name: string;
}

export interface RepositoryLicense {
  name: string;
}

export interface RepositoryDetail {
  id: number;
  name: string;
  full_name: string;
  description: string;
  default_branch: string;
  html_url: string;
  language: string;
  stargazers_count: number;
  watchers_count: number;
  forks_count: number;
  open_issues_count: number;
  subscribers_count: number;
  owner: RepositoryOwner;
  size?: number;
  fork?: boolean;
  parent?: RepositoryParent | null;
  topics?: string[];
  license?: RepositoryLicense | null;
  created_at?: string;
  pushed_at?: string;
}

export interface RepositoryEventActor {
  login: string;
  avatar_url: string;
}

export interface RepositoryEventRepo {
  id: number;
  name: string;
}

export interface RepositoryEventItem {
  id: string;
  type: string;
  actor: RepositoryEventActor;
  repo: RepositoryEventRepo;
  created_at: string;
  payload: Record<string, Object>;
}

export interface RepositoryCommitAuthor {
  name: string;
  email: string;
  date: string;
}

export interface RepositoryCommitDetail {
  message: string;
  author: RepositoryCommitAuthor;
  committer: RepositoryCommitAuthor;
}

export interface RepositoryCommitUser {
  login: string;
  avatar_url: string;
}

export interface RepositoryCommitItem {
  sha: string;
  commit: RepositoryCommitDetail;
  author?: RepositoryCommitUser | null;
  committer?: RepositoryCommitUser | null;
}

export interface RepositoryPulseData {
  weekOpenedCount: number;
  weekClosedCount: number;
  description: string;
}

export interface RepositoryIssueUser {
  login: string;
  avatar_url: string;
}

export interface RepositoryIssueItem {
  id: number;
  number: number;
  title: string;
  body: string;
  state: string;
  user: RepositoryIssueUser;
  comments: number;
  created_at: string;
  updated_at: string;
  html_url: string;
}

export interface RepositoryFileItem {
  name: string;
  path: string;
  sha: string;
  size: number;
  type: string;
  download_url: string;
  html_url: string;
}

export const ISSUE_STATE_OPEN: string = 'open';
export const ISSUE_STATE_CLOSED: string = 'closed';
export const ISSUE_STATE_ALL: string = 'all';

@Observed
export class RepositoryDetailStore {
  detail: RepositoryDetail | null = null;
  readmeHtml: string = '';
  readmeLoading: boolean = false;
  readmeError: string = '';
  issues: RepositoryIssueItem[] = [];
  activity: RepositoryEventItem[] = [];
  files: RepositoryFileItem[] = [];
  starred: boolean = false;
  watching: boolean = false;
  loading: boolean = false;
  error: string = '';
  issuesPage: number = 1;
  issuesHasMore: boolean = true;
  activityPage: number = 1;
  activityHasMore: boolean = true;

  issueList: RepositoryIssueItem[] = [];
  issuePage: number = 1;
  issueHasMore: boolean = true;
  issueLoading: boolean = false;
  issueState: string = ISSUE_STATE_ALL;
  issueSearchQuery: string = '';

  eventList: RepositoryEventItem[] = [];
  eventPage: number = 1;
  eventHasMore: boolean = true;
  eventLoading: boolean = false;

  currentPath: string = '';
  fileList: RepositoryFileItem[] = [];
  fileLoading: boolean = false;
  pathStack: string[] = [];

  commits: RepositoryCommitItem[] = [];
  commitsPage: number = 1;
  commitsHasMore: boolean = true;
  commitsLoading: boolean = false;

  pulse: RepositoryPulseData | null = null;
  pulseLoading: boolean = false;

  branches: string[] = [];
  currentBranch: string = '';

  reset(): void {
    this.detail = null;
    this.readmeHtml = '';
    this.readmeLoading = false;
    this.readmeError = '';
    this.issues = [];
    this.activity = [];
    this.files = [];
    this.starred = false;
    this.watching = false;
    this.loading = false;
    this.error = '';
    this.issuesPage = 1;
    this.issuesHasMore = true;
    this.activityPage = 1;
    this.activityHasMore = true;
    this.issueList = [];
    this.issuePage = 1;
    this.issueHasMore = true;
    this.issueLoading = false;
    this.issueState = ISSUE_STATE_ALL;
    this.issueSearchQuery = '';
    this.eventList = [];
    this.eventPage = 1;
    this.eventHasMore = true;
    this.eventLoading = false;
    this.currentPath = '';
    this.fileList = [];
    this.fileLoading = false;
    this.pathStack = [];
    this.commits = [];
    this.commitsPage = 1;
    this.commitsHasMore = true;
    this.commitsLoading = false;
    this.pulse = null;
    this.pulseLoading = false;
    this.branches = [];
    this.currentBranch = '';
  }

  startLoading(): void {
    this.loading = true;
    this.error = '';
  }

  finishLoading(): void {
    this.loading = false;
  }

  setError(msg: string): void {
    this.error = msg;
    this.loading = false;
  }

  setDetail(detail: RepositoryDetail): void {
    this.detail = detail;
  }

  setReadmeHtml(html: string): void {
    this.readmeHtml = html;
    this.readmeLoading = false;
    this.readmeError = '';
  }

  startReadmeLoading(): void {
    this.readmeLoading = true;
    this.readmeError = '';
  }

  setReadmeError(msg: string): void {
    this.readmeLoading = false;
    this.readmeError = msg !== null && msg !== undefined ? msg : '';
  }

  setStarred(starred: boolean): void {
    this.starred = starred;
  }

  setWatching(watching: boolean): void {
    this.watching = watching;
  }

  setFiles(files: RepositoryFileItem[]): void {
    this.files = files.slice();
  }

  applyActivityRefresh(events: RepositoryEventItem[], pageSize: number): void {
    this.activity = events.slice();
    this.activityPage = 1;
    this.activityHasMore = events.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyActivityAppend(events: RepositoryEventItem[], page: number, pageSize: number): void {
    const merged: RepositoryEventItem[] = this.activity.slice();
    for (let i = 0; i < events.length; i++) {
      merged.push(events[i]);
    }
    this.activity = merged;
    this.activityPage = page;
    this.activityHasMore = events.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyIssuesRefresh(items: RepositoryIssueItem[], pageSize: number): void {
    this.issues = items.slice();
    this.issuesPage = 1;
    this.issuesHasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyIssuesAppend(items: RepositoryIssueItem[], page: number, pageSize: number): void {
    const merged: RepositoryIssueItem[] = this.issues.slice();
    for (let i = 0; i < items.length; i++) {
      merged.push(items[i]);
    }
    this.issues = merged;
    this.issuesPage = page;
    this.issuesHasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  startIssueLoading(): void {
    this.issueLoading = true;
    this.error = '';
  }

  finishIssueLoading(): void {
    this.issueLoading = false;
  }

  setIssueState(state: string): void {
    const safe: string = state !== null && state !== undefined && state.length > 0
      ? state : ISSUE_STATE_ALL;
    this.issueState = safe;
    this.issueList = [];
    this.issuePage = 1;
    this.issueHasMore = true;
  }

  setIssueSearchQuery(query: string): void {
    this.issueSearchQuery = query !== null && query !== undefined ? query : '';
  }

  resetIssuePage(): void {
    this.issues = [];
    this.issuesPage = 1;
    this.issuesHasMore = true;
    this.issueList = [];
    this.issuePage = 1;
    this.issueHasMore = true;
  }

  applyIssueRefresh(items: RepositoryIssueItem[], pageSize: number): void {
    this.issueList = items.slice();
    this.issuePage = 1;
    this.issueHasMore = items.length >= pageSize;
    this.issueLoading = false;
    this.error = '';
  }

  applyIssueAppend(items: RepositoryIssueItem[], page: number, pageSize: number): void {
    const merged: RepositoryIssueItem[] = this.issueList.slice();
    for (let i = 0; i < items.length; i++) {
      merged.push(items[i]);
    }
    this.issueList = merged;
    this.issuePage = page;
    this.issueHasMore = items.length >= pageSize;
    this.issueLoading = false;
    this.error = '';
  }

  startEventLoading(): void {
    this.eventLoading = true;
    this.error = '';
  }

  finishEventLoading(): void {
    this.eventLoading = false;
  }

  applyEventRefresh(events: RepositoryEventItem[], pageSize: number): void {
    this.eventList = events.slice();
    this.eventPage = 1;
    this.eventHasMore = events.length >= pageSize;
    this.eventLoading = false;
    this.error = '';
  }

  applyEventAppend(events: RepositoryEventItem[], page: number, pageSize: number): void {
    const merged: RepositoryEventItem[] = this.eventList.slice();
    for (let i = 0; i < events.length; i++) {
      merged.push(events[i]);
    }
    this.eventList = merged;
    this.eventPage = page;
    this.eventHasMore = events.length >= pageSize;
    this.eventLoading = false;
    this.error = '';
  }

  startFileLoading(): void {
    this.fileLoading = true;
    this.error = '';
  }

  finishFileLoading(): void {
    this.fileLoading = false;
  }

  applyFileRefresh(files: RepositoryFileItem[]): void {
    this.fileList = files.slice();
    this.fileLoading = false;
    this.error = '';
  }

  setPath(path: string): void {
    const safe: string = path !== null && path !== undefined ? path : '';
    if (safe !== this.currentPath) {
      const stackCopy: string[] = this.pathStack.slice();
      stackCopy.push(this.currentPath);
      this.pathStack = stackCopy;
    }
    this.currentPath = safe;
  }

  popPath(): string {
    if (this.pathStack.length === 0) {
      this.currentPath = '';
      return '';
    }
    const stackCopy: string[] = this.pathStack.slice();
    const previous: string = stackCopy.pop() as string;
    this.pathStack = stackCopy;
    this.currentPath = previous;
    return previous;
  }

  startCommitsLoading(): void {
    this.commitsLoading = true;
    this.error = '';
  }

  finishCommitsLoading(): void {
    this.commitsLoading = false;
  }

  applyCommitsRefresh(items: RepositoryCommitItem[], pageSize: number): void {
    this.commits = items.slice();
    this.commitsPage = 1;
    this.commitsHasMore = items.length >= pageSize;
    this.commitsLoading = false;
    this.error = '';
  }

  applyCommitsAppend(items: RepositoryCommitItem[], page: number, pageSize: number): void {
    const merged: RepositoryCommitItem[] = this.commits.slice();
    for (let i = 0; i < items.length; i++) {
      merged.push(items[i]);
    }
    this.commits = merged;
    this.commitsPage = page;
    this.commitsHasMore = items.length >= pageSize;
    this.commitsLoading = false;
    this.error = '';
  }

  setPulse(data: RepositoryPulseData | null): void {
    this.pulse = data;
    this.pulseLoading = false;
  }

  setBranches(list: string[]): void {
    this.branches = list;
  }

  setCurrentBranch(branch: string): void {
    this.currentBranch = branch;
  }
}
