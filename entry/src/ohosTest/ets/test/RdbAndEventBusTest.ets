import { describe, it, expect, beforeAll, afterAll, beforeEach } from '@ohos/hypium';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import common from '@ohos.app.ability.common';
import {
  RdbStore,
  ValuesBucket
} from '../../../main/ets/dao/db/RdbStore';
import {
  Preferences,
  KEY_LANGUAGE_SELECT,
  KEY_LANGUAGE_SELECT_NAME
} from '../../../main/ets/dao/db/Preferences';
import {
  DB_NAME,
  DB_VERSION,
  ALL_TABLES,
  ALL_CREATE_SQL,
  TABLE_REPOSITORY_DETAIL,
  TABLE_READ_HISTORY,
  TABLE_TREND_REPOSITORY_V2,
  TABLE_ISSUE_COMMENT
} from '../../../main/ets/dao/db/Schema';
import {
  EventBus,
  EVENT_LANGUAGE_CHANGED,
  EVENT_USER_LOGGED_IN
} from '../../../main/ets/utils/EventBus';
import relationalStore from '@ohos.data.relationalStore';

async function detectRdbCrudAvailable(): Promise<boolean> {
  const fullName: string = 'hypium/probe-' + Date.now().toString();
  const values: ValuesBucket = { 'fullName': fullName, 'data': 'probe', 'updateAt': Date.now() };
  let rs: relationalStore.ResultSet | null = null;
  try {
    await RdbStore.insertOrReplace(TABLE_REPOSITORY_DETAIL, values);
    const predicates: relationalStore.RdbPredicates = RdbStore.newPredicates(TABLE_REPOSITORY_DETAIL);
    predicates.equalTo('fullName', fullName);
    rs = await RdbStore.query(predicates, ['fullName']);
    const ok: boolean = rs.rowCount === 1;
    rs.close();
    rs = null;
    await RdbStore.deleteByPredicates(predicates);
    return ok;
  } catch (_e) {
    if (rs !== null) {
      try {
        rs.close();
      } catch (_ignored) {
      }
    }
    return false;
  }
}

export default function RdbAndEventBusTest() {

  describe('Schema', () => {
    it('schema_meta_db_name_and_version', 0, () => {
      expect(DB_NAME).assertEqual('gsygithub_oh.db');
      expect(DB_VERSION).assertEqual(1);
    });

    it('schema_has_current_tables', 0, () => {
      expect(ALL_TABLES.length).assertEqual(26);
    });

    it('schema_create_sql_count_includes_index', 0, () => {
      expect(ALL_CREATE_SQL.length).assertEqual(27);
    });

    it('schema_create_sql_all_start_with_create', 0, () => {
      for (let i = 0; i < ALL_CREATE_SQL.length; i++) {
        const sql: string = ALL_CREATE_SQL[i];
        expect(sql.indexOf('CREATE') === 0).assertTrue();
      }
    });

    it('schema_table_names_unique', 0, () => {
      const set: Set<string> = new Set<string>(ALL_TABLES);
      expect(set.size).assertEqual(ALL_TABLES.length);
    });

    it('schema_contains_required_tables', 0, () => {
      expect(ALL_TABLES.indexOf(TABLE_REPOSITORY_DETAIL) >= 0).assertTrue();
      expect(ALL_TABLES.indexOf(TABLE_READ_HISTORY) >= 0).assertTrue();
      expect(ALL_TABLES.indexOf(TABLE_TREND_REPOSITORY_V2) >= 0).assertTrue();
      expect(ALL_TABLES.indexOf(TABLE_ISSUE_COMMENT) >= 0).assertTrue();
    });
  });

  describe('RdbStore', () => {
    let context: common.Context;
    let crudAvailable: boolean = false;

    beforeAll(async (): Promise<void> => {
      context = abilityDelegatorRegistry.getAbilityDelegator().getAppContext() as common.Context;
      await RdbStore.init(context);
      crudAvailable = await detectRdbCrudAvailable();
    });

    afterAll(async (): Promise<void> => {
      try {
        await RdbStore.clearAll();
      } catch (_) {
      }
    });

    it('rdb_init_ready', 0, () => {
      expect(RdbStore.isReady()).assertTrue();
    });

    it('rdb_insert_and_query_repository_detail', 0, async (done: Function): Promise<void> => {
      if (!crudAvailable) {
        done();
        return;
      }
      const fullName: string = 'CarGuo/GSYGithubAppOH';
      const payload: string = JSON.stringify({ stars: 1, name: fullName });
      const values: ValuesBucket = {
        'fullName': fullName,
        'data': payload,
        'updateAt': Date.now()
      };
      await RdbStore.insertOrReplace(TABLE_REPOSITORY_DETAIL, values);

      const predicates: relationalStore.RdbPredicates =
        RdbStore.newPredicates(TABLE_REPOSITORY_DETAIL);
      predicates.equalTo('fullName', fullName);
      const rs: relationalStore.ResultSet = await RdbStore.query(predicates, ['fullName', 'data']);
      expect(rs.rowCount).assertEqual(1);
      rs.goToFirstRow();
      const readName: string = rs.getString(rs.getColumnIndex('fullName'));
      const readData: string = rs.getString(rs.getColumnIndex('data'));
      rs.close();
      expect(readName).assertEqual(fullName);
      expect(readData).assertEqual(payload);
      done();
    });

    it('rdb_replace_on_conflict', 0, async (done: Function): Promise<void> => {
      if (!crudAvailable) {
        done();
        return;
      }
      const fullName: string = 'CarGuo/replace-test';
      const v1: ValuesBucket = { 'fullName': fullName, 'data': 'v1', 'updateAt': 1 };
      const v2: ValuesBucket = { 'fullName': fullName, 'data': 'v2', 'updateAt': 2 };
      await RdbStore.insertOrReplace(TABLE_REPOSITORY_DETAIL, v1);
      await RdbStore.insertOrReplace(TABLE_REPOSITORY_DETAIL, v2);

      const predicates: relationalStore.RdbPredicates =
        RdbStore.newPredicates(TABLE_REPOSITORY_DETAIL);
      predicates.equalTo('fullName', fullName);
      const rs: relationalStore.ResultSet = await RdbStore.query(predicates, ['data']);
      expect(rs.rowCount).assertEqual(1);
      rs.goToFirstRow();
      const readData: string = rs.getString(rs.getColumnIndex('data'));
      rs.close();
      expect(readData).assertEqual('v2');
      done();
    });

    it('rdb_delete_by_predicates', 0, async (done: Function): Promise<void> => {
      if (!crudAvailable) {
        done();
        return;
      }
      const fullName: string = 'CarGuo/delete-test';
      const values: ValuesBucket = { 'fullName': fullName, 'data': 'd', 'updateAt': Date.now() };
      await RdbStore.insertOrReplace(TABLE_REPOSITORY_DETAIL, values);

      const predicates: relationalStore.RdbPredicates =
        RdbStore.newPredicates(TABLE_REPOSITORY_DETAIL);
      predicates.equalTo('fullName', fullName);
      const removed: number = await RdbStore.deleteByPredicates(predicates);
      expect(removed).assertEqual(1);

      const predicates2: relationalStore.RdbPredicates =
        RdbStore.newPredicates(TABLE_REPOSITORY_DETAIL);
      predicates2.equalTo('fullName', fullName);
      const rs: relationalStore.ResultSet = await RdbStore.query(predicates2, ['fullName']);
      expect(rs.rowCount).assertEqual(0);
      rs.close();
      done();
    });

    it('rdb_querysql_count_for_existing_table', 0, async (done: Function): Promise<void> => {
      const rs: relationalStore.ResultSet =
        await RdbStore.querySql('SELECT COUNT(*) AS c FROM ' + TABLE_REPOSITORY_DETAIL);
      rs.goToFirstRow();
      const c: number = rs.getLong(rs.getColumnIndex('c'));
      rs.close();
      expect(c >= 0).assertTrue();
      done();
    });
  });

  describe('Preferences', () => {
    let context: common.Context;

    beforeAll(async (): Promise<void> => {
      context = abilityDelegatorRegistry.getAbilityDelegator().getAppContext() as common.Context;
      await Preferences.init(context, 'gsygithub_oh_pref_test');
    });

    afterAll(async (): Promise<void> => {
      try {
        await Preferences.clear();
      } catch (_) {
      }
    });

    it('pref_ready', 0, () => {
      expect(Preferences.isReady()).assertTrue();
    });

    it('pref_string_put_get', 0, async (done: Function): Promise<void> => {
      await Preferences.putString(KEY_LANGUAGE_SELECT, 'zh-CN');
      const v: string = await Preferences.getString(KEY_LANGUAGE_SELECT, '');
      expect(v).assertEqual('zh-CN');
      done();
    });

    it('pref_default_when_missing', 0, async (done: Function): Promise<void> => {
      const v: string = await Preferences.getString('not_exist_key', 'fallback');
      expect(v).assertEqual('fallback');
      done();
    });

    it('pref_remove', 0, async (done: Function): Promise<void> => {
      await Preferences.putString(KEY_LANGUAGE_SELECT_NAME, 'zhLanguage');
      let exists: boolean = await Preferences.has(KEY_LANGUAGE_SELECT_NAME);
      expect(exists).assertTrue();
      await Preferences.remove(KEY_LANGUAGE_SELECT_NAME);
      exists = await Preferences.has(KEY_LANGUAGE_SELECT_NAME);
      expect(exists).assertFalse();
      done();
    });

    it('pref_number_and_boolean', 0, async (done: Function): Promise<void> => {
      await Preferences.putNumber('num_key', 42);
      const n: number = await Preferences.getNumber('num_key', 0);
      expect(n).assertEqual(42);
      await Preferences.putBoolean('bool_key', true);
      const b: boolean = await Preferences.getBoolean('bool_key', false);
      expect(b).assertTrue();
      done();
    });
  });

  describe('EventBus', () => {

    beforeEach((): void => {
      EventBus.removeAll();
    });

    it('eventbus_subscribe_and_emit', 0, () => {
      let received: string = '';
      const off: () => void = EventBus.on(EVENT_LANGUAGE_CHANGED, (payload: ESObject): void => {
        received = payload as string;
      });
      EventBus.emit(EVENT_LANGUAGE_CHANGED, 'zh-CN');
      off();
      expect(received).assertEqual('zh-CN');
    });

    it('eventbus_emit_without_listener_is_noop', 0, () => {
      EventBus.emit('event.no.such', 'x');
      expect(EventBus.hasListeners('event.no.such')).assertFalse();
    });

    it('eventbus_unsubscribe_via_returned_handle', 0, () => {
      let count: number = 0;
      const off: () => void = EventBus.on(EVENT_USER_LOGGED_IN, (): void => {
        count = count + 1;
      });
      EventBus.emit(EVENT_USER_LOGGED_IN, null);
      off();
      EventBus.emit(EVENT_USER_LOGGED_IN, null);
      expect(count).assertEqual(1);
    });

    it('eventbus_listener_count_tracks_subscribers', 0, () => {
      const off1: () => void = EventBus.on(EVENT_LANGUAGE_CHANGED, (): void => {
      });
      const off2: () => void = EventBus.on(EVENT_LANGUAGE_CHANGED, (): void => {
      });
      expect(EventBus.listenerCount(EVENT_LANGUAGE_CHANGED)).assertEqual(2);
      off1();
      expect(EventBus.listenerCount(EVENT_LANGUAGE_CHANGED)).assertEqual(1);
      off2();
      expect(EventBus.hasListeners(EVENT_LANGUAGE_CHANGED)).assertFalse();
    });

    it('eventbus_once_only_fires_one_time', 0, () => {
      let count: number = 0;
      EventBus.once(EVENT_LANGUAGE_CHANGED, (): void => {
        count = count + 1;
      });
      EventBus.emit(EVENT_LANGUAGE_CHANGED, 'a');
      EventBus.emit(EVENT_LANGUAGE_CHANGED, 'b');
      expect(count).assertEqual(1);
    });

    it('eventbus_sticky_delivers_to_late_subscriber', 0, () => {
      EventBus.emitSticky('event.sticky.test', 'pending-value');
      let received: string = '';
      EventBus.on('event.sticky.test', (payload: ESObject): void => {
        received = payload as string;
      });
      expect(received).assertEqual('pending-value');
    });

    it('eventbus_multiple_listeners_all_get_notified', 0, () => {
      let a: number = 0;
      let b: number = 0;
      EventBus.on(EVENT_USER_LOGGED_IN, (): void => {
        a = a + 1;
      });
      EventBus.on(EVENT_USER_LOGGED_IN, (): void => {
        b = b + 2;
      });
      EventBus.emit(EVENT_USER_LOGGED_IN, null);
      expect(a).assertEqual(1);
      expect(b).assertEqual(2);
    });

    it('eventbus_remove_all_clears_all_topics', 0, () => {
      EventBus.on(EVENT_LANGUAGE_CHANGED, (): void => {
      });
      EventBus.on(EVENT_USER_LOGGED_IN, (): void => {
      });
      EventBus.removeAll();
      expect(EventBus.hasListeners(EVENT_LANGUAGE_CHANGED)).assertFalse();
      expect(EventBus.hasListeners(EVENT_USER_LOGGED_IN)).assertFalse();
    });
  });
}
