import relationalStore from '@ohos.data.relationalStore';
import {
  RdbStoreLike,
  ReadResult,
  defaultStore,
  splitCompositeKey
} from './DaoBase';
import { ValuesBucket } from './db/RdbStore';
import { TABLE_READ_HISTORY } from './db/Schema';

export const READ_HISTORY_TABLE: string = TABLE_READ_HISTORY;

export interface ReadHistoryRow {
  id: number;
  type: string;
  fullName: string;
  title: string;
  data: string;
  updateAt: number;
}

export class ReadHistoryDao {
  private store: RdbStoreLike;

  constructor(store?: RdbStoreLike) {
    this.store = store !== undefined ? store : defaultStore();
  }

  async save(key: string, jsonString: string): Promise<number> {
    const segs: string[] = splitCompositeKey(key, 3);
    const type: string = segs[0];
    const fullName: string = segs[1];
    const title: string = segs[2];
    const predicates: relationalStore.RdbPredicates = this.store.newPredicates(READ_HISTORY_TABLE);
    predicates.equalTo('type', type);
    predicates.and();
    predicates.equalTo('fullName', fullName);
    await this.store.deleteByPredicates(predicates);
    const bucket: ValuesBucket = {
      'type': type,
      'fullName': fullName,
      'title': title,
      'data': jsonString,
      'updateAt': Date.now()
    };
    return await this.store.insertOrReplace(READ_HISTORY_TABLE, bucket);
  }

  async read(key: string): Promise<ReadResult> {
    const segs: string[] = splitCompositeKey(key, 3);
    const type: string = segs[0];
    const fullName: string = segs[1];
    const predicates: relationalStore.RdbPredicates = this.store.newPredicates(READ_HISTORY_TABLE);
    predicates.equalTo('type', type);
    predicates.and();
    predicates.equalTo('fullName', fullName);
    predicates.orderByDesc('updateAt');
    predicates.limitAs(1);
    const rs: relationalStore.ResultSet =
      await this.store.query(predicates, ['data', 'updateAt']);
    if (rs.rowCount <= 0) {
      rs.close();
      return { result: false, data: '', updateAt: 0 } as ReadResult;
    }
    rs.goToFirstRow();
    const data: string = rs.getString(rs.getColumnIndex('data'));
    const updateAt: number = rs.getLong(rs.getColumnIndex('updateAt'));
    rs.close();
    return { result: true, data: data, updateAt: updateAt } as ReadResult;
  }

  clear(): Promise<number> {
    return this.store.deleteAllInTable(READ_HISTORY_TABLE);
  }

  add(type: string, fullName: string, title: string, jsonString: string): Promise<number> {
    const key: string = type + '|' + fullName + '|' + title;
    return this.save(key, jsonString);
  }

  async list(page: number, pageSize: number): Promise<ReadHistoryRow[]> {
    const offset: number = (page - 1) * pageSize;
    const predicates: relationalStore.RdbPredicates = this.store.newPredicates(READ_HISTORY_TABLE);
    predicates.orderByDesc('updateAt');
    predicates.limitAs(pageSize);
    predicates.offsetAs(offset);
    const rs: relationalStore.ResultSet =
      await this.store.query(predicates, ['id', 'type', 'fullName', 'title', 'data', 'updateAt']);
    const out: ReadHistoryRow[] = [];
    while (rs.goToNextRow()) {
      const row: ReadHistoryRow = {
        id: rs.getLong(rs.getColumnIndex('id')),
        type: rs.getString(rs.getColumnIndex('type')),
        fullName: rs.getString(rs.getColumnIndex('fullName')),
        title: rs.getString(rs.getColumnIndex('title')),
        data: rs.getString(rs.getColumnIndex('data')),
        updateAt: rs.getLong(rs.getColumnIndex('updateAt'))
      } as ReadHistoryRow;
      out.push(row);
    }
    rs.close();
    return out;
  }
}
