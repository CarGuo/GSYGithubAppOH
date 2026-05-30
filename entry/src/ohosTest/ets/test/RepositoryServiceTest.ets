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
  RepositoryDao,
  REPO_TABLE_COMMITS,
  REPO_TABLE_DETAIL,
  REPO_TABLE_DETAIL_README,
  REPO_TABLE_EVENT,
  REPO_TABLE_ISSUE,
} from '../../../main/ets/dao/RepositoryDao';
import {
  RepositoryService,
  RepositoryServiceResult,
  SubListResult,
  SubRepositoryItem,
} from '../../../main/ets/service/RepositoryService';
import {
  RepositoryDetail,
  RepositoryDetailStore,
  RepositoryCommitItem,
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
  onRequest: (() => void) | null = null;

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
    if (this.onRequest !== null) {
      (this.onRequest as () => void)();
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
const FULL_NAME: string = 'CarGuo/GSYGithubApp';
const OWNER: string = 'CarGuo';
const REPO_NAME: string = 'GSYGithubApp';

function buildDetail(): RepositoryDetail {
  return {
    'id': 1,
    'name': REPO_NAME,
    'full_name': FULL_NAME,
    'description': 'GSY Github App for OH',
    'default_branch': 'master',
    'html_url': 'https://github.com/' + FULL_NAME,
    'language': 'TypeScript',
    'stargazers_count': 9999,
    'watchers_count': 8888,
    'forks_count': 7777,
    'open_issues_count': 12,
    'subscribers_count': 100,
    'owner': {
      'login': OWNER,
      'avatar_url': '',
      'html_url': 'https://github.com/' + OWNER,
    },
  } as RepositoryDetail;
}

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

function buildIssues(count: number, prefix: string): RepositoryIssueItem[] {
  const out: RepositoryIssueItem[] = [];
  for (let i = 0; i < count; i++) {
    out.push({
      'id': i,
      'number': i,
      'title': prefix + '-' + i.toString(),
      'body': '',
      'state': 'open',
      'user': { 'login': OWNER, 'avatar_url': '' },
      'comments': 0,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
      'html_url': '',
    } as RepositoryIssueItem);
  }
  return out;
}

function buildFiles(count: number): RepositoryFileItem[] {
  const out: RepositoryFileItem[] = [];
  for (let i = 0; i < count; i++) {
    out.push({
      'name': 'file' + i.toString() + '.ts',
      'path': 'file' + i.toString() + '.ts',
      'sha': 'sha' + i.toString(),
      'size': 100 + i,
      'type': 'file',
      'download_url': '',
      'html_url': '',
    } as RepositoryFileItem);
  }
  return out;
}

function buildCommits(count: number, prefix: string): RepositoryCommitItem[] {
  const out: RepositoryCommitItem[] = [];
  for (let i = 0; i < count; i++) {
    out.push({
      'sha': prefix + '-sha-' + i.toString(),
      'commit': {
        'message': prefix + ' commit ' + i.toString(),
        'author': { 'name': 'author', 'email': 'a@example.com', 'date': '2024-01-01T00:00:00Z' },
        'committer': { 'name': 'committer', 'email': 'c@example.com', 'date': '2024-01-01T00:00:00Z' },
      },
      'author': { 'login': OWNER, 'avatar_url': '' },
      'committer': { 'login': OWNER, 'avatar_url': '' },
    } as RepositoryCommitItem);
  }
  return out;
}

function buildStore(): FakeRdbStore {
  const s: FakeRdbStore = new FakeRdbStore();
  s.setPrimaryKey(REPO_TABLE_DETAIL, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_DETAIL_README, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_EVENT, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_ISSUE, ['fullName', 'state', 'page']);
  s.setPrimaryKey(REPO_TABLE_COMMITS, ['fullName', 'branch', 'page']);
  return s;
}

export default function RepositoryServiceTest(): void {
  describe('RepositoryServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let rdb: FakeRdbStore;
    let dao: RepositoryDao;
    let store: RepositoryDetailStore;
    let service: RepositoryService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      rdb = buildStore();
      dao = new RepositoryDao(rdb);
      store = new RepositoryDetailStore();
      service = new RepositoryService(store, dao, PAGE_SIZE);

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

    it('getReposInfo_uses_detail_url_and_writes_cache', 0, async (): Promise<void> => {
      const detail: RepositoryDetail = buildDetail();
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(detail);

      const res: RepositoryServiceResult<RepositoryDetail> = await service.getReposInfo(FULL_NAME);

      expect(provider.captured.url).assertEqual(Address.getReposDetail(OWNER, REPO_NAME));
      expect(provider.captured.method).assertEqual('GET');
      expect(res.result).assertTrue();
      expect(store.detail !== null).assertTrue();
      const writes: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_DETAIL);
      expect(writes !== undefined && writes >= 1).assertTrue();
    });

    it('getReadme_uses_rendered_html_and_writes_cache', 0, async (): Promise<void> => {
      const htmlBody: string = '<h1>Hello</h1>';
      provider.nextStatus = SUCCESS;
      provider.nextBody = htmlBody;
      let sawLoadingBeforeRequest: boolean = false;
      provider.onRequest = (): void => {
        sawLoadingBeforeRequest = store.readmeLoading
          && store.readmeHtml.length === 0
          && store.readmeError.length === 0;
      };

      const res: RepositoryServiceResult<string> = await service.getReadme(FULL_NAME, null);

      expect(sawLoadingBeforeRequest).assertTrue();
      expect(provider.captured.url).assertEqual(Address.getReposReadme(OWNER, REPO_NAME, null));
      expect(provider.captured.method).assertEqual('GET');
      expect(res.result).assertTrue();
      expect(store.readmeHtml.length > 0).assertTrue();
      expect(store.readmeHtml.indexOf('Hello') >= 0).assertTrue();
      expect(store.readmeLoading).assertFalse();
      expect(store.readmeError.length).assertEqual(0);
      const writes: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_DETAIL_README);
      expect(writes !== undefined && writes >= 1).assertTrue();
    });

    it('getReadme_no_cache_keeps_loading_until_failure_then_sets_readme_error', 0,
      async (): Promise<void> => {
        provider.nextStatus = NETWORK_ERROR;
        provider.nextBody = '';
        let sawLoadingBeforeRequest: boolean = false;
        provider.onRequest = (): void => {
          sawLoadingBeforeRequest = store.readmeLoading
            && store.readmeHtml.length === 0
            && store.readmeError.length === 0;
        };

        const res: RepositoryServiceResult<string> = await service.getReadme(FULL_NAME, null);

        expect(sawLoadingBeforeRequest).assertTrue();
        expect(res.result).assertFalse();
        expect(store.readmeLoading).assertFalse();
        expect(store.readmeError.length > 0).assertTrue();
        expect(store.readmeHtml.length).assertEqual(0);
      });

    it('getReadme_non_default_branch_does_not_use_default_cache', 0, async (): Promise<void> => {
      await dao.saveReadme(FULL_NAME, '<h1>Cached default</h1>');
      const writesBefore: number = rdb.insertCountByTable.get(REPO_TABLE_DETAIL_README) as number;
      const queryBefore: number = rdb.queryCount;
      store.setDetail(buildDetail());
      provider.nextStatus = SUCCESS;
      provider.nextBody = '<h1>Feature branch</h1>';

      const res: RepositoryServiceResult<string> = await service.getReadme(FULL_NAME, 'feature');

      expect(provider.captured.url).assertEqual(Address.getReposReadme(OWNER, REPO_NAME, 'feature'));
      expect(res.result).assertTrue();
      expect(store.readmeHtml.indexOf('Feature branch') >= 0).assertTrue();
      expect(store.readmeHtml.indexOf('Cached default') < 0).assertTrue();
      expect(rdb.queryCount).assertEqual(queryBefore);
      expect(rdb.insertCountByTable.get(REPO_TABLE_DETAIL_README)).assertEqual(writesBefore);
    });

    it('getRepositoryCommits_default_branch_cache_first_then_network_writes_cache', 0,
      async (): Promise<void> => {
        store.setDetail(buildDetail());
        store.setCurrentBranch('master');
        await dao.saveCommits(FULL_NAME, 'master', 1, JSON.stringify(buildCommits(1, 'cached')));
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(buildCommits(2, 'network'));

        const res: RepositoryServiceResult<RepositoryCommitItem[]> =
          await service.getRepositoryCommits(FULL_NAME, 1);

        expect(provider.captured.url)
          .assertEqual(Address.getReposCommitsPaged(OWNER, REPO_NAME, 1, PAGE_SIZE, 'master'));
        expect(res.result).assertTrue();
        expect(res.fromCache).assertFalse();
        expect(store.commits.length).assertEqual(2);
        expect(store.commits[0].sha.indexOf('network') >= 0).assertTrue();
        const writes: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_COMMITS);
        expect(writes !== undefined && writes >= 2).assertTrue();
      });

    it('getRepositoryCommits_default_branch_falls_back_to_cache_when_network_fails', 0,
      async (): Promise<void> => {
        store.setDetail(buildDetail());
        store.setCurrentBranch('master');
        await dao.saveCommits(FULL_NAME, 'master', 1, JSON.stringify(buildCommits(1, 'cached')));
        provider.nextStatus = NETWORK_ERROR;
        provider.nextBody = '';

        const res: RepositoryServiceResult<RepositoryCommitItem[]> =
          await service.getRepositoryCommits(FULL_NAME, 1);

        expect(res.result).assertTrue();
        expect(res.fromCache).assertTrue();
        expect(store.commits.length).assertEqual(1);
        expect(store.commits[0].sha.indexOf('cached') >= 0).assertTrue();
      });

    it('getStarStatus_calls_star_and_watch_urls', 0, async (): Promise<void> => {
      provider.pushResponse(SUCCESS, '');
      provider.pushResponse(SUCCESS, '');

      const res: RepositoryServiceResult<boolean> = await service.getStarStatus(FULL_NAME);

      expect(res.result).assertTrue();
      expect(provider.callCount).assertEqual(2);
      expect(provider.capturedAll[0].url).assertEqual(Address.getStar(OWNER, REPO_NAME));
      expect(provider.capturedAll[0].method).assertEqual('GET');
      expect(provider.capturedAll[1].url).assertEqual(Address.getWatch(OWNER, REPO_NAME));
      expect(provider.capturedAll[1].method).assertEqual('GET');
      expect(store.starred).assertTrue();
      expect(store.watching).assertTrue();
    });

    it('star_uses_PUT_and_unstar_uses_DELETE', 0, async (): Promise<void> => {
      provider.pushResponse(SUCCESS, '');
      const r1: RepositoryServiceResult<boolean> = await service.star(FULL_NAME);
      expect(r1.result).assertTrue();
      expect(provider.captured.url).assertEqual(Address.setStar(OWNER, REPO_NAME));
      expect(provider.captured.method).assertEqual('PUT');
      expect(store.starred).assertTrue();

      provider.pushResponse(SUCCESS, '');
      const r2: RepositoryServiceResult<boolean> = await service.unstar(FULL_NAME);
      expect(r2.result).assertTrue();
      expect(provider.captured.url).assertEqual(Address.setUnstar(OWNER, REPO_NAME));
      expect(provider.captured.method).assertEqual('DELETE');
      expect(store.starred).assertFalse();
    });

    it('watch_uses_PUT_and_unwatch_uses_DELETE', 0, async (): Promise<void> => {
      provider.pushResponse(SUCCESS, '');
      const r1: RepositoryServiceResult<boolean> = await service.watch(FULL_NAME);
      expect(r1.result).assertTrue();
      expect(provider.captured.url).assertEqual(Address.setWatch(OWNER, REPO_NAME));
      expect(provider.captured.method).assertEqual('PUT');
      expect(store.watching).assertTrue();

      provider.pushResponse(SUCCESS, '');
      const r2: RepositoryServiceResult<boolean> = await service.unwatch(FULL_NAME);
      expect(r2.result).assertTrue();
      expect(provider.captured.url).assertEqual(Address.setUnwatch(OWNER, REPO_NAME));
      expect(provider.captured.method).assertEqual('DELETE');
      expect(store.watching).assertFalse();
    });

    it('getRepositoryEvents_first_page_writes_cache_and_updates_store', 0,
      async (): Promise<void> => {
        const events: RepositoryEventItem[] = buildEvents(PAGE_SIZE, 'a');
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(events);

        const res: RepositoryServiceResult<RepositoryEventItem[]> =
          await service.getRepositoryEvents(FULL_NAME, 1);

        expect(provider.captured.url).assertEqual(
          Address.getRepositoryEvent(OWNER, REPO_NAME, 1, PAGE_SIZE));
        expect(res.result).assertTrue();
        expect(store.activity.length).assertEqual(PAGE_SIZE);
        expect(store.activityPage).assertEqual(1);
        expect(store.activityHasMore).assertTrue();
        const writes: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_EVENT);
        expect(writes !== undefined && writes >= 1).assertTrue();
      });

    it('getRepositoryEvents_first_page_applies_cache_before_network_refresh', 0,
      async (): Promise<void> => {
        const cached: RepositoryEventItem[] = buildEvents(1, 'cache-first');
        await dao.saveEvent(FULL_NAME, JSON.stringify(cached));
        const network: RepositoryEventItem[] = buildEvents(2, 'network');
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(network);
        let sawCacheBeforeRequest: boolean = false;
        provider.onRequest = (): void => {
          sawCacheBeforeRequest = store.activity.length === 1
            && store.activity[0].id.indexOf('cache-first') >= 0;
        };

        const res: RepositoryServiceResult<RepositoryEventItem[]> =
          await service.getRepositoryEvents(FULL_NAME, 1);

        expect(sawCacheBeforeRequest).assertTrue();
        expect(res.result).assertTrue();
        expect(res.fromCache).assertFalse();
        expect(store.activity.length).assertEqual(2);
        expect(store.activity[0].id.indexOf('network') >= 0).assertTrue();
      });

    it('getRepositoryEvents_falls_back_to_cache_on_first_page_failure', 0,
      async (): Promise<void> => {
        const cached: RepositoryEventItem[] = buildEvents(2, 'cache');
        await dao.saveEvent(FULL_NAME, JSON.stringify(cached));

        provider.nextStatus = NETWORK_ERROR;
        provider.nextBody = '';

        const res: RepositoryServiceResult<RepositoryEventItem[]> =
          await service.getRepositoryEvents(FULL_NAME, 1);

        expect(res.result).assertTrue();
        expect(res.fromCache).assertTrue();
        expect(store.activity.length).assertEqual(2);
      });

    it('getRepositoryFiles_uses_contents_url_and_updates_store', 0, async (): Promise<void> => {
      const files: RepositoryFileItem[] = buildFiles(2);
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(files);

      const res: RepositoryServiceResult<RepositoryFileItem[]> =
        await service.getRepositoryFiles(FULL_NAME, 'src');

      expect(provider.captured.url).assertEqual(
        Address.getReposFileDir(OWNER, REPO_NAME, 'src', null));
      expect(res.result).assertTrue();
      expect(store.files.length).assertEqual(2);
    });

    it('getIssues_first_page_writes_cache_and_updates_store', 0, async (): Promise<void> => {
      const issues: RepositoryIssueItem[] = buildIssues(PAGE_SIZE, 'open');
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(issues);

      const res: RepositoryServiceResult<RepositoryIssueItem[]> =
        await service.getIssues(FULL_NAME, 'open', 1);

      expect(provider.captured.url).assertEqual(
        Address.getRepositoryIssue(OWNER, REPO_NAME, 1, 'open', PAGE_SIZE));
      expect(res.result).assertTrue();
      expect(store.issues.length).assertEqual(PAGE_SIZE);
      expect(store.issuesPage).assertEqual(1);
      expect(store.issuesHasMore).assertTrue();
      const writes: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_ISSUE);
      expect(writes !== undefined && writes >= 1).assertTrue();
    });

    it('getIssues_all_first_page_applies_cache_before_network_refresh', 0, async (): Promise<void> => {
      const cached: RepositoryIssueItem[] = buildIssues(1, 'cache-first');
      await dao.saveIssue(FULL_NAME, 'all', 1, JSON.stringify(cached));
      const network: RepositoryIssueItem[] = buildIssues(PAGE_SIZE, 'network');
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(network);
      let sawCacheBeforeRequest: boolean = false;
      provider.onRequest = (): void => {
        sawCacheBeforeRequest = store.issues.length === 1
          && store.issues[0].title === 'cache-first-0';
      };

      const res: RepositoryServiceResult<RepositoryIssueItem[]> =
        await service.getIssues(FULL_NAME, 'all', 1);

      expect(sawCacheBeforeRequest).assertTrue();
      expect(res.result).assertTrue();
      expect(res.fromCache).assertFalse();
      expect(store.issues.length).assertEqual(PAGE_SIZE);
      expect(store.issues[0].title).assertEqual('network-0');
    });

    it('getIssues_with_query_uses_search_issues_and_skips_cache_write', 0, async (): Promise<void> => {
      const issues: RepositoryIssueItem[] = buildIssues(1, 'search');
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify({
        'total_count': 1,
        'incomplete_results': false,
        'items': issues,
      });

      const res: RepositoryServiceResult<RepositoryIssueItem[]> =
        await service.getIssues(FULL_NAME, 'open', 1, 'bug fix');

      expect(provider.captured.url).assertEqual(
        Address.getRepositoryIssueSearch(FULL_NAME, 'open', 'bug fix', 1, PAGE_SIZE));
      expect(res.result).assertTrue();
      expect(store.issues.length).assertEqual(1);
      const writes: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_ISSUE);
      expect(writes === undefined || writes === 0).assertTrue();
    });

    it('getIssues_second_page_does_not_write_cache_and_appends', 0, async (): Promise<void> => {
      const first: RepositoryIssueItem[] = buildIssues(PAGE_SIZE, 'a');
      const second: RepositoryIssueItem[] = buildIssues(PAGE_SIZE, 'b');
      provider.pushResponse(SUCCESS, JSON.stringify(first));
      provider.pushResponse(SUCCESS, JSON.stringify(second));

      await service.getIssues(FULL_NAME, 'all', 1);
      const writesAfterFirst: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_ISSUE);

      await service.getIssues(FULL_NAME, 'all', 2);
      const writesAfterSecond: number | undefined = rdb.insertCountByTable.get(REPO_TABLE_ISSUE);

      expect(writesAfterFirst).assertEqual(writesAfterSecond);
      expect(store.issues.length).assertEqual(PAGE_SIZE * 2);
      expect(store.issuesPage).assertEqual(2);
    });

    it('searchTopicRepos_uses_compose_topic_query_and_maps_repositories', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = '{"items":[{"id":10,"name":"topic-repo","full_name":"CarGuo/topic-repo",'
        + '"description":"topic result","language":"Kotlin","stargazers_count":7,'
        + '"forks_count":2,"watchers_count":3,'
        + '"owner":{"login":"CarGuo","avatar_url":"https://avatars.githubusercontent.com/u/1?v=4"}}]}';

      const res: SubListResult<SubRepositoryItem> = await service.searchTopicRepos('github', 2);

      expect(provider.captured.url).assertEqual(Address.search('topic:github', 'stars', 'desc', null, 2, PAGE_SIZE));
      expect(provider.captured.method).assertEqual('GET');
      expect(res.result).assertTrue();
      expect(res.data.length).assertEqual(1);
      expect(res.data[0].name).assertEqual('topic-repo');
      expect(res.data[0].owner_login).assertEqual('CarGuo');
      expect(res.data[0].stargazers_count).assertEqual(7);
    });
  });
}
