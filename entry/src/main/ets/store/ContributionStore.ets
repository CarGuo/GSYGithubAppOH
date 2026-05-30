export interface ContributionDay {
  date: string;
  count: number;
  level: number;
}

export function emptyContributionDay(): ContributionDay {
  return {
    'date': '',
    'count': 0,
    'level': 0,
  } as ContributionDay;
}

export function clampContributionLevel(level: number): number {
  if (level < 0) {
    return 0;
  }
  if (level > 4) {
    return 4;
  }
  return Math.floor(level);
}

@Observed
export class ContributionStore {
  days: ContributionDay[] = [];
  loading: boolean = false;
  error: string = '';
  fromCache: boolean = false;

  reset(): void {
    this.days = [];
    this.loading = false;
    this.error = '';
    this.fromCache = false;
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

  applyDays(days: ContributionDay[], fromCache: boolean): void {
    const normalized: ContributionDay[] = [];
    for (let i = 0; i < days.length; i++) {
      const d: ContributionDay = days[i];
      const item: ContributionDay = {
        'date': d.date !== undefined && d.date !== null ? d.date : '',
        'count': typeof d.count === 'number' ? d.count : 0,
        'level': clampContributionLevel(typeof d.level === 'number' ? d.level : 0),
      } as ContributionDay;
      normalized.push(item);
    }
    this.days = normalized;
    this.fromCache = fromCache;
    this.loading = false;
    this.error = '';
  }
}
