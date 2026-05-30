import { describe, beforeEach, afterEach, it, expect } from '@ohos/hypium';
import router from '@ohos.router';
import {
  AuthStore,
  AuthUserInfo,
} from '../../../main/ets/store/AuthStore';
import {
  DrawerHeaderLogic,
  DrawerHeaderTexts,
} from '../../../main/ets/common/DrawerHeader';
import {
  buildDrawerMenuItems,
  DrawerMenuItem,
  DRAWER_MENU_KEY_HISTORY,
  DRAWER_MENU_KEY_FEEDBACK,
  DRAWER_MENU_KEY_PERSONAL_INFO,
  DRAWER_MENU_KEY_LANGUAGE,
  DRAWER_MENU_KEY_CHECK_UPDATE,
  DRAWER_MENU_KEY_ABOUT,
  DRAWER_MENU_KEY_LOGOUT,
} from '../../../main/ets/common/DrawerMenu';
import { NavigationService, RouterLike } from '../../../main/ets/navigation/NavigationService';
import { I18n } from '../../../main/ets/i18n/I18n';

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

const TEST_USER_JSON: string =
  '{"login":"DrawerLogin","name":"DrawerName","avatar_url":"https://x/y.png",' +
  '"html_url":"https://github.com/DrawerLogin","bio":"hello drawer",' +
  '"followers":12,"following":34,"public_repos":5}';

export default function DrawerHeaderTest(): void {
  describe('DrawerHeaderTest', (): void => {
    let store: AuthStore;
    let fakeRouter: FakeRouter;

    beforeEach((): void => {
      store = new AuthStore();
      store.setAppStorageSyncEnabled(false);
      store.clear();
      fakeRouter = new FakeRouter();
      NavigationService.setRouter(fakeRouter);
    });

    afterEach((): void => {
      NavigationService.setRouter(null);
    });

    it('drawer_header_returns_placeholder_when_user_is_null', 0, (): void => {
      const texts: DrawerHeaderTexts = DrawerHeaderLogic.fromAuthStore(store);
      expect(texts.nameText).assertEqual('--');
      expect(texts.loginText).assertEqual('--');
      expect(texts.followersText).assertEqual('--');
      expect(texts.followingText).assertEqual('--');
    });

    it('drawer_header_renders_login_bio_followers_following_when_user_present',
      0, (): void => {
        const user: AuthUserInfo | null = AuthUserInfo.fromJson(TEST_USER_JSON);
        expect(user !== null).assertTrue();
        store.setUser('token x', user);

        const texts: DrawerHeaderTexts = DrawerHeaderLogic.fromAuthStore(store);
        expect(texts.nameText).assertEqual('DrawerName');
        expect(texts.loginText).assertEqual('DrawerLogin');
        expect(texts.followersText).assertEqual('12');
        expect(texts.followingText).assertEqual('34');
      });

    it('drawer_header_uses_userInfoNoting_for_empty_bio', 0, (): void => {
      const partial: string =
        '{"login":"NoBio","avatar_url":"","followers":0,"following":0}';
      const user: AuthUserInfo | null = AuthUserInfo.fromJson(partial);
      expect(user !== null).assertTrue();
      store.setUser('token y', user);

      const texts: DrawerHeaderTexts = DrawerHeaderLogic.fromAuthStore(store);
      expect(texts.nameText).assertEqual('NoBio');
      expect(texts.loginText).assertEqual('NoBio');
    });

    it('drawer_header_logic_parse_user_handles_invalid_input', 0, (): void => {
      expect(DrawerHeaderLogic.parseUser('') === null).assertTrue();
      expect(DrawerHeaderLogic.parseUser('not-json') === null).assertTrue();
      const ok: AuthUserInfo | null = DrawerHeaderLogic.parseUser(TEST_USER_JSON);
      expect(ok !== null).assertTrue();
      expect((ok as AuthUserInfo).login).assertEqual('DrawerLogin');
    });

    it('drawer_menu_items_have_seven_keys_in_order', 0, (): void => {
      const items: DrawerMenuItem[] = buildDrawerMenuItems();
      expect(items.length).assertEqual(7);
      expect(items[0].key).assertEqual(DRAWER_MENU_KEY_HISTORY);
      expect(items[1].key).assertEqual(DRAWER_MENU_KEY_FEEDBACK);
      expect(items[2].key).assertEqual(DRAWER_MENU_KEY_PERSONAL_INFO);
      expect(items[3].key).assertEqual(DRAWER_MENU_KEY_LANGUAGE);
      expect(items[4].key).assertEqual(DRAWER_MENU_KEY_CHECK_UPDATE);
      expect(items[5].key).assertEqual(DRAWER_MENU_KEY_ABOUT);
      expect(items[6].key).assertEqual(DRAWER_MENU_KEY_LOGOUT);
    });

    it('drawer_menu_items_titles_use_i18n_keys', 0, (): void => {
      const items: DrawerMenuItem[] = buildDrawerMenuItems();
      expect(items[0].title).assertEqual(I18n('drawerHistory'));
      expect(items[1].title).assertEqual(I18n('drawerFeedback'));
      expect(items[2].title).assertEqual(I18n('drawerPersonalInfo'));
      expect(items[3].title).assertEqual(I18n('drawerLanguage'));
      expect(items[4].title).assertEqual(I18n('drawerCheckUpdate'));
      expect(items[5].title).assertEqual(I18n('drawerAbout'));
      expect(items[6].title).assertEqual(I18n('drawerLogout'));
    });

    it('navigation_push_user_detail_increments_router_count', 0, (): void => {
      NavigationService.push('UserDetail',
        { 'login': 'DrawerLogin' } as Record<string, Object>);
      expect(fakeRouter.routes.length).assertEqual(1);
      const last: CapturedRoute = fakeRouter.routes[0];
      expect(last.kind).assertEqual('push');
      expect(last.url).assertEqual('pages/UserDetailPage');
      expect(last.params !== null).assertTrue();
      expect((last.params as Record<string, Object>)['login']).assertEqual('DrawerLogin');
    });

    it('navigation_replace_login_increments_router_count', 0, (): void => {
      NavigationService.replace('Login');
      expect(fakeRouter.routes.length).assertEqual(1);
      expect(fakeRouter.routes[0].kind).assertEqual('replace');
      expect(fakeRouter.routes[0].url).assertEqual('pages/LoginPage');
    });
  });
}
