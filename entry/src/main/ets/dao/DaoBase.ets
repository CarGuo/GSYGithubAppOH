import relationalStore from '@ohos.data.relationalStore';
import { ValueType, ValuesBucket, RdbStore as DefaultRdbStore } from './db/RdbStore';

export interface RdbStoreLike {
  insertOrReplace(table: string, values: ValuesBucket): Promise<number>;
  query(predicates: relationalStore.RdbPredicates,
    columns?: string[]): Promise<relationalStore.ResultSet>;
  newPredicates(table: string): relationalStore.RdbPredicates;
  deleteByPredicates(predicates: relationalStore.RdbPredicates): Promise<number>;
  deleteAllInTable(table: string): Promise<number>;
  executeSql?(sql: string, args?: ValueType[]): Promise<void>;
  querySql?(sql: string, args?: ValueType[]): Promise<relationalStore.ResultSet>;
}

export const KEY_SEP: string = '|';

export interface ReadResult {
  result: boolean;
  data: string;
  updateAt: number;
}

export const EMPTY_READ: ReadResult = { result: false, data: '', updateAt: 0 } as ReadResult;

export class TableSpec {
  table: string;
  keyColumns: string[];

  constructor(table: string, keyColumns: string[]) {
    this.table = table;
    this.keyColumns = keyColumns;
  }
}

export function splitCompositeKey(key: string, parts: number): string[] {
  const segs: string[] = key.split(KEY_SEP);
  const out: string[] = [];
  for (let i = 0; i < parts; i++) {
    out.push(i < segs.length ? segs[i] : '');
  }
  return out;
}

export function buildPredicatesByKey(store: RdbStoreLike, spec: TableSpec,
  key: string): relationalStore.RdbPredicates {
  const predicates: relationalStore.RdbPredicates = store.newPredicates(spec.table);
  const segs: string[] = splitCompositeKey(key, spec.keyColumns.length);
  for (let i = 0; i < spec.keyColumns.length; i++) {
    const col: string = spec.keyColumns[i];
    const val: string = segs[i];
    predicates.equalTo(col, val);
  }
  return predicates;
}

export function buildBucketByKey(spec: TableSpec, key: string,
  jsonString: string, updateAt: number): ValuesBucket {
  const bucket: ValuesBucket = {};
  const segs: string[] = splitCompositeKey(key, spec.keyColumns.length);
  for (let i = 0; i < spec.keyColumns.length; i++) {
    const col: string = spec.keyColumns[i];
    bucket[col] = segs[i];
  }
  const dataKey: string = 'data';
  const updateAtKey: string = 'updateAt';
  bucket[dataKey] = jsonString;
  bucket[updateAtKey] = updateAt;
  return bucket;
}

export async function readByKey(store: RdbStoreLike, spec: TableSpec,
  key: string): Promise<ReadResult> {
  const predicates: relationalStore.RdbPredicates = buildPredicatesByKey(store, spec, key);
  const rs: relationalStore.ResultSet = await store.query(predicates, ['data', 'updateAt']);
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

export async function saveByKey(store: RdbStoreLike, spec: TableSpec,
  key: string, jsonString: string): Promise<number> {
  const bucket: ValuesBucket = buildBucketByKey(spec, key, jsonString, Date.now());
  return await store.insertOrReplace(spec.table, bucket);
}

export async function clearTable(store: RdbStoreLike, table: string): Promise<number> {
  return await store.deleteAllInTable(table);
}

export function defaultStore(): RdbStoreLike {
  return DefaultRdbStore as RdbStoreLike;
}
