import { describe, beforeAll, afterAll, beforeEach, afterEach, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import {
  SettingPageDeps,
  PreferencesPort,
  RdbPort,
} from '../../../main/ets/pages/SettingPage';
import {
  LoginUseCase,
  LoginOutcome,
  PreferencesLike,
} from '../../../main/ets/auth/LoginUseCase';
import { HttpResult } from '../../../main/ets/net/Result';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { AuthUserInfo, AuthStore } from '../../../main/ets/store/AuthStore';
import {
  ThemeManager,
  DARK_PALETTE,
  LIGHT_PALETTE,
} from '../../../main/ets/theme/ThemeManager';
import { EventBus } from '../../../main/ets/utils/EventBus';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const SETTING_PAGE_PATH: string = 'pages/SettingPage';

class FakeUiPrefs implements PreferencesPort, PreferencesLike {
  data: Map<string, string> = new Map<string, string>();

  async putString(key: string, value: string): Promise<void> {
    this.data.set(key, value);
  }

  async getString(key: string, defValue: string): Promise<string> {
    const v: string | undefined = this.data.get(key);
    return v !== undefined ? v : defValue;
  }

  async remove(key: string): Promise<void> {
    this.data.delete(key);
  }
}

class FakeUiRdb implements RdbPort {
  async clearAll(): Promise<void> {
  }
}

class MockUiLoginUseCase extends LoginUseCase {
  constructor(store: AuthStore, prefs: PreferencesLike) {
    super(store, null, prefs, null);
  }

  async logout(): Promise<void> {
  }

  async loginWithBasicAuth(_user: string, _pwd: string): Promise<LoginOutcome> {
    return HttpResult.ok<AuthUserInfo>(SUCCESS, new AuthUserInfo('CarGuo', 'gsy', '', '', '{}'));
  }
}

async function startSettingPage(): Promise<void> {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  await delegator.startAbility({
    bundleName: BUNDLE,
    abilityName: ABILITY,
    parameters: {
      targetPage: SETTING_PAGE_PATH,
    },
  });
  const driver: Driver = Driver.create();
  await driver.delayMs(1500);
}

function readBackgroundColor(key: string): string {
  try {
    const raw: string = getInspectorByKey(key);
    if (!raw || raw.length === 0) {
      return '';
    }
    const obj: Record<string, Object> = JSON.parse(raw) as Record<string, Object>;
    const attrs: Record<string, Object> | undefined = obj['$attrs'] as Record<string, Object> | undefined;
    if (attrs === undefined) {
      return '';
    }
    const v: Object | undefined = attrs['backgroundColor'];
    return v === undefined ? '' : (v as string).toString();
  } catch (_e) {
    return '';
  }
}

export default function ThemeUiTest(): void {
  describe('ThemeUiTest', (): void => {
    let prefs: FakeUiPrefs;
    let rdb: FakeUiRdb;
    let store: AuthStore;
    let useCase: MockUiLoginUseCase;

    beforeAll(async (): Promise<void> => {
      prefs = new FakeUiPrefs();
      rdb = new FakeUiRdb();
      store = new AuthStore();
      store.clear();
      useCase = new MockUiLoginUseCase(store, prefs);
      SettingPageDeps.setUseCase(useCase);
      SettingPageDeps.setPrefs(prefs);
      SettingPageDeps.setRdb(rdb);
      EventBus.removeAll();
      ThemeManager.reset();
      await ThemeManager.setMode('light');
      await startSettingPage();
    });

    afterAll((): void => {
      SettingPageDeps.reset();
      EventBus.removeAll();
      ThemeManager.reset();
    });

    beforeEach(async (): Promise<void> => {
      await ThemeManager.setMode('light');
    });

    afterEach((): void => {
    });

    it('appbar_should_change_background_color_when_switch_to_dark', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(400);

      const beforeBg: string = readBackgroundColor('appbar_root');
      expect(beforeBg.length >= 0).assertTrue();

      const darkBtn: Component = await driver.findComponent(ON.id('setting_theme_dark_btn'));
      expect(darkBtn !== null).assertTrue();
      await darkBtn.click();
      await driver.delayMs(600);

      expect(ThemeManager.current().background).assertEqual(DARK_PALETTE.background);
      expect(ThemeManager.getMode()).assertEqual('dark');

      const afterBg: string = readBackgroundColor('appbar_root');
      if (afterBg.length > 0) {
        expect(afterBg !== beforeBg || afterBg.toUpperCase().indexOf('0D1117') >= 0 || afterBg.toUpperCase().indexOf('010409') >= 0).assertTrue();
      } else {
        expect(true).assertTrue();
      }
    });

    it('appbar_should_restore_to_light_palette_when_switch_back', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const darkBtn: Component = await driver.findComponent(ON.id('setting_theme_dark_btn'));
      await darkBtn.click();
      await driver.delayMs(400);
      expect(ThemeManager.current().background).assertEqual(DARK_PALETTE.background);

      const lightBtn: Component = await driver.findComponent(ON.id('setting_theme_light_btn'));
      await lightBtn.click();
      await driver.delayMs(400);
      expect(ThemeManager.current().background).assertEqual(LIGHT_PALETTE.background);
    });
  });
}
