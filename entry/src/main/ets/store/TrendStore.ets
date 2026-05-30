export interface TrendBuiltBy {
  href: string;
  avatar: string;
  username: string;
}

export interface TrendRepo {
  author: string;
  name: string;
  avatar: string;
  url: string;
  description: string;
  language: string;
  languageColor: string;
  stars: number;
  forks: number;
  currentPeriodStars: number;
  builtBy: TrendBuiltBy[];
}

export type TrendSince = 'daily' | 'weekly' | 'monthly';

export const TREND_SINCE_DAILY: TrendSince = 'daily';
export const TREND_SINCE_WEEKLY: TrendSince = 'weekly';
export const TREND_SINCE_MONTHLY: TrendSince = 'monthly';

export const TREND_LANGUAGE_ALL: string = '';

export function fullNameOf(repo: TrendRepo): string {
  if (!repo) {
    return '';
  }
  const author: string = repo.author && repo.author.length > 0 ? repo.author : '';
  const name: string = repo.name && repo.name.length > 0 ? repo.name : '';
  if (author.length === 0) {
    return name;
  }
  if (name.length === 0) {
    return author;
  }
  return author + '/' + name;
}

@Observed
export class TrendStore {
  list: TrendRepo[] = [];
  loading: boolean = false;
  since: TrendSince = TREND_SINCE_DAILY;
  language: string = TREND_LANGUAGE_ALL;
  error: string = '';

  reset(): void {
    this.list = [];
    this.loading = false;
    this.since = TREND_SINCE_DAILY;
    this.language = TREND_LANGUAGE_ALL;
    this.error = '';
  }

  startLoading(): void {
    this.loading = true;
    this.error = '';
  }

  finishLoading(): void {
    this.loading = false;
  }

  setSince(since: TrendSince): void {
    this.since = since;
  }

  setLanguage(language: string): void {
    this.language = language;
  }

  setError(msg: string): void {
    this.error = msg;
    this.loading = false;
  }

  applyRefresh(repos: TrendRepo[]): void {
    this.list = repos.slice();
    this.loading = false;
    this.error = '';
  }

  applyCachedFallback(repos: TrendRepo[]): void {
    this.list = repos.slice();
    this.loading = false;
  }
}
