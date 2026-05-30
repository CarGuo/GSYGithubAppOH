/**
 * MyService 单测：
 *
 * 复用 [DynamicServiceTest](./DynamicServiceTest.ets) / [AuthStoreTest](./AuthStoreTest.ets)
 * 的同款 FakeHttpProvider + FakeRdb 协议，验证：
 *   - GET /user 200：写 MyStore.user / AuthStore.userInfo / UserDao(UserInfo)。
 *   - GET /user 401：MyStore.error 非空 + AuthStore.clear（authed=false）。
 *   - 网络异常：MyStore.error 非空，但 AuthStore 不被清空。
 *   - JSON 不含 login：归类为解析失败，store.error 非空。
 *
 * 不依赖真实网络与 RDB，可在 ohosTest 上稳定执行。
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
import {
  SUCCESS,
  UNAUTHORIZED,
  NETWORK_ERROR,
} from '../../../main/ets/net/NetworkCode';
import { Address } from '../../../main/ets/net/Address';
import { ValueType, ValuesBucket } from '../../../main/ets/dao/db/RdbStore';
import { RdbStoreLike } from '../../../main/ets/dao/DaoBase';
import { UserDao, USER_TABLE_INFO } from '../../../main/ets/dao/UserDao';
import {
  AuthStore,
  AuthUserInfo,
  APP_STORAGE_KEY_USER_INFO,
} from '../../../main/ets/store/AuthStore';
import { MyStore } from '../../../main/ets/store/MyStore';
import { MyService, RefreshMeResult, FetchUnReadResult, FetchUserOrgsResult, FetchStarredCountResult, MyOrgItem } from '../../../main/ets/service/MyService';

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

  goToNextRow(): boolean {
    if (this.cursor + 1 >= this.rows.length) {
      this.cursor = this.rows.length;
      return false;
    }
    this.cursor = this.cursor + 1;
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
    const fp: FakePredicates = predicates as ESObject as FakePredicates;
    const rows: FakeRow[] = this.ensureTable(fp.table);
    const out: FakeRow[] = [];
    for (let i = 0; i < rows.length; i++) {
      if (this.matchConditions(rows[i], fp.conditions)) {
        out.push(rows[i]);
      }
    }
    const cols: string[] = columns !== undefined && columns.length > 0
      ? columns
      : (out.length > 0 ? Object.keys(out[0]) : []);
    return new FakeResultSet(out, cols) as ESObject as relationalStore.ResultSet;
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

  rowAt(table: string, index: number): FakeRow {
    return this.ensureTable(table)[index];
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
  url: string;
  method: string;
  headers: HttpHeaders;
  body: string | null;

  constructor(url: string, method: string, headers: HttpHeaders, body: string | null) {
    this.url = url;
    this.method = method;
    this.headers = headers;
    this.body = body;
  }
}

class FakeHttpProvider implements HttpProvider {
  nextStatus: number = SUCCESS;
  nextBody: string = '{}';
  captured: CapturedRequest[] = [];
  callCount: number = 0;
  routedStatuses: Map<string, number> = new Map<string, number>();
  routedBodies: Map<string, string> = new Map<string, string>();
  onRequest: (() => void) | null = null;

  async request(url: string,
                method: string,
                headers: HttpHeaders,
                body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    this.captured.push(new CapturedRequest(url, method, headers, body));
    if (this.onRequest !== null) {
      (this.onRequest as () => void)();
    }
    let status: number = this.nextStatus;
    let respBody: string = this.nextBody;
    const keys: IterableIterator<string> = this.routedBodies.keys();
    let next: IteratorResult<string> = keys.next();
    while (!next.done) {
      const key: string = next.value;
      if (url.indexOf(key) >= 0) {
        respBody = this.routedBodies.get(key) as string;
        const s: number | undefined = this.routedStatuses.get(key);
        status = s !== undefined ? s : SUCCESS;
        break;
      }
      next = keys.next();
    }
    return new RawResponse(status, respBody, {});
  }

  routeByUrlContains(keyword: string, status: number, body: string): void {
    this.routedStatuses.set(keyword, status);
    this.routedBodies.set(keyword, body);
  }

  lastByMethod(method: string): CapturedRequest | null {
    for (let i = this.captured.length - 1; i >= 0; i--) {
      if (this.captured[i].method === method) {
        return this.captured[i];
      }
    }
    return null;
  }

  lastByUrlContains(keyword: string): CapturedRequest | null {
    for (let i = this.captured.length - 1; i >= 0; i--) {
      if (this.captured[i].url.indexOf(keyword) >= 0) {
        return this.captured[i];
      }
    }
    return null;
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

const USER_JSON: string =
  '{"login":"CarGuo","name":"gsy","avatar_url":"https://x/y.png",' +
  '"html_url":"https://github.com/CarGuo","bio":"Hello GSY",' +
  '"followers":12,"following":34,"public_repos":56}';

export default function MyServiceTest(): void {
  describe('MyServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let rdb: FakeRdbStore;
    let userDao: UserDao;
    let myStore: MyStore;
    let authStore: AuthStore;
    let service: MyService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      rdb = new FakeRdbStore();
      rdb.setPrimaryKey(USER_TABLE_INFO, ['login']);
      userDao = new UserDao(rdb);
      myStore = new MyStore();
      myStore.reset();
      authStore = new AuthStore();
      authStore.clear();
      service = new MyService(myStore, authStore, userDao);

      HttpManager.setMockProvider(provider);
      HttpManager.setTokenStorage(storage);
      HttpManager.setTimeout(15000);
      HttpManager.setAuthorization('token preset_token');
      LoginExpiredBus.clear();
    });

    afterEach((): void => {
      HttpManager.setMockProvider(null);
      LoginExpiredBus.clear();
      AppStorage.setOrCreate<string>(APP_STORAGE_KEY_USER_INFO, '');
    });

    it('refreshMe_calls_GET_user_endpoint', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = USER_JSON;

      await service.refreshMe();

      const last: CapturedRequest | null = provider.lastByMethod('GET');
      expect(last !== null).assertTrue();
      expect((last as CapturedRequest).url).assertEqual(Address.getMyUserInfo());
      expect((last as CapturedRequest).method).assertEqual('GET');
    });

    it('refreshMe_success_writes_my_store_and_auth_store_and_userdao',
      0, async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = USER_JSON;
        authStore.setUser('token preset_token',
          new AuthUserInfo('CarGuo', '', '', '', USER_JSON));

        const res: RefreshMeResult = await service.refreshMe();

        expect(res.result).assertTrue();
        expect(res.code).assertEqual(SUCCESS);
        expect(res.data !== null).assertTrue();
        expect((res.data as AuthUserInfo).login).assertEqual('CarGuo');
        expect((res.data as AuthUserInfo).bio).assertEqual('Hello GSY');
        expect((res.data as AuthUserInfo).followers).assertEqual(12);
        expect((res.data as AuthUserInfo).following).assertEqual(34);
        expect((res.data as AuthUserInfo).publicRepos).assertEqual(56);

        expect(myStore.user !== null).assertTrue();
        expect((myStore.user as AuthUserInfo).login).assertEqual('CarGuo');
        expect((myStore.user as AuthUserInfo).bio).assertEqual('Hello GSY');
        expect((myStore.user as AuthUserInfo).followers).assertEqual(12);
        expect(myStore.loading).assertFalse();
        expect(myStore.error).assertEqual('');

        expect(authStore.userInfo !== null).assertTrue();
        expect((authStore.userInfo as AuthUserInfo).login).assertEqual('CarGuo');
        expect(authStore.token).assertEqual('token preset_token');
        expect(authStore.authed).assertTrue();

        expect(rdb.rowCountOf(USER_TABLE_INFO)).assertEqual(1);
        const row: Record<string, ValueType> = rdb.rowAt(USER_TABLE_INFO, 0);
        expect(row['login']).assertEqual('CarGuo');
        const dataValue: ValueType = row['data'];
        const dataString: string = typeof dataValue === 'string' ? dataValue : '';
        const parsed: Record<string, Object> = JSON.parse(dataString) as Record<string, Object>;
        expect(parsed['login'] as string).assertEqual('CarGuo');

        const mirrored: string | undefined =
          AppStorage.get<string>(APP_STORAGE_KEY_USER_INFO);
        expect(mirrored !== undefined && (mirrored as string).indexOf('CarGuo') >= 0).assertTrue();
      });

    it('refreshMe_starts_loading_then_finishes_on_success',
      0, async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = USER_JSON;

        const promise: Promise<RefreshMeResult> = service.refreshMe();
        expect(myStore.loading).assertTrue();
        const res: RefreshMeResult = await promise;
        expect(res.result).assertTrue();
        expect(myStore.loading).assertFalse();
      });

    it('refreshMe_applies_cached_user_before_network_refresh',
      0, async (): Promise<void> => {
        const cachedJson: string =
          '{"login":"CarGuo","name":"cached","avatar_url":"https://x/cache.png",' +
          '"html_url":"https://github.com/CarGuo","bio":"Cached Bio",' +
          '"followers":1,"following":2,"public_repos":3}';
        await userDao.save(USER_TABLE_INFO, 'CarGuo', cachedJson);
        authStore.setUser('token preset_token',
          new AuthUserInfo('CarGuo', '', '', '', cachedJson));
        provider.nextStatus = SUCCESS;
        provider.nextBody = USER_JSON;
        let sawCacheBeforeRequest: boolean = false;
        provider.onRequest = (): void => {
          sawCacheBeforeRequest = myStore.user !== null
            && (myStore.user as AuthUserInfo).name === 'cached'
            && authStore.userInfo !== null
            && (authStore.userInfo as AuthUserInfo).bio === 'Cached Bio';
        };

        const res: RefreshMeResult = await service.refreshMe();

        expect(sawCacheBeforeRequest).assertTrue();
        expect(res.result).assertTrue();
        expect(res.fromCache).assertFalse();
        expect(myStore.user !== null).assertTrue();
        expect((myStore.user as AuthUserInfo).bio).assertEqual('Hello GSY');
      });

    it('refreshMe_unauthorized_sets_error_and_clears_auth_store',
      0, async (): Promise<void> => {
        provider.nextStatus = UNAUTHORIZED;
        provider.nextBody = '{"message":"Bad credentials"}';
        authStore.setUser('token preset_token',
          new AuthUserInfo('CarGuo', '', '', '', USER_JSON));
        expect(authStore.authed).assertTrue();

        const res: RefreshMeResult = await service.refreshMe();

        expect(res.result).assertFalse();
        expect(res.code).assertEqual(UNAUTHORIZED);
        expect(myStore.user).assertNull();
        expect(myStore.loading).assertFalse();
        expect(myStore.error.length > 0).assertTrue();
        expect(authStore.authed).assertFalse();
        expect(authStore.token).assertEqual('');
        expect(rdb.rowCountOf(USER_TABLE_INFO)).assertEqual(0);
      });

    it('refreshMe_network_error_sets_error_but_keeps_auth_store',
      0, async (): Promise<void> => {
        provider.nextStatus = NETWORK_ERROR;
        provider.nextBody = '';
        authStore.setUser('token preset_token',
          new AuthUserInfo('CarGuo', '', '', '', USER_JSON));

        const res: RefreshMeResult = await service.refreshMe();

        expect(res.result).assertFalse();
        expect(myStore.loading).assertFalse();
        expect(myStore.error.length > 0).assertTrue();
        expect(authStore.authed).assertTrue();
        expect(authStore.token).assertEqual('token preset_token');
        expect(rdb.rowCountOf(USER_TABLE_INFO)).assertEqual(0);
      });

    it('refreshMe_invalid_json_short_circuits_with_parse_error',
      0, async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = '{"name":"no-login-field"}';

        const res: RefreshMeResult = await service.refreshMe();

        expect(res.result).assertFalse();
        expect(myStore.user).assertNull();
        expect(myStore.error.length > 0).assertTrue();
        expect(rdb.rowCountOf(USER_TABLE_INFO)).assertEqual(0);
      });

    it('refreshMe_keeps_existing_token_when_writing_auth_store',
      0, async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = USER_JSON;
        authStore.setUser('token keep_me',
          new AuthUserInfo('older', '', '', '', '{}'));

        await service.refreshMe();

        expect(authStore.token).assertEqual('token keep_me');
        expect((authStore.userInfo as AuthUserInfo).login).assertEqual('CarGuo');
        expect(authStore.authed).assertTrue();
      });

    it('fetchUnRead_calls_notifications_with_all_false_and_returns_true_when_list_non_empty',
      0, async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = '[{"id":"1","unread":true}]';

        const res: FetchUnReadResult = await service.fetchUnRead();
        expect(res.result).assertTrue();
        expect(res.unRead).assertTrue();

        const last: CapturedRequest | null = provider.lastByMethod('GET');
        expect(last !== null).assertTrue();
        const url: string = (last as CapturedRequest).url;
        expect(url.indexOf('notifications') >= 0).assertTrue();
        expect(url.indexOf('all=false') >= 0).assertTrue();
        expect(url.indexOf('participating=false') >= 0).assertTrue();
      });

    it('fetchUnRead_returns_false_when_list_is_empty',
      0, async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = '[]';

        const res: FetchUnReadResult = await service.fetchUnRead();
        expect(res.result).assertTrue();
        expect(res.unRead).assertFalse();
      });

    it('fetchUnRead_returns_failure_on_network_error',
      0, async (): Promise<void> => {
        provider.nextStatus = NETWORK_ERROR;
        provider.nextBody = '';

        const res: FetchUnReadResult = await service.fetchUnRead();
        expect(res.result).assertFalse();
        expect(res.unRead).assertFalse();
      });

    it('fetchUserOrgs_calls_user_orgs_url_and_returns_data',
      0, async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = '[{"id":1,"login":"OpenHarmony","avatar_url":"https://x/a.png"},'
          + '{"id":2,"login":"flutter","avatar_url":"https://x/b.png"}]';

        const res: FetchUserOrgsResult = await service.fetchUserOrgs('CarGuo');
        expect(res.result).assertTrue();
        expect(res.data.length).assertEqual(2);
        const first: MyOrgItem = res.data[0];
        expect(first.login).assertEqual('OpenHarmony');
        expect(first.avatar_url).assertEqual('https://x/a.png');

        const last: CapturedRequest | null = provider.lastByMethod('GET');
        expect(last !== null).assertTrue();
        expect((last as CapturedRequest).url.indexOf('users/CarGuo/orgs') >= 0).assertTrue();
      });

    it('fetchUserOrgs_returns_failure_on_empty_login',
      0, async (): Promise<void> => {
        const res: FetchUserOrgsResult = await service.fetchUserOrgs('');
        expect(res.result).assertFalse();
        expect(res.data.length).assertEqual(0);
        expect(provider.callCount).assertEqual(0);
      });

    it('fetchUserOrgs_returns_failure_when_http_error',
      0, async (): Promise<void> => {
        provider.nextStatus = NETWORK_ERROR;
        provider.nextBody = '';

        const res: FetchUserOrgsResult = await service.fetchUserOrgs('CarGuo');
        expect(res.result).assertFalse();
        expect(res.data.length).assertEqual(0);
      });

    it('fetchUserStarredCount_counts_starred_list_without_link_header',
      0, async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = '[{"stargazers_count":10},{"stargazers_count":25},{"stargazers_count":7}]';

        const res: FetchStarredCountResult = await service.fetchUserStarredCount('CarGuo');
        expect(res.result).assertTrue();
        expect(res.count).assertEqual(3);

        const last: CapturedRequest | null = provider.lastByMethod('GET');
        expect(last !== null).assertTrue();
        const url: string = (last as CapturedRequest).url;
        expect(url.indexOf('users/CarGuo/starred') >= 0).assertTrue();
        expect(url.indexOf('per_page=1') >= 0).assertTrue();
      });

    it('fetchUserStarredCount_returns_zero_for_empty_array',
      0, async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = '[]';

        const res: FetchStarredCountResult = await service.fetchUserStarredCount('CarGuo');
        expect(res.result).assertTrue();
        expect(res.count).assertEqual(0);
      });

    it('fetchUserStarredCount_returns_failure_on_empty_login',
      0, async (): Promise<void> => {
        const res: FetchStarredCountResult = await service.fetchUserStarredCount('');
        expect(res.result).assertFalse();
        expect(res.count).assertEqual(0);
        expect(provider.callCount).assertEqual(0);
      });

    it('fetchUserStarredCount_returns_failure_on_network_error',
      0, async (): Promise<void> => {
        provider.nextStatus = NETWORK_ERROR;
        provider.nextBody = '';

        const res: FetchStarredCountResult = await service.fetchUserStarredCount('CarGuo');
        expect(res.result).assertFalse();
        expect(res.count).assertEqual(0);
      });
  });

  describe('MyStore_state', (): void => {
    it('reset_clears_user_loading_error', 0, (): void => {
      const s: MyStore = new MyStore();
      s.setUser(new AuthUserInfo('a', 'b', '', '', '{}'));
      s.setError('boom');
      s.reset();
      expect(s.user).assertNull();
      expect(s.error).assertEqual('');
      expect(s.loading).assertFalse();
    });

    it('startLoading_clears_error_and_sets_flag', 0, (): void => {
      const s: MyStore = new MyStore();
      s.setError('previous');
      expect(s.error).assertEqual('previous');
      s.startLoading();
      expect(s.loading).assertTrue();
      expect(s.error).assertEqual('');
    });

    it('setUser_finalizes_loading_and_clears_error', 0, (): void => {
      const s: MyStore = new MyStore();
      s.startLoading();
      s.setUser(new AuthUserInfo('CarGuo', 'gsy', '', '', '{}'));
      expect(s.loading).assertFalse();
      expect(s.error).assertEqual('');
      expect(s.user !== null).assertTrue();
      expect((s.user as AuthUserInfo).login).assertEqual('CarGuo');
    });

    it('applyRawUserInfo_parses_extended_fields_from_json', 0, (): void => {
      const s: MyStore = new MyStore();
      s.applyRawUserInfo(USER_JSON);
      expect(s.user !== null).assertTrue();
      expect((s.user as AuthUserInfo).bio).assertEqual('Hello GSY');
      expect((s.user as AuthUserInfo).followers).assertEqual(12);
      expect((s.user as AuthUserInfo).following).assertEqual(34);
      expect((s.user as AuthUserInfo).publicRepos).assertEqual(56);
    });

    it('applyRawUserInfo_empty_clears_user', 0, (): void => {
      const s: MyStore = new MyStore();
      s.setUser(new AuthUserInfo('a', '', '', '', '{}'));
      s.applyRawUserInfo('');
      expect(s.user).assertNull();
    });

    it('syncFromAppStorage_reads_user_info_mirror', 0, (): void => {
      AppStorage.setOrCreate<string>(APP_STORAGE_KEY_USER_INFO, USER_JSON);
      const s: MyStore = new MyStore();
      s.syncFromAppStorage();
      expect(s.user !== null).assertTrue();
      expect((s.user as AuthUserInfo).login).assertEqual('CarGuo');
      expect((s.user as AuthUserInfo).publicRepos).assertEqual(56);
      AppStorage.setOrCreate<string>(APP_STORAGE_KEY_USER_INFO, '');
    });
  });
}
