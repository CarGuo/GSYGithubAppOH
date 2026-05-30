import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import hilog from '@ohos.hilog';
import {
  DB_NAME,
  DB_VERSION,
  DB_SECURITY_LEVEL,
  ALL_CREATE_SQL,
  ALL_TABLES
} from './Schema';

const TAG: string = 'RdbStore';

export type ValueType = number | string | boolean | null;
export type ValuesBucket = Record<string, ValueType>;

export class RdbStoreHelper {
  private store: relationalStore.RdbStore | null = null;
  private initializing: Promise<void> | null = null;

  isReady(): boolean {
    return this.store !== null;
  }

  async init(context: common.Context): Promise<void> {
    if (this.store !== null) {
      return;
    }
    if (this.initializing !== null) {
      await this.initializing;
      return;
    }
    this.initializing = this.doInit(context);
    try {
      await this.initializing;
    } finally {
      this.initializing = null;
    }
  }

  private async doInit(context: common.Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: DB_SECURITY_LEVEL as relationalStore.SecurityLevel
    };
    const store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, config);
    store.version = DB_VERSION;
    for (let i = 0; i < ALL_CREATE_SQL.length; i++) {
      const sql: string = ALL_CREATE_SQL[i];
      await store.executeSql(sql);
    }
    this.store = store;
    hilog.info(0x0000, TAG, 'rdb ready, tables=%{public}d', ALL_TABLES.length);
  }

  getStore(): relationalStore.RdbStore {
    if (this.store === null) {
      throw new Error('RdbStore not initialized, call init(context) first');
    }
    return this.store;
  }

  async executeSql(sql: string, args?: ValueType[]): Promise<void> {
    const store: relationalStore.RdbStore = this.getStore();
    if (args && args.length > 0) {
      await store.executeSql(sql, args as relationalStore.ValueType[]);
    } else {
      await store.executeSql(sql);
    }
  }

  async insertOrReplace(table: string, values: ValuesBucket): Promise<number> {
    const store: relationalStore.RdbStore = this.getStore();
    const bucket: relationalStore.ValuesBucket = values as relationalStore.ValuesBucket;
    return await store.insert(table, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async insert(table: string, values: ValuesBucket): Promise<number> {
    const store: relationalStore.RdbStore = this.getStore();
    const bucket: relationalStore.ValuesBucket = values as relationalStore.ValuesBucket;
    return await store.insert(table, bucket);
  }

  async deleteByPredicates(predicates: relationalStore.RdbPredicates): Promise<number> {
    const store: relationalStore.RdbStore = this.getStore();
    return await store.delete(predicates);
  }

  async deleteAllInTable(table: string): Promise<number> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(table);
    return await this.deleteByPredicates(predicates);
  }

  async query(predicates: relationalStore.RdbPredicates,
    columns?: string[]): Promise<relationalStore.ResultSet> {
    const store: relationalStore.RdbStore = this.getStore();
    return await store.query(predicates, columns);
  }

  async querySql(sql: string, args?: ValueType[]): Promise<relationalStore.ResultSet> {
    const store: relationalStore.RdbStore = this.getStore();
    if (args && args.length > 0) {
      return await store.querySql(sql, args as relationalStore.ValueType[]);
    }
    return await store.querySql(sql);
  }

  newPredicates(table: string): relationalStore.RdbPredicates {
    return new relationalStore.RdbPredicates(table);
  }

  async clearAll(): Promise<void> {
    for (let i = 0; i < ALL_TABLES.length; i++) {
      const table: string = ALL_TABLES[i];
      await this.deleteAllInTable(table);
    }
  }

  async close(context: common.Context): Promise<void> {
    if (this.store === null) {
      return;
    }
    this.store = null;
    await relationalStore.deleteRdbStore(context, DB_NAME).catch((): void => {
    });
  }
}

export const RdbStore: RdbStoreHelper = new RdbStoreHelper();
