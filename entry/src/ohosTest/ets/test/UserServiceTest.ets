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
import { Address } from '../../../main/ets/net/Address';
import { ValueType, ValuesBucket } from '../../../main/ets/dao/db/RdbStore';
import { RdbStoreLike } from '../../../main/ets/dao/DaoBase';
import {
  UserDao,
  USER_TABLE_INFO,
  USER_TABLE_ORG_MEMBER,
  USER_TABLE_REPOS
} from '../../../main/ets/dao/UserDao';
import {
  UserService,
  FetchUserResult,
  FetchUserReposResult,
  FetchSubUserListResult,
  FetchFollowResult,
  FetchStarredCountResult,
  UpdateUserResult
} from '../../../main/ets/service/UserService';
import {
  UserDetail,
  UserDetailStore,
  UserRepoItem
} from '../../../main/ets/store/UserDetailStore';
import { SubUserItem } from '../../../main/ets/service/RepositoryService';

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
  insertCountByTable: Map<string, number> = new Map<string, number>();
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
    const prev: number = this.insertCountByTable.has(table)
      ? (this.insertCountByTable.get(table) as number) : 0;
    this.insertCountByTable.set(table, prev + 1);
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
  headers: HttpHeaders = {};
  body: string | null = null;
}

class FakeHttpProvider implements HttpProvider {
  nextStatus: number = SUCCESS;
  nextBody: string = '{}';
  nextHeaders: HttpHeaders = {};
  shouldThrow: boolean = false;
  callCount: number = 0;
  captured: CapturedRequest = new CapturedRequest();
  capturedAll: CapturedRequest[] = [];
  responses: RawResponse[] = [];
  onRequest: (() => void) | null = null;

  pushResponse(status: number, body: string, headers: HttpHeaders = {}): void {
    this.responses.push(new RawResponse(status, body, headers));
  }

  async request(url: string,
                method: string,
                headers: HttpHeaders,
                body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    this.captured.url = url;
    this.captured.method = method;
    this.captured.headers = headers;
    this.captured.body = body;
    const c: CapturedRequest = new CapturedRequest();
    c.url = url;
    c.method = method;
    c.headers = headers;
    c.body = body;
    this.capturedAll.push(c);
    if (this.onRequest !== null) {
      (this.onRequest as () => void)();
    }
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
const TEST_LOGIN: string = 'CarGuo';
const STATUS_NO_CONTENT: number = 204;
const STATUS_NOT_FOUND: number = 404;

function buildUser(login: string): UserDetail {
  return {
    'id': 1,
    'login': login,
    'name': 'Guo',
    'avatar_url': 'https://x.com/a.png',
    'bio': 'hello',
    'company': 'oh',
    'location': 'sh',
    'email': '',
    'blog': '',
    'type': 'User',
    'followers': 99,
    'following': 12,
    'public_repos': 33,
    'public_gists': 0,
    'created_at': '2019-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
    'starred': '',
  } as UserDetail;
}

function buildRepo(idx: number, login: string): UserRepoItem {
  return {
    'id': idx,
    'name': 'repo' + idx.toString(),
    'full_name': login + '/repo' + idx.toString(),
    'description': 'd' + idx.toString(),
    'language': 'TypeScript',
    'stargazers_count': idx * 10,
    'forks_count': idx,
    'watchers_count': idx,
    'open_issues_count': 0,
    'fork': false,
    'private': false,
    'html_url': '',
    'owner_login': login,
    'pushed_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
  } as UserRepoItem;
}

function buildRepos(count: number, login: string): UserRepoItem[] {
  const out: UserRepoItem[] = [];
  for (let i = 0; i < count; i++) {
    out.push(buildRepo(i, login));
  }
  return out;
}

function buildSubUsers(count: number, prefix: string): SubUserItem[] {
  const out: SubUserItem[] = [];
  for (let i = 0; i < count; i++) {
    out.push({
      'id': i,
      'login': prefix + i.toString(),
      'avatar_url': 'https://x.com/' + prefix + i.toString() + '.png',
      'html_url': 'https://github.com/' + prefix + i.toString(),
    } as SubUserItem);
  }
  return out;
}

function buildStore(): FakeRdbStore {
  const s: FakeRdbStore = new FakeRdbStore();
  s.setPrimaryKey(USER_TABLE_INFO, ['login']);
  s.setPrimaryKey(USER_TABLE_ORG_MEMBER, ['org']);
  s.setPrimaryKey(USER_TABLE_REPOS, ['login']);
  return s;
}

export default function UserServiceTest(): void {
  describe('UserServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let rdb: FakeRdbStore;
    let dao: UserDao;
    let store: UserDetailStore;
    let service: UserService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      rdb = buildStore();
      dao = new UserDao(rdb);
      store = new UserDetailStore();
      service = new UserService(store, dao, PAGE_SIZE);

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

    it('getUser_uses_user_info_url_and_writes_cache', 0, async (): Promise<void> => {
      const user: UserDetail = buildUser(TEST_LOGIN);
      provider.pushResponse(SUCCESS, JSON.stringify(user));
      provider.pushResponse(SUCCESS, '[{}]', {
        'Link': '<https://api.github.com/users/CarGuo/starred?sort=updated&page=2&per_page=1>; rel="next", <https://api.github.com/users/CarGuo/starred?sort=updated&page=17&per_page=1>; rel="last"',
      });

      const res: FetchUserResult = await service.getUser(TEST_LOGIN);

      expect(res.result).assertTrue();
      expect(res.fromCache).assertFalse();
      expect(provider.capturedAll[0].url).assertEqual(Address.getUserInfo(TEST_LOGIN));
      expect(provider.capturedAll[0].method).assertEqual('GET');
      expect(provider.capturedAll[1].url).assertEqual(Address.getUserStarred(TEST_LOGIN, 1, 1, 'updated'));
      expect(store.user.login).assertEqual(TEST_LOGIN);
      expect(store.user.followers).assertEqual(99);
      expect(store.user.starred).assertEqual('17');
      expect(store.starredCount).assertEqual(17);
      expect(store.error).assertEqual('');
      expect(store.loading).assertFalse();

      const writes: number = rdb.insertCountByTable.has(USER_TABLE_INFO)
        ? (rdb.insertCountByTable.get(USER_TABLE_INFO) as number) : 0;
      expect(writes).assertEqual(1);

      const cached = await dao.readUserInfo(TEST_LOGIN);
      expect(cached.result).assertTrue();
      const parsed: UserDetail = JSON.parse(cached.data) as UserDetail;
      expect(parsed.login).assertEqual(TEST_LOGIN);
      expect(parsed.starred).assertEqual('17');
    });

    it('getUser_falls_back_to_cache_on_network_error', 0, async (): Promise<void> => {
      const user: UserDetail = buildUser(TEST_LOGIN);
      await dao.saveUserInfo(TEST_LOGIN, JSON.stringify(user));

      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: FetchUserResult = await service.getUser(TEST_LOGIN);
      expect(res.result).assertTrue();
      expect(res.fromCache).assertTrue();
      expect(store.user.login).assertEqual(TEST_LOGIN);
    });

    it('getUser_applies_cache_before_network_refresh', 0, async (): Promise<void> => {
      const cached: UserDetail = buildUser(TEST_LOGIN);
      cached.name = 'cached user';
      await dao.saveUserInfo(TEST_LOGIN, JSON.stringify(cached));
      const network: UserDetail = buildUser(TEST_LOGIN);
      network.name = 'network user';
      provider.pushResponse(SUCCESS, JSON.stringify(network));
      provider.pushResponse(SUCCESS, '[{}]');
      let sawCacheBeforeRequest: boolean = false;
      provider.onRequest = (): void => {
        sawCacheBeforeRequest = store.user.login === TEST_LOGIN
          && store.user.name === 'cached user';
      };

      const res: FetchUserResult = await service.getUser(TEST_LOGIN);

      expect(sawCacheBeforeRequest).assertTrue();
      expect(res.result).assertTrue();
      expect(res.fromCache).assertFalse();
      expect(store.user.login).assertEqual(TEST_LOGIN);
      expect(store.user.name).assertEqual('network user');
    });

    it('getUserStarredCount_parses_link_last_page_and_updates_store', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = '[{}]';
      provider.nextHeaders = {
        'link': '<https://api.github.com/users/CarGuo/starred?sort=updated&page=2&per_page=1>; rel="next", <https://api.github.com/users/CarGuo/starred?sort=updated&page=42&per_page=1>; rel="last"',
      };

      const res: FetchStarredCountResult = await service.getUserStarredCount(TEST_LOGIN);

      expect(res.result).assertTrue();
      expect(res.count).assertEqual(42);
      expect(store.starredCount).assertEqual(42);
      expect(store.user.starred).assertEqual('42');
      expect(provider.captured.url).assertEqual(Address.getUserStarred(TEST_LOGIN, 1, 1, 'updated'));
    });

    it('getUserStarredCount_without_link_uses_response_length', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = '[{}]';
      provider.nextHeaders = {};

      const res: FetchStarredCountResult = await service.getUserStarredCount(TEST_LOGIN);

      expect(res.result).assertTrue();
      expect(res.count).assertEqual(1);
      expect(store.starredCount).assertEqual(1);
    });

    it('getUserRepos_uses_user_repos_url_with_page_and_per_page', 0, async (): Promise<void> => {
      const repos: UserRepoItem[] = buildRepos(PAGE_SIZE, TEST_LOGIN);
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(repos);

      await service.getUserRepos(TEST_LOGIN, 1);

      const expected: string = Address.getUserRepos(TEST_LOGIN, 1, null, PAGE_SIZE);
      expect(provider.captured.url).assertEqual(expected);
      expect(provider.captured.method).assertEqual('GET');
    });

    it('getUserRepos_first_page_writes_cache_and_updates_store', 0, async (): Promise<void> => {
      const repos: UserRepoItem[] = buildRepos(PAGE_SIZE, TEST_LOGIN);
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(repos);

      const res: FetchUserReposResult = await service.getUserRepos(TEST_LOGIN, 1);
      expect(res.result).assertTrue();
      expect(res.fromCache).assertFalse();
      expect(res.data.length).assertEqual(PAGE_SIZE);

      const reposWrites: number = rdb.insertCountByTable.has(USER_TABLE_REPOS)
        ? (rdb.insertCountByTable.get(USER_TABLE_REPOS) as number) : 0;
      expect(reposWrites).assertEqual(1);
      expect(store.repos.length).assertEqual(PAGE_SIZE);
      expect(store.page).assertEqual(1);
      expect(store.hasMore).assertTrue();

      const cached = await dao.readUserRepos(TEST_LOGIN);
      expect(cached.result).assertTrue();
      const parsed: Object = JSON.parse(cached.data) as Object;
      expect(Array.isArray(parsed)).assertTrue();
      expect((parsed as UserRepoItem[]).length).assertEqual(PAGE_SIZE);
    });

    it('getUserRepos_second_page_does_not_write_cache_and_appends', 0, async (): Promise<void> => {
      const fullPage: UserRepoItem[] = buildRepos(PAGE_SIZE, TEST_LOGIN);
      const secondPage: UserRepoItem[] = buildRepos(2, TEST_LOGIN);
      provider.pushResponse(SUCCESS, JSON.stringify(fullPage));
      provider.pushResponse(SUCCESS, JSON.stringify(secondPage));

      await service.getUserRepos(TEST_LOGIN, 1);
      const writesAfterFirst: number = rdb.insertCountByTable.has(USER_TABLE_REPOS)
        ? (rdb.insertCountByTable.get(USER_TABLE_REPOS) as number) : 0;

      await service.getUserRepos(TEST_LOGIN, 2);
      const writesAfterSecond: number = rdb.insertCountByTable.has(USER_TABLE_REPOS)
        ? (rdb.insertCountByTable.get(USER_TABLE_REPOS) as number) : 0;

      expect(writesAfterSecond).assertEqual(writesAfterFirst);
      expect(store.repos.length).assertEqual(PAGE_SIZE + 2);
      expect(store.page).assertEqual(2);
      expect(store.hasMore).assertFalse();
    });

    it('getOrgMembers_applies_cache_before_network_refresh', 0, async (): Promise<void> => {
      const cached: SubUserItem[] = buildSubUsers(2, 'cached');
      const network: SubUserItem[] = buildSubUsers(PAGE_SIZE, 'network');
      await dao.saveOrgMember('openai', JSON.stringify(cached));
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(network);
      let callbackItems: SubUserItem[] = [];
      let sawCacheBeforeRequest: boolean = false;
      provider.onRequest = (): void => {
        sawCacheBeforeRequest = callbackItems.length === cached.length
          && callbackItems[0].login === 'cached0';
      };

      const res: FetchSubUserListResult = await service.getOrgMembers('openai', 1,
        (items: SubUserItem[]): void => {
          callbackItems = items.slice();
        });

      expect(sawCacheBeforeRequest).assertTrue();
      expect(res.result).assertTrue();
      expect(res.fromCache).assertFalse();
      expect(res.data.length).assertEqual(PAGE_SIZE);
      expect(res.data[0].login).assertEqual('network0');
      const orgWrites: number = rdb.insertCountByTable.has(USER_TABLE_ORG_MEMBER)
        ? (rdb.insertCountByTable.get(USER_TABLE_ORG_MEMBER) as number) : 0;
      expect(orgWrites).assertEqual(2);
      const saved = await dao.readOrgMember('openai');
      expect(saved.result).assertTrue();
      const parsed: Object = JSON.parse(saved.data) as Object;
      expect(Array.isArray(parsed)).assertTrue();
      expect((parsed as SubUserItem[])[0].login).assertEqual('network0');
    });

    it('getUserOrgs_uses_compose_user_orgs_url', 0, async (): Promise<void> => {
      const orgs: SubUserItem[] = buildSubUsers(PAGE_SIZE, 'org');
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(orgs);

      const res: FetchSubUserListResult = await service.getUserOrgs(TEST_LOGIN, 1);

      expect(provider.captured.url).assertEqual(Address.getUserOrgsPaged(TEST_LOGIN, 1, PAGE_SIZE));
      expect(provider.captured.method).assertEqual('GET');
      expect(res.result).assertTrue();
      expect(res.fromCache).assertFalse();
      expect(res.data.length).assertEqual(PAGE_SIZE);
      expect(res.data[0].login).assertEqual('org0');
    });

    it('getFollowStatus_returns_followed_true_on_204', 0, async (): Promise<void> => {
      provider.nextStatus = STATUS_NO_CONTENT;
      provider.nextBody = '';

      const res: FetchFollowResult = await service.getFollowStatus(TEST_LOGIN);
      expect(res.result).assertTrue();
      expect(res.followed).assertTrue();
      expect(provider.captured.url).assertEqual(Address.getFollowStatus(TEST_LOGIN));
      expect(provider.captured.method).assertEqual('GET');
      expect(store.followed).assertTrue();
    });

    it('getFollowStatus_returns_followed_false_on_404', 0, async (): Promise<void> => {
      provider.nextStatus = STATUS_NOT_FOUND;
      provider.nextBody = '';

      const res: FetchFollowResult = await service.getFollowStatus(TEST_LOGIN);
      expect(res.result).assertTrue();
      expect(res.followed).assertFalse();
      expect(store.followed).assertFalse();
    });

    it('follow_uses_put_and_sets_followed_true', 0, async (): Promise<void> => {
      provider.nextStatus = STATUS_NO_CONTENT;
      provider.nextBody = '';

      const res: FetchFollowResult = await service.follow(TEST_LOGIN);
      expect(res.result).assertTrue();
      expect(res.followed).assertTrue();
      expect(provider.captured.url).assertEqual(Address.setFollow(TEST_LOGIN));
      expect(provider.captured.method).assertEqual('PUT');
      expect(store.followed).assertTrue();
    });

    it('unfollow_uses_delete_and_sets_followed_false', 0, async (): Promise<void> => {
      store.applyFollowed(true);
      provider.nextStatus = STATUS_NO_CONTENT;
      provider.nextBody = '';

      const res: FetchFollowResult = await service.unfollow(TEST_LOGIN);
      expect(res.result).assertTrue();
      expect(res.followed).assertFalse();
      expect(provider.captured.url).assertEqual(Address.setUnfollow(TEST_LOGIN));
      expect(provider.captured.method).assertEqual('DELETE');
      expect(store.followed).assertFalse();
    });

    it('updateUser_uses_patch_user_json_body_and_writes_cache_like_compose', 0, async (): Promise<void> => {
      const updated: UserDetail = buildUser(TEST_LOGIN);
      updated.name = 'Small Guo';
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(updated);

      const res: UpdateUserResult = await UserService.updateUser('name', 'Small Guo', dao);

      expect(res.result).assertTrue();
      expect(res.user !== null).assertTrue();
      expect(provider.captured.url).assertEqual(Address.getMyUserInfo());
      expect(provider.captured.method).assertEqual('PATCH');
      expect(provider.captured.headers['Content-Type']).assertEqual('application/json');
      expect(provider.captured.body !== null).assertTrue();
      const sent: Record<string, Object> = JSON.parse(provider.captured.body as string) as Record<string, Object>;
      expect(Object.keys(sent).length).assertEqual(1);
      expect(sent['name'] as string).assertEqual('Small Guo');

      const cached = await dao.readUserInfo(TEST_LOGIN);
      expect(cached.result).assertTrue();
      const parsed: UserDetail = JSON.parse(cached.data) as UserDetail;
      expect(parsed.login).assertEqual(TEST_LOGIN);
      expect(parsed.name).assertEqual('Small Guo');
    });

    it('empty_login_does_not_request_network_for_any_method', 0, async (): Promise<void> => {
      const u: FetchUserResult = await service.getUser('');
      const r: FetchUserReposResult = await service.getUserRepos('', 1);
      const f: FetchFollowResult = await service.getFollowStatus('');
      const fa: FetchFollowResult = await service.follow('');
      const fu: FetchFollowResult = await service.unfollow('');

      expect(u.result).assertFalse();
      expect(r.result).assertFalse();
      expect(f.result).assertFalse();
      expect(fa.result).assertFalse();
      expect(fu.result).assertFalse();
      expect(provider.callCount).assertEqual(0);
    });
  });
}
