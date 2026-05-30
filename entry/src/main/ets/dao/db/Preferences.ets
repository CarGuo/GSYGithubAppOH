import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import hilog from '@ohos.hilog';

const TAG: string = 'Preferences';

export const PREF_NAME: string = 'gsygithub_oh_pref';

export const KEY_LANGUAGE_SELECT: string = 'languageSelect';
export const KEY_LANGUAGE_SELECT_NAME: string = 'languageSelectName';
export const KEY_USER_BASIC: string = 'userBasic';
export const KEY_USER_TOKEN: string = 'userToken';
export const KEY_USER_INFO: string = 'userInfo';
export const KEY_USER_NAME: string = 'userName';
export const KEY_USER_PASSWORD: string = 'userPassword';
export const KEY_OAUTH_STATE: string = 'oauthState';
export const KEY_THEME: string = 'theme';

export type PrefValue = string | number | boolean;

export class PreferencesHelper {
  private pref: preferences.Preferences | null = null;
  private initializing: Promise<void> | null = null;

  isReady(): boolean {
    return this.pref !== null;
  }

  async init(context: common.Context, name: string = PREF_NAME): Promise<void> {
    if (this.pref !== null) {
      return;
    }
    if (this.initializing !== null) {
      await this.initializing;
      return;
    }
    this.initializing = this.doInit(context, name);
    try {
      await this.initializing;
    } finally {
      this.initializing = null;
    }
  }

  private async doInit(context: common.Context, name: string): Promise<void> {
    this.pref = await preferences.getPreferences(context, name);
    hilog.info(0x0000, TAG, 'pref ready: %{public}s', name);
  }

  private getPref(): preferences.Preferences {
    if (this.pref === null) {
      throw new Error('Preferences not initialized, call init(context) first');
    }
    return this.pref;
  }

  async putString(key: string, value: string): Promise<void> {
    const p: preferences.Preferences = this.getPref();
    await p.put(key, value);
    await p.flush();
  }

  async getString(key: string, defValue: string = ''): Promise<string> {
    const p: preferences.Preferences = this.getPref();
    const v: preferences.ValueType = await p.get(key, defValue);
    return typeof v === 'string' ? v : defValue;
  }

  async putNumber(key: string, value: number): Promise<void> {
    const p: preferences.Preferences = this.getPref();
    await p.put(key, value);
    await p.flush();
  }

  async getNumber(key: string, defValue: number = 0): Promise<number> {
    const p: preferences.Preferences = this.getPref();
    const v: preferences.ValueType = await p.get(key, defValue);
    return typeof v === 'number' ? v : defValue;
  }

  async putBoolean(key: string, value: boolean): Promise<void> {
    const p: preferences.Preferences = this.getPref();
    await p.put(key, value);
    await p.flush();
  }

  async getBoolean(key: string, defValue: boolean = false): Promise<boolean> {
    const p: preferences.Preferences = this.getPref();
    const v: preferences.ValueType = await p.get(key, defValue);
    return typeof v === 'boolean' ? v : defValue;
  }

  async has(key: string): Promise<boolean> {
    const p: preferences.Preferences = this.getPref();
    return await p.has(key);
  }

  async remove(key: string): Promise<void> {
    const p: preferences.Preferences = this.getPref();
    await p.delete(key);
    await p.flush();
  }

  async clear(): Promise<void> {
    const p: preferences.Preferences = this.getPref();
    await p.clear();
    await p.flush();
  }
}

export const Preferences: PreferencesHelper = new PreferencesHelper();
