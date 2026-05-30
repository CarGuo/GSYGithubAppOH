export const READ_HISTORY_TYPE_REPO: string = 'repo';
export const READ_HISTORY_TYPE_USER: string = 'user';

export interface ReadHistoryItem {
  type: string;
  key: string;
  title: string;
  subtitle: string;
  avatar: string;
  payloadJson: string;
  time: number;
}

export function emptyReadHistoryItem(): ReadHistoryItem {
  return {
    'type': '',
    'key': '',
    'title': '',
    'subtitle': '',
    'avatar': '',
    'payloadJson': '',
    'time': 0,
  } as ReadHistoryItem;
}

@Observed
export class ReadHistoryStore {
  list: ReadHistoryItem[] = [];
  loading: boolean = false;
  error: string = '';
  page: number = 1;
  hasMore: boolean = true;
  filterType: string = '';

  reset(): void {
    this.list = [];
    this.loading = false;
    this.error = '';
    this.page = 1;
    this.hasMore = true;
    this.filterType = '';
  }

  startLoading(): void {
    this.loading = true;
    this.error = '';
  }

  finishLoading(): void {
    this.loading = false;
  }

  setError(msg: string): void {
    this.error = msg !== null && msg !== undefined ? msg : '';
    this.loading = false;
  }

  setFilterType(type: string): void {
    const safe: string = type !== null && type !== undefined ? type : '';
    this.filterType = safe;
    this.list = [];
    this.page = 1;
    this.hasMore = true;
  }

  applyRefresh(items: ReadHistoryItem[], pageSize: number): void {
    this.list = items.slice();
    this.page = 1;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyAppend(items: ReadHistoryItem[], page: number, pageSize: number): void {
    const merged: ReadHistoryItem[] = this.list.slice();
    for (let i = 0; i < items.length; i++) {
      merged.push(items[i]);
    }
    this.list = merged;
    this.page = page;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  clearList(): void {
    this.list = [];
    this.page = 1;
    this.hasMore = false;
    this.loading = false;
    this.error = '';
  }
}
