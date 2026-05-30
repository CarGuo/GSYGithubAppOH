export type NotifyFilter = 'unread' | 'participating' | 'all';

export const NOTIFY_FILTER_UNREAD: NotifyFilter = 'unread';
export const NOTIFY_FILTER_PARTICIPATING: NotifyFilter = 'participating';
export const NOTIFY_FILTER_ALL: NotifyFilter = 'all';

export interface NotifySubject {
  title: string;
  url: string;
  latest_comment_url: string;
  type: string;
}

export interface NotifyRepository {
  id: number;
  name: string;
  full_name: string;
  owner_login: string;
  html_url: string;
}

export interface NotifyThread {
  id: string;
  unread: boolean;
  reason: string;
  updated_at: string;
  last_read_at: string;
  url: string;
  subject: NotifySubject;
  repository: NotifyRepository;
}

export function emptySubject(): NotifySubject {
  return {
    'title': '',
    'url': '',
    'latest_comment_url': '',
    'type': '',
  } as NotifySubject;
}

export function emptyRepository(): NotifyRepository {
  return {
    'id': 0,
    'name': '',
    'full_name': '',
    'owner_login': '',
    'html_url': '',
  } as NotifyRepository;
}

@Observed
export class NotifyStore {
  list: NotifyThread[] = [];
  filter: NotifyFilter = NOTIFY_FILTER_UNREAD;
  loading: boolean = false;
  page: number = 1;
  hasMore: boolean = true;
  error: string = '';

  reset(): void {
    this.list = [];
    this.filter = NOTIFY_FILTER_UNREAD;
    this.loading = false;
    this.page = 1;
    this.hasMore = true;
    this.error = '';
  }

  setFilter(filter: NotifyFilter): void {
    this.filter = filter;
    this.list = [];
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

  applyRefresh(threads: NotifyThread[], pageSize: number): void {
    this.list = threads.slice();
    this.page = 1;
    this.hasMore = threads.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyAppend(threads: NotifyThread[], page: number, pageSize: number): void {
    const merged: NotifyThread[] = this.list.slice();
    for (let i = 0; i < threads.length; i++) {
      merged.push(threads[i]);
    }
    this.list = merged;
    this.page = page;
    this.hasMore = threads.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  markThreadRead(threadId: string): void {
    const next: NotifyThread[] = [];
    for (let i = 0; i < this.list.length; i++) {
      const t: NotifyThread = this.list[i];
      if (t.id === threadId) {
        const updated: NotifyThread = {
          'id': t.id,
          'unread': false,
          'reason': t.reason,
          'updated_at': t.updated_at,
          'last_read_at': t.last_read_at,
          'url': t.url,
          'subject': t.subject,
          'repository': t.repository,
        } as NotifyThread;
        next.push(updated);
      } else {
        next.push(t);
      }
    }
    this.list = next;
  }

  markAllRead(): void {
    const next: NotifyThread[] = [];
    for (let i = 0; i < this.list.length; i++) {
      const t: NotifyThread = this.list[i];
      const updated: NotifyThread = {
        'id': t.id,
        'unread': false,
        'reason': t.reason,
        'updated_at': t.updated_at,
        'last_read_at': t.last_read_at,
        'url': t.url,
        'subject': t.subject,
        'repository': t.repository,
      } as NotifyThread;
      next.push(updated);
    }
    this.list = next;
  }
}
