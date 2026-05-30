import { describe, beforeAll, afterAll, beforeEach, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import router from '@ohos.router';
import { LoginUseCase, PreferencesLike } from '../../../main/ets/auth/LoginUseCase';
import {
  AuthStore,
  AuthUserInfo,
  APP_STORAGE_KEY_USER_INFO,
} from '../../../main/ets/store/AuthStore';
import { DrawerMenuDeps } from '../../../main/ets/common/DrawerMenu';
import { DrawerHeaderDeps } from '../../../main/ets/common/DrawerHeader';
import { NavigationService, RouterLike } from '../../../main/ets/navigation/NavigationService';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/DrawerHostPage';

const HOST_USER_BODY: string =
  '{"login":"DrawerLogin","name":"DrawerName","avatar_url":"",' +
  '"html_url":"https://github.com/DrawerLogin","bio":"drawer-bio",' +
  '"followers":12,"following":34,"public_repos":5}';

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
    this.routes.push(new CapturedRoute('push', options.url,
      options.params as Record<string, Object> | null));
    return Promise.resolve();
  }

  replaceUrl(options: router.RouterOptions): Promise<void> {
    this.routes.push(new CapturedRoute('replace', options.url,
      options.params as Record<string, Object> | null));
    return Promise.resolve();
  }

  back(): void {
    this.backCount = this.backCount + 1;
  }

  clear(): void {
    this.clearCount = this.clearCount + 1;
  }
}

class FakePreferences implements PreferencesLike {
  data: Map<string, string> = new Map<string, string>();

  async putString(key: string, value: string): Promise<void> {
    this.data.set(key, value);
  }

  async remove(key: string): Promise<void> {
    this.data.delete(key);
  }
}

class MockLoginUseCase extends LoginUseCase {
  logoutCalls: number = 0;

  constructor(store: AuthStore, prefs: PreferencesLike) {
    super(store, null, prefs, null);
  }

  async logout(): Promise<void> {
    this.logoutCalls = this.logoutCalls + 1;
  }
}

async function startDrawerHost(): Promise<void> {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  await delegator.startAbility({
    bundleName: BUNDLE,
    abilityName: ABILITY,
    parameters: {
      targetPage: HOST_PAGE_PATH,
    },
  });
  const driver: Driver = Driver.create();
  await driver.delayMs(1500);
}

export default function DrawerMenuUiTest(): void {
  describe('DrawerMenuUiTest', (): void => {
    let mockUseCase: MockLoginUseCase;
    let fakeRouter: FakeRouter;
    let fakePrefs: FakePreferences;
    let testAuth: AuthStore;

    beforeAll(async (): Promise<void> => {
      fakePrefs = new FakePreferences();
      testAuth = new AuthStore();
      testAuth.setAppStorageSyncEnabled(false);
      testAuth.clear();
      const user: AuthUserInfo | null = AuthUserInfo.fromJson(HOST_USER_BODY);
      if (user !== null) {
        testAuth.setUser('token drawer', user);
      }
      mockUseCase = new MockLoginUseCase(testAuth, fakePrefs);
      fakeRouter = new FakeRouter();
      AppStorage.setOrCreate<string>(APP_STORAGE_KEY_USER_INFO, HOST_USER_BODY);
      DrawerMenuDeps.setStore(testAuth);
      DrawerMenuDeps.setLoginUseCase(mockUseCase);
      DrawerHeaderDeps.setStore(testAuth);
      NavigationService.setRouter(fakeRouter);
      await startDrawerHost();
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      DrawerMenuDeps.reset();
      DrawerHeaderDeps.reset();
      NavigationService.setRouter(null);
      AppStorage.setOrCreate<string>(APP_STORAGE_KEY_USER_INFO, '');
    });

    beforeEach((): void => {
      mockUseCase.logoutCalls = 0;
      fakeRouter.routes = [];
      fakeRouter.backCount = 0;
      fakeRouter.clearCount = 0;
    });

    it('should_render_drawer_root_and_header_and_menu', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(600);
      const root: Component = await driver.findComponent(ON.id('drawer_root'));
      expect(root !== null).assertTrue();
      const header: Component = await driver.findComponent(ON.id('drawer_header'));
      expect(header !== null).assertTrue();
      const menu: Component = await driver.findComponent(ON.id('drawer_menu'));
      expect(menu !== null).assertTrue();
    });

    it('should_render_drawer_name_and_login_text', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      const nameText: Component = await driver.findComponent(ON.id('drawer_name'));
      expect(nameText !== null).assertTrue();
      const nameValue: string = await nameText.getText();
      expect(nameValue.indexOf('DrawerName') >= 0).assertTrue();

      const loginText: Component = await driver.findComponent(ON.id('drawer_login'));
      expect(loginText !== null).assertTrue();
      const loginValue: string = await loginText.getText();
      expect(loginValue.indexOf('DrawerLogin') >= 0).assertTrue();
    });

    it('should_render_all_seven_drawer_menu_items', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      const history: Component = await driver.findComponent(ON.id('drawer_menu_item_history'));
      const feedback: Component = await driver.findComponent(ON.id('drawer_menu_item_feedback'));
      const personalInfo: Component = await driver.findComponent(ON.id('drawer_menu_item_personal_info'));
      const language: Component = await driver.findComponent(ON.id('drawer_menu_item_language'));
      const checkUpdate: Component = await driver.findComponent(ON.id('drawer_menu_item_check_update'));
      const about: Component = await driver.findComponent(ON.id('drawer_menu_item_about'));
      const logout: Component = await driver.findComponent(ON.id('drawer_menu_item_logout'));
      expect(history !== null).assertTrue();
      expect(feedback !== null).assertTrue();
      expect(personalInfo !== null).assertTrue();
      expect(language !== null).assertTrue();
      expect(checkUpdate !== null).assertTrue();
      expect(about !== null).assertTrue();
      expect(logout !== null).assertTrue();
    });

    it('should_render_drawer_avatar', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      const avatar: Component = await driver.findComponent(ON.id('drawer_avatar'));
      expect(avatar !== null).assertTrue();
    });

    it('logout_click_invokes_login_usecase_and_replace_to_login',
      0, async (): Promise<void> => {
        const driver: Driver = Driver.create();
        await driver.delayMs(300);
        const logoutItem: Component = await driver.findComponent(ON.id('drawer_menu_item_logout'));
        expect(logoutItem !== null).assertTrue();
        await logoutItem.click();
        await driver.delayMs(600);

        expect(mockUseCase.logoutCalls >= 1).assertTrue();

        let replacedToLogin: boolean = false;
        for (let i: number = 0; i < fakeRouter.routes.length; i++) {
          const r: CapturedRoute = fakeRouter.routes[i];
          if (r.kind === 'replace' && r.url === 'pages/LoginPage') {
            replacedToLogin = true;
            break;
          }
        }
        expect(replacedToLogin).assertTrue();
      });

    it('about_click_opens_compose_style_dialog_without_about_page_route', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      const aboutItem: Component = await driver.findComponent(ON.id('drawer_menu_item_about'));
      expect(aboutItem !== null).assertTrue();
      await aboutItem.click();
      await driver.delayMs(2400);

      let pushedAbout: boolean = false;
      for (let i: number = 0; i < fakeRouter.routes.length; i++) {
        const r: CapturedRoute = fakeRouter.routes[i];
        if (r.kind === 'push' && r.url === 'pages/AboutPage') {
          pushedAbout = true;
          break;
        }
      }
      expect(pushedAbout).assertFalse();

      const dialog: Component = await driver.findComponent(ON.id('drawer_about_dialog_root'));
      const title: Component = await driver.findComponent(ON.id('drawer_about_dialog_title'));
      const text: Component = await driver.findComponent(ON.id('drawer_about_dialog_text'));
      const ok: Component = await driver.findComponent(ON.id('drawer_about_dialog_confirm'));
      expect(dialog !== null).assertTrue();
      expect(title !== null).assertTrue();
      expect(text !== null).assertTrue();
      expect(ok !== null).assertTrue();
    });
  });
}
