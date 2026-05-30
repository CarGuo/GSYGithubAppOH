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
import { SUCCESS, UNAUTHORIZED } from '../../../main/ets/net/NetworkCode';
import { Address } from '../../../main/ets/net/Address';
import { ValueType, ValuesBucket } from '../../../main/ets/dao/db/RdbStore';
import { RdbStoreLike } from '../../../main/ets/dao/DaoBase';
import {
  RepositoryDao,
  REPO_TABLE_DETAIL,
  REPO_TABLE_DETAIL_README,
  REPO_TABLE_EVENT,
  REPO_TABLE_FILE_LIST,
  REPO_TABLE_ISSUE,
} from '../../../main/ets/dao/RepositoryDao';
import { IssueDao, ISSUE_TABLE_REPO_ISSUE } from '../../../main/ets/dao/IssueDao';
import {
  RepositoryService,
  RepositoryServiceResult,
} from '../../../main/ets/service/RepositoryService';
import {
  RepositoryDetailStore,
  RepositoryDetail,
  RepositoryEventItem,
  RepositoryFileItem,
  RepositoryIssueItem,
} from '../../../main/ets/store/RepositoryDetailStore';

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
  callCount: number = 0;
  captured: CapturedRequest = new CapturedRequest();
  capturedAll: CapturedRequest[] = [];
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
    const cap: CapturedRequest = new CapturedRequest();
    cap.url = url;
    cap.method = method;
    this.capturedAll.push(cap);
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
const FULL_NAME: string = 'CarGuo/GSYGithubApp';
const OWNER: string = 'CarGuo';
const REPO_NAME: string = 'GSYGithubApp';

function buildEvents(count: number, prefix: string): RepositoryEventItem[] {
  const out: RepositoryEventItem[] = [];
  for (let i = 0; i < count; i++) {
    out.push({
      'id': prefix + '-' + i.toString(),
      'type': 'PushEvent',
      'actor': { 'login': OWNER, 'avatar_url': '' },
      'repo': { 'id': 1, 'name': FULL_NAME },
      'created_at': '2024-01-01T00:00:00Z',
      'payload': {} as Record<string, Object>,
    } as RepositoryEventItem);
  }
  return out;
}

function buildIssues(count: number, prefix: string, state: string): RepositoryIssueItem[] {
  const out: RepositoryIssueItem[] = [];
  for (let i = 0; i < count; i++) {
    out.push({
      'id': i,
      'number': i,
      'title': prefix + '-' + i.toString(),
      'body': '',
      'state': state,
      'user': { 'login': OWNER, 'avatar_url': '' },
      'comments': 0,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
      'html_url': '',
    } as RepositoryIssueItem);
  }
  return out;
}

function buildFiles(count: number, type: string): RepositoryFileItem[] {
  const out: RepositoryFileItem[] = [];
  for (let i = 0; i < count; i++) {
    out.push({
      'name': type === 'dir' ? 'dir' + i.toString() : 'file' + i.toString() + '.ts',
      'path': type === 'dir' ? 'dir' + i.toString() : 'file' + i.toString() + '.ts',
      'sha': 'sha' + i.toString(),
      'size': 100 + i,
      'type': type,
      'download_url': '',
      'html_url': '',
    } as RepositoryFileItem);
  }
  return out;
}

function buildDetail(defaultBranch: string): RepositoryDetail {
  return {
    'id': 1,
    'name': REPO_NAME,
    'full_name': FULL_NAME,
    'description': '',
    'default_branch': defaultBranch,
    'html_url': '',
    'language': '',
    'stargazers_count': 0,
    'watchers_count': 0,
    'forks_count': 0,
    'open_issues_count': 0,
    'subscribers_count': 0,
    'owner': {
      'login': OWNER,
      'avatar_url': '',
      'html_url': '',
    },
  } as RepositoryDetail;
}

function buildStore(): FakeRdbStore {
  const s: FakeRdbStore = new FakeRdbStore();
  s.setPrimaryKey(REPO_TABLE_DETAIL, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_DETAIL_README, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_EVENT, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_FILE_LIST, ['fullName', 'branch', 'path']);
  s.setPrimaryKey(REPO_TABLE_ISSUE, ['fullName', 'state', 'page']);
  s.setPrimaryKey(ISSUE_TABLE_REPO_ISSUE, ['fullName', 'state', 'page']);
  return s;
}

export default function RepoTabsServiceTest(): void {
  describe('RepoTabsServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let rdb: FakeRdbStore;
    let dao: RepositoryDao;
    let issueDao: IssueDao;
    let store: RepositoryDetailStore;
    let service: RepositoryService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      rdb = buildStore();
      dao = new RepositoryDao(rdb);
      issueDao = new IssueDao(rdb);
      store = new RepositoryDetailStore();
      service = new RepositoryService(store, dao, PAGE_SIZE, issueDao);

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

      it('getIssues_uses_open_url_and_writes_issue_dao_only_on_first_page', 0,
        async (): Promise<void> => {
        const issues: RepositoryIssueItem[] = buildIssues(PAGE_SIZE, 'A', 'open');
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(issues);

        const res: RepositoryServiceResult<RepositoryIssueItem[]> =
          await service.getIssues(FULL_NAME, 'open', 1);

        expect(res.result).assertTrue();
        expect(provider.captured.url).assertEqual(
          Address.getRepositoryIssue(OWNER, REPO_NAME, 1, 'open', PAGE_SIZE));
        expect(store.issueList.length).assertEqual(PAGE_SIZE);
        expect(store.issuePage).assertEqual(1);
        expect(store.issueHasMore).assertTrue();
        const repoIssueWrites: number | undefined = rdb.insertCountByTable.get(ISSUE_TABLE_REPO_ISSUE);
        expect(repoIssueWrites !== undefined && repoIssueWrites >= 1).assertTrue();
      });

    it('getIssues_with_query_uses_compose_search_issues_url', 0, async (): Promise<void> => {
      const issues: RepositoryIssueItem[] = buildIssues(1, 'Search', 'open');
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify({
        'total_count': 1,
        'incomplete_results': false,
        'items': issues,
      });

      const res: RepositoryServiceResult<RepositoryIssueItem[]> =
        await service.getIssues(FULL_NAME, 'all', 1, 'crash');

      expect(res.result).assertTrue();
      expect(provider.captured.url).assertEqual(
        Address.getRepositoryIssueSearch(FULL_NAME, 'all', 'crash', 1, PAGE_SIZE));
      expect(store.issueList.length).assertEqual(1);
      expect(store.issuePage).assertEqual(1);
      const repoIssueWrites: number | undefined = rdb.insertCountByTable.get(ISSUE_TABLE_REPO_ISSUE);
      expect(repoIssueWrites === undefined || repoIssueWrites === 0).assertTrue();
    });

    it('getIssues_second_page_does_not_write_cache_and_appends_list', 0,
      async (): Promise<void> => {
        const first: RepositoryIssueItem[] = buildIssues(PAGE_SIZE, 'P1', 'all');
        const second: RepositoryIssueItem[] = buildIssues(PAGE_SIZE, 'P2', 'all');
        provider.pushResponse(SUCCESS, JSON.stringify(first));
        provider.pushResponse(SUCCESS, JSON.stringify(second));

        await service.getIssues(FULL_NAME, 'all', 1);
        const writesAfterFirst: number | undefined = rdb.insertCountByTable.get(ISSUE_TABLE_REPO_ISSUE);

        await service.getIssues(FULL_NAME, 'all', 2);
        const writesAfterSecond: number | undefined = rdb.insertCountByTable.get(ISSUE_TABLE_REPO_ISSUE);

        expect(writesAfterFirst).assertEqual(writesAfterSecond);
        expect(store.issueList.length).assertEqual(PAGE_SIZE * 2);
        expect(store.issuePage).assertEqual(2);
        expect(provider.capturedAll.length).assertEqual(2);
        expect(provider.capturedAll[1].url).assertEqual(
          Address.getRepositoryIssue(OWNER, REPO_NAME, 2, 'all', PAGE_SIZE));
      });

    it('getIssues_unauthorized_propagates_401', 0, async (): Promise<void> => {
      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '';

      const res: RepositoryServiceResult<RepositoryIssueItem[]> =
        await service.getIssues(FULL_NAME, 'closed', 1);

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(store.issueLoading).assertFalse();
    });

    it('getEvents_uses_events_url_and_writes_repo_dao_only_on_first_page', 0,
      async (): Promise<void> => {
        const events: RepositoryEventItem[] = buildEvents(PAGE_SIZE, 'E1');
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(events);

        const res: RepositoryServiceResult<RepositoryEventItem[]> =
          await service.getEvents(FULL_NAME, 1);

        expect(res.result).assertTrue();
        expect(provider.captured.url).assertEqual(
          Address.getRepositoryEvent(OWNER, REPO_NAME, 1, PAGE_SIZE));
        expect(store.eventList.length).assertEqual(PAGE_SIZE);
        expect(store.eventPage).assertEqual(1);
        expect(store.eventHasMore).assertTrue();
        const eventWrites: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_EVENT);
        expect(eventWrites !== undefined && eventWrites >= 1).assertTrue();
      });

    it('getEvents_second_page_does_not_write_cache_and_appends', 0,
      async (): Promise<void> => {
        const first: RepositoryEventItem[] = buildEvents(PAGE_SIZE, 'A');
        const second: RepositoryEventItem[] = buildEvents(PAGE_SIZE, 'B');
        provider.pushResponse(SUCCESS, JSON.stringify(first));
        provider.pushResponse(SUCCESS, JSON.stringify(second));

        await service.getEvents(FULL_NAME, 1);
        const writesAfterFirst: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_EVENT);

        await service.getEvents(FULL_NAME, 2);
        const writesAfterSecond: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_EVENT);

        expect(writesAfterFirst).assertEqual(writesAfterSecond);
        expect(store.eventList.length).assertEqual(PAGE_SIZE * 2);
        expect(store.eventPage).assertEqual(2);
      });

    it('getEvents_unauthorized_propagates_401', 0, async (): Promise<void> => {
      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '';

      const res: RepositoryServiceResult<RepositoryEventItem[]> =
        await service.getEvents(FULL_NAME, 1);

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(store.eventLoading).assertFalse();
    });

    it('getFiles_root_uses_contents_url_and_writes_cache', 0,
      async (): Promise<void> => {
        const files: RepositoryFileItem[] = buildFiles(2, 'file');
        store.setDetail(buildDetail('master'));
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(files);

        const res: RepositoryServiceResult<RepositoryFileItem[]> =
          await service.getFiles(FULL_NAME, 'master', '');

        expect(res.result).assertTrue();
        expect(provider.captured.url).assertEqual(
          Address.getReposFileDir(OWNER, REPO_NAME, '', 'master'));
        expect(store.fileList.length).assertEqual(2);
        const fileWrites: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_FILE_LIST);
        expect(fileWrites !== undefined && fileWrites >= 1).assertTrue();
      });

    it('getFiles_with_branch_and_path_appends_ref_query', 0,
      async (): Promise<void> => {
        const files: RepositoryFileItem[] = buildFiles(1, 'dir');
        store.setDetail(buildDetail('master'));
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(files);

        const res: RepositoryServiceResult<RepositoryFileItem[]> =
          await service.getFiles(FULL_NAME, 'master', 'src/main');

        expect(res.result).assertTrue();
        expect(provider.captured.url).assertEqual(
          Address.getReposFileDir(OWNER, REPO_NAME, 'src/main', 'master'));
        expect(provider.captured.url.indexOf('?ref=master') >= 0).assertTrue();
        expect(store.fileList.length).assertEqual(1);
        const fileWrites: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_FILE_LIST);
        expect(fileWrites === undefined || fileWrites === 0).assertTrue();
      });

    it('getFiles_default_root_falls_back_to_cache_when_network_fails', 0,
      async (): Promise<void> => {
        const cached: RepositoryFileItem[] = buildFiles(1, 'file');
        store.setDetail(buildDetail('master'));
        await dao.saveFile(FULL_NAME, 'master', '', JSON.stringify(cached));
        provider.nextStatus = 500;
        provider.nextBody = '';

        const res: RepositoryServiceResult<RepositoryFileItem[]> =
          await service.getFiles(FULL_NAME, 'master', '');

        expect(res.result).assertTrue();
        expect(res.fromCache).assertTrue();
        expect(res.data !== null ? res.data.length : 0).assertEqual(1);
        expect(store.fileList.length).assertEqual(1);
        expect(store.fileList[0].name).assertEqual('file0.ts');
      });

    it('getFiles_non_default_root_does_not_read_or_write_default_branch_cache', 0,
      async (): Promise<void> => {
        const cached: RepositoryFileItem[] = buildFiles(1, 'file');
        store.setDetail(buildDetail('master'));
        await dao.saveFile(FULL_NAME, 'master', '', JSON.stringify(cached));
        provider.nextStatus = 500;
        provider.nextBody = '';

        const res: RepositoryServiceResult<RepositoryFileItem[]> =
          await service.getFiles(FULL_NAME, 'dev', '');

        expect(res.result).assertFalse();
        expect(res.fromCache).assertFalse();
        expect(store.fileList.length).assertEqual(0);
        const fileWrites: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_FILE_LIST);
        expect(fileWrites).assertEqual(1);
      });

    it('getFiles_unauthorized_propagates_401', 0, async (): Promise<void> => {
      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '';

      const res: RepositoryServiceResult<RepositoryFileItem[]> =
        await service.getFiles(FULL_NAME, null, '');

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(store.fileLoading).assertFalse();
    });

    it('store_setPath_pushes_stack_and_popPath_restores_previous', 0,
      async (): Promise<void> => {
        store.setPath('a');
        store.setPath('a/b');
        expect(store.currentPath).assertEqual('a/b');

        const popped: string = store.popPath();
        expect(popped).assertEqual('a');
        expect(store.currentPath).assertEqual('a');

        const popped2: string = store.popPath();
        expect(popped2).assertEqual('');
        expect(store.currentPath).assertEqual('');
      });
  });
}
