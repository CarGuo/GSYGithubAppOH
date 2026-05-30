import {
  RdbStoreLike,
  TableSpec,
  ReadResult,
  readByKey,
  saveByKey,
  clearTable,
  defaultStore
} from './DaoBase';
import {
  TABLE_RECEIVED_EVENT,
  TABLE_USER_EVENT,
  TABLE_REPOSITORY_EVENT
} from './db/Schema';

export const DYN_TABLE_RECEIVED: string = TABLE_RECEIVED_EVENT;
export const DYN_TABLE_USER_EVENT: string = TABLE_USER_EVENT;
export const DYN_TABLE_REPO_EVENT: string = TABLE_REPOSITORY_EVENT;

export class DynamicDao {
  private store: RdbStoreLike;
  private specs: Map<string, TableSpec>;

  constructor(store?: RdbStoreLike) {
    this.store = store !== undefined ? store : defaultStore();
    this.specs = new Map<string, TableSpec>();
    this.specs.set(DYN_TABLE_RECEIVED, new TableSpec(DYN_TABLE_RECEIVED, ['login']));
    this.specs.set(DYN_TABLE_USER_EVENT, new TableSpec(DYN_TABLE_USER_EVENT, ['login']));
    this.specs.set(DYN_TABLE_REPO_EVENT, new TableSpec(DYN_TABLE_REPO_EVENT, ['fullName']));
  }

  private specOf(table: string): TableSpec {
    const spec: TableSpec | undefined = this.specs.get(table);
    if (spec === undefined) {
      throw new Error('DynamicDao unknown table: ' + table);
    }
    return spec;
  }

  save(table: string, key: string, jsonString: string): Promise<number> {
    return saveByKey(this.store, this.specOf(table), key, jsonString);
  }

  read(table: string, key: string): Promise<ReadResult> {
    return readByKey(this.store, this.specOf(table), key);
  }

  clear(table?: string): Promise<number> {
    if (table !== undefined) {
      return clearTable(this.store, this.specOf(table).table);
    }
    return this.clearAll();
  }

  private async clearAll(): Promise<number> {
    let total: number = 0;
    const tables: string[] = [
      DYN_TABLE_RECEIVED,
      DYN_TABLE_USER_EVENT,
      DYN_TABLE_REPO_EVENT
    ];
    for (let i = 0; i < tables.length; i++) {
      total = total + await clearTable(this.store, tables[i]);
    }
    return total;
  }

  saveReceivedEvent(login: string, jsonString: string): Promise<number> {
    return this.save(DYN_TABLE_RECEIVED, login, jsonString);
  }

  readReceivedEvent(login: string): Promise<ReadResult> {
    return this.read(DYN_TABLE_RECEIVED, login);
  }

  saveUserEvent(login: string, jsonString: string): Promise<number> {
    return this.save(DYN_TABLE_USER_EVENT, login, jsonString);
  }

  readUserEvent(login: string): Promise<ReadResult> {
    return this.read(DYN_TABLE_USER_EVENT, login);
  }

  saveRepositoryEvent(fullName: string, jsonString: string): Promise<number> {
    return this.save(DYN_TABLE_REPO_EVENT, fullName, jsonString);
  }

  readRepositoryEvent(fullName: string): Promise<ReadResult> {
    return this.read(DYN_TABLE_REPO_EVENT, fullName);
  }
}
