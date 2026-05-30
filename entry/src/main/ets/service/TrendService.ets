import HttpManager from '../net/HttpManager';
import { Address } from '../net/Address';
import { HttpResult, HttpHeaders } from '../net/Result';
import { UNAUTHORIZED } from '../net/NetworkCode';
import { TrendDao } from '../dao/TrendDao';
import { ReadResult } from '../dao/DaoBase';
import {
  TrendRepo,
  TrendStore,
  TrendSince,
  TREND_LANGUAGE_ALL,
} from '../store/TrendStore';

const TRENDING_API_TOKEN: string = '4d65e2a5626103f92a71867d7b49fea0';

interface TrendApiRawItem {
  fullName?: string;
  author?: string;
  avatar?: string;
  url?: string;
  description?: string;
  language?: string;
  languageColor?: string;
  meta?: string;
  contributors?: string[];
  contributorsUrl?: string;
  starCount?: string;
  forkCount?: string;
  stars?: number;
  forks?: number;
  currentPeriodStars?: number;
  builtBy?: TrendBuiltBySafe[];
  name?: string;
  reposName?: string;
  des?: string;
}

function parseIntSafe(value: string | number | undefined): number {
  if (value === undefined || value === null) {
    return 0;
  }
  if (typeof value === 'number') {
    return isNaN(value) ? 0 : value;
  }
  const cleaned: string = value.replace(/[,\s]/g, '');
  if (cleaned.length === 0) {
    return 0;
  }
  const n: number = parseInt(cleaned, 10);
  return isNaN(n) ? 0 : n;
}

function parseStarsTodayFromMeta(meta: string | undefined): number {
  if (meta === undefined || meta === null || meta.length === 0) {
    return -1;
  }
  const match: RegExpMatchArray | null = meta.match(/([\d,]+)\s*stars?/i);
  if (match === null || match.length < 2) {
    return -1;
  }
  return parseIntSafe(match[1]);
}

function adaptApiItemToRepo(raw: TrendApiRawItem): TrendRepo {
  const fullName: string = raw.fullName && raw.fullName.length > 0 ? raw.fullName : '';
  const slash: number = fullName.indexOf('/');
  const fullOwner: string = slash > 0 ? fullName.substring(0, slash) : '';
  const fullRepo: string = slash > 0 && slash < fullName.length - 1 ? fullName.substring(slash + 1) : '';
  const author: string = raw.author && raw.author.length > 0
    ? raw.author
    : (fullOwner.length > 0 ? fullOwner : (raw.name && raw.name.length > 0 ? raw.name : ''));
  const reposName: string = raw.reposName && raw.reposName.length > 0
    ? raw.reposName
    : (fullRepo.length > 0 ? fullRepo : (raw.author && raw.author.length > 0 && raw.name ? raw.name : ''));
  const avatar: string = raw.avatar && raw.avatar.length > 0
    ? raw.avatar
    : (raw.contributorsUrl && raw.contributorsUrl.length > 0
    ? raw.contributorsUrl
    : (raw.contributors && raw.contributors.length > 0 ? raw.contributors[0] : ''));
  const url: string = raw.url && raw.url.length > 0 ? raw.url : '';
  const desc: string = raw.description && raw.description.length > 0
    ? raw.description
    : (raw.des && raw.des.length > 0 ? raw.des : '');
  const lang: string = raw.language && raw.language.length > 0 ? raw.language : '';
  const stars: number = raw.stars !== undefined && raw.stars !== null ? raw.stars : parseIntSafe(raw.starCount);
  const forks: number = raw.forks !== undefined && raw.forks !== null ? raw.forks : parseIntSafe(raw.forkCount);
  const today: number = raw.currentPeriodStars !== undefined && raw.currentPeriodStars !== null
    ? raw.currentPeriodStars
    : parseStarsTodayFromMeta(raw.meta);
  let builtBy: TrendBuiltBySafe[] = [];
  if (raw.builtBy !== undefined && raw.builtBy !== null) {
    builtBy = raw.builtBy;
  } else {
    const contributors: string[] = raw.contributors !== undefined && raw.contributors !== null
      ? raw.contributors : [];
    for (let i = 0; i < contributors.length; i++) {
      const a: string = contributors[i];
      builtBy.push({
        href: '',
        avatar: a,
        username: '',
      } as TrendBuiltBySafe);
    }
  }
  return {
    author: author,
    name: reposName,
    avatar: avatar,
    url: url,
    description: desc,
    language: lang,
    languageColor: raw.languageColor && raw.languageColor.length > 0 ? raw.languageColor : '',
    stars: stars,
    forks: forks,
    currentPeriodStars: today,
    builtBy: builtBy,
  } as TrendRepo;
}

interface TrendBuiltBySafe {
  href: string;
  avatar: string;
  username: string;
}

export class FetchTrendingResult {
  result: boolean;
  code: number;
  data: TrendRepo[];
  fromCache: boolean;
  msg: string;

  constructor(result: boolean, code: number, data: TrendRepo[], fromCache: boolean, msg: string) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.fromCache = fromCache;
    this.msg = msg;
  }
}

export class TrendService {
  private store: TrendStore;
  private dao: TrendDao;

  constructor(store: TrendStore, dao?: TrendDao) {
    this.store = store;
    this.dao = dao !== undefined ? dao : new TrendDao();
  }

  getStore(): TrendStore {
    return this.store;
  }

  getDao(): TrendDao {
    return this.dao;
  }

  async fetchTrending(since: TrendSince, language: string): Promise<FetchTrendingResult> {
    const finalLanguage: string = language && language.length > 0 ? language : TREND_LANGUAGE_ALL;
    this.store.setSince(since);
    this.store.setLanguage(finalLanguage);
    this.store.startLoading();
    const cached: TrendRepo[] = await this.readCache(since, finalLanguage);
    if (cached.length > 0) {
      this.store.applyCachedFallback(cached);
    }
    this.store.startLoading();

    const lang: string | null = finalLanguage.length > 0 ? finalLanguage : null;
    // 对齐 RN：[repositoryDao.js#L15-L23] 用 https://guoshuyu.cn/github/trend/list + api-token header
    const url: string = Address.trendingApi(since, lang);
    const headers: HttpHeaders = {
      'api-token': TRENDING_API_TOKEN,
    };
    const httpResult: HttpResult<TrendApiRawItem[]> =
      await HttpManager.getFetch<TrendApiRawItem[]>(url, headers);

    if (httpResult.result && httpResult.data !== null) {
      const rawList: TrendApiRawItem[] = httpResult.data as TrendApiRawItem[];
      const repos: TrendRepo[] = [];
      for (let i = 0; i < rawList.length; i++) {
        repos.push(adaptApiItemToRepo(rawList[i]));
      }
      try {
        await this.dao.saveTrend(since, finalLanguage, JSON.stringify(repos));
      } catch (_e) {
      }
      this.store.applyRefresh(repos);
      return new FetchTrendingResult(true, httpResult.code, repos, false, '');
    }

    if (httpResult.code === UNAUTHORIZED) {
      const msg: string = httpResult.msg !== null ? httpResult.msg : 'unauthorized';
      this.store.setError(msg);
      return new FetchTrendingResult(false, UNAUTHORIZED, [], false, msg);
    }

    if (cached.length > 0) {
      this.store.applyCachedFallback(cached);
      return new FetchTrendingResult(true, httpResult.code, cached, true,
        httpResult.msg !== null ? httpResult.msg : '');
    }

    const failMsg: string = httpResult.msg !== null ? httpResult.msg : 'network error';
    this.store.setError(failMsg);
    return new FetchTrendingResult(false, httpResult.code, [], false, failMsg);
  }

  private async readCache(since: TrendSince, language: string): Promise<TrendRepo[]> {
    try {
      const cache: ReadResult = await this.dao.readTrend(since, language);
      if (!cache.result || cache.data.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(cache.data) as Object;
      if (Array.isArray(parsed)) {
        return parsed as TrendRepo[];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }
}
