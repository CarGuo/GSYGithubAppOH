import { Preferences } from '../dao/db/Preferences';

export const KEY_SEARCH_HISTORY: string = 'search.history';
export const SEARCH_HISTORY_MAX: number = 20;

export interface SearchHistoryStorage {
  putString(key: string, value: string): Promise<void>;
  getString(key: string, defValue: string): Promise<string>;
  remove(key: string): Promise<void>;
}

class DefaultSearchHistoryStorage implements SearchHistoryStorage {
  async putString(key: string, value: string): Promise<void> {
    await Preferences.putString(key, value);
  }

  async getString(key: string, defValue: string): Promise<string> {
    return await Preferences.getString(key, defValue);
  }

  async remove(key: string): Promise<void> {
    await Preferences.remove(key);
  }
}

export class SearchHistoryManager {
  private storage: SearchHistoryStorage;
  private key: string;
  private max: number;

  constructor(storage?: SearchHistoryStorage, key?: string, max?: number) {
    this.storage = storage !== undefined ? storage : new DefaultSearchHistoryStorage();
    this.key = key !== undefined && key.length > 0 ? key : KEY_SEARCH_HISTORY;
    this.max = max !== undefined && max > 0 ? max : SEARCH_HISTORY_MAX;
  }

  setStorage(storage: SearchHistoryStorage): void {
    this.storage = storage;
  }

  getKey(): string {
    return this.key;
  }

  getMax(): number {
    return this.max;
  }

  async list(): Promise<string[]> {
    const raw: string = await this.storage.getString(this.key, '');
    return SearchHistoryManager.parseList(raw);
  }

  async add(q: string): Promise<string[]> {
    const trimmed: string = q !== null && q !== undefined ? q.trim() : '';
    if (trimmed.length === 0) {
      return await this.list();
    }
    const existing: string[] = await this.list();
    const next: string[] = [trimmed];
    for (let i = 0; i < existing.length; i++) {
      const item: string = existing[i];
      if (item !== trimmed && next.length < this.max) {
        next.push(item);
      }
    }
    await this.storage.putString(this.key, JSON.stringify(next));
    return next;
  }

  async clear(): Promise<void> {
    await this.storage.remove(this.key);
  }

  private static parseList(raw: string): string[] {
    if (raw === null || raw === undefined || raw.length === 0) {
      return [];
    }
    let parsed: Object | null = null;
    try {
      parsed = JSON.parse(raw) as Object;
    } catch (_e) {
      return [];
    }
    if (parsed === null || parsed === undefined) {
      return [];
    }
    if (!Array.isArray(parsed)) {
      return [];
    }
    const arr: Object[] = parsed as Object[];
    const out: string[] = [];
    for (let i = 0; i < arr.length; i++) {
      const v: Object = arr[i];
      if (typeof v === 'string') {
        const s: string = v as string;
        if (s.length > 0) {
          out.push(s);
        }
      }
    }
    return out;
  }
}

export const SearchHistory: SearchHistoryManager = new SearchHistoryManager();
