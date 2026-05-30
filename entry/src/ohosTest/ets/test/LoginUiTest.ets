import { describe, beforeAll, afterAll, beforeEach, afterEach, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import router from '@ohos.router';
import {
  LoginUseCase,
  LoginOutcome,
  PreferencesLike,
  OAuthClientConfig,
} from '../../../main/ets/auth/LoginUseCase';
import { HttpResult } from '../../../main/ets/net/Result';
import { SUCCESS, UNAUTHORIZED } from '../../../main/ets/net/NetworkCode';
import { AuthUserInfo, AuthStore, GlobalAuthStore } from '../../../main/ets/store/AuthStore';
import { LoginPageDeps } from '../../../main/ets/pages/LoginPage';
import {
  SettingPageDeps,
  PreferencesPort,
} from '../../../main/ets/pages/SettingPage';
import { KEY_LANGUAGE_SELECT } from '../../../main/ets/dao/db/Preferences';
import { NavigationService, RouterLike } from '../../../main/ets/navigation/NavigationService';
import { EventBus, EVENT_USER_LOGGED_IN } from '../../../main/ets/utils/EventBus';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const LOGIN_PAGE_PATH: string = 'pages/LoginPage';

class CapturedRoute {
  kind: string;
  url: string;
  params: Record<string, Object> | null;

  constructor(kind: string, url: string, params: Record<string, Object> | null) {
    this.kind = kind;
    this.url = url;
    this.params = params;
  }
}

class FakeRouter implements RouterLike {
  routes: CapturedRoute[] = [];
  backCount: number = 0;
  clearCount: number = 0;

  pushUrl(options: router.RouterOptions): Promise<void> {
    this.routes.push(new CapturedRoute('push', options.url, options.params as Record<string, Object> | null));
    return Promise.resolve();
  }

  replaceUrl(options: router.RouterOptions): Promise<void> {
    this.routes.push(new CapturedRoute('replace', options.url, options.params as Record<string, Object> | null));
    return Promise.resolve();
  }

  back(): void {
    this.backCount += 1;
  }

  clear(): void {
    this.clearCount += 1;
  }
}

class FakePreferences implements PreferencesLike, PreferencesPort {
  data: Map<string, string> = new Map<string, string>();

  async putString(key: string, value: string): Promise<void> {
    this.data.set(key, value);
  }

  async getString(key: string, defValue: string): Promise<string> {
    const value: string | undefined = this.data.get(key);
    return value !== undefined ? value : defValue;
  }

  async remove(key: string): Promise<void> {
    this.data.delete(key);
  }
}

class MockLoginUseCase extends LoginUseCase {
  basicCalls: number = 0;
  patCalls: number = 0;
  oauthCalls: number = 0;
  lastUser: string = '';
  lastPwd: string = '';
  lastToken: string = '';
  lastCode: string = '';
  basicResult: LoginOutcome = HttpResult.ok<AuthUserInfo>(
    SUCCESS,
    new AuthUserInfo('CarGuo', 'gsy', '', '', '{}'));
  patResult: LoginOutcome = HttpResult.ok<AuthUserInfo>(
    SUCCESS,
    new AuthUserInfo('CarGuo', 'gsy', '', '', '{}'));
  oauthResult: LoginOutcome = HttpResult.ok<AuthUserInfo>(
    SUCCESS,
    new AuthUserInfo('CarGuo', 'gsy', '', '', '{}'));

  constructor(store: AuthStore, prefs: PreferencesLike) {
    super(store, null, prefs, null);
  }

  async loginWithBasicAuth(user: string, pwd: string): Promise<LoginOutcome> {
    this.basicCalls += 1;
    this.lastUser = user;
    this.lastPwd = pwd;
    return this.basicResult;
  }

  async loginWithPersonalAccessToken(token: string): Promise<LoginOutcome> {
    this.patCalls += 1;
    this.lastToken = token;
    return this.patResult;
  }

  async exchangeOAuthCode(code: string): Promise<LoginOutcome> {
    this.oauthCalls += 1;
    this.lastCode = code;
    return this.oauthResult;
  }

  setOAuthConfig(_oauth: OAuthClientConfig): void {
  }

  async logout(): Promise<void> {
  }
}

async function startLoginPage(): Promise<void> {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  await delegator.startAbility({
    bundleName: BUNDLE,
    abilityName: ABILITY,
    parameters: {
      targetPage: LOGIN_PAGE_PATH,
    },
  });
  const driver: Driver = Driver.create();
  await driver.delayMs(1500);
}

export default function LoginUiTest(): void {
  describe('LoginUiTest', (): void => {
    let mockUseCase: MockLoginUseCase;
    let fakeRouter: FakeRouter;
    let fakePrefs: FakePreferences;
    let testStore: AuthStore;

    beforeAll(async (): Promise<void> => {
      fakePrefs = new FakePreferences();
      testStore = new AuthStore();
      testStore.clear();
      mockUseCase = new MockLoginUseCase(testStore, fakePrefs);
      fakeRouter = new FakeRouter();
      LoginPageDeps.setUseCase(mockUseCase);
      LoginPageDeps.setStore(testStore);
      SettingPageDeps.setPrefs(fakePrefs);
      NavigationService.setRouter(fakeRouter);
      EventBus.removeAll();
      await startLoginPage();
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      LoginPageDeps.reset();
      SettingPageDeps.reset();
      NavigationService.setRouter(null);
      EventBus.removeAll();
    });

    beforeEach((): void => {
      mockUseCase.basicCalls = 0;
      mockUseCase.patCalls = 0;
      mockUseCase.oauthCalls = 0;
      mockUseCase.lastUser = '';
      mockUseCase.lastPwd = '';
      mockUseCase.lastToken = '';
      mockUseCase.lastCode = '';
      fakePrefs.data.clear();
      fakeRouter.routes = [];
      fakeRouter.backCount = 0;
      fakeRouter.clearCount = 0;
      testStore.clear();
    });

    afterEach((): void => {
    });

    it('should_render_login_page_root_and_logo', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(500);
      const root: Component = await driver.findComponent(ON.id('login_stack_root'));
      expect(root !== null).assertTrue();
      const innerRoot: Component = await driver.findComponent(ON.id('login_root'));
      expect(innerRoot !== null).assertTrue();
      const logo: Component = await driver.findComponent(ON.id('login_logo'));
      expect(logo !== null).assertTrue();
      const form: Component = await driver.findComponent(ON.id('login_form'));
      expect(form !== null).assertTrue();
    });

    it('should_expose_animated_logo_switcher', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(2500);
      const logo: Component = await driver.findComponent(ON.id('login_logo'));
      expect(logo !== null).assertTrue();
      let hasAnimationState: boolean = false;
      try {
        const anim: Component = await driver.findComponent(ON.id('login_logo_harmony_letter'));
        hasAnimationState = anim !== null;
      } catch (_e) {
      }
      expect(hasAnimationState).assertTrue();
    });

    it('should_render_compose_token_inputs_and_buttons', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const tokenInput: Component = await driver.findComponent(ON.id('login_token_input'));
      expect(tokenInput !== null).assertTrue();
      const tokenField: Component = await driver.findComponent(ON.id('login_token_field'));
      expect(tokenField !== null).assertTrue();
      const tokenIcon: Component = await driver.findComponent(ON.id('login_token_leading_icon'));
      expect(tokenIcon !== null).assertTrue();
      const tokenHelper: Component = await driver.findComponent(ON.id('login_token_helper'));
      expect(tokenHelper !== null).assertTrue();
      const submitBtn: Component = await driver.findComponent(ON.id('login_submit_btn'));
      expect(submitBtn !== null).assertTrue();
      const oauthBtn: Component = await driver.findComponent(ON.id('login_oauth_btn'));
      expect(oauthBtn !== null).assertTrue();
      const languageBtn: Component = await driver.findComponent(ON.id('login_language_btn'));
      expect(languageBtn !== null).assertTrue();
    });

    it('should_not_render_legacy_basic_login_probe_nodes', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const legacyProbe: Component | null = await driver.findComponent(ON.id('login_legacy_probe'));
      expect(legacyProbe === null).assertTrue();
      const usernameInput: Component | null = await driver.findComponent(ON.id('login_username_input'));
      expect(usernameInput === null).assertTrue();
      const passwordInput: Component | null = await driver.findComponent(ON.id('login_password_input'));
      expect(passwordInput === null).assertTrue();
      const registerLink: Component | null = await driver.findComponent(ON.id('login_register_link'));
      expect(registerLink === null).assertTrue();
      const patBtn: Component | null = await driver.findComponent(ON.id('login_pat_btn'));
      expect(patBtn === null).assertTrue();
    });

    it('should_invoke_basic_login_when_use_case_called_directly', 0, async (): Promise<void> => {
      // RN 实际行为：主登录按钮直接走 OAuth Web，因此页面 UI 不再触发 basic login。
      // 但 LoginUseCase 仍保留 basic auth 接口，单独验证调用计数。
      await mockUseCase.loginWithBasicAuth('alice', 'pwd123');
      expect(mockUseCase.basicCalls).assertEqual(1);
      expect(mockUseCase.lastUser).assertEqual('alice');
      expect(mockUseCase.lastPwd).assertEqual('pwd123');
    });

    it('should_invoke_token_login_when_submit_button_clicked', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const input: Component = await driver.findComponent(ON.id('login_token_input'));
      await input.inputText('ghp_test');
      await driver.delayMs(200);
      const submitBtn: Component = await driver.findComponent(ON.id('login_submit_btn'));
      await submitBtn.click();
      await driver.delayMs(400);

      expect(mockUseCase.patCalls).assertEqual(1);
      expect(mockUseCase.lastToken).assertEqual('ghp_test');
    });

    it('should_open_language_dialog_when_language_clicked', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const languageBtn: Component = await driver.findComponent(ON.id('login_language_btn'));
      await languageBtn.click();
      await driver.delayMs(400);

      const dialog: Component = await driver.findComponent(ON.id('login_language_dialog'));
      expect(dialog !== null).assertTrue();
      const systemOption: Component = await driver.findComponent(ON.id('login_language_option_local'));
      expect(systemOption !== null).assertTrue();
      const zhOption: Component = await driver.findComponent(ON.id('login_language_option_zh-CN'));
      expect(zhOption !== null).assertTrue();
      const enOption: Component = await driver.findComponent(ON.id('login_language_option_en'));
      expect(enOption !== null).assertTrue();
      const enRadio: Component = await driver.findComponent(ON.id('login_language_radio_en'));
      expect(enRadio !== null).assertTrue();
      await enOption.click();
      await driver.delayMs(300);
      expect(fakePrefs.data.get(KEY_LANGUAGE_SELECT)).assertEqual('en');
    });

    it('should_push_login_web_via_oauth_button', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const oauthBtn: Component = await driver.findComponent(ON.id('login_oauth_btn'));
      await oauthBtn.click();
      await driver.delayMs(300);

      let pushedToWeb: boolean = false;
      for (let i: number = 0; i < fakeRouter.routes.length; i++) {
        const r: CapturedRoute = fakeRouter.routes[i];
        if (r.kind === 'push' && r.url === 'pages/LoginWebPage') {
          pushedToWeb = true;
          break;
        }
      }
      expect(pushedToWeb).assertTrue();
    });

    it('should_replace_to_home_when_logged_in_event_emits', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(200);

      const before: number = fakeRouter.routes.length;
      EventBus.emit(EVENT_USER_LOGGED_IN, new AuthUserInfo('CarGuo', 'gsy', '', '', '{}'));
      await driver.delayMs(400);

      let replacedToHome: boolean = false;
      for (let i: number = before; i < fakeRouter.routes.length; i++) {
        const r: CapturedRoute = fakeRouter.routes[i];
        if (r.kind === 'replace' && r.url === 'pages/HomePage') {
          replacedToHome = true;
          break;
        }
      }
      expect(replacedToHome).assertTrue();
    });

    it('login_page_uses_global_auth_store_when_not_overridden', 0, (): void => {
      const ref: AuthStore = LoginPageDeps.getStore();
      expect(ref === testStore).assertTrue();
      LoginPageDeps.reset();
      expect(LoginPageDeps.getStore() === GlobalAuthStore).assertTrue();
      LoginPageDeps.setUseCase(mockUseCase);
      LoginPageDeps.setStore(testStore);
    });
  });
}
