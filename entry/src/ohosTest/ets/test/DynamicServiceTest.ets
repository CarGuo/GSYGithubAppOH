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
import {
  DynamicDao,
  DYN_TABLE_RECEIVED,
  DYN_TABLE_USER_EVENT,
} from '../../../main/ets/dao/DynamicDao';
import { DynamicService, FetchReceivedResult } from '../../../main/ets/service/DynamicService';
import { DynamicEvent, DynamicStore } from '../../../main/ets/store/DynamicStore';

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

  rowCountOf(table: string): number {
    return this.ensureTable(table).length;
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

const PAGE_SIZE: number = 3;
const TEST_USER: string = 'CarGuo';

function buildEvent(id: string, type: string, login: string, repoName: string,
  createdAt: string): DynamicEvent {
  return {
    'id': id,
    'type': type,
    'actor': {
      'id': 1,
      'login': login,
      'display_login': login,
      'avatar_url': '',
    },
    'repo': {
      'id': 2,
      'name': repoName,
      'url': '',
    },
    'created_at': createdAt,
    'payload': {} as Record<string, Object>,
  } as DynamicEvent;
}

function buildPayload(count: number, prefix: string): DynamicEvent[] {
  const out: DynamicEvent[] = [];
  for (let i = 0; i < count; i++) {
    out.push(buildEvent(prefix + '-' + i.toString(), 'PushEvent', 'CarGuo',
      'CarGuo/repo' + i.toString(), '2024-01-01T00:00:00Z'));
  }
  return out;
}

function buildStore(): FakeRdbStore {
  const s: FakeRdbStore = new FakeRdbStore();
  s.setPrimaryKey(DYN_TABLE_RECEIVED, ['login']);
  s.setPrimaryKey(DYN_TABLE_USER_EVENT, ['login']);
  return s;
}

export default function DynamicServiceTest(): void {
  describe('DynamicServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let rdb: FakeRdbStore;
    let dao: DynamicDao;
    let store: DynamicStore;
    let service: DynamicService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      rdb = buildStore();
      dao = new DynamicDao(rdb);
      store = new DynamicStore();
      service = new DynamicService(store, dao, PAGE_SIZE);

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

    it('uses_received_event_url_with_page_and_per_page', 0, async (): Promise<void> => {
      const events: DynamicEvent[] = buildPayload(PAGE_SIZE, 'a');
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(events);

      await service.fetchReceivedEvents(TEST_USER, 1);

      const expected: string = Address.getReceivedEvent(TEST_USER, 1, PAGE_SIZE);
      expect(provider.captured.url).assertEqual(expected);
      expect(provider.captured.method).assertEqual('GET');
    });

    it('first_page_success_writes_cache_and_updates_store', 0, async (): Promise<void> => {
      const events: DynamicEvent[] = buildPayload(PAGE_SIZE, 'first');
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(events);

      const res: FetchReceivedResult = await service.fetchReceivedEvents(TEST_USER, 1);

      expect(res.result).assertTrue();
      expect(res.fromCache).assertFalse();
      expect(res.data.length).assertEqual(PAGE_SIZE);
      expect(rdb.insertCount).assertEqual(1);
      expect(store.list.length).assertEqual(PAGE_SIZE);
      expect(store.page).assertEqual(1);
      expect(store.hasMore).assertTrue();
      expect(store.loading).assertFalse();
      expect(store.error).assertEqual('');

      const cached = await dao.readReceivedEvent(TEST_USER);
      expect(cached.result).assertTrue();
      const parsed: Object = JSON.parse(cached.data) as Object;
      expect(Array.isArray(parsed)).assertTrue();
      expect((parsed as DynamicEvent[]).length).assertEqual(PAGE_SIZE);
    });

    it('failure_falls_back_to_cache_on_first_page', 0, async (): Promise<void> => {
      const cachedEvents: DynamicEvent[] = buildPayload(2, 'cache');
      await dao.saveReceivedEvent(TEST_USER, JSON.stringify(cachedEvents));

      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: FetchReceivedResult = await service.fetchReceivedEvents(TEST_USER, 1);

      expect(res.result).assertTrue();
      expect(res.fromCache).assertTrue();
      expect(res.data.length).assertEqual(2);
      expect(store.list.length).assertEqual(2);
      expect(store.hasMore).assertFalse();
      expect(store.error).assertEqual('');
    });

    it('failure_without_cache_sets_error_and_keeps_list_empty', 0, async (): Promise<void> => {
      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: FetchReceivedResult = await service.fetchReceivedEvents(TEST_USER, 1);

      expect(res.result).assertFalse();
      expect(res.fromCache).assertFalse();
      expect(store.list.length).assertEqual(0);
      expect(store.error.length > 0).assertTrue();
      expect(store.loading).assertFalse();
    });

    it('hasMore_true_when_full_page_and_false_when_short_page', 0, async (): Promise<void> => {
      const fullPage: DynamicEvent[] = buildPayload(PAGE_SIZE, 'p1');
      const shortPage: DynamicEvent[] = buildPayload(1, 'p2');
      provider.pushResponse(SUCCESS, JSON.stringify(fullPage));
      provider.pushResponse(SUCCESS, JSON.stringify(shortPage));

      const r1: FetchReceivedResult = await service.fetchReceivedEvents(TEST_USER, 1);
      expect(r1.result).assertTrue();
      expect(store.hasMore).assertTrue();
      expect(store.list.length).assertEqual(PAGE_SIZE);
      expect(store.page).assertEqual(1);

      const r2: FetchReceivedResult = await service.fetchReceivedEvents(TEST_USER, 2);
      expect(r2.result).assertTrue();
      expect(store.hasMore).assertFalse();
      expect(store.list.length).assertEqual(PAGE_SIZE + 1);
      expect(store.page).assertEqual(2);
    });

    it('second_page_does_not_write_cache', 0, async (): Promise<void> => {
      const fullPage: DynamicEvent[] = buildPayload(PAGE_SIZE, 'p1');
      const secondPage: DynamicEvent[] = buildPayload(PAGE_SIZE, 'p2');
      provider.pushResponse(SUCCESS, JSON.stringify(fullPage));
      provider.pushResponse(SUCCESS, JSON.stringify(secondPage));

      await service.fetchReceivedEvents(TEST_USER, 1);
      const writesAfterFirst: number = rdb.insertCount;

      await service.fetchReceivedEvents(TEST_USER, 2);
      expect(rdb.insertCount).assertEqual(writesAfterFirst);
      expect(store.list.length).assertEqual(PAGE_SIZE * 2);
    });

    it('on_401_publishes_login_expired_and_keeps_list_empty', 0, async (): Promise<void> => {
      let fired: number = 0;
      LoginExpiredBus.subscribe((): void => {
        fired = fired + 1;
      });
      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '{"message":"Bad credentials"}';

      const res: FetchReceivedResult = await service.fetchReceivedEvents(TEST_USER, 1);

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(fired).assertEqual(1);
      expect(store.list.length).assertEqual(0);
      expect(store.error.length > 0).assertTrue();
      expect(store.loading).assertFalse();
    });

    it('on_401_keeps_cache_visible_after_cache_first_emit', 0, async (): Promise<void> => {
      const cachedEvents: DynamicEvent[] = buildPayload(2, 'cache');
      await dao.saveReceivedEvent(TEST_USER, JSON.stringify(cachedEvents));

      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '';

      const res: FetchReceivedResult = await service.fetchReceivedEvents(TEST_USER, 1);

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(res.fromCache).assertFalse();
      expect(store.list.length).assertEqual(2);
    });

    it('empty_user_does_not_request_network', 0, async (): Promise<void> => {
      const res: FetchReceivedResult = await service.fetchReceivedEvents('', 1);

      expect(res.result).assertFalse();
      expect(provider.callCount).assertEqual(0);
      expect(store.error.length > 0).assertTrue();
    });

    it('fetchUserEvents_uses_user_event_url_with_page_and_per_page',
      0, async (): Promise<void> => {
        const events: DynamicEvent[] = buildPayload(PAGE_SIZE, 'ue');
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(events);

        await service.fetchUserEvents(TEST_USER, 1);

        const expected: string = Address.getUserEvent(TEST_USER, 1, PAGE_SIZE);
        expect(provider.captured.url).assertEqual(expected);
        expect(provider.captured.method).assertEqual('GET');
      });

    it('fetchUserEvents_first_page_writes_user_event_cache_and_updates_store',
      0, async (): Promise<void> => {
        const events: DynamicEvent[] = buildPayload(PAGE_SIZE, 'ue-first');
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(events);

        const res: FetchReceivedResult = await service.fetchUserEvents(TEST_USER, 1);

        expect(res.result).assertTrue();
        expect(res.fromCache).assertFalse();
        expect(store.list.length).assertEqual(PAGE_SIZE);
        expect(store.page).assertEqual(1);
        expect(rdb.rowCountOf(DYN_TABLE_USER_EVENT)).assertEqual(1);
        expect(rdb.rowCountOf(DYN_TABLE_RECEIVED)).assertEqual(0);
      });

    it('fetchUserEvents_appends_on_second_page_and_updates_has_more',
      0, async (): Promise<void> => {
        const fullPage: DynamicEvent[] = buildPayload(PAGE_SIZE, 'ue-p1');
        const shortPage: DynamicEvent[] = buildPayload(1, 'ue-p2');
        provider.pushResponse(SUCCESS, JSON.stringify(fullPage));
        provider.pushResponse(SUCCESS, JSON.stringify(shortPage));

        const r1: FetchReceivedResult = await service.fetchUserEvents(TEST_USER, 1);
        expect(r1.result).assertTrue();
        expect(store.hasMore).assertTrue();
        expect(store.page).assertEqual(1);

        const r2: FetchReceivedResult = await service.fetchUserEvents(TEST_USER, 2);
        expect(r2.result).assertTrue();
        expect(store.hasMore).assertFalse();
        expect(store.list.length).assertEqual(PAGE_SIZE + 1);
        expect(store.page).assertEqual(2);
      });

    it('fetchUserEvents_falls_back_to_user_event_cache_on_network_error',
      0, async (): Promise<void> => {
        const cached: DynamicEvent[] = buildPayload(2, 'ue-cache');
        await dao.saveUserEvent(TEST_USER, JSON.stringify(cached));

        provider.nextStatus = NETWORK_ERROR;
        provider.nextBody = '';

        const res: FetchReceivedResult = await service.fetchUserEvents(TEST_USER, 1);

        expect(res.result).assertTrue();
        expect(res.fromCache).assertTrue();
        expect(store.list.length).assertEqual(2);
      });

    it('fetchUserEvents_on_401_publishes_login_expired_and_keeps_list_empty',
      0, async (): Promise<void> => {
        let fired: number = 0;
        LoginExpiredBus.subscribe((): void => {
          fired = fired + 1;
        });
        provider.nextStatus = UNAUTHORIZED;
        provider.nextBody = '{"message":"Bad credentials"}';

        const res: FetchReceivedResult = await service.fetchUserEvents(TEST_USER, 1);

        expect(res.result).assertFalse();
        expect(res.code).assertEqual(UNAUTHORIZED);
        expect(fired).assertEqual(1);
        expect(store.list.length).assertEqual(0);
      });

    it('fetchUserEvents_empty_user_does_not_request_network',
      0, async (): Promise<void> => {
        const res: FetchReceivedResult = await service.fetchUserEvents('', 1);
        expect(res.result).assertFalse();
        expect(provider.callCount).assertEqual(0);
        expect(store.error.length > 0).assertTrue();
      });
  });
}
