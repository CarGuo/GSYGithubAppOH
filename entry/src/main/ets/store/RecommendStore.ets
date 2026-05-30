export interface RecommendOwner {
  id: number;
  login: string;
  avatar_url: string;
}

export interface RecommendRepo {
  id: number;
  name: string;
  full_name: string;
  description: string | null;
  language: string | null;
  stargazers_count: number;
  forks_count: number;
  watchers_count: number;
  html_url: string;
  owner: RecommendOwner;
}

export interface RecommendSearchResponse {
  total_count: number;
  incomplete_results: boolean;
  items: RecommendRepo[];
}

@Observed
export class RecommendStore {
  list: RecommendRepo[] = [];
  loading: boolean = false;
  hasMore: boolean = true;
  page: number = 1;
  error: string = '';

  reset(): void {
    this.list = [];
    this.loading = false;
    this.hasMore = true;
    this.page = 1;
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

  applyRefresh(items: RecommendRepo[], pageSize: number): void {
    this.list = items.slice();
    this.page = 1;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyAppend(items: RecommendRepo[], page: number, pageSize: number): void {
    const merged: RecommendRepo[] = this.list.slice();
    for (let i = 0; i < items.length; i++) {
      merged.push(items[i]);
    }
    this.list = merged;
    this.page = page;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }
}
