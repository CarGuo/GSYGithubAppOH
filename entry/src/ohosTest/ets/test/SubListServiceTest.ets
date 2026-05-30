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
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { Address } from '../../../main/ets/net/Address';
import { ValueType, ValuesBucket } from '../../../main/ets/dao/db/RdbStore';
import { RdbStoreLike } from '../../../main/ets/dao/DaoBase';
import {
  RepositoryDao,
  REPO_TABLE_STAR,
  REPO_TABLE_FORK,
  REPO_TABLE_WATCHER,
} from '../../../main/ets/dao/RepositoryDao';
import {
  UserDao,
  USER_TABLE_FOLLOWER,
  USER_TABLE_FOLLOWED,
} from '../../../main/ets/dao/UserDao';
import {
  RepositoryService,
  SubUserItem,
  SubRepositoryItem,
  SubListResult,
} from '../../../main/ets/service/RepositoryService';
import {
  UserService,
  FetchSubUserListResult,
} from '../../../main/ets/service/UserService';
import { RepositoryDetailStore } from '../../../main/ets/store/RepositoryDetailStore';
import { UserDetailStore } from '../../../main/ets/store/UserDetailStore';

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
    const prev: number | undefined = this.insertCountByTable.get(table);
    this.insertCountByTable.set(table, (prev !== undefined ? prev : 0) + 1);
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
  callCount: number = 0;
  captured: CapturedRequest = new CapturedRequest();

  async request(url: string,
                method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    this.captured.url = url;
    this.captured.method = method;
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
const FULL_NAME: string = 'CarGuo/GSYGithubApp';
const OWNER: string = 'CarGuo';
const REPO_NAME: string = 'GSYGithubApp';
const LOGIN: string = 'CarGuo';

function buildUsers(count: number): SubUserItem[] {
  const out: SubUserItem[] = [];
  for (let i: number = 0; i < count; i++) {
    out.push({
      'id': i + 1,
      'login': 'user_' + i.toString(),
      'avatar_url': 'https://avatars.example.com/' + i.toString(),
      'html_url': 'https://github.com/user_' + i.toString(),
    } as SubUserItem);
  }
  return out;
}

function buildRepos(count: number): SubRepositoryItem[] {
  const out: SubRepositoryItem[] = [];
  for (let i: number = 0; i < count; i++) {
    out.push({
      'id': i + 1,
      'name': 'repo_' + i.toString(),
      'full_name': 'CarGuo/repo_' + i.toString(),
      'description': 'desc_' + i.toString(),
      'language': 'TypeScript',
      'stargazers_count': 10 + i,
      'forks_count': 1 + i,
      'watchers_count': 5 + i,
      'owner_login': 'CarGuo',
    } as SubRepositoryItem);
  }
  return out;
}

function buildRepoStore(): FakeRdbStore {
  const s: FakeRdbStore = new FakeRdbStore();
  s.setPrimaryKey(REPO_TABLE_STAR, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_FORK, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_WATCHER, ['fullName']);
  return s;
}

function buildUserStore(): FakeRdbStore {
  const s: FakeRdbStore = new FakeRdbStore();
  s.setPrimaryKey(USER_TABLE_FOLLOWER, ['login']);
  s.setPrimaryKey(USER_TABLE_FOLLOWED, ['login']);
  return s;
}

export default function SubListServiceTest(): void {
  describe('SubListServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
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

    it('getStars_first_page_uses_url_and_writes_cache', 0, async (): Promise<void> => {
      const rdb: FakeRdbStore = buildRepoStore();
      const dao: RepositoryDao = new RepositoryDao(rdb);
      const store: RepositoryDetailStore = new RepositoryDetailStore();
      const service: RepositoryService = new RepositoryService(store, dao, PAGE_SIZE);
      const users: SubUserItem[] = buildUsers(PAGE_SIZE);
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(users);

      const res: SubListResult<SubUserItem> = await service.getStars(FULL_NAME, 1);

      expect(provider.captured.url).assertEqual(
        Address.getRepositoryStars(OWNER, REPO_NAME, 1, PAGE_SIZE));
      expect(provider.captured.method).assertEqual('GET');
      expect(res.result).assertTrue();
      expect(res.data.length).assertEqual(PAGE_SIZE);
      const writes: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_STAR);
      expect(writes !== undefined && writes >= 1).assertTrue();
    });

    it('getStars_second_page_does_not_write_cache', 0, async (): Promise<void> => {
      const rdb: FakeRdbStore = buildRepoStore();
      const dao: RepositoryDao = new RepositoryDao(rdb);
      const store: RepositoryDetailStore = new RepositoryDetailStore();
      const service: RepositoryService = new RepositoryService(store, dao, PAGE_SIZE);
      const users: SubUserItem[] = buildUsers(PAGE_SIZE);
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(users);

      const res: SubListResult<SubUserItem> = await service.getStars(FULL_NAME, 2);

      expect(provider.captured.url).assertEqual(
        Address.getRepositoryStars(OWNER, REPO_NAME, 2, PAGE_SIZE));
      expect(res.result).assertTrue();
      const writes: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_STAR);
      expect(writes === undefined || writes === 0).assertTrue();
    });

    it('getForks_first_page_uses_url_and_writes_cache', 0, async (): Promise<void> => {
      const rdb: FakeRdbStore = buildRepoStore();
      const dao: RepositoryDao = new RepositoryDao(rdb);
      const store: RepositoryDetailStore = new RepositoryDetailStore();
      const service: RepositoryService = new RepositoryService(store, dao, PAGE_SIZE);
      const repos: SubRepositoryItem[] = buildRepos(PAGE_SIZE);
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(repos);

      const res: SubListResult<SubRepositoryItem> = await service.getForks(FULL_NAME, 1);

      expect(provider.captured.url).assertEqual(
        Address.getRepositoryForks(OWNER, REPO_NAME, 1, PAGE_SIZE));
      expect(res.result).assertTrue();
      expect(res.data.length).assertEqual(PAGE_SIZE);
      const writes: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_FORK);
      expect(writes !== undefined && writes >= 1).assertTrue();
    });

    it('getWatchers_first_page_uses_url_and_writes_cache', 0, async (): Promise<void> => {
      const rdb: FakeRdbStore = buildRepoStore();
      const dao: RepositoryDao = new RepositoryDao(rdb);
      const store: RepositoryDetailStore = new RepositoryDetailStore();
      const service: RepositoryService = new RepositoryService(store, dao, PAGE_SIZE);
      const users: SubUserItem[] = buildUsers(PAGE_SIZE);
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(users);

      const res: SubListResult<SubUserItem> = await service.getWatchers(FULL_NAME, 1);

      expect(provider.captured.url).assertEqual(
        Address.getRepositoryWatchers(OWNER, REPO_NAME, 1, PAGE_SIZE));
      expect(res.result).assertTrue();
      expect(res.data.length).assertEqual(PAGE_SIZE);
      const writes: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_WATCHER);
      expect(writes !== undefined && writes >= 1).assertTrue();
    });

    it('getUserFollowers_first_page_uses_url_and_writes_cache', 0,
      async (): Promise<void> => {
        const rdb: FakeRdbStore = buildUserStore();
        const dao: UserDao = new UserDao(rdb);
        const store: UserDetailStore = new UserDetailStore();
        const service: UserService = new UserService(store, dao, PAGE_SIZE);
        const users: SubUserItem[] = buildUsers(PAGE_SIZE);
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(users);

        const res: FetchSubUserListResult = await service.getUserFollowers(LOGIN, 1);

        expect(provider.captured.url).assertEqual(
          Address.getUserFollowers(LOGIN, 1, PAGE_SIZE));
        expect(res.result).assertTrue();
        expect(res.data.length).assertEqual(PAGE_SIZE);
        const writes: number | undefined = rdb.insertCountByTable.get(USER_TABLE_FOLLOWER);
        expect(writes !== undefined && writes >= 1).assertTrue();
      });

    it('getUserFollowers_second_page_does_not_write_cache', 0,
      async (): Promise<void> => {
        const rdb: FakeRdbStore = buildUserStore();
        const dao: UserDao = new UserDao(rdb);
        const store: UserDetailStore = new UserDetailStore();
        const service: UserService = new UserService(store, dao, PAGE_SIZE);
        const users: SubUserItem[] = buildUsers(PAGE_SIZE);
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(users);

        const res: FetchSubUserListResult = await service.getUserFollowers(LOGIN, 2);

        expect(provider.captured.url).assertEqual(
          Address.getUserFollowers(LOGIN, 2, PAGE_SIZE));
        expect(res.result).assertTrue();
        const writes: number | undefined = rdb.insertCountByTable.get(USER_TABLE_FOLLOWER);
        expect(writes === undefined || writes === 0).assertTrue();
      });

    it('getUserFollowed_first_page_uses_url_and_writes_cache', 0,
      async (): Promise<void> => {
        const rdb: FakeRdbStore = buildUserStore();
        const dao: UserDao = new UserDao(rdb);
        const store: UserDetailStore = new UserDetailStore();
        const service: UserService = new UserService(store, dao, PAGE_SIZE);
        const users: SubUserItem[] = buildUsers(PAGE_SIZE);
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(users);

        const res: FetchSubUserListResult = await service.getUserFollowed(LOGIN, 1);

        expect(provider.captured.url).assertEqual(
          Address.getUserFollowed(LOGIN, 1, PAGE_SIZE));
        expect(res.result).assertTrue();
        expect(res.data.length).assertEqual(PAGE_SIZE);
        const writes: number | undefined = rdb.insertCountByTable.get(USER_TABLE_FOLLOWED);
        expect(writes !== undefined && writes >= 1).assertTrue();
      });
  });
}
