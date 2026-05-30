import HttpManager from '../net/HttpManager';
import { HttpResult } from '../net/Result';
import { UNAUTHORIZED } from '../net/NetworkCode';
import {
  ContributionDay,
  ContributionStore,
  clampContributionLevel,
} from '../store/ContributionStore';

export const CONTRIBUTION_API_HOST: string = 'https://github-contributions-api.jogruber.de/v4/';

export interface ContributionRespItem {
  date: string;
  count: number;
  level: number;
}

export interface ContributionResp {
  total: Record<string, number>;
  contributions: ContributionRespItem[];
}

export class FetchContributionsResult {
  result: boolean;
  code: number;
  data: ContributionDay[];
  fromCache: boolean;
  msg: string;

  constructor(result: boolean, code: number, data: ContributionDay[],
    fromCache: boolean, msg: string) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.fromCache = fromCache;
    this.msg = msg;
  }
}

export class ContributionService {
  private store: ContributionStore;

  constructor(store: ContributionStore) {
    this.store = store;
  }

  getStore(): ContributionStore {
    return this.store;
  }

  static buildUrl(login: string): string {
    return `${CONTRIBUTION_API_HOST}${login}`;
  }

  async getContributions(login: string): Promise<FetchContributionsResult> {
    if (!login || login.length === 0) {
      const empty: FetchContributionsResult = new FetchContributionsResult(
        false, 0, [], false, 'empty login');
      this.store.setError(empty.msg);
      return empty;
    }

    this.store.startLoading();
    const url: string = ContributionService.buildUrl(login);
    const httpResult: HttpResult<ContributionResp> = await HttpManager.getFetch<ContributionResp>(url);

    if (httpResult.result && httpResult.data !== null) {
      const resp: ContributionResp = httpResult.data as ContributionResp;
      const days: ContributionDay[] = ContributionService.parseDays(resp);
      this.store.applyDays(days, false);
      return new FetchContributionsResult(true, httpResult.code, days, false, '');
    }

    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new FetchContributionsResult(false, UNAUTHORIZED, [], false, msg);
    }

    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new FetchContributionsResult(false, httpResult.code, [], false, failMsg);
  }

  private static parseDays(resp: ContributionResp): ContributionDay[] {
    const out: ContributionDay[] = [];
    if (resp === null || resp === undefined) {
      return out;
    }
    const list: ContributionRespItem[] = resp.contributions !== undefined && resp.contributions !== null
      ? resp.contributions : [];
    for (let i = 0; i < list.length; i++) {
      const it: ContributionRespItem = list[i];
      const day: ContributionDay = {
        'date': it.date !== undefined && it.date !== null ? it.date : '',
        'count': typeof it.count === 'number' ? it.count : 0,
        'level': clampContributionLevel(typeof it.level === 'number' ? it.level : 0),
      } as ContributionDay;
      out.push(day);
    }
    return out;
  }
}
