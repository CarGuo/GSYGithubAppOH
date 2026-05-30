import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import relationalStore from '@ohos.data.relationalStore';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
  TokenStorage,
  LoginExpiredBus,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS, UNAUTHORIZED, NETWORK_ERROR } from '../../../main/ets/net/NetworkCode';
import { Address } from '../../../main/ets/net/Address';
import { ValueType, ValuesBucket } from '../../../main/ets/dao/db/RdbStore';
import { RdbStoreLike } from '../../../main/ets/dao/DaoBase';
import { TrendDao, TREND_TABLE } from '../../../main/ets/dao/TrendDao';
import { TrendService, FetchTrendingResult } from '../../../main/ets/service/TrendService';
import {
  TrendRepo,
  TrendStore,
  TrendSince,
  TREND_SINCE_DAILY,
  TREND_SINCE_WEEKLY,
  TREND_LANGUAGE_ALL,
} from '../../../main/ets/store/TrendStore';

type FakeRow = Record<string, ValueType>;

class FakeCondition {
  column: string;
  value: ValueType;

  constructor(column: string, value: ValueType) {
    this.column = column;
    this.value = value;
  }
}

class FakePredicates {
  table: string;
  conditions: FakeCondition[] = [];

  constructor(table: string) {
    this.table = table;
  }

  equalTo(column: string, value: ValueType): FakePredicates {
    this.conditions.push(new FakeCondition(column, value));
    return this;
  }

  and(): FakePredicates {
    return this;
  }
}

class FakeResultSet {
  private rows: FakeRow[];
  private columns: string[];
  private cursor: number = -1;

  constructor(rows: FakeRow[], columns: string[]) {
    this.rows = rows;
    this.columns = columns;
  }

  get rowCount(): number {
    return this.rows.length;
  }

  goToFirstRow(): boolean {
    if (this.rows.length === 0) {
      return false;
    }
    this.cursor = 0;
    return true;
  }

  getColumnIndex(name: string): number {
    return this.columns.indexOf(name);
  }

  getString(index: number): string {
    const col: string = this.columns[index];
    const v: ValueType = this.rows[this.cursor][col];
    return typeof v === 'string' ? v : (v === null || v === undefined ? '' : String(v));
  }

  getLong(index: number): number {
    const col: string = this.columns[index];
    const v: ValueType = this.rows[this.cursor][col];
    return typeof v === 'number' ? v : 0;
  }

  close(): void {
    this.cursor = -1;
  }
}

class FakeRdbStore implements RdbStoreLike {
  private tables: Map<string, FakeRow[]> = new Map<string, FakeRow[]>();
  private primaryKeys: Map<string, string[]> = new Map<string, string[]>();
  insertCount: number = 0;
  queryCount: number = 0;

  setPrimaryKey(table: string, columns: string[]): void {
    this.primaryKeys.set(table, columns);
    if (!this.tables.has(table)) {
      this.tables.set(table, []);
    }
  }

  ensureTable(table: string): FakeRow[] {
    let rows: FakeRow[] | undefined = this.tables.get(table);
    if (rows === undefined) {
      rows = [];
      this.tables.set(table, rows);
    }
    return rows;
  }

  newPredicates(table: string): relationalStore.RdbPredicates {
    return new FakePredicates(table) as ESObject as relationalStore.RdbPredicates;
  }

  async insertOrReplace(table: string, values: ValuesBucket): Promise<number> {
    this.insertCount = this.insertCount + 1;
    const rows: FakeRow[] = this.ensureTable(table);
    const pk: string[] | undefined = this.primaryKeys.get(table);
    if (pk !== undefined && pk.length > 0) {
      for (let i = rows.length - 1; i >= 0; i--) {
        let match: boolean = true;
        for (let j = 0; j < pk.length; j++) {
          const col: string = pk[j];
          if (this.toCompare(rows[i][col]) !== this.toCompare(values[col])) {
            match = false;
            break;
          }
        }
        if (match) {
          rows.splice(i, 1);
        }
      }
    }
    const row: FakeRow = {};
    const keys: string[] = Object.keys(values);
    for (let i = 0; i < keys.length; i++) {
      row[keys[i]] = values[keys[i]];
    }
    rows.push(row);
    return rows.length;
  }

  async query(predicates: relationalStore.RdbPredicates,
    columns?: string[]): Promise<relationalStore.ResultSet> {
    this.queryCount = this.queryCount + 1;
    const fp: FakePredicates = predicates as ESObject as FakePredicates;
    const rows: FakeRow[] = this.ensureTable(fp.table);
    const filtered: FakeRow[] = [];
    for (let i = 0; i < rows.length; i++) {
      if (this.matchConditions(rows[i], fp.conditions)) {
        filtered.push(rows[i]);
      }
    }
    const cols: string[] = columns !== undefined && columns.length > 0
      ? columns
      : (filtered.length > 0 ? Object.keys(filtered[0]) : []);
    return new FakeResultSet(filtered, cols) as ESObject as relationalStore.ResultSet;
  }

  async deleteByPredicates(predicates: relationalStore.RdbPredicates): Promise<number> {
    const fp: FakePredicates = predicates as ESObject as FakePredicates;
    const rows: FakeRow[] = this.ensureTable(fp.table);
    let removed: number = 0;
    for (let i = rows.length - 1; i >= 0; i--) {
      if (this.matchConditions(rows[i], fp.conditions)) {
        rows.splice(i, 1);
        removed = removed + 1;
      }
    }
    return removed;
  }

  async deleteAllInTable(table: string): Promise<number> {
    const rows: FakeRow[] = this.ensureTable(table);
    const n: number = rows.length;
    rows.length = 0;
    return n;
  }

  private toCompare(v: ValueType): string {
    if (v === null || v === undefined) {
      return '';
    }
    return String(v);
  }

  private matchConditions(row: FakeRow, conditions: FakeCondition[]): boolean {
    for (let i = 0; i < conditions.length; i++) {
      const c: FakeCondition = conditions[i];
      if (this.toCompare(row[c.column]) !== this.toCompare(c.value)) {
        return false;
      }
    }
    return true;
  }
}

class CapturedRequest {
  url: string = '';
  method: string = '';
}

class FakeHttpProvider implements HttpProvider {
  nextStatus: number = SUCCESS;
  nextBody: string = '[]';
  nextHeaders: HttpHeaders = {};
  shouldThrow: boolean = false;
  callCount: number = 0;
  captured: CapturedRequest = new CapturedRequest();
  responses: RawResponse[] = [];

  pushResponse(status: number, body: string): void {
    this.responses.push(new RawResponse(status, body, {}));
  }

  async request(url: string,
                method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    this.captured.url = url;
    this.captured.method = method;
    if (this.shouldThrow) {
      throw new Error('boom');
    }
    if (this.responses.length > 0) {
      const head: RawResponse | undefined = this.responses.shift();
      return head as RawResponse;
    }
    return new RawResponse(this.nextStatus, this.nextBody, this.nextHeaders);
  }
}

class FakeTokenStorage implements TokenStorage {
  value: string | null = null;

  async load(): Promise<string | null> {
    return this.value;
  }

  async save(token: string): Promise<void> {
    this.value = token;
  }

  async clear(): Promise<void> {
    this.value = null;
  }
}

function buildRepo(author: string, name: string, language: string, stars: number,
                   description: string): TrendRepo {
  return {
    'author': author,
    'name': name,
    'avatar': '',
    'url': 'https://github.com/' + author + '/' + name,
    'description': description,
    'language': language,
    'languageColor': '#000000',
    'stars': stars,
    'forks': 0,
    'currentPeriodStars': 0,
    'builtBy': [],
  } as TrendRepo;
}

function buildPayload(count: number, prefix: string, language: string): TrendRepo[] {
  const out: TrendRepo[] = [];
  for (let i = 0; i < count; i++) {
    out.push(buildRepo('CarGuo' + i.toString(), prefix + '-' + i.toString(),
      language, 100 + i, 'desc-' + i.toString()));
  }
  return out;
}

class ComposeTrendingRawPayload {
  fullName: string = 'CarGuoUI/ComposeTrend';
  url: string = 'https://github.com/CarGuoUI/ComposeTrend';
  description: string = 'Compose trend row';
  language: string = 'Kotlin';
  contributors: string[] = ['https://avatars.githubusercontent.com/u/1?v=4'];
  starCount: string = '1,234';
  forkCount: string = '56';
  name: string = 'CarGuoUI';
  reposName: string = 'ComposeTrend';
}

function buildStore(): FakeRdbStore {
  const s: FakeRdbStore = new FakeRdbStore();
  s.setPrimaryKey(TREND_TABLE, ['since', 'lang']);
  return s;
}

export default function TrendServiceTest(): void {
  describe('TrendServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let rdb: FakeRdbStore;
    let dao: TrendDao;
    let store: TrendStore;
    let service: TrendService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      rdb = buildStore();
      dao = new TrendDao(rdb);
      store = new TrendStore();
      service = new TrendService(store, dao);

      HttpManager.setMockProvider(provider);
      HttpManager.setTokenStorage(storage);
      HttpManager.setTimeout(15000);
      HttpManager.setAuthorization(null);
      LoginExpiredBus.clear();
    });

    afterEach((): void => {
      HttpManager.setMockProvider(null);
      LoginExpiredBus.clear();
    });

    it('uses_trending_url_with_since_and_language', 0, async (): Promise<void> => {
      const repos: TrendRepo[] = buildPayload(2, 'daily', 'TypeScript');
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(repos);

      await service.fetchTrending(TREND_SINCE_DAILY, 'typescript');

      const expected: string = Address.trendingApi(TREND_SINCE_DAILY, 'typescript');
      expect(provider.captured.url).assertEqual(expected);
      expect(provider.captured.method).assertEqual('GET');
    });

    it('all_language_emits_no_language_param', 0, async (): Promise<void> => {
      const repos: TrendRepo[] = buildPayload(1, 'daily', 'Java');
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(repos);

      await service.fetchTrending(TREND_SINCE_WEEKLY, TREND_LANGUAGE_ALL);

      const expected: string = Address.trendingApi(TREND_SINCE_WEEKLY, null);
      expect(provider.captured.url).assertEqual(expected);
    });

    it('first_load_success_writes_cache_and_updates_store', 0, async (): Promise<void> => {
      const repos: TrendRepo[] = buildPayload(3, 'first', 'Go');
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(repos);

      const res: FetchTrendingResult = await service.fetchTrending(TREND_SINCE_DAILY, 'go');

      expect(res.result).assertTrue();
      expect(res.fromCache).assertFalse();
      expect(res.data.length).assertEqual(3);
      expect(rdb.insertCount).assertEqual(1);
      expect(store.list.length).assertEqual(3);
      expect(store.since).assertEqual(TREND_SINCE_DAILY);
      expect(store.language).assertEqual('go');
      expect(store.loading).assertFalse();
      expect(store.error).assertEqual('');

      const cached = await dao.readTrend(TREND_SINCE_DAILY, 'go');
      expect(cached.result).assertTrue();
      const parsed: Object = JSON.parse(cached.data) as Object;
      expect(Array.isArray(parsed)).assertTrue();
      expect((parsed as TrendRepo[]).length).assertEqual(3);
    });

    it('maps_compose_trending_model_full_name_and_counts', 0, async (): Promise<void> => {
      const raw: ComposeTrendingRawPayload[] = [new ComposeTrendingRawPayload()];
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(raw);

      const res: FetchTrendingResult = await service.fetchTrending(TREND_SINCE_DAILY, TREND_LANGUAGE_ALL);

      expect(res.result).assertTrue();
      expect(res.data.length).assertEqual(1);
      expect(res.data[0].author).assertEqual('CarGuoUI');
      expect(res.data[0].name).assertEqual('ComposeTrend');
      expect(res.data[0].stars).assertEqual(1234);
      expect(res.data[0].forks).assertEqual(56);
      expect(res.data[0].avatar).assertEqual('https://avatars.githubusercontent.com/u/1?v=4');
    });

    it('failure_falls_back_to_cache', 0, async (): Promise<void> => {
      const cachedRepos: TrendRepo[] = buildPayload(2, 'cache', 'Python');
      await dao.saveTrend(TREND_SINCE_WEEKLY, 'python', JSON.stringify(cachedRepos));

      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: FetchTrendingResult = await service.fetchTrending(TREND_SINCE_WEEKLY, 'python');

      expect(res.result).assertTrue();
      expect(res.fromCache).assertTrue();
      expect(res.data.length).assertEqual(2);
      expect(store.list.length).assertEqual(2);
      expect(store.since).assertEqual(TREND_SINCE_WEEKLY);
      expect(store.language).assertEqual('python');
      expect(store.error).assertEqual('');
    });

    it('failure_without_cache_sets_error', 0, async (): Promise<void> => {
      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: FetchTrendingResult = await service.fetchTrending(TREND_SINCE_DAILY, 'java');

      expect(res.result).assertFalse();
      expect(res.fromCache).assertFalse();
      expect(store.list.length).assertEqual(0);
      expect(store.error.length > 0).assertTrue();
      expect(store.loading).assertFalse();
    });

    it('on_401_keeps_cache_visible_after_cache_first_emit', 0, async (): Promise<void> => {
      const cachedRepos: TrendRepo[] = buildPayload(2, 'cache', 'Python');
      await dao.saveTrend(TREND_SINCE_DAILY, 'python', JSON.stringify(cachedRepos));

      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '';

      const res: FetchTrendingResult = await service.fetchTrending(TREND_SINCE_DAILY, 'python');

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(res.fromCache).assertFalse();
      expect(store.list.length).assertEqual(2);
      expect(store.error.length > 0).assertTrue();
    });

    it('switching_since_and_language_uses_distinct_cache_keys', 0, async (): Promise<void> => {
      const dayRepos: TrendRepo[] = buildPayload(2, 'day', 'Java');
      const weekRepos: TrendRepo[] = buildPayload(3, 'week', 'TypeScript');
      provider.pushResponse(SUCCESS, JSON.stringify(dayRepos));
      provider.pushResponse(SUCCESS, JSON.stringify(weekRepos));

      await service.fetchTrending(TREND_SINCE_DAILY, 'java');
      expect(store.list.length).assertEqual(2);

      await service.fetchTrending(TREND_SINCE_WEEKLY, 'typescript');
      expect(store.list.length).assertEqual(3);

      const dayCache = await dao.readTrend(TREND_SINCE_DAILY, 'java');
      const weekCache = await dao.readTrend(TREND_SINCE_WEEKLY, 'typescript');
      expect(dayCache.result).assertTrue();
      expect(weekCache.result).assertTrue();
      const dayParsed: TrendRepo[] = JSON.parse(dayCache.data) as TrendRepo[];
      const weekParsed: TrendRepo[] = JSON.parse(weekCache.data) as TrendRepo[];
      expect(dayParsed.length).assertEqual(2);
      expect(weekParsed.length).assertEqual(3);
    });

    it('store_marks_loading_during_request', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = '[]';

      const promise: Promise<FetchTrendingResult> = service.fetchTrending(TREND_SINCE_DAILY,
        TREND_LANGUAGE_ALL);
      expect(store.loading).assertTrue();
      await promise;
      expect(store.loading).assertFalse();
    });
  });
}
