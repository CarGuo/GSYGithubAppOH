import { describe, it, expect, beforeEach } from '@ohos/hypium';
import relationalStore from '@ohos.data.relationalStore';
import { ValueType, ValuesBucket } from '../../../main/ets/dao/db/RdbStore';
import { RdbStoreLike } from '../../../main/ets/dao/DaoBase';
import {
  ReadHistoryService,
  ReadHistoryAddParam,
  ReadHistoryServiceResult,
  encodeReadHistoryData,
  decodeReadHistoryData,
  isValidReadHistoryType,
  ReadHistoryDataPayload,
  READ_HISTORY_PAGE_SIZE
} from '../../../main/ets/service/ReadHistoryService';
import {
  ReadHistoryStore,
  ReadHistoryItem,
  READ_HISTORY_TYPE_REPO,
  READ_HISTORY_TYPE_USER
} from '../../../main/ets/store/ReadHistoryStore';

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
  rows: FakeRow[] = [];
  insertCount: number = 0;
  queryCount: number = 0;
  deleteCount: number = 0;
  private nowCounter: number = 0;

  newPredicates(table: string): relationalStore.RdbPredicates {
    return new FakePredicates(table) as ESObject as relationalStore.RdbPredicates;
  }

  async insertOrReplace(_table: string, values: ValuesBucket): Promise<number> {
    this.insertCount = this.insertCount + 1;
    const row: FakeRow = {};
    const keys: string[] = Object.keys(values);
    for (let i = 0; i < keys.length; i++) {
      row[keys[i]] = values[keys[i]];
    }
    this.nowCounter = this.nowCounter + 1;
    if (row['updateAt'] === undefined || row['updateAt'] === null
      || (typeof row['updateAt'] === 'number' && (row['updateAt'] as number) === 0)) {
      row['updateAt'] = Date.now() + this.nowCounter;
    } else {
      row['updateAt'] = (row['updateAt'] as number) + this.nowCounter;
    }
    if (row['id'] === undefined) {
      row['id'] = this.rows.length + 1;
    }
    this.rows.push(row);
    return this.rows.length;
  }

  async query(predicates: relationalStore.RdbPredicates,
    columns?: string[]): Promise<relationalStore.ResultSet> {
    this.queryCount = this.queryCount + 1;
    const fp: FakePredicates = predicates as ESObject as FakePredicates;
    let filtered: FakeRow[] = this.filterRows(this.rows, fp);
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
    let removed: number = 0;
    for (let i = this.rows.length - 1; i >= 0; i--) {
      if (this.matchConditions(this.rows[i], fp.conditions)) {
        this.rows.splice(i, 1);
        removed = removed + 1;
      }
    }
    return removed;
  }

  async deleteAllInTable(_table: string): Promise<number> {
    const n: number = this.rows.length;
    this.rows.length = 0;
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

function buildAddParam(type: string, key: string, title: string,
  subtitle: string, avatar: string, payload: string): ReadHistoryAddParam {
  return {
    'type': type,
    'key': key,
    'title': title,
    'subtitle': subtitle,
    'avatar': avatar,
    'payloadJson': payload,
    'time': Date.now(),
  } as ReadHistoryAddParam;
}

export default function ReadHistoryServiceTest(): void {

  describe('ReadHistoryServiceTest_helpers', (): void => {
    it('isValidReadHistoryType_accepts_repo_and_user', 0, (): void => {
      expect(isValidReadHistoryType(READ_HISTORY_TYPE_REPO)).assertTrue();
      expect(isValidReadHistoryType(READ_HISTORY_TYPE_USER)).assertTrue();
      expect(isValidReadHistoryType('xxx')).assertFalse();
      expect(isValidReadHistoryType('')).assertFalse();
    });

    it('encode_decode_roundtrip', 0, (): void => {
      const encoded: string = encodeReadHistoryData('sub', 'http://a/b.png', '{"k":1}');
      const decoded: ReadHistoryDataPayload = decodeReadHistoryData(encoded);
      expect(decoded.subtitle).assertEqual('sub');
      expect(decoded.avatar).assertEqual('http://a/b.png');
      expect(decoded.payload).assertEqual('{"k":1}');
    });

    it('decode_invalid_returns_payload_as_raw', 0, (): void => {
      const decoded: ReadHistoryDataPayload = decodeReadHistoryData('not-json');
      expect(decoded.subtitle).assertEqual('');
      expect(decoded.avatar).assertEqual('');
      expect(decoded.payload).assertEqual('not-json');
    });

    it('decode_empty_returns_empty_payload', 0, (): void => {
      const decoded: ReadHistoryDataPayload = decodeReadHistoryData('');
      expect(decoded.subtitle).assertEqual('');
      expect(decoded.avatar).assertEqual('');
      expect(decoded.payload).assertEqual('');
    });

    it('page_size_default_is_30', 0, (): void => {
      expect(READ_HISTORY_PAGE_SIZE).assertEqual(30);
    });
  });

  describe('ReadHistoryServiceTest_add_and_list', (): void => {
    let store: FakeRdbStore;
    let uiStore: ReadHistoryStore;
    let service: ReadHistoryService;

    beforeEach((): void => {
      store = new FakeRdbStore();
      uiStore = new ReadHistoryStore();
      service = new ReadHistoryService(uiStore, store);
    });

    it('add_persists_row_with_encoded_data', 0,
      async (done: Function): Promise<void> => {
        const param: ReadHistoryAddParam = buildAddParam(READ_HISTORY_TYPE_REPO,
          'a/b', 'A B', 'desc', 'avatar', '{"x":1}');
        const r: ReadHistoryServiceResult<number> = await service.add(param);
        expect(r.result).assertTrue();
        expect(store.rows.length).assertEqual(1);
        const dataField: ValueType = store.rows[0]['data'];
        expect(typeof dataField === 'string').assertTrue();
        const decoded: ReadHistoryDataPayload = decodeReadHistoryData(dataField as string);
        expect(decoded.subtitle).assertEqual('desc');
        expect(decoded.avatar).assertEqual('avatar');
        expect(decoded.payload).assertEqual('{"x":1}');
        done();
      });

    it('add_invalid_type_returns_failure', 0,
      async (done: Function): Promise<void> => {
        const param: ReadHistoryAddParam = buildAddParam('bad', 'k', 't', 's', 'a', 'p');
        const r: ReadHistoryServiceResult<number> = await service.add(param);
        expect(r.result).assertFalse();
        expect(store.rows.length).assertEqual(0);
        done();
      });

    it('add_empty_key_returns_failure', 0,
      async (done: Function): Promise<void> => {
        const param: ReadHistoryAddParam = buildAddParam(READ_HISTORY_TYPE_REPO,
          '', 't', 's', 'a', 'p');
        const r: ReadHistoryServiceResult<number> = await service.add(param);
        expect(r.result).assertFalse();
        done();
      });

    it('add_same_key_updates_in_place', 0,
      async (done: Function): Promise<void> => {
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'a/b', 't1', 's1', '', 'p1'));
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'a/b', 't2', 's2', '', 'p2'));
        const list: ReadHistoryServiceResult<ReadHistoryItem[]> = await service.list();
        expect(list.result).assertTrue();
        const items: ReadHistoryItem[] = list.data as ReadHistoryItem[];
        expect(items.length).assertEqual(1);
        expect(items[0].title).assertEqual('t2');
        expect(items[0].subtitle).assertEqual('s2');
        done();
      });

    it('list_orders_by_time_desc', 0,
      async (done: Function): Promise<void> => {
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'a/1', 't1', '', '', ''));
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'a/2', 't2', '', '', ''));
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'a/3', 't3', '', '', ''));
        const r: ReadHistoryServiceResult<ReadHistoryItem[]> = await service.list();
        const items: ReadHistoryItem[] = r.data as ReadHistoryItem[];
        expect(items.length).assertEqual(3);
        expect(items[0].key).assertEqual('a/3');
        expect(items[1].key).assertEqual('a/2');
        expect(items[2].key).assertEqual('a/1');
        done();
      });

    it('list_filter_by_type_repo', 0,
      async (done: Function): Promise<void> => {
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'a/b', 'r', '', '', ''));
        await service.add(buildAddParam(READ_HISTORY_TYPE_USER, 'gsy', 'u', '', '', ''));
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'c/d', 'r2', '', '', ''));
        const r: ReadHistoryServiceResult<ReadHistoryItem[]> =
          await service.list(READ_HISTORY_TYPE_REPO);
        const items: ReadHistoryItem[] = r.data as ReadHistoryItem[];
        expect(items.length).assertEqual(2);
        expect(items[0].type).assertEqual(READ_HISTORY_TYPE_REPO);
        expect(items[1].type).assertEqual(READ_HISTORY_TYPE_REPO);
        done();
      });

    it('list_filter_by_type_user', 0,
      async (done: Function): Promise<void> => {
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'a/b', 'r', '', '', ''));
        await service.add(buildAddParam(READ_HISTORY_TYPE_USER, 'gsy', 'u1', '', '', ''));
        await service.add(buildAddParam(READ_HISTORY_TYPE_USER, 'tom', 'u2', '', '', ''));
        const r: ReadHistoryServiceResult<ReadHistoryItem[]> =
          await service.list(READ_HISTORY_TYPE_USER);
        const items: ReadHistoryItem[] = r.data as ReadHistoryItem[];
        expect(items.length).assertEqual(2);
        for (let i = 0; i < items.length; i++) {
          expect(items[i].type).assertEqual(READ_HISTORY_TYPE_USER);
        }
        done();
      });

    it('list_paging_uses_size', 0,
      async (done: Function): Promise<void> => {
        for (let i = 0; i < 5; i++) {
          await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'a/' + i.toString(),
            't', '', '', ''));
        }
        const r: ReadHistoryServiceResult<ReadHistoryItem[]> = await service.list(undefined, 1, 2);
        const items: ReadHistoryItem[] = r.data as ReadHistoryItem[];
        expect(items.length).assertEqual(2);
        const r2: ReadHistoryServiceResult<ReadHistoryItem[]> = await service.list(undefined, 2, 2);
        const items2: ReadHistoryItem[] = r2.data as ReadHistoryItem[];
        expect(items2.length).assertEqual(2);
        done();
      });

    it('list_syncs_into_ui_store', 0,
      async (done: Function): Promise<void> => {
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'a/b', 't1', 'sub', 'av', 'pp'));
        await service.list();
        expect(uiStore.list.length).assertEqual(1);
        expect(uiStore.list[0].title).assertEqual('t1');
        expect(uiStore.list[0].subtitle).assertEqual('sub');
        expect(uiStore.list[0].avatar).assertEqual('av');
        expect(uiStore.list[0].payloadJson).assertEqual('pp');
        done();
      });
  });

  describe('ReadHistoryServiceTest_clear', (): void => {
    let store: FakeRdbStore;
    let uiStore: ReadHistoryStore;
    let service: ReadHistoryService;

    beforeEach((): void => {
      store = new FakeRdbStore();
      uiStore = new ReadHistoryStore();
      service = new ReadHistoryService(uiStore, store);
    });

    it('clear_all_removes_every_row', 0,
      async (done: Function): Promise<void> => {
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'a/b', '', '', '', ''));
        await service.add(buildAddParam(READ_HISTORY_TYPE_USER, 'tom', '', '', '', ''));
        const r: ReadHistoryServiceResult<number> = await service.clear();
        expect(r.result).assertTrue();
        expect((r.data as number)).assertEqual(2);
        expect(store.rows.length).assertEqual(0);
        expect(uiStore.list.length).assertEqual(0);
        done();
      });

    it('clear_by_type_only_removes_that_type', 0,
      async (done: Function): Promise<void> => {
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'a/b', '', '', '', ''));
        await service.add(buildAddParam(READ_HISTORY_TYPE_USER, 'tom', '', '', '', ''));
        await service.add(buildAddParam(READ_HISTORY_TYPE_REPO, 'c/d', '', '', '', ''));
        const r: ReadHistoryServiceResult<number> = await service.clear(READ_HISTORY_TYPE_REPO);
        expect(r.result).assertTrue();
        expect((r.data as number)).assertEqual(2);
        expect(store.rows.length).assertEqual(1);
        const remaining: ValueType = store.rows[0]['type'];
        expect(remaining as string).assertEqual(READ_HISTORY_TYPE_USER);
        done();
      });
  });
}
