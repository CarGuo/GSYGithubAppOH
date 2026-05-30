import { describe, it, expect, beforeEach } from '@ohos/hypium';
import relationalStore from '@ohos.data.relationalStore';
import { ValueType, ValuesBucket } from '../../../main/ets/dao/db/RdbStore';
import { RdbStoreLike } from '../../../main/ets/dao/DaoBase';
import {
  UserDao,
  USER_TABLE_INFO,
  USER_TABLE_FOLLOWER,
  USER_TABLE_FOLLOWED,
  USER_TABLE_ORG_MEMBER,
  USER_TABLE_ORGS,
  USER_TABLE_STARED,
  USER_TABLE_REPOS
} from '../../../main/ets/dao/UserDao';
import {
  DynamicDao,
  DYN_TABLE_RECEIVED,
  DYN_TABLE_USER_EVENT,
  DYN_TABLE_REPO_EVENT
} from '../../../main/ets/dao/DynamicDao';
import {
  RepositoryDao,
  REPO_TABLE_PULSE,
  REPO_TABLE_BRANCH,
  REPO_TABLE_COMMITS,
  REPO_TABLE_WATCHER,
  REPO_TABLE_STAR,
  REPO_TABLE_FORK,
  REPO_TABLE_DETAIL,
  REPO_TABLE_DETAIL_README,
  REPO_TABLE_COMMIT_INFO_DETAIL
} from '../../../main/ets/dao/RepositoryDao';
import {
  IssueDao,
  ISSUE_TABLE_REPO_ISSUE,
  ISSUE_TABLE_DETAIL,
  ISSUE_TABLE_COMMENT
} from '../../../main/ets/dao/IssueDao';
import {
  ReadHistoryDao,
  READ_HISTORY_TABLE,
  ReadHistoryRow
} from '../../../main/ets/dao/ReadHistoryDao';
import { TrendDao, TREND_TABLE } from '../../../main/ets/dao/TrendDao';

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
  orderColumn: string = '';
  orderDesc: boolean = false;
  limit: number = -1;
  offset: number = 0;

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

  orderByDesc(column: string): FakePredicates {
    this.orderColumn = column;
    this.orderDesc = true;
    return this;
  }

  orderByAsc(column: string): FakePredicates {
    this.orderColumn = column;
    this.orderDesc = false;
    return this;
  }

  limitAs(value: number): FakePredicates {
    this.limit = value;
    return this;
  }

  offsetAs(value: number): FakePredicates {
    this.offset = value;
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
  queryCount: number = 0;
  deleteCount: number = 0;

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
    if (row['id'] === undefined) {
      row['id'] = rows.length + 1;
    }
    rows.push(row);
    return rows.length;
  }

  async query(predicates: relationalStore.RdbPredicates,
    columns?: string[]): Promise<relationalStore.ResultSet> {
    this.queryCount = this.queryCount + 1;
    const fp: FakePredicates = predicates as ESObject as FakePredicates;
    const rows: FakeRow[] = this.ensureTable(fp.table);
    let filtered: FakeRow[] = this.filterRows(rows, fp);
    filtered = this.sortRows(filtered, fp);
    filtered = this.pageRows(filtered, fp);
    const cols: string[] = columns !== undefined && columns.length > 0
      ? columns
      : (filtered.length > 0 ? Object.keys(filtered[0]) : []);
    return new FakeResultSet(filtered, cols) as ESObject as relationalStore.ResultSet;
  }

  async deleteByPredicates(predicates: relationalStore.RdbPredicates): Promise<number> {
    this.deleteCount = this.deleteCount + 1;
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

  private filterRows(rows: FakeRow[], fp: FakePredicates): FakeRow[] {
    const out: FakeRow[] = [];
    for (let i = 0; i < rows.length; i++) {
      if (this.matchConditions(rows[i], fp.conditions)) {
        out.push(rows[i]);
      }
    }
    return out;
  }

  private sortRows(rows: FakeRow[], fp: FakePredicates): FakeRow[] {
    if (fp.orderColumn.length === 0) {
      return rows;
    }
    const col: string = fp.orderColumn;
    const desc: boolean = fp.orderDesc;
    rows.sort((a: FakeRow, b: FakeRow): number => {
      const av: ValueType = a[col];
      const bv: ValueType = b[col];
      const an: number = typeof av === 'number' ? av : 0;
      const bn: number = typeof bv === 'number' ? bv : 0;
      return desc ? (bn - an) : (an - bn);
    });
    return rows;
  }

  private pageRows(rows: FakeRow[], fp: FakePredicates): FakeRow[] {
    let out: FakeRow[] = rows;
    if (fp.offset > 0) {
      out = out.slice(fp.offset);
    }
    if (fp.limit > 0) {
      out = out.slice(0, fp.limit);
    }
    return out;
  }
}

function buildStore(): FakeRdbStore {
  const s: FakeRdbStore = new FakeRdbStore();
  s.setPrimaryKey(USER_TABLE_INFO, ['login']);
  s.setPrimaryKey(USER_TABLE_FOLLOWER, ['login']);
  s.setPrimaryKey(USER_TABLE_FOLLOWED, ['login']);
  s.setPrimaryKey(USER_TABLE_ORG_MEMBER, ['org']);
  s.setPrimaryKey(USER_TABLE_ORGS, ['login']);
  s.setPrimaryKey(USER_TABLE_STARED, ['login']);
  s.setPrimaryKey(USER_TABLE_REPOS, ['login']);
  s.setPrimaryKey(DYN_TABLE_RECEIVED, ['login']);
  s.setPrimaryKey(DYN_TABLE_USER_EVENT, ['login']);
  s.setPrimaryKey(DYN_TABLE_REPO_EVENT, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_PULSE, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_BRANCH, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_COMMITS, ['fullName', 'branch', 'page']);
  s.setPrimaryKey(REPO_TABLE_WATCHER, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_STAR, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_FORK, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_DETAIL, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_DETAIL_README, ['fullName']);
  s.setPrimaryKey(REPO_TABLE_COMMIT_INFO_DETAIL, ['fullName', 'sha']);
  s.setPrimaryKey(ISSUE_TABLE_REPO_ISSUE, ['fullName', 'state', 'page']);
  s.setPrimaryKey(ISSUE_TABLE_DETAIL, ['fullName', 'number']);
  s.setPrimaryKey(ISSUE_TABLE_COMMENT, ['fullName', 'number', 'page']);
  s.setPrimaryKey(READ_HISTORY_TABLE, []);
  s.setPrimaryKey(TREND_TABLE, ['since', 'lang']);
  return s;
}

export default function DaoTest(): void {

  describe('UserDao', () => {
    let store: FakeRdbStore;
    let dao: UserDao;

    beforeEach((): void => {
      store = buildStore();
      dao = new UserDao(store);
    });

    it('user_dao_save_then_read_user_info', 0, async (done: Function): Promise<void> => {
      const json: string = JSON.stringify({ login: 'CarGuo', name: 'gsy' });
      await dao.save(USER_TABLE_INFO, 'CarGuo', json);
      const r = await dao.read(USER_TABLE_INFO, 'CarGuo');
      expect(r.result).assertTrue();
      expect(r.data).assertEqual(json);
      done();
    });

    it('user_dao_read_missing_returns_false', 0, async (done: Function): Promise<void> => {
      const r = await dao.read(USER_TABLE_INFO, 'no-one');
      expect(r.result).assertFalse();
      expect(r.data).assertEqual('');
      done();
    });

    it('user_dao_save_overrides_same_key', 0, async (done: Function): Promise<void> => {
      await dao.saveUserInfo('alice', '{"v":1}');
      await dao.saveUserInfo('alice', '{"v":2}');
      const r = await dao.readUserInfo('alice');
      expect(r.data).assertEqual('{"v":2}');
      done();
    });

    it('user_dao_clear_single_table', 0, async (done: Function): Promise<void> => {
      await dao.saveFollower('a', 'fa');
      await dao.saveFollower('b', 'fb');
      const removed: number = await dao.clear(USER_TABLE_FOLLOWER);
      expect(removed).assertEqual(2);
      const r = await dao.readFollower('a');
      expect(r.result).assertFalse();
      done();
    });

    it('user_dao_clear_all_tables', 0, async (done: Function): Promise<void> => {
      await dao.saveUserInfo('a', '1');
      await dao.saveOrgMember('o', 'm');
      await dao.saveUserOrgs('a', 'os');
      await dao.saveUserStared('a', 'st');
      await dao.saveUserRepos('a', 'rs');
      await dao.saveFollowed('a', 'fd');
      const removed: number = await dao.clear();
      expect(removed).assertEqual(6);
      done();
    });

    it('user_dao_unknown_table_throws', 0, () => {
      let caught: boolean = false;
      try {
        dao.save('NotExist', 'k', 'v');
      } catch (e) {
        caught = true;
      }
      expect(caught).assertTrue();
    });
  });

  describe('DynamicDao', () => {
    let store: FakeRdbStore;
    let dao: DynamicDao;

    beforeEach((): void => {
      store = buildStore();
      dao = new DynamicDao(store);
    });

    it('dyn_dao_received_event_save_read', 0, async (done: Function): Promise<void> => {
      await dao.saveReceivedEvent('me', '[{"id":1}]');
      const r = await dao.readReceivedEvent('me');
      expect(r.result).assertTrue();
      expect(r.data).assertEqual('[{"id":1}]');
      done();
    });

    it('dyn_dao_user_event_save_read', 0, async (done: Function): Promise<void> => {
      await dao.saveUserEvent('alice', 'ue');
      const r = await dao.readUserEvent('alice');
      expect(r.data).assertEqual('ue');
      done();
    });

    it('dyn_dao_repo_event_save_read', 0, async (done: Function): Promise<void> => {
      await dao.saveRepositoryEvent('CarGuo/GSY', 're');
      const r = await dao.readRepositoryEvent('CarGuo/GSY');
      expect(r.data).assertEqual('re');
      done();
    });

    it('dyn_dao_clear_specific_table', 0, async (done: Function): Promise<void> => {
      await dao.saveReceivedEvent('a', '1');
      await dao.saveUserEvent('a', '2');
      await dao.clear(DYN_TABLE_RECEIVED);
      const r1 = await dao.readReceivedEvent('a');
      const r2 = await dao.readUserEvent('a');
      expect(r1.result).assertFalse();
      expect(r2.result).assertTrue();
      done();
    });

    it('dyn_dao_clear_all', 0, async (done: Function): Promise<void> => {
      await dao.saveReceivedEvent('a', '1');
      await dao.saveUserEvent('a', '2');
      await dao.saveRepositoryEvent('x/y', '3');
      const removed: number = await dao.clear();
      expect(removed).assertEqual(3);
      done();
    });
  });

  describe('RepositoryDao', () => {
    let store: FakeRdbStore;
    let dao: RepositoryDao;

    beforeEach((): void => {
      store = buildStore();
      dao = new RepositoryDao(store);
    });

    it('repo_dao_pulse_save_read', 0, async (done: Function): Promise<void> => {
      await dao.savePulse('a/b', 'pulse');
      const r = await dao.readPulse('a/b');
      expect(r.data).assertEqual('pulse');
      done();
    });

    it('repo_dao_branch_save_read', 0, async (done: Function): Promise<void> => {
      await dao.saveBranch('a/b', 'branches');
      const r = await dao.readBranch('a/b');
      expect(r.data).assertEqual('branches');
      done();
    });

    it('repo_dao_commits_composite_key', 0, async (done: Function): Promise<void> => {
      await dao.saveCommits('a/b', 'main', 1, 'p1');
      await dao.saveCommits('a/b', 'main', 2, 'p2');
      const r1 = await dao.readCommits('a/b', 'main', 1);
      const r2 = await dao.readCommits('a/b', 'main', 2);
      const rNone = await dao.readCommits('a/b', 'main', 3);
      expect(r1.data).assertEqual('p1');
      expect(r2.data).assertEqual('p2');
      expect(rNone.result).assertFalse();
      done();
    });

    it('repo_dao_detail_overwrite', 0, async (done: Function): Promise<void> => {
      await dao.saveDetail('a/b', 'v1');
      await dao.saveDetail('a/b', 'v2');
      const r = await dao.readDetail('a/b');
      expect(r.data).assertEqual('v2');
      done();
    });

    it('repo_dao_watcher_star_fork', 0, async (done: Function): Promise<void> => {
      await dao.saveWatcher('a/b', 'w');
      await dao.saveStar('a/b', 's');
      await dao.saveFork('a/b', 'f');
      expect((await dao.readWatcher('a/b')).data).assertEqual('w');
      expect((await dao.readStar('a/b')).data).assertEqual('s');
      expect((await dao.readFork('a/b')).data).assertEqual('f');
      done();
    });

    it('repo_dao_readme_and_commit_info', 0, async (done: Function): Promise<void> => {
      await dao.saveReadme('a/b', 'md');
      await dao.saveCommitInfoDetail('a/b', 'sha123', 'commit-data');
      expect((await dao.readReadme('a/b')).data).assertEqual('md');
      expect((await dao.readCommitInfoDetail('a/b', 'sha123')).data).assertEqual('commit-data');
      done();
    });

    it('repo_dao_clear_one_table', 0, async (done: Function): Promise<void> => {
      await dao.savePulse('a/b', 'p');
      await dao.saveBranch('a/b', 'br');
      const removed: number = await dao.clear(REPO_TABLE_PULSE);
      expect(removed).assertEqual(1);
      expect((await dao.readBranch('a/b')).result).assertTrue();
      done();
    });

    it('repo_dao_clear_all', 0, async (done: Function): Promise<void> => {
      await dao.savePulse('a/b', '1');
      await dao.saveBranch('a/b', '2');
      await dao.saveCommits('a/b', 'm', 1, '3');
      await dao.saveWatcher('a/b', '4');
      await dao.saveStar('a/b', '5');
      await dao.saveFork('a/b', '6');
      await dao.saveDetail('a/b', '7');
      await dao.saveReadme('a/b', '8');
      await dao.saveCommitInfoDetail('a/b', 's', '9');
      const removed: number = await dao.clear();
      expect(removed).assertEqual(9);
      done();
    });
  });

  describe('IssueDao', () => {
    let store: FakeRdbStore;
    let dao: IssueDao;

    beforeEach((): void => {
      store = buildStore();
      dao = new IssueDao(store);
    });

    it('issue_dao_repo_issue_pages', 0, async (done: Function): Promise<void> => {
      await dao.saveRepoIssue('a/b', 'open', 1, 'open-p1');
      await dao.saveRepoIssue('a/b', 'open', 2, 'open-p2');
      await dao.saveRepoIssue('a/b', 'closed', 1, 'closed-p1');
      const r1 = await dao.readRepoIssue('a/b', 'open', 1);
      const r2 = await dao.readRepoIssue('a/b', 'open', 2);
      const r3 = await dao.readRepoIssue('a/b', 'closed', 1);
      expect(r1.data).assertEqual('open-p1');
      expect(r2.data).assertEqual('open-p2');
      expect(r3.data).assertEqual('closed-p1');
      done();
    });

    it('issue_dao_detail_save_read', 0, async (done: Function): Promise<void> => {
      await dao.saveIssueDetail('a/b', 100, 'detail');
      const r = await dao.readIssueDetail('a/b', 100);
      expect(r.data).assertEqual('detail');
      done();
    });

    it('issue_dao_comment_save_read', 0, async (done: Function): Promise<void> => {
      await dao.saveIssueComment('a/b', 7, 1, 'c1');
      await dao.saveIssueComment('a/b', 7, 2, 'c2');
      expect((await dao.readIssueComment('a/b', 7, 1)).data).assertEqual('c1');
      expect((await dao.readIssueComment('a/b', 7, 2)).data).assertEqual('c2');
      done();
    });

    it('issue_dao_clear_table', 0, async (done: Function): Promise<void> => {
      await dao.saveIssueDetail('a/b', 1, 'x');
      await dao.saveIssueDetail('a/b', 2, 'y');
      const n: number = await dao.clear(ISSUE_TABLE_DETAIL);
      expect(n).assertEqual(2);
      done();
    });

    it('issue_dao_clear_all', 0, async (done: Function): Promise<void> => {
      await dao.saveRepoIssue('a/b', 'open', 1, '1');
      await dao.saveIssueDetail('a/b', 1, '2');
      await dao.saveIssueComment('a/b', 1, 1, '3');
      const n: number = await dao.clear();
      expect(n).assertEqual(3);
      done();
    });

    it('issue_dao_unknown_table_throws', 0, () => {
      let caught: boolean = false;
      try {
        dao.save('Bad', 'k', 'v');
      } catch (e) {
        caught = true;
      }
      expect(caught).assertTrue();
    });
  });

  describe('ReadHistoryDao', () => {
    let store: FakeRdbStore;
    let dao: ReadHistoryDao;

    beforeEach((): void => {
      store = buildStore();
      dao = new ReadHistoryDao(store);
    });

    it('read_history_save_then_read', 0, async (done: Function): Promise<void> => {
      await dao.add('repo', 'a/b', 'A B', '{"name":"a/b"}');
      const r = await dao.read('repo|a/b|A B');
      expect(r.result).assertTrue();
      expect(r.data).assertEqual('{"name":"a/b"}');
      done();
    });

    it('read_history_save_replaces_same_full_name', 0,
      async (done: Function): Promise<void> => {
        await dao.add('repo', 'a/b', 't1', 'v1');
        await dao.add('repo', 'a/b', 't2', 'v2');
        const r = await dao.read('repo|a/b|t2');
        expect(r.data).assertEqual('v2');
        const list: ReadHistoryRow[] = await dao.list(1, 10);
        expect(list.length).assertEqual(1);
        done();
      });

    it('read_history_list_paging_desc', 0, async (done: Function): Promise<void> => {
      await dao.add('repo', 'a/1', 't', '1');
      await dao.add('repo', 'a/2', 't', '2');
      await dao.add('repo', 'a/3', 't', '3');
      const list: ReadHistoryRow[] = await dao.list(1, 2);
      expect(list.length).assertEqual(2);
      done();
    });

    it('read_history_clear_all', 0, async (done: Function): Promise<void> => {
      await dao.add('repo', 'a/b', 't', 'x');
      await dao.add('repo', 'c/d', 't', 'y');
      const removed: number = await dao.clear();
      expect(removed).assertEqual(2);
      const list: ReadHistoryRow[] = await dao.list(1, 10);
      expect(list.length).assertEqual(0);
      done();
    });

    it('read_history_read_missing', 0, async (done: Function): Promise<void> => {
      const r = await dao.read('repo|none|t');
      expect(r.result).assertFalse();
      done();
    });
  });

  describe('TrendDao', () => {
    let store: FakeRdbStore;
    let dao: TrendDao;

    beforeEach((): void => {
      store = buildStore();
      dao = new TrendDao(store);
    });

    it('trend_dao_save_read_with_lang', 0, async (done: Function): Promise<void> => {
      await dao.saveTrend('daily', 'TypeScript', '[{}]');
      const r = await dao.readTrend('daily', 'TypeScript');
      expect(r.result).assertTrue();
      expect(r.data).assertEqual('[{}]');
      done();
    });

    it('trend_dao_save_read_empty_lang', 0, async (done: Function): Promise<void> => {
      await dao.saveTrend('weekly', '', '[]');
      const r = await dao.readTrend('weekly', '');
      expect(r.data).assertEqual('[]');
      done();
    });

    it('trend_dao_overwrites_same_combo', 0, async (done: Function): Promise<void> => {
      await dao.saveTrend('monthly', 'Go', 'v1');
      await dao.saveTrend('monthly', 'Go', 'v2');
      const r = await dao.readTrend('monthly', 'Go');
      expect(r.data).assertEqual('v2');
      done();
    });

    it('trend_dao_isolates_by_since_and_lang', 0, async (done: Function): Promise<void> => {
      await dao.saveTrend('daily', 'A', '1');
      await dao.saveTrend('daily', 'B', '2');
      await dao.saveTrend('weekly', 'A', '3');
      expect((await dao.readTrend('daily', 'A')).data).assertEqual('1');
      expect((await dao.readTrend('daily', 'B')).data).assertEqual('2');
      expect((await dao.readTrend('weekly', 'A')).data).assertEqual('3');
      done();
    });

    it('trend_dao_clear', 0, async (done: Function): Promise<void> => {
      await dao.saveTrend('daily', 'A', '1');
      await dao.saveTrend('daily', 'B', '2');
      const removed: number = await dao.clear();
      expect(removed).assertEqual(2);
      const r = await dao.readTrend('daily', 'A');
      expect(r.result).assertFalse();
      done();
    });

    it('trend_dao_read_missing', 0, async (done: Function): Promise<void> => {
      const r = await dao.readTrend('daily', 'Rust');
      expect(r.result).assertFalse();
      expect(r.data).assertEqual('');
      done();
    });
  });
}
