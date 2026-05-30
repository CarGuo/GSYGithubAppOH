/**
 * MyTabPage UI 单测（R5f 重写版）：
 *
 *  对齐 Android Compose ProfileScreen / ProfileHeader：
 *
 *    - UserHeadItem header（user_head_root / user_head_avatar(_placeholder) /
 *      user_head_display_name / user_head_login / user_head_des / user_head_bell /
 *      user_head_counter_value_<key> 四格指标 + user_head_dynamic_title_bar）
 *    - PullLoadMoreList 容器（my_pull_list），事件列表为空时回退 my_empty_root + my_empty_text
 *    - 整页根 id：tab_page_root_my
 *
 *  通过 [MyTabPageDeps](../../../main/ets/pages/tabs/MyTabPage.ets) 的依赖注入桩：
 *    - setService(StubMyService)：refreshMe / fetchUnRead / fetchUserOrgs /
 *      fetchUserStarredCount 全部用稳定的本地数据
 *    - setDynamicServiceFactory(...)：把 DynamicService 替换为 StubDynamicService，
 *      让 fetchUserEvents 直接 push 一条空 list，UI 走"空态"分支以稳定断言。
 *
 *  使用 Host 页 [MyTabPageHost](../pages/MyTabPageHost.ets) 通过 startAbility(targetPage=...) 进入。
 */

import { describe, beforeAll, afterAll, beforeEach, afterEach, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import router from '@ohos.router';
import {
  AuthUserInfo,
  AuthStore,
  APP_STORAGE_KEY_USER_INFO,
} from '../../../main/ets/store/AuthStore';
import { MyStore, GlobalMyStore } from '../../../main/ets/store/MyStore';
import {
  MyService,
  RefreshMeResult,
  FetchUnReadResult,
  FetchUserOrgsResult,
  FetchStarredCountResult,
  MyOrgItem,
} from '../../../main/ets/service/MyService';
import { MyTabPageDeps } from '../../../main/ets/pages/tabs/MyTabPage';
import { DynamicService, FetchReceivedResult } from '../../../main/ets/service/DynamicService';
import { DynamicStore } from '../../../main/ets/store/DynamicStore';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { LoginUseCase } from '../../../main/ets/auth/LoginUseCase';
import { NavigationService, RouterLike } from '../../../main/ets/navigation/NavigationService';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/MyTabPageHost';

const HOST_USER_BODY: string =
  '{"login":"CarGuoUI","name":"GsyUI","avatar_url":"",'
  + '"html_url":"https://github.com/CarGuoUI","bio":"Hello GSY UI",'
  + '"followers":7,"following":8,"public_repos":9,'
  + '"company":"OpenHarmonyTest","location":"Earth","blog":"https://gsy.com",'
  + '"created_at":"2017-09-01T00:00:00Z","type":"User"}';

class CapturedMyRoute {
  kind: string;
  url: string;

  constructor(kind: string, url: string) {
    this.kind = kind;
    this.url = url;
  }
}

class FakeMyRouter implements RouterLike {
  routes: CapturedMyRoute[] = [];
  backCount: number = 0;
  clearCount: number = 0;

  pushUrl(options: router.RouterOptions): Promise<void> {
    this.routes.push(new CapturedMyRoute('push', options.url));
    return Promise.resolve();
  }

  replaceUrl(options: router.RouterOptions): Promise<void> {
    this.routes.push(new CapturedMyRoute('replace', options.url));
    return Promise.resolve();
  }

  back(): void {
    this.backCount += 1;
  }

  clear(): void {
    this.clearCount += 1;
    this.routes = [];
  }
}

class StubMyService extends MyService {
  refreshCalls: number = 0;
  unReadCalls: number = 0;
  orgCalls: number = 0;
  starredCalls: number = 0;
  orgsResp: MyOrgItem[] = [];
  unReadResp: boolean = false;
  starredCountResp: number = 0;

  constructor(store: MyStore, authStore: AuthStore) {
    super(store, authStore, null);
  }

  async refreshMe(): Promise<RefreshMeResult> {
    this.refreshCalls = this.refreshCalls + 1;
    const user: AuthUserInfo | null = AuthUserInfo.fromJson(HOST_USER_BODY);
    if (user !== null) {
      this.getStore().setUser(user);
      this.getAuthStore().setUser(this.getAuthStore().token, user);
    }
    return new RefreshMeResult(true, SUCCESS, user, '');
  }

  async fetchUnRead(): Promise<FetchUnReadResult> {
    this.unReadCalls = this.unReadCalls + 1;
    return new FetchUnReadResult(true, this.unReadResp, '');
  }

  async fetchUserOrgs(_login: string): Promise<FetchUserOrgsResult> {
    this.orgCalls = this.orgCalls + 1;
    return new FetchUserOrgsResult(true, this.orgsResp, '');
  }

  async fetchUserStarredCount(_login: string): Promise<FetchStarredCountResult> {
    this.starredCalls = this.starredCalls + 1;
    return new FetchStarredCountResult(true, this.starredCountResp, '');
  }
}

class StubDynamicService extends DynamicService {
  fetchUserEventsCalls: number = 0;

  constructor(store: DynamicStore) {
    super(store);
  }

  async fetchUserEvents(_user: string, _page: number): Promise<FetchReceivedResult> {
    this.fetchUserEventsCalls = this.fetchUserEventsCalls + 1;
    this.getStore().applyRefresh([], 30);
    return new FetchReceivedResult(true, SUCCESS, [], false, '');
  }
}

class MockMyLoginUseCase extends LoginUseCase {
  logoutCalls: number = 0;

  constructor(store: AuthStore) {
    super(store, null, null, null);
  }

  async logout(): Promise<void> {
    this.logoutCalls = this.logoutCalls + 1;
  }
}

async function startMyHost(): Promise<void> {
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

export default function MyUiTest(): void {
  describe('MyUiTest', (): void => {
    let testAuth: AuthStore;
    let testStore: MyStore;
    let stubService: StubMyService;
    let mockLoginUseCase: MockMyLoginUseCase;
    let fakeRouter: FakeMyRouter;
    let lastDynamic: StubDynamicService | null = null;

    beforeAll(async (): Promise<void> => {
      testAuth = new AuthStore();
      testAuth.setAppStorageSyncEnabled(false);
      testAuth.clear();
      testStore = new MyStore();
      testStore.reset();
      stubService = new StubMyService(testStore, testAuth);
      mockLoginUseCase = new MockMyLoginUseCase(testAuth);
      fakeRouter = new FakeMyRouter();
      stubService.starredCountResp = 99;
      stubService.unReadResp = true;
      stubService.orgsResp = [
        { id: 1, login: 'OpenHarmony', avatar_url: 'https://x/o.png' } as MyOrgItem,
      ];

      AppStorage.setOrCreate<string>(APP_STORAGE_KEY_USER_INFO, HOST_USER_BODY);
      MyTabPageDeps.setStore(testStore);
      MyTabPageDeps.setService(stubService);
      MyTabPageDeps.setDynamicServiceFactory((s: DynamicStore): DynamicService => {
        const stub: StubDynamicService = new StubDynamicService(s);
        lastDynamic = stub;
        return stub;
      });
      MyTabPageDeps.setLoginUseCase(mockLoginUseCase);
      NavigationService.setRouter(fakeRouter);
      await startMyHost();
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      MyTabPageDeps.reset();
      NavigationService.setRouter(null);
      AppStorage.setOrCreate<string>(APP_STORAGE_KEY_USER_INFO, '');
    });

    beforeEach((): void => {
    });

    afterEach((): void => {
    });

    it('should_render_my_tab_root_and_pull_list', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const root: Component = await driver.findComponent(ON.id('tab_page_root_my'));
      expect(root !== null).assertTrue();
      const list: Component = await driver.findComponent(ON.id('my_pull_list'));
      expect(list !== null).assertTrue();
      const logout: Component = await driver.findComponent(ON.id('my_logout_btn'));
      expect(logout === null).assertTrue();
    });

    it('should_render_user_head_with_display_name_login_and_des', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(400);
      const headRoot: Component = await driver.findComponent(ON.id('user_head_root'));
      expect(headRoot !== null).assertTrue();

      const display: Component = await driver.findComponent(ON.id('user_head_display_name'));
      expect(display !== null).assertTrue();
      const displayValue: string = await display.getText();
      expect(displayValue.indexOf('GsyUI') >= 0).assertTrue();

      const loginText: Component = await driver.findComponent(ON.id('user_head_login'));
      expect(loginText !== null).assertTrue();
      const loginValue: string = await loginText.getText();
      expect(loginValue.indexOf('CarGuoUI') >= 0).assertTrue();

      const desText: Component = await driver.findComponent(ON.id('user_head_des'));
      expect(desText !== null).assertTrue();
      const desValue: string = await desText.getText();
      expect(desValue.indexOf('Hello GSY UI') >= 0).assertTrue();

      const joinedText: Component = await driver.findComponent(ON.id('user_head_joined'));
      expect(joinedText !== null).assertTrue();
    });

    it('should_render_avatar_placeholder_when_avatar_url_empty',
      0, async (): Promise<void> => {
        const driver: Driver = Driver.create();
        await driver.delayMs(200);
        const placeholder: Component
          = await driver.findComponent(ON.id('user_head_avatar_placeholder'));
        expect(placeholder !== null).assertTrue();
        const txt: string = await placeholder.getText();
        expect(txt.toUpperCase().indexOf('C') >= 0).assertTrue();
      });

    it('should_render_compose_4_counter_cells_repos_follower_followed_star',
      0, async (): Promise<void> => {
        const driver: Driver = Driver.create();
        await driver.delayMs(400);

        const repos: Component
          = await driver.findComponent(ON.id('user_head_counter_value_repos'));
        expect(repos !== null).assertTrue();
        expect((await repos.getText()).indexOf('9') >= 0).assertTrue();

        const follower: Component
          = await driver.findComponent(ON.id('user_head_counter_value_follower'));
        expect(follower !== null).assertTrue();
        expect((await follower.getText()).indexOf('7') >= 0).assertTrue();

        const followed: Component
          = await driver.findComponent(ON.id('user_head_counter_value_followed'));
        expect(followed !== null).assertTrue();
        expect((await followed.getText()).indexOf('8') >= 0).assertTrue();

        const star: Component
          = await driver.findComponent(ON.id('user_head_counter_value_star'));
        expect(star !== null).assertTrue();

        const reposLabel: Component
          = await driver.findComponent(ON.id('user_head_counter_label_repos'));
        expect(reposLabel !== null).assertTrue();
        expect(await reposLabel.getText()).assertEqual('Repositories');
        const followerLabel: Component
          = await driver.findComponent(ON.id('user_head_counter_label_follower'));
        expect(followerLabel !== null).assertTrue();
        expect(await followerLabel.getText()).assertEqual('Followers');
        const followedLabel: Component
          = await driver.findComponent(ON.id('user_head_counter_label_followed'));
        expect(followedLabel !== null).assertTrue();
        expect(await followedLabel.getText()).assertEqual('Following');
        const starLabel: Component
          = await driver.findComponent(ON.id('user_head_counter_label_star'));
        expect(starLabel !== null).assertTrue();
        expect(await starLabel.getText()).assertEqual('Stars');

        const dynamicTitle: Component = await driver.findComponent(ON.id('user_head_dynamic_title'));
        expect(dynamicTitle !== null).assertTrue();
      });

    it('should_render_notification_bell_when_setting_true',
      0, async (): Promise<void> => {
        const driver: Driver = Driver.create();
        await driver.delayMs(200);
        const bell: Component = await driver.findComponent(ON.id('user_head_bell'));
        expect(bell !== null).assertTrue();
      });

    it('should_invoke_my_service_apis_and_dynamic_user_events',
      0, async (): Promise<void> => {
        const driver: Driver = Driver.create();
        await driver.delayMs(500);
        expect(stubService.refreshCalls >= 1).assertTrue();
        expect(stubService.unReadCalls >= 1).assertTrue();
        expect(stubService.orgCalls === 0).assertTrue();
        expect(stubService.starredCalls >= 1).assertTrue();
        const dyn: StubDynamicService | null = lastDynamic;
        expect(dyn !== null).assertTrue();
        expect((dyn as StubDynamicService).fetchUserEventsCalls >= 1).assertTrue();
      });

    it('should_render_empty_state_when_event_list_is_empty',
      0, async (): Promise<void> => {
        const driver: Driver = Driver.create();
        await driver.delayMs(300);
        const empty: Component = await driver.findComponent(ON.id('my_empty_root'));
        expect(empty !== null).assertTrue();
        const emptyText: Component = await driver.findComponent(ON.id('my_empty_text'));
        expect(emptyText !== null).assertTrue();
      });

    it('my_tab_page_uses_global_my_store_when_not_overridden', 0, (): void => {
      const ref: MyStore = MyTabPageDeps.getStore();
      expect(ref === testStore).assertTrue();
      MyTabPageDeps.reset();
      expect(MyTabPageDeps.getStore() === GlobalMyStore).assertTrue();
      MyTabPageDeps.setStore(testStore);
      MyTabPageDeps.setService(stubService);
      MyTabPageDeps.setDynamicServiceFactory((s: DynamicStore): DynamicService => {
        const stub: StubDynamicService = new StubDynamicService(s);
        lastDynamic = stub;
        return stub;
      });
      MyTabPageDeps.setLoginUseCase(mockLoginUseCase);
    });

    it('should_not_render_compose_profile_logout_button', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      mockLoginUseCase.logoutCalls = 0;
      fakeRouter.routes = [];
      const logout: Component = await driver.findComponent(ON.id('my_logout_btn'));
      expect(logout === null).assertTrue();
      expect(mockLoginUseCase.logoutCalls).assertEqual(0);
    });

    it('should_keep_avatar_non_clickable_like_compose_profile_header', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      fakeRouter.routes = [];
      const avatar: Component = await driver.findComponent(ON.id('user_head_avatar_placeholder'));
      expect(avatar !== null).assertTrue();
      await avatar.click();
      await driver.delayMs(300);
      for (let i: number = 0; i < fakeRouter.routes.length; i++) {
        expect(fakeRouter.routes[i].url !== 'pages/SettingPage').assertTrue();
      }
    });
  });
}
