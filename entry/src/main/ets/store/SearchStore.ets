import { RecommendOwner, RecommendRepo } from './RecommendStore';

export type SearchTab = 'repo' | 'user' | 'issue';

export const SEARCH_TAB_REPO: SearchTab = 'repo';
export const SEARCH_TAB_USER: SearchTab = 'user';
export const SEARCH_TAB_ISSUE: SearchTab = 'issue';

export interface SearchUserItem {
  id: number;
  login: string;
  avatar_url: string;
  html_url: string;
  type: string;
}

export interface SearchIssueItem {
  id: number;
  number: number;
  title: string;
  state: string;
  body: string;
  html_url: string;
  repository_url: string;
  comments: number;
  user: RecommendOwner;
}

export interface SearchUserSearchResponse {
  total_count: number;
  incomplete_results: boolean;
  items: SearchUserItem[];
}

export interface SearchIssueSearchResponse {
  total_count: number;
  incomplete_results: boolean;
  items: SearchIssueItem[];
}

@Observed
export class SearchStore {
  query: string = '';
  tab: SearchTab = SEARCH_TAB_REPO;
  repos: RecommendRepo[] = [];
  users: SearchUserItem[] = [];
  issues: SearchIssueItem[] = [];
  loading: boolean = false;
  page: number = 1;
  hasMore: boolean = true;
  error: string = '';

  reset(): void {
    this.query = '';
    this.tab = SEARCH_TAB_REPO;
    this.repos = [];
    this.users = [];
    this.issues = [];
    this.loading = false;
    this.page = 1;
    this.hasMore = true;
    this.error = '';
  }

  setQuery(q: string): void {
    this.query = q;
  }

  setTab(tab: SearchTab): void {
    this.tab = tab;
    this.page = 1;
    this.hasMore = true;
    this.error = '';
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

  applyReposRefresh(items: RecommendRepo[], pageSize: number): void {
    this.repos = items.slice();
    this.page = 1;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyReposAppend(items: RecommendRepo[], page: number, pageSize: number): void {
    const merged: RecommendRepo[] = this.repos.slice();
    for (let i = 0; i < items.length; i++) {
      merged.push(items[i]);
    }
    this.repos = merged;
    this.page = page;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyUsersRefresh(items: SearchUserItem[], pageSize: number): void {
    this.users = items.slice();
    this.page = 1;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyUsersAppend(items: SearchUserItem[], page: number, pageSize: number): void {
    const merged: SearchUserItem[] = this.users.slice();
    for (let i = 0; i < items.length; i++) {
      merged.push(items[i]);
    }
    this.users = merged;
    this.page = page;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyIssuesRefresh(items: SearchIssueItem[], pageSize: number): void {
    this.issues = items.slice();
    this.page = 1;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyIssuesAppend(items: SearchIssueItem[], page: number, pageSize: number): void {
    const merged: SearchIssueItem[] = this.issues.slice();
    for (let i = 0; i < items.length; i++) {
      merged.push(items[i]);
    }
    this.issues = merged;
    this.page = page;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }
}
