/**
 * OfflineFallbackTest —— 离线降级与网络监视：
 *
 *  - DynamicService 在网络失败（NETWORK_ERROR）时应回退到 [DynamicDao](../../../main/ets/dao/DynamicDao.ets)
 *    缓存，结果 `fromCache=true` 且 list 来自缓存条目（与 [DynamicServiceTest](./DynamicServiceTest.ets) 同语义，
 *    但本测试聚焦「fromCache 是否正确回填」与 store.list 是否来自 dao 缓存）。
 *  - NetworkMonitor 通过注入 fake provider 模拟「断网 → 通知所有 onChange 监听者收到 false」，
 *    避免在 CI 上访问真实 `@ohos.net.connection`。
 */

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
import { SUCCESS, NETWORK_ERROR } from '../../../main/ets/net/NetworkCode';
import { ValueType, ValuesBucket } from '../../../main/ets/dao/db/RdbStore';
import { RdbStoreLike } from '../../../main/ets/dao/DaoBase';
import { DynamicDao, DYN_TABLE_RECEIVED } from '../../../main/ets/dao/DynamicDao';
import { DynamicService, FetchReceivedResult } from '../../../main/ets/service/DynamicService';
import { DynamicEvent, DynamicStore } from '../../../main/ets/store/DynamicStore';
import { NetworkMonitor, NetworkProvider } from '../../../main/ets/net/NetworkMonitor';

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

class FakeHttpProvider implements HttpProvider {
  nextStatus: number = SUCCESS;
  nextBody: string = '[]';

  async request(_url: string,
                _method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    return new RawResponse(this.nextStatus, this.nextBody, {});
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

class FakeNetworkProvider implements NetworkProvider {
  available: (() => void) | null = null;
  lost: (() => void) | null = null;
  startCount: number = 0;
  stopCount: number = 0;

  start(onAvailable: () => void, onLost: () => void): void {
    this.startCount = this.startCount + 1;
    this.available = onAvailable;
    this.lost = onLost;
  }

  stop(): void {
    this.stopCount = this.stopCount + 1;
    this.available = null;
    this.lost = null;
  }

  triggerLost(): void {
    if (this.lost !== null) {
      (this.lost as () => void)();
    }
  }

  triggerAvailable(): void {
    if (this.available !== null) {
      (this.available as () => void)();
    }
  }
}

const PAGE_SIZE: number = 3;
const TEST_USER: string = 'CarGuo';

function buildEvent(id: string, repoName: string): DynamicEvent {
  return {
    'id': id,
    'type': 'PushEvent',
    'actor': {
      'id': 1,
      'login': 'CarGuo',
      'display_login': 'CarGuo',
      'avatar_url': '',
    },
    'repo': {
      'id': 2,
      'name': repoName,
      'url': '',
    },
    'created_at': '2024-01-01T00:00:00Z',
    'payload': {} as Record<string, Object>,
  } as DynamicEvent;
}

function buildPayload(count: number, prefix: string): DynamicEvent[] {
  const out: DynamicEvent[] = [];
  for (let i = 0; i < count; i++) {
    out.push(buildEvent(prefix + '-' + i.toString(), 'CarGuo/repo' + i.toString()));
  }
  return out;
}

function buildRdb(): FakeRdbStore {
  const s: FakeRdbStore = new FakeRdbStore();
  s.setPrimaryKey(DYN_TABLE_RECEIVED, ['login']);
  return s;
}

export default function OfflineFallbackTest(): void {
  describe('OfflineFallbackTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let rdb: FakeRdbStore;
    let dao: DynamicDao;
    let store: DynamicStore;
    let service: DynamicService;
    let netProvider: FakeNetworkProvider;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      rdb = buildRdb();
      dao = new DynamicDao(rdb);
      store = new DynamicStore();
      service = new DynamicService(store, dao, PAGE_SIZE);
      netProvider = new FakeNetworkProvider();

      HttpManager.setMockProvider(provider);
      HttpManager.setTokenStorage(storage);
      HttpManager.setTimeout(15000);
      HttpManager.setAuthorization(null);
      LoginExpiredBus.clear();

      NetworkMonitor.clear();
      NetworkMonitor.setProvider(netProvider);
    });

    afterEach((): void => {
      HttpManager.setMockProvider(null);
      LoginExpiredBus.clear();
      NetworkMonitor.clear();
      NetworkMonitor.setProvider(null);
    });

    it('dynamic_service_falls_back_to_dao_cache_with_from_cache_true', 0,
      async (): Promise<void> => {
        const cached: DynamicEvent[] = buildPayload(2, 'cache');
        await dao.saveReceivedEvent(TEST_USER, JSON.stringify(cached));

        provider.nextStatus = NETWORK_ERROR;
        provider.nextBody = '';

        const res: FetchReceivedResult = await service.fetchReceivedEvents(TEST_USER, 1);

        expect(res.result).assertTrue();
        expect(res.fromCache).assertTrue();
        expect(res.data.length).assertEqual(2);
        expect(res.data[0].id).assertEqual('cache-0');
        expect(store.list.length).assertEqual(2);
        expect(store.list[0].id).assertEqual('cache-0');
        expect(store.list[1].id).assertEqual('cache-1');
        expect(store.error).assertEqual('');
      });

    it('dynamic_service_no_cache_returns_from_cache_false_and_error', 0,
      async (): Promise<void> => {
        provider.nextStatus = NETWORK_ERROR;
        provider.nextBody = '';

        const res: FetchReceivedResult = await service.fetchReceivedEvents(TEST_USER, 1);

        expect(res.result).assertFalse();
        expect(res.fromCache).assertFalse();
        expect(store.list.length).assertEqual(0);
        expect(store.error.length > 0).assertTrue();
      });

    it('network_monitor_onChange_receives_false_when_provider_loses', 0,
      async (): Promise<void> => {
        const observed: boolean[] = [];
        const unsubscribe: () => void = NetworkMonitor.onChange((online: boolean): void => {
          observed.push(online);
        });

        netProvider.triggerLost();

        expect(observed.length).assertEqual(1);
        expect(observed[0]).assertFalse();
        expect(NetworkMonitor.isOnline()).assertFalse();

        unsubscribe();
      });

    it('network_monitor_onChange_receives_true_after_recovery', 0,
      async (): Promise<void> => {
        const observed: boolean[] = [];
        const unsubscribe: () => void = NetworkMonitor.onChange((online: boolean): void => {
          observed.push(online);
        });

        netProvider.triggerLost();
        netProvider.triggerAvailable();

        expect(observed.length).assertEqual(2);
        expect(observed[0]).assertFalse();
        expect(observed[1]).assertTrue();
        expect(NetworkMonitor.isOnline()).assertTrue();

        unsubscribe();
      });

    it('network_monitor_unsubscribe_stops_callback', 0, async (): Promise<void> => {
      const observed: boolean[] = [];
      const unsubscribe: () => void = NetworkMonitor.onChange((online: boolean): void => {
        observed.push(online);
      });

      unsubscribe();
      netProvider.triggerLost();

      expect(observed.length).assertEqual(0);
    });

    it('network_monitor_dedupes_same_state', 0, async (): Promise<void> => {
      const observed: boolean[] = [];
      const unsubscribe: () => void = NetworkMonitor.onChange((online: boolean): void => {
        observed.push(online);
      });

      netProvider.triggerLost();
      netProvider.triggerLost();

      expect(observed.length).assertEqual(1);
      expect(observed[0]).assertFalse();

      unsubscribe();
    });
  });
}
