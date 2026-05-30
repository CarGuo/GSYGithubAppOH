import relationalStore from '@ohos.data.relationalStore';
import { ReadHistoryDao, ReadHistoryRow, READ_HISTORY_TABLE } from '../dao/ReadHistoryDao';
import { RdbStoreLike, defaultStore } from '../dao/DaoBase';
import {
  ReadHistoryItem,
  ReadHistoryStore,
  READ_HISTORY_TYPE_REPO,
  READ_HISTORY_TYPE_USER
} from '../store/ReadHistoryStore';

export const READ_HISTORY_PAGE_SIZE: number = 30;

export interface ReadHistoryAddParam {
  type: string;
  key: string;
  title: string;
  subtitle: string;
  avatar: string;
  payloadJson: string;
  time: number;
}

export interface ReadHistoryDataPayload {
  subtitle: string;
  avatar: string;
  payload: string;
}

export class ReadHistoryServiceResult<T> {
  result: boolean;
  data: T | null;
  msg: string;

  constructor(result: boolean, data: T | null, msg: string) {
    this.result = result;
    this.data = data;
    this.msg = msg;
  }
}

export function isValidReadHistoryType(type: string): boolean {
  return type === READ_HISTORY_TYPE_REPO || type === READ_HISTORY_TYPE_USER;
}

export function encodeReadHistoryData(subtitle: string, avatar: string,
  payloadJson: string): string {
  const safeSubtitle: string = subtitle !== null && subtitle !== undefined ? subtitle : '';
  const safeAvatar: string = avatar !== null && avatar !== undefined ? avatar : '';
  const safePayload: string = payloadJson !== null && payloadJson !== undefined ? payloadJson : '';
  const obj: ReadHistoryDataPayload = {
    'subtitle': safeSubtitle,
    'avatar': safeAvatar,
    'payload': safePayload,
  } as ReadHistoryDataPayload;
  return JSON.stringify(obj);
}

export function decodeReadHistoryData(data: string): ReadHistoryDataPayload {
  if (data === null || data === undefined || data.length === 0) {
    return { 'subtitle': '', 'avatar': '', 'payload': '' } as ReadHistoryDataPayload;
  }
  try {
    const parsed: ReadHistoryDataPayload = JSON.parse(data) as ReadHistoryDataPayload;
    const subtitle: string = parsed.subtitle !== null && parsed.subtitle !== undefined
      ? parsed.subtitle : '';
    const avatar: string = parsed.avatar !== null && parsed.avatar !== undefined
      ? parsed.avatar : '';
    const payload: string = parsed.payload !== null && parsed.payload !== undefined
      ? parsed.payload : '';
    return { 'subtitle': subtitle, 'avatar': avatar, 'payload': payload } as ReadHistoryDataPayload;
  } catch (_e) {
    return { 'subtitle': '', 'avatar': '', 'payload': data } as ReadHistoryDataPayload;
  }
}

function rowToItem(row: ReadHistoryRow): ReadHistoryItem {
  const decoded: ReadHistoryDataPayload = decodeReadHistoryData(row.data);
  const item: ReadHistoryItem = {
    'type': row.type,
    'key': row.fullName,
    'title': row.title !== null && row.title !== undefined ? row.title : '',
    'subtitle': decoded.subtitle,
    'avatar': decoded.avatar,
    'payloadJson': decoded.payload,
    'time': row.updateAt,
  } as ReadHistoryItem;
  return item;
}

export class ReadHistoryService {
  private dao: ReadHistoryDao;
  private store: ReadHistoryStore | null;
  private rdb: RdbStoreLike;

  constructor(uiStore?: ReadHistoryStore, rdbStore?: RdbStoreLike) {
    this.rdb = rdbStore !== undefined ? rdbStore : defaultStore();
    this.dao = new ReadHistoryDao(this.rdb);
    this.store = uiStore !== undefined ? uiStore : null;
  }

  getDao(): ReadHistoryDao {
    return this.dao;
  }

  bindStore(store: ReadHistoryStore): void {
    this.store = store;
  }

  async add(param: ReadHistoryAddParam): Promise<ReadHistoryServiceResult<number>> {
    if (param === null || param === undefined) {
      return new ReadHistoryServiceResult<number>(false, null, 'invalid param');
    }
    if (!isValidReadHistoryType(param.type)) {
      return new ReadHistoryServiceResult<number>(false, null, 'invalid type');
    }
    const safeKey: string = param.key !== null && param.key !== undefined ? param.key : '';
    if (safeKey.length === 0) {
      return new ReadHistoryServiceResult<number>(false, null, 'invalid key');
    }
    const safeTitle: string = param.title !== null && param.title !== undefined ? param.title : '';
    const data: string = encodeReadHistoryData(param.subtitle, param.avatar, param.payloadJson);
    try {
      const id: number = await this.dao.add(param.type, safeKey, safeTitle, data);
      return new ReadHistoryServiceResult<number>(true, id, '');
    } catch (e) {
      const err: Error = e as Error;
      return new ReadHistoryServiceResult<number>(false, null, err.message);
    }
  }

  async list(type?: string, page: number = 1,
    size: number = READ_HISTORY_PAGE_SIZE): Promise<ReadHistoryServiceResult<ReadHistoryItem[]>> {
    const safeType: string = type !== undefined && type !== null ? type : '';
    const safePage: number = page > 0 ? page : 1;
    const safeSize: number = size > 0 ? size : READ_HISTORY_PAGE_SIZE;
    try {
      let items: ReadHistoryItem[];
      if (safeType.length === 0) {
        const rows: ReadHistoryRow[] = await this.dao.list(safePage, safeSize);
        items = this.mapRows(rows);
      } else {
        const rows: ReadHistoryRow[] = await this.queryByType(safeType, safePage, safeSize);
        items = this.mapRows(rows);
      }
      if (this.store !== null) {
        const ui: ReadHistoryStore = this.store as ReadHistoryStore;
        if (safePage <= 1) {
          ui.applyRefresh(items, safeSize);
        } else {
          ui.applyAppend(items, safePage, safeSize);
        }
      }
      return new ReadHistoryServiceResult<ReadHistoryItem[]>(true, items, '');
    } catch (e) {
      const err: Error = e as Error;
      if (this.store !== null) {
        (this.store as ReadHistoryStore).setError(err.message);
      }
      return new ReadHistoryServiceResult<ReadHistoryItem[]>(false, null, err.message);
    }
  }

  async clear(type?: string): Promise<ReadHistoryServiceResult<number>> {
    const safeType: string = type !== undefined && type !== null ? type : '';
    try {
      let removed: number;
      if (safeType.length === 0) {
        removed = await this.dao.clear();
      } else {
        removed = await this.deleteByType(safeType);
      }
      if (this.store !== null) {
        (this.store as ReadHistoryStore).clearList();
      }
      return new ReadHistoryServiceResult<number>(true, removed, '');
    } catch (e) {
      const err: Error = e as Error;
      return new ReadHistoryServiceResult<number>(false, null, err.message);
    }
  }

  private mapRows(rows: ReadHistoryRow[]): ReadHistoryItem[] {
    const out: ReadHistoryItem[] = [];
    for (let i = 0; i < rows.length; i++) {
      out.push(rowToItem(rows[i]));
    }
    return out;
  }

  private async queryByType(type: string, page: number,
    pageSize: number): Promise<ReadHistoryRow[]> {
    const offset: number = (page - 1) * pageSize;
    const predicates: relationalStore.RdbPredicates = this.rdb.newPredicates(READ_HISTORY_TABLE);
    predicates.equalTo('type', type);
    predicates.orderByDesc('updateAt');
    predicates.limitAs(pageSize);
    predicates.offsetAs(offset);
    const rs: relationalStore.ResultSet = await this.rdb.query(predicates,
      ['id', 'type', 'fullName', 'title', 'data', 'updateAt']);
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

  private async deleteByType(type: string): Promise<number> {
    const predicates: relationalStore.RdbPredicates = this.rdb.newPredicates(READ_HISTORY_TABLE);
    predicates.equalTo('type', type);
    return await this.rdb.deleteByPredicates(predicates);
  }
}
