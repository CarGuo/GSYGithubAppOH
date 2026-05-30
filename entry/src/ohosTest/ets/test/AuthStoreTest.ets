/**
 * AuthStore + LoginUseCase 单测：
 *
 *  - 内存 FakeRdbStore（与 [DaoTest.ets](./DaoTest.ets) 同源风格）替代真实 relationalStore，
 *    保证 UserDao 可在单测环境中读写 UserInfo 表。
 *  - FakeHttpProvider / FakeTokenStorage（与 [HttpManagerTest.ets](./HttpManagerTest.ets)
 *    保持同一种 mock 协议）注入到 HttpManager，避免真实网络。
 *  - FakePreferences 实现 PreferencesLike，保证 token / basic 写入路径可验证。
 *
 * 覆盖矩阵：
 *  1. PAT 登录：token 拼成 'token xxx' → /user 200 → AuthStore 进入 authed=true，
 *     UserDao 落库 + EVENT_USER_LOGGED_IN 触发，token 同步进 Preferences 与 AppStorage。
 *  2. PAT 登录失败 401：HttpManager 已发 LoginExpired，UseCase 还原 store 与 token。
 *  3. OAuth code 兑换：先 GET access_token（form / json 两种 body 都能解析），再 GET /user。
 *  4. logout：清 Preferences + AppStorage + UserDao + 发 EVENT_USER_LOGGED_OUT。
 *  5. 状态机：setLoading / setError / setUser / clear 的字段语义与 AppStorage 镜像。
 */

import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import relationalStore from '@ohos.data.relationalStore';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
  TokenStorage,
  LoginExpiredBus,
  DEFAULT_USER_AGENT,
  HttpMethod,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS, CREATED, UNAUTHORIZED } from '../../../main/ets/net/NetworkCode';
import { ValueType, ValuesBucket } from '../../../main/ets/dao/db/RdbStore';
import { RdbStoreLike } from '../../../main/ets/dao/DaoBase';
import { UserDao, USER_TABLE_INFO } from '../../../main/ets/dao/UserDao';
import {
  AuthStore,
  AuthUserInfo,
  APP_STORAGE_KEY_AUTHED,
  APP_STORAGE_KEY_LOADING,
  APP_STORAGE_KEY_ERROR,
  APP_STORAGE_KEY_TOKEN,
  APP_STORAGE_KEY_USER_LOGIN,
  APP_STORAGE_KEY_USER_INFO,
} from '../../../main/ets/store/AuthStore';
import {
  LoginUseCase,
  PreferencesLike,
  OAuthClientConfig,
  LoginOutcome,
} from '../../../main/ets/auth/LoginUseCase';
import {
  KEY_USER_TOKEN,
  KEY_USER_BASIC,
  KEY_USER_NAME,
  KEY_USER_PASSWORD,
} from '../../../main/ets/dao/db/Preferences';
import {
  EventBus,
  EVENT_USER_LOGGED_IN,
  EVENT_USER_LOGGED_OUT,
} from '../../../main/ets/utils/EventBus';

class ScriptedResponse {
  status: number;
  body: string;
  headers: HttpHeaders;

  constructor(status: number, body: string, headers: HttpHeaders = {}) {
    this.status = status;
    this.body = body;
    this.headers = headers;
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
  scripted: Map<string, ScriptedResponse[]> = new Map<string, ScriptedResponse[]>();
  fallback: ScriptedResponse = new ScriptedResponse(SUCCESS, '{}');
  captured: CapturedRequest[] = [];

  enqueue(method: HttpMethod, urlContains: string, response: ScriptedResponse): void {
    const key: string = `${method}|${urlContains}`;
    let arr: ScriptedResponse[] | undefined = this.scripted.get(key);
    if (arr === undefined) {
      arr = [];
      this.scripted.set(key, arr);
    }
    arr.push(response);
  }

  async request(url: string,
                method: string,
                headers: HttpHeaders,
                body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.captured.push(new CapturedRequest(url, method, headers, body));
    const keys: string[] = Array.from(this.scripted.keys());
    for (let i = 0; i < keys.length; i++) {
      const key: string = keys[i];
      const sep: number = key.indexOf('|');
      const m: string = key.substring(0, sep);
      const u: string = key.substring(sep + 1);
      if (m === method && url.indexOf(u) >= 0) {
        const arr: ScriptedResponse[] = this.scripted.get(key) as ScriptedResponse[];
        if (arr.length > 0) {
          const next: ScriptedResponse = arr.shift() as ScriptedResponse;
          return new RawResponse(next.status, next.body, next.headers);
        }
      }
    }
    return new RawResponse(this.fallback.status, this.fallback.body, this.fallback.headers);
  }

  lastByMethod(method: string): CapturedRequest | null {
    for (let i = this.captured.length - 1; i >= 0; i--) {
      if (this.captured[i].method === method) {
        return this.captured[i];
      }
    }
    return null;
  }

  countByMethod(method: string): number {
    let n: number = 0;
    for (let i = 0; i < this.captured.length; i++) {
      if (this.captured[i].method === method) {
        n = n + 1;
      }
    }
    return n;
  }
}

class FakeTokenStorage implements TokenStorage {
  value: string | null = null;
  saveCount: number = 0;
  clearCount: number = 0;

  async load(): Promise<string | null> {
    return this.value;
  }

  async save(token: string): Promise<void> {
    this.value = token;
    this.saveCount += 1;
  }

  async clear(): Promise<void> {
    this.value = null;
    this.clearCount += 1;
  }
}

class FakePreferences implements PreferencesLike {
  data: Map<string, string> = new Map<string, string>();
  removeCount: number = 0;
  putCount: number = 0;

  async putString(key: string, value: string): Promise<void> {
    this.data.set(key, value);
    this.putCount += 1;
  }

  async remove(key: string): Promise<void> {
    this.data.delete(key);
    this.removeCount += 1;
  }
}

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

const USER_JSON: string =
  '{"login":"CarGuo","name":"gsy","avatar_url":"https://x/y.png","html_url":"https://github.com/CarGuo"}';

export default function AuthStoreTest(): void {

  describe('AuthStore_state', (): void => {
    let store: AuthStore;

    beforeEach((): void => {
      store = new AuthStore();
      store.clear();
    });

    it('auth_store_initial_state_is_anonymous', 0, (): void => {
      expect(store.authed).assertFalse();
      expect(store.loading).assertFalse();
      expect(store.error).assertEqual('');
      expect(store.token).assertEqual('');
      expect(store.userInfo).assertNull();
    });

    it('auth_store_set_loading_clears_error_and_syncs_appstorage', 0, (): void => {
      store.setError('boom');
      expect(store.error).assertEqual('boom');
      store.setLoading(true);
      expect(store.loading).assertTrue();
      expect(store.error).assertEqual('');
      const inStorage: boolean | undefined = AppStorage.get<boolean>(APP_STORAGE_KEY_LOADING);
      expect(inStorage === true).assertTrue();
      const errInStorage: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_ERROR);
      expect(errInStorage === '' || errInStorage === undefined).assertTrue();
    });

    it('auth_store_set_error_resets_loading', 0, (): void => {
      store.setLoading(true);
      store.setError('bad credentials');
      expect(store.loading).assertFalse();
      expect(store.error).assertEqual('bad credentials');
      const errInStorage: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_ERROR);
      expect(errInStorage).assertEqual('bad credentials');
    });

    it('auth_store_set_user_marks_authed_and_writes_appstorage', 0, (): void => {
      const user: AuthUserInfo | null = AuthUserInfo.fromJson(USER_JSON);
      expect(user !== null).assertTrue();
      store.setUser('token abc', user);
      expect(store.authed).assertTrue();
      expect(store.token).assertEqual('token abc');
      expect(store.loading).assertFalse();
      expect(store.error).assertEqual('');
      expect(store.userInfo !== null).assertTrue();
      expect((store.userInfo as AuthUserInfo).login).assertEqual('CarGuo');
      const tokenInStorage: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_TOKEN);
      expect(tokenInStorage).assertEqual('token abc');
      const authedInStorage: boolean | undefined = AppStorage.get<boolean>(APP_STORAGE_KEY_AUTHED);
      expect(authedInStorage === true).assertTrue();
      const loginInStorage: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_USER_LOGIN);
      expect(loginInStorage).assertEqual('CarGuo');
      const rawInStorage: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_USER_INFO);
      expect(rawInStorage).assertEqual(USER_JSON);
    });

    it('auth_store_set_user_with_empty_token_keeps_authed_false', 0, (): void => {
      const user: AuthUserInfo | null = AuthUserInfo.fromJson(USER_JSON);
      store.setUser('', user);
      expect(store.authed).assertFalse();
    });

    it('auth_store_clear_resets_all_fields_and_appstorage', 0, (): void => {
      const user: AuthUserInfo | null = AuthUserInfo.fromJson(USER_JSON);
      store.setUser('token abc', user);
      store.clear();
      expect(store.authed).assertFalse();
      expect(store.token).assertEqual('');
      expect(store.userInfo).assertNull();
      const tokenInStorage: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_TOKEN);
      expect(tokenInStorage === '' || tokenInStorage === undefined).assertTrue();
      const authedInStorage: boolean | undefined = AppStorage.get<boolean>(APP_STORAGE_KEY_AUTHED);
      expect(authedInStorage === false || authedInStorage === undefined).assertTrue();
    });

    it('auth_store_state_machine_loading_to_user_to_clear', 0, (): void => {
      store.setLoading(true);
      expect(store.loading).assertTrue();
      expect(store.authed).assertFalse();

      const user: AuthUserInfo | null = AuthUserInfo.fromJson(USER_JSON);
      store.setUser('token abc', user);
      expect(store.loading).assertFalse();
      expect(store.authed).assertTrue();

      store.setError('expired');
      expect(store.error).assertEqual('expired');
      expect(store.loading).assertFalse();

      store.clear();
      expect(store.error).assertEqual('');
      expect(store.authed).assertFalse();
    });

    it('auth_user_info_from_json_invalid_returns_null', 0, (): void => {
      expect(AuthUserInfo.fromJson('') === null).assertTrue();
      expect(AuthUserInfo.fromJson('not-json') === null).assertTrue();
    });
  });

  describe('LoginUseCase', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let prefs: FakePreferences;
    let rdb: FakeRdbStore;
    let userDao: UserDao;
    let store: AuthStore;
    let useCase: LoginUseCase;
    let loggedInPayload: AuthUserInfo | null = null;
    let loggedOutCount: number = 0;
    let offIn: () => void = (): void => {
    };
    let offOut: () => void = (): void => {
    };

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      prefs = new FakePreferences();
      rdb = new FakeRdbStore();
      rdb.setPrimaryKey(USER_TABLE_INFO, ['login']);
      userDao = new UserDao(rdb);
      store = new AuthStore();
      store.clear();
      useCase = new LoginUseCase(store, userDao, prefs, null);

      HttpManager.setMockProvider(provider);
      HttpManager.setTokenStorage(storage);
      HttpManager.setTimeout(15000);
      HttpManager.setUserAgent(DEFAULT_USER_AGENT);
      HttpManager.setAuthorization(null);
      LoginExpiredBus.clear();
      EventBus.removeAll();

      loggedInPayload = null;
      loggedOutCount = 0;
      offIn = EventBus.on(EVENT_USER_LOGGED_IN, (payload: ESObject): void => {
        loggedInPayload = payload as AuthUserInfo;
      });
      offOut = EventBus.on(EVENT_USER_LOGGED_OUT, (): void => {
        loggedOutCount = loggedOutCount + 1;
      });
    });

    afterEach((): void => {
      offIn();
      offOut();
      HttpManager.setMockProvider(null);
      LoginExpiredBus.clear();
      EventBus.removeAll();
    });

    it('pat_login_success_writes_token_user_and_emits_event', 0, async (): Promise<void> => {
      provider.enqueue('GET', '/user', new ScriptedResponse(SUCCESS, USER_JSON));

      const res: LoginOutcome = await useCase.loginWithPersonalAccessToken('ghp_test_token');

      expect(res.result).assertTrue();
      expect(res.code).assertEqual(SUCCESS);
      expect(store.authed).assertTrue();
      expect(store.token).assertEqual('token ghp_test_token');
      expect(store.userInfo !== null).assertTrue();
      expect((store.userInfo as AuthUserInfo).login).assertEqual('CarGuo');
      expect(prefs.data.get(KEY_USER_TOKEN)).assertEqual('token ghp_test_token');
      expect(rdb.rowCountOf(USER_TABLE_INFO)).assertEqual(1);
      expect(loggedInPayload !== null).assertTrue();
      expect((loggedInPayload as AuthUserInfo).login).assertEqual('CarGuo');
      const lastGet: CapturedRequest | null = provider.lastByMethod('GET');
      expect(lastGet !== null).assertTrue();
      expect((lastGet as CapturedRequest).headers['Authorization']).assertEqual('token ghp_test_token');
    });

    it('pat_login_strips_existing_token_prefix_case_insensitive', 0, async (): Promise<void> => {
      provider.enqueue('GET', '/user', new ScriptedResponse(SUCCESS, USER_JSON));
      const res: LoginOutcome = await useCase.loginWithPersonalAccessToken('Token  ghp_xx');
      expect(res.result).assertTrue();
      expect(store.token).assertEqual('token ghp_xx');
    });

    it('pat_login_401_clears_token_and_keeps_unauthed', 0, async (): Promise<void> => {
      provider.enqueue('GET', '/user',
        new ScriptedResponse(UNAUTHORIZED, '{"message":"Bad credentials"}'));

      const res: LoginOutcome = await useCase.loginWithPersonalAccessToken('ghp_invalid');

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(store.authed).assertFalse();
      expect(store.token).assertEqual('');
      expect(store.error.length > 0).assertTrue();
      expect(rdb.rowCountOf(USER_TABLE_INFO)).assertEqual(0);
      expect(loggedInPayload === null).assertTrue();
      expect(prefs.data.has(KEY_USER_TOKEN)).assertFalse();
    });

    it('pat_login_empty_token_short_circuits', 0, async (): Promise<void> => {
      const res: LoginOutcome = await useCase.loginWithPersonalAccessToken('   ');
      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(provider.captured.length).assertEqual(0);
      expect(store.authed).assertFalse();
    });

    it('basic_auth_login_success_persists_basic_and_user', 0, async (): Promise<void> => {
      provider.enqueue('POST', '/authorizations',
        new ScriptedResponse(CREATED, '{"token":"basic_issued_token"}'));
      provider.enqueue('GET', '/user', new ScriptedResponse(SUCCESS, USER_JSON));

      const res: LoginOutcome = await useCase.loginWithBasicAuth('alice', 'pwd');

      expect(res.result).assertTrue();
      expect(store.authed).assertTrue();
      expect(store.token).assertEqual('token basic_issued_token');
      expect(prefs.data.get(KEY_USER_NAME)).assertEqual('alice');
      expect(prefs.data.get(KEY_USER_PASSWORD)).assertEqual('pwd');
      expect(prefs.data.get(KEY_USER_BASIC) !== undefined).assertTrue();
      expect(prefs.data.get(KEY_USER_TOKEN)).assertEqual('token basic_issued_token');
      expect(rdb.rowCountOf(USER_TABLE_INFO)).assertEqual(1);
    });

    it('basic_auth_login_empty_input_fails_without_network', 0, async (): Promise<void> => {
      const res: LoginOutcome = await useCase.loginWithBasicAuth('', 'pwd');
      expect(res.result).assertFalse();
      expect(provider.captured.length).assertEqual(0);
    });

    it('oauth_exchange_form_body_then_user_success', 0, async (): Promise<void> => {
      useCase.setOAuthConfig(new OAuthClientConfig('cid', 'csec'));
      provider.enqueue('GET', 'login/oauth/access_token',
        new ScriptedResponse(SUCCESS, 'access_token=oauth_tk_1&scope=user&token_type=bearer'));
      provider.enqueue('GET', '/user', new ScriptedResponse(SUCCESS, USER_JSON));

      const res: LoginOutcome = await useCase.exchangeOAuthCode('the_code');

      expect(res.result).assertTrue();
      expect(store.token).assertEqual('token oauth_tk_1');
      expect(prefs.data.get(KEY_USER_TOKEN)).assertEqual('token oauth_tk_1');
      expect(rdb.rowCountOf(USER_TABLE_INFO)).assertEqual(1);
      expect(loggedInPayload !== null).assertTrue();
      const oauthCall: CapturedRequest = provider.captured[0];
      expect(oauthCall.url.indexOf('client_id=cid') >= 0).assertTrue();
      expect(oauthCall.url.indexOf('client_secret=csec') >= 0).assertTrue();
      expect(oauthCall.url.indexOf('code=the_code') >= 0).assertTrue();
    });

    it('oauth_exchange_json_body_also_works', 0, async (): Promise<void> => {
      useCase.setOAuthConfig(new OAuthClientConfig('cid', 'csec'));
      provider.enqueue('GET', 'login/oauth/access_token',
        new ScriptedResponse(SUCCESS, '{"access_token":"oauth_tk_2","token_type":"bearer"}'));
      provider.enqueue('GET', '/user', new ScriptedResponse(SUCCESS, USER_JSON));

      const res: LoginOutcome = await useCase.exchangeOAuthCode('code2');

      expect(res.result).assertTrue();
      expect(store.token).assertEqual('token oauth_tk_2');
    });

    it('oauth_exchange_without_access_token_field_fails', 0, async (): Promise<void> => {
      useCase.setOAuthConfig(new OAuthClientConfig('cid', 'csec'));
      provider.enqueue('GET', 'login/oauth/access_token',
        new ScriptedResponse(SUCCESS, 'error=bad_verification_code'));

      const res: LoginOutcome = await useCase.exchangeOAuthCode('xx');

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(store.authed).assertFalse();
      expect(store.token).assertEqual('');
    });

    it('oauth_exchange_without_config_fails_short_circuits', 0, async (): Promise<void> => {
      const res: LoginOutcome = await useCase.exchangeOAuthCode('xx');
      expect(res.result).assertFalse();
      expect(provider.captured.length).assertEqual(0);
    });

    it('logout_clears_pref_appstorage_userdao_and_emits_event',
      0, async (): Promise<void> => {
        provider.enqueue('GET', '/user', new ScriptedResponse(SUCCESS, USER_JSON));
        const loginRes: LoginOutcome = await useCase.loginWithPersonalAccessToken('ghp_x');
        expect(loginRes.result).assertTrue();
        expect(rdb.rowCountOf(USER_TABLE_INFO)).assertEqual(1);

        await useCase.logout();

        expect(store.authed).assertFalse();
        expect(store.token).assertEqual('');
        expect(store.userInfo).assertNull();
        expect(prefs.data.has(KEY_USER_TOKEN)).assertFalse();
        expect(prefs.data.has(KEY_USER_BASIC)).assertFalse();
        expect(prefs.data.has(KEY_USER_NAME)).assertFalse();
        expect(prefs.data.has(KEY_USER_PASSWORD)).assertFalse();
        expect(rdb.rowCountOf(USER_TABLE_INFO)).assertEqual(0);
        expect(loggedOutCount).assertEqual(1);
        expect(HttpManager.getAuthorizationInMemory()).assertNull();
        const tokenInStorage: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_TOKEN);
        expect(tokenInStorage === '' || tokenInStorage === undefined).assertTrue();
      });
  });
}
