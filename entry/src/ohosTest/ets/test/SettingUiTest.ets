import { describe, beforeAll, afterAll, beforeEach, afterEach, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import router from '@ohos.router';
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
import { I18n, changeLocale } from '../../../main/ets/i18n/I18n';
import { NavigationService, RouterLike } from '../../../main/ets/navigation/NavigationService';
import {
  EventBus,
  EVENT_LANGUAGE_CHANGED,
} from '../../../main/ets/utils/EventBus';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const SETTING_PAGE_PATH: string = 'pages/SettingPage';

class CapturedSettingRoute {
  kind: string;
  url: string;
  params: Record<string, Object> | null;

  constructor(kind: string, url: string, params: Record<string, Object> | null) {
    this.kind = kind;
    this.url = url;
    this.params = params;
  }
}

class FakeSettingRouter implements RouterLike {
  routes: CapturedSettingRoute[] = [];
  backCount: number = 0;
  clearCount: number = 0;

  pushUrl(options: router.RouterOptions): Promise<void> {
    this.routes.push(new CapturedSettingRoute('push', options.url, options.params as Record<string, Object> | null));
    return Promise.resolve();
  }

  replaceUrl(options: router.RouterOptions): Promise<void> {
    this.routes.push(new CapturedSettingRoute('replace', options.url, options.params as Record<string, Object> | null));
    return Promise.resolve();
  }

  back(): void {
    this.backCount += 1;
  }

  clear(): void {
    this.clearCount += 1;
  }
}

class FakeSettingPrefs implements PreferencesPort, PreferencesLike {
  data: Map<string, string> = new Map<string, string>();
  putCalls: number = 0;
  removeCalls: number = 0;

  async putString(key: string, value: string): Promise<void> {
    this.putCalls += 1;
    this.data.set(key, value);
  }

  async getString(key: string, defValue: string): Promise<string> {
    const v: string | undefined = this.data.get(key);
    return v !== undefined ? v : defValue;
  }

  async remove(key: string): Promise<void> {
    this.removeCalls += 1;
    this.data.delete(key);
  }
}

class FakeSettingRdb implements RdbPort {
  clearCalls: number = 0;

  async clearAll(): Promise<void> {
    this.clearCalls += 1;
  }
}

class MockSettingLoginUseCase extends LoginUseCase {
  logoutCalls: number = 0;

  constructor(store: AuthStore, prefs: PreferencesLike) {
    super(store, null, prefs, null);
  }

  async logout(): Promise<void> {
    this.logoutCalls += 1;
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

export default function SettingUiTest(): void {
  describe('SettingUiTest', (): void => {
    let mockUseCase: MockSettingLoginUseCase;
    let fakeRouter: FakeSettingRouter;
    let fakePrefs: FakeSettingPrefs;
    let fakeRdb: FakeSettingRdb;
    let testStore: AuthStore;
    let languageEventCount: number = 0;
    let offLanguage: (() => void) | null = null;

    beforeAll(async (): Promise<void> => {
      fakePrefs = new FakeSettingPrefs();
      fakeRdb = new FakeSettingRdb();
      testStore = new AuthStore();
      testStore.clear();
      mockUseCase = new MockSettingLoginUseCase(testStore, fakePrefs);
      fakeRouter = new FakeSettingRouter();
      SettingPageDeps.setUseCase(mockUseCase);
      SettingPageDeps.setPrefs(fakePrefs);
      SettingPageDeps.setRdb(fakeRdb);
      NavigationService.setRouter(fakeRouter);
      EventBus.removeAll();
      offLanguage = EventBus.on(EVENT_LANGUAGE_CHANGED, (): void => {
        languageEventCount = languageEventCount + 1;
      });
      await startSettingPage();
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      if (offLanguage !== null) {
        offLanguage();
        offLanguage = null;
      }
      SettingPageDeps.reset();
      NavigationService.setRouter(null);
      EventBus.removeAll();
      changeLocale('zh-CN');
    });

    beforeEach((): void => {
      mockUseCase.logoutCalls = 0;
      fakePrefs.putCalls = 0;
      fakePrefs.removeCalls = 0;
      fakePrefs.data.clear();
      fakeRdb.clearCalls = 0;
      fakeRouter.routes = [];
      fakeRouter.backCount = 0;
      fakeRouter.clearCount = 0;
      languageEventCount = 0;
    });

    afterEach((): void => {
    });

    it('should_render_setting_page_root_and_titles', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(400);
      const root: Component = await driver.findComponent(ON.id('setting_root'));
      expect(root !== null).assertTrue();
      const langTitle: Component = await driver.findComponent(ON.id('setting_language_title'));
      expect(langTitle !== null).assertTrue();
      const themeTitle: Component = await driver.findComponent(ON.id('setting_theme_title'));
      expect(themeTitle !== null).assertTrue();
      const clearBtn: Component = await driver.findComponent(ON.id('setting_clear_cache_btn'));
      expect(clearBtn !== null).assertTrue();
      const logoutBtn: Component = await driver.findComponent(ON.id('setting_logout_btn'));
      expect(logoutBtn !== null).assertTrue();
    });

    it('should_switch_to_english_and_update_ok_label', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      changeLocale('zh-CN');
      const okLabelBefore: Component = await driver.findComponent(ON.id('setting_ok_label_text'));
      expect(okLabelBefore !== null).assertTrue();

      const enBtn: Component = await driver.findComponent(ON.id('setting_language_en_btn'));
      await enBtn.click();
      await driver.delayMs(500);

      const okLabelAfter: Component = await driver.findComponent(ON.id('setting_ok_label_text'));
      const labelText: string = await okLabelAfter.getText();
      expect(labelText.indexOf('ok-label:') === 0).assertTrue();
      const okValue: string = labelText.replace('ok-label:', '');
      expect(okValue).assertEqual('ok');
      expect(I18n('ok')).assertEqual('ok');

      const counter: Component = await driver.findComponent(ON.id('setting_language_event_count'));
      const eventText: string = await counter.getText();
      const eventNum: number = Number.parseInt(eventText.replace('language-event:', ''), 10);
      expect(eventNum >= 1).assertTrue();

      expect(languageEventCount >= 1).assertTrue();
      expect(fakePrefs.data.get('languageSelect')).assertEqual('en');
    });

    it('should_switch_to_chinese_and_update_ok_label', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const zhBtn: Component = await driver.findComponent(ON.id('setting_language_zh_btn'));
      await zhBtn.click();
      await driver.delayMs(500);

      const okLabel: Component = await driver.findComponent(ON.id('setting_ok_label_text'));
      const labelText: string = await okLabel.getText();
      const okValue: string = labelText.replace('ok-label:', '');
      expect(okValue).assertEqual('确定');
      expect(I18n('ok')).assertEqual('确定');

      expect(languageEventCount >= 1).assertTrue();
      expect(fakePrefs.data.get('languageSelect')).assertEqual('zh-CN');
    });

    it('should_invoke_logout_and_replace_to_login', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const logoutBtn: Component = await driver.findComponent(ON.id('setting_logout_btn'));
      await logoutBtn.click();
      await driver.delayMs(500);

      expect(mockUseCase.logoutCalls >= 1).assertTrue();

      let replacedToLogin: boolean = false;
      for (let i: number = 0; i < fakeRouter.routes.length; i++) {
        const r: CapturedSettingRoute = fakeRouter.routes[i];
        if (r.kind === 'replace' && r.url === 'pages/LoginPage') {
          replacedToLogin = true;
          break;
        }
      }
      expect(replacedToLogin).assertTrue();
    });

    it('should_clear_cache_when_clicking_clear_button', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const clearBtn: Component = await driver.findComponent(ON.id('setting_clear_cache_btn'));
      await clearBtn.click();
      await driver.delayMs(400);

      expect(fakeRdb.clearCalls >= 1).assertTrue();
      expect(fakePrefs.removeCalls >= 1).assertTrue();
    });

    it('should_persist_theme_when_picking_dark_theme', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const darkBtn: Component = await driver.findComponent(ON.id('setting_theme_dark_btn'));
      await darkBtn.click();
      await driver.delayMs(300);

      expect(fakePrefs.data.get('theme')).assertEqual('dark');
    });
  });
}
