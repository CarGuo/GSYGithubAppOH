import {
  RdbStoreLike,
  TableSpec,
  ReadResult,
  readByKey,
  saveByKey,
  clearTable,
  defaultStore
} from './DaoBase';
import { TABLE_TREND_REPOSITORY_V2 } from './db/Schema';

export const TREND_TABLE: string = TABLE_TREND_REPOSITORY_V2;

export class TrendDao {
  private store: RdbStoreLike;
  private spec: TableSpec;

  constructor(store?: RdbStoreLike) {
    this.store = store !== undefined ? store : defaultStore();
    this.spec = new TableSpec(TREND_TABLE, ['since', 'lang']);
  }

  save(key: string, jsonString: string): Promise<number> {
    return saveByKey(this.store, this.spec, key, jsonString);
  }

  read(key: string): Promise<ReadResult> {
    return readByKey(this.store, this.spec, key);
  }

  clear(): Promise<number> {
    return clearTable(this.store, TREND_TABLE);
  }

  saveTrend(since: string, lang: string, jsonString: string): Promise<number> {
    const localLang: string = lang.length > 0 ? lang : '';
    const key: string = since + '|' + localLang;
    return this.save(key, jsonString);
  }

  readTrend(since: string, lang: string): Promise<ReadResult> {
    const localLang: string = lang.length > 0 ? lang : '';
    const key: string = since + '|' + localLang;
    return this.read(key);
  }
}
