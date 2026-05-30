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
  IssueDao,
  ISSUE_TABLE_DETAIL,
  ISSUE_TABLE_COMMENT,
} from '../../../main/ets/dao/IssueDao';
import {
  IssueService,
  IssueServiceResult,
} from '../../../main/ets/service/IssueService';
import {
  IssueDetailModel,
  IssueCommentModel,
  IssueDetailStore,
  ISSUE_STATE_OPEN,
  ISSUE_STATE_CLOSED,
} from '../../../main/ets/store/IssueDetailStore';

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
  body: string | null = null;
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
                body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    this.captured.url = url;
    this.captured.method = method;
    this.captured.body = body;
    const cap: CapturedRequest = new CapturedRequest();
    cap.url = url;
    cap.method = method;
    cap.body = body;
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

const PAGE_SIZE: number = 2;
const FULL_NAME: string = 'CarGuo/GSYGithubApp';
const OWNER: string = 'CarGuo';
const REPO_NAME: string = 'GSYGithubApp';
const ISSUE_NUMBER: number = 42;

function buildIssue(state: string): IssueDetailModel {
  return {
    'id': 1001,
    'number': ISSUE_NUMBER,
    'title': 'sample issue',
    'body': 'sample body',
    'body_html': '<p>sample body</p>',
    'state': state,
    'locked': false,
    'comments': 1,
    'user': {
      'login': OWNER,
      'avatar_url': '',
      'html_url': 'https://github.com/' + OWNER,
    },
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-02T00:00:00Z',
    'closed_at': '',
    'html_url': 'https://github.com/' + FULL_NAME + '/issues/' + ISSUE_NUMBER.toString(),
  } as IssueDetailModel;
}

function buildComments(count: number, prefix: string): IssueCommentModel[] {
  const out: IssueCommentModel[] = [];
  for (let i = 0; i < count; i++) {
    out.push({
      'id': i + 1,
      'body': prefix + '-' + i.toString(),
      'body_html': '<p>' + prefix + '-' + i.toString() + '</p>',
      'user': { 'login': OWNER, 'avatar_url': '', 'html_url': '' },
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
      'html_url': '',
    } as IssueCommentModel);
  }
  return out;
}

function buildStore(): FakeRdbStore {
  const s: FakeRdbStore = new FakeRdbStore();
  s.setPrimaryKey(ISSUE_TABLE_DETAIL, ['fullName', 'number']);
  s.setPrimaryKey(ISSUE_TABLE_COMMENT, ['fullName', 'number', 'page']);
  return s;
}

export default function IssueServiceTest(): void {
  describe('IssueServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let rdb: FakeRdbStore;
    let dao: IssueDao;
    let store: IssueDetailStore;
    let service: IssueService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      rdb = buildStore();
      dao = new IssueDao(rdb);
      store = new IssueDetailStore();
      service = new IssueService(store, dao, PAGE_SIZE);

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

    it('getIssue_uses_detail_url_and_writes_cache', 0, async (): Promise<void> => {
      const detail: IssueDetailModel = buildIssue(ISSUE_STATE_OPEN);
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(detail);

      const res: IssueServiceResult<IssueDetailModel> =
        await service.getIssue(FULL_NAME, ISSUE_NUMBER);

      expect(provider.captured.url).assertEqual(Address.getIssue(OWNER, REPO_NAME, ISSUE_NUMBER));
      expect(provider.captured.method).assertEqual('GET');
      expect(res.result).assertTrue();
      expect(store.issue !== null).assertTrue();
      expect(store.state).assertEqual(ISSUE_STATE_OPEN);
      const writes: number | undefined = rdb.insertCountByTable.get(ISSUE_TABLE_DETAIL);
      expect(writes !== undefined && writes >= 1).assertTrue();
    });

    it('getIssue_falls_back_to_cache_on_failure', 0, async (): Promise<void> => {
      const cached: IssueDetailModel = buildIssue(ISSUE_STATE_CLOSED);
      await dao.saveIssueDetail(FULL_NAME, ISSUE_NUMBER, JSON.stringify(cached));

      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: IssueServiceResult<IssueDetailModel> =
        await service.getIssue(FULL_NAME, ISSUE_NUMBER);

      expect(res.result).assertTrue();
      expect(res.fromCache).assertTrue();
      expect(store.issue !== null).assertTrue();
      expect(store.state).assertEqual(ISSUE_STATE_CLOSED);
    });

    it('getIssue_applies_cache_before_network_refresh', 0, async (): Promise<void> => {
      const cached: IssueDetailModel = buildIssue(ISSUE_STATE_CLOSED);
      cached.title = 'cached issue title';
      await dao.saveIssueDetail(FULL_NAME, ISSUE_NUMBER, JSON.stringify(cached));
      const network: IssueDetailModel = buildIssue(ISSUE_STATE_OPEN);
      network.title = 'network issue title';
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(network);
      let sawCacheBeforeRequest: boolean = false;
      provider.onRequest = (): void => {
        sawCacheBeforeRequest = store.issue !== null
          && (store.issue as IssueDetailModel).title === 'cached issue title'
          && store.state === ISSUE_STATE_CLOSED;
      };

      const res: IssueServiceResult<IssueDetailModel> =
        await service.getIssue(FULL_NAME, ISSUE_NUMBER);

      expect(sawCacheBeforeRequest).assertTrue();
      expect(res.result).assertTrue();
      expect(res.fromCache).assertFalse();
      expect(store.issue !== null).assertTrue();
      expect((store.issue as IssueDetailModel).title).assertEqual('network issue title');
      expect(store.state).assertEqual(ISSUE_STATE_OPEN);
    });

    it('getComments_first_page_writes_cache_and_refreshes_store', 0, async (): Promise<void> => {
      const comments: IssueCommentModel[] = buildComments(PAGE_SIZE, 'p1');
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(comments);

      const res: IssueServiceResult<IssueCommentModel[]> =
        await service.getComments(FULL_NAME, ISSUE_NUMBER, 1);

      expect(provider.captured.url).assertEqual(
        Address.getIssueComments(OWNER, REPO_NAME, ISSUE_NUMBER, 1, PAGE_SIZE));
      expect(provider.captured.method).assertEqual('GET');
      expect(res.result).assertTrue();
      expect(store.comments.length).assertEqual(PAGE_SIZE);
      expect(store.page).assertEqual(1);
      expect(store.hasMore).assertTrue();
      const writes: number | undefined = rdb.insertCountByTable.get(ISSUE_TABLE_COMMENT);
      expect(writes !== undefined && writes >= 1).assertTrue();
    });

    it('getComments_second_page_appends_and_does_not_write_cache', 0,
      async (): Promise<void> => {
        const first: IssueCommentModel[] = buildComments(PAGE_SIZE, 'a');
        const second: IssueCommentModel[] = buildComments(PAGE_SIZE, 'b');
        provider.pushResponse(SUCCESS, JSON.stringify(first));
        provider.pushResponse(SUCCESS, JSON.stringify(second));

        await service.getComments(FULL_NAME, ISSUE_NUMBER, 1);
        const writesAfterFirst: number | undefined =
          rdb.insertCountByTable.get(ISSUE_TABLE_COMMENT);

        await service.getComments(FULL_NAME, ISSUE_NUMBER, 2);
        const writesAfterSecond: number | undefined =
          rdb.insertCountByTable.get(ISSUE_TABLE_COMMENT);

        expect(writesAfterFirst).assertEqual(writesAfterSecond);
        expect(store.comments.length).assertEqual(PAGE_SIZE * 2);
        expect(store.page).assertEqual(2);
      });

    it('getComments_first_page_falls_back_to_cache_on_failure', 0,
      async (): Promise<void> => {
        const cached: IssueCommentModel[] = buildComments(PAGE_SIZE, 'cache');
        await dao.saveIssueComment(FULL_NAME, ISSUE_NUMBER, 1, JSON.stringify(cached));

        provider.nextStatus = NETWORK_ERROR;
        provider.nextBody = '';

        const res: IssueServiceResult<IssueCommentModel[]> =
          await service.getComments(FULL_NAME, ISSUE_NUMBER, 1);

        expect(res.result).assertTrue();
        expect(res.fromCache).assertTrue();
        expect(store.comments.length).assertEqual(PAGE_SIZE);
      });

    it('getComments_first_page_applies_cache_before_network_refresh', 0,
      async (): Promise<void> => {
        const cached: IssueCommentModel[] = buildComments(1, 'cache-first');
        await dao.saveIssueComment(FULL_NAME, ISSUE_NUMBER, 1, JSON.stringify(cached));
        const network: IssueCommentModel[] = buildComments(2, 'network');
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(network);
        let sawCacheBeforeRequest: boolean = false;
        provider.onRequest = (): void => {
          sawCacheBeforeRequest = store.comments.length === 1
            && store.comments[0].body.indexOf('cache-first') >= 0;
        };

        const res: IssueServiceResult<IssueCommentModel[]> =
          await service.getComments(FULL_NAME, ISSUE_NUMBER, 1);

        expect(sawCacheBeforeRequest).assertTrue();
        expect(res.result).assertTrue();
        expect(res.fromCache).assertFalse();
        expect(store.comments.length).assertEqual(2);
        expect(store.comments[0].body.indexOf('network') >= 0).assertTrue();
      });

    it('createComment_uses_post_url_and_appends_to_store', 0, async (): Promise<void> => {
      const reply: IssueCommentModel = buildComments(1, 'reply')[0];
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(reply);

      const res: IssueServiceResult<IssueCommentModel> =
        await service.createComment(FULL_NAME, ISSUE_NUMBER, 'hello world');

      expect(res.result).assertTrue();
      expect(provider.captured.url).assertEqual(
        Address.createIssueComment(OWNER, REPO_NAME, ISSUE_NUMBER));
      expect(provider.captured.method).assertEqual('POST');
      expect(provider.captured.body !== null
        && (provider.captured.body as string).indexOf('hello world') >= 0).assertTrue();
      expect(store.comments.length).assertEqual(1);
    });

    it('closeIssue_uses_patch_with_state_closed_and_writes_cache', 0,
      async (): Promise<void> => {
        const closed: IssueDetailModel = buildIssue(ISSUE_STATE_CLOSED);
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(closed);

        const res: IssueServiceResult<IssueDetailModel> =
          await service.closeIssue(FULL_NAME, ISSUE_NUMBER);

        expect(res.result).assertTrue();
        expect(provider.captured.url).assertEqual(
          Address.setIssueState(OWNER, REPO_NAME, ISSUE_NUMBER));
        expect(provider.captured.method).assertEqual('PATCH');
        expect(provider.captured.body !== null
          && (provider.captured.body as string).indexOf(ISSUE_STATE_CLOSED) >= 0).assertTrue();
        expect(store.state).assertEqual(ISSUE_STATE_CLOSED);
        const writes: number | undefined = rdb.insertCountByTable.get(ISSUE_TABLE_DETAIL);
        expect(writes !== undefined && writes >= 1).assertTrue();
      });

    it('reopenIssue_uses_patch_with_state_open', 0, async (): Promise<void> => {
      const opened: IssueDetailModel = buildIssue(ISSUE_STATE_OPEN);
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(opened);

      const res: IssueServiceResult<IssueDetailModel> =
        await service.reopenIssue(FULL_NAME, ISSUE_NUMBER);

      expect(res.result).assertTrue();
      expect(provider.captured.url).assertEqual(
        Address.setIssueState(OWNER, REPO_NAME, ISSUE_NUMBER));
      expect(provider.captured.method).assertEqual('PATCH');
      expect(provider.captured.body !== null
        && (provider.captured.body as string).indexOf(ISSUE_STATE_OPEN) >= 0).assertTrue();
      expect(store.state).assertEqual(ISSUE_STATE_OPEN);
    });
  });
}
