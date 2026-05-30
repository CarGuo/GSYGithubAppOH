export interface DynamicActor {
  id: number;
  login: string;
  display_login: string;
  avatar_url: string;
}

export interface DynamicRepo {
  id: number;
  name: string;
  url: string;
}

export interface DynamicEvent {
  id: string;
  type: string;
  actor: DynamicActor;
  repo: DynamicRepo;
  created_at: string;
  payload: Record<string, Object>;
}

@Observed
export class DynamicStore {
  list: DynamicEvent[] = [];
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

  applyRefresh(events: DynamicEvent[], pageSize: number): void {
    this.list = events.slice();
    this.page = 1;
    this.hasMore = events.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyAppend(events: DynamicEvent[], page: number, pageSize: number): void {
    const merged: DynamicEvent[] = this.list.slice();
    for (let i = 0; i < events.length; i++) {
      merged.push(events[i]);
    }
    this.list = merged;
    this.page = page;
    this.hasMore = events.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyCachedFallback(events: DynamicEvent[]): void {
    this.list = events.slice();
    this.page = 1;
    this.hasMore = false;
    this.loading = false;
  }
}
