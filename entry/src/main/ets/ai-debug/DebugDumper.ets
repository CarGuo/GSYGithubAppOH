import fs from '@ohos.file.fs';
import deviceInfo from '@ohos.deviceInfo';
import i18n from '@ohos.i18n';
import common from '@ohos.app.ability.common';
import bundleManager from '@ohos.bundle.bundleManager';
import { Logger, LogEntry } from './Logger';
import { HttpRecorder, HttpRecord } from './HttpRecorder';
import { NavigationService, NavRouteSnapshot } from '../navigation/NavigationService';

export interface StoreLike {
  toJSON(): Object;
}

export interface DumpMeta {
  bundleVersion: string;
  runtimeOS: string;
  deviceModel: string;
  language: string;
  authed: boolean;
}

export interface DumpPayload {
  ts: number;
  meta: DumpMeta;
  routes: NavRouteSnapshot[];
  stores: Record<string, Object>;
  httpRecent: HttpRecord[];
  consoleRecent: LogEntry[];
}

export interface DumpResult {
  filePath: string;
  payload: DumpPayload;
}

class StoreDumpError {
  error: string;

  constructor(error: string) {
    this.error = error;
  }
}

const DUMP_DIR_NAME: string = 'ai-debug';
const HTTP_DUMP_LIMIT: number = 30;
const LOG_DUMP_LIMIT: number = 200;
const TAG: string = 'DebugDumper';

class DebugDumperImpl {
  private stores: Map<string, StoreLike> = new Map<string, StoreLike>();
  private authedProvider: () => boolean = (): boolean => false;

  registerStore(name: string, store: StoreLike): void {
    this.stores.set(name, store);
  }

  unregisterStore(name: string): void {
    this.stores.delete(name);
  }

  setAuthedProvider(fn: () => boolean): void {
    this.authedProvider = fn;
  }

  buildPayload(): DumpPayload {
    const now: number = Date.now();
    const stores: Record<string, Object> = {};
    this.stores.forEach((store: StoreLike, name: string): void => {
      try {
        stores[name] = store.toJSON();
      } catch (e) {
        const err: Error = e as Error;
        stores[name] = new StoreDumpError(err.message);
      }
    });
    const payload: DumpPayload = {
      ts: now,
      meta: this.buildMeta(),
      routes: NavigationService.snapshot(),
      stores: stores,
      httpRecent: HttpRecorder.snapshot(HTTP_DUMP_LIMIT),
      consoleRecent: Logger.snapshot(LOG_DUMP_LIMIT),
    };
    return payload;
  }

  async dump(context: common.Context): Promise<DumpResult> {
    const payload: DumpPayload = this.buildPayload();
    const baseDir: string = context.filesDir + '/' + DUMP_DIR_NAME;
    this.ensureDir(baseDir);
    const fileName: string = this.formatTs(payload.ts) + '.json';
    const filePath: string = baseDir + '/' + fileName;
    const json: string = JSON.stringify(payload);
    const file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, json);
    } finally {
      fs.closeSync(file);
    }
    Logger.i(TAG, 'dump written ' + filePath);
    return { filePath: filePath, payload: payload };
  }

  private ensureDir(dir: string): void {
    try {
      const exist: boolean = fs.accessSync(dir);
      if (!exist) {
        fs.mkdirSync(dir, true);
      }
    } catch (e) {
      const err: Error = e as Error;
      Logger.w(TAG, 'ensureDir fail ' + err.message);
    }
  }

  private buildMeta(): DumpMeta {
    let runtimeOS: string = '';
    let deviceModel: string = '';
    try {
      runtimeOS = deviceInfo.osFullName;
      deviceModel = deviceInfo.productModel;
    } catch (e) {
      runtimeOS = '';
      deviceModel = '';
    }
    let language: string = '';
    try {
      language = i18n.System.getSystemLanguage();
    } catch (e) {
      language = '';
    }
    let bundleVersion: string = '';
    try {
      const flags: number = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
      const info: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(flags);
      bundleVersion = info.versionName;
    } catch (e) {
      bundleVersion = '';
    }
    return {
      bundleVersion: bundleVersion,
      runtimeOS: runtimeOS,
      deviceModel: deviceModel,
      language: language,
      authed: this.authedProvider(),
    };
  }

  formatTs(ts: number): string {
    const d: Date = new Date(ts);
    const yyyy: string = String(d.getFullYear());
    const MM: string = this.pad2(d.getMonth() + 1);
    const dd: string = this.pad2(d.getDate());
    const HH: string = this.pad2(d.getHours());
    const mm: string = this.pad2(d.getMinutes());
    const ss: string = this.pad2(d.getSeconds());
    return yyyy + MM + dd + '-' + HH + mm + ss;
  }

  private pad2(n: number): string {
    return n < 10 ? '0' + String(n) : String(n);
  }
}

export const DebugDumper: DebugDumperImpl = new DebugDumperImpl();

export const DUMP_DIR: string = DUMP_DIR_NAME;
export const DUMP_HTTP_LIMIT: number = HTTP_DUMP_LIMIT;
export const DUMP_LOG_LIMIT: number = LOG_DUMP_LIMIT;
