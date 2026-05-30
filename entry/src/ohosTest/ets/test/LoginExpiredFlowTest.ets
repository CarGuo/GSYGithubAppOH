/**
 * LoginExpiredFlowTest —— 登录过期闭环流：
 *
 *  - 通过 FakeHttpProvider 让任意请求返回 401，覆盖 [HttpManager](../../../main/ets/net/HttpManager.ets)
 *    现有的 401 行为：清 Token + 派发 LoginExpiredBus。
 *  - 监听 LoginExpiredBus 后调用 [AuthStore.clear()](../../../main/ets/store/AuthStore.ets)
 *    与 [NavigationService.replace(RouteName.Login)](../../../main/ets/navigation/NavigationService.ets)，
 *    与 HomePage.aboutToAppear 中的真实订阅同构。
 *  - 用 FakeRouter 计数，断言 replace 命中 'pages/LoginPage'。
 */

import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import router from '@ohos.router';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
  TokenStorage,
  LoginExpiredBus,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { UNAUTHORIZED } from '../../../main/ets/net/NetworkCode';
import { AuthStore, AuthUserInfo } from '../../../main/ets/store/AuthStore';
import { NavigationService, RouterLike } from '../../../main/ets/navigation/NavigationService';
import { RouteName } from '../../../main/ets/navigation/Routes';

class CapturedRoute {
  kind: string;
  url: string;

  constructor(kind: string, url: string) {
    this.kind = kind;
    this.url = url;
  }
}

class FakeRouter implements RouterLike {
  routes: CapturedRoute[] = [];
  backCount: number = 0;
  clearCount: number = 0;

  pushUrl(options: router.RouterOptions): Promise<void> {
    this.routes.push(new CapturedRoute('push', options.url));
    return Promise.resolve();
  }

  replaceUrl(options: router.RouterOptions): Promise<void> {
    this.routes.push(new CapturedRoute('replace', options.url));
    return Promise.resolve();
  }

  back(): void {
    this.backCount = this.backCount + 1;
  }

  clear(): void {
    this.clearCount = this.clearCount + 1;
  }

  countReplace(url: string): number {
    let n: number = 0;
    for (let i: number = 0; i < this.routes.length; i++) {
      const r: CapturedRoute = this.routes[i];
      if (r.kind === 'replace' && r.url === url) {
        n = n + 1;
      }
    }
    return n;
  }
}

class FakeProvider implements HttpProvider {
  nextStatus: number = UNAUTHORIZED;
  nextBody: string = '{"message":"Bad credentials"}';

  async request(_url: string,
                _method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    return new RawResponse(this.nextStatus, this.nextBody, {});
  }
}

class FakeTokenStorage implements TokenStorage {
  value: string | null = null;
  clearCount: number = 0;

  async load(): Promise<string | null> {
    return this.value;
  }

  async save(token: string): Promise<void> {
    this.value = token;
  }

  async clear(): Promise<void> {
    this.value = null;
    this.clearCount = this.clearCount + 1;
  }
}

export default function LoginExpiredFlowTest(): void {
  describe('LoginExpiredFlowTest', (): void => {
    let provider: FakeProvider;
    let storage: FakeTokenStorage;
    let fakeRouter: FakeRouter;
    let authStore: AuthStore;
    let unsubscribe: (() => void) | null = null;

    beforeEach((): void => {
      provider = new FakeProvider();
      storage = new FakeTokenStorage();
      fakeRouter = new FakeRouter();
      NavigationService.setRouter(fakeRouter);

      HttpManager.setMockProvider(provider);
      HttpManager.setTokenStorage(storage);
      HttpManager.setTimeout(15000);
      HttpManager.setAuthorization('token expired-token');
      LoginExpiredBus.clear();

      authStore = new AuthStore();
      authStore.setUser('token expired-token',
        new AuthUserInfo('CarGuo', 'Guo', '', '', '', '', 0, 0, 0));
    });

    afterEach((): void => {
      if (unsubscribe !== null) {
        unsubscribe();
        unsubscribe = null;
      }
      HttpManager.setMockProvider(null);
      LoginExpiredBus.clear();
    });

    it('401_publishes_login_expired_then_clears_auth_and_replaces_to_login', 0,
      async (): Promise<void> => {
        let busFired: number = 0;
        unsubscribe = LoginExpiredBus.subscribe((): void => {
          busFired = busFired + 1;
          authStore.clear();
          NavigationService.replace(RouteName.Login);
        });

        const res = await HttpManager.getFetch<Object>('https://api.github.com/user');

        expect(res.result).assertFalse();
        expect(res.code).assertEqual(UNAUTHORIZED);
        expect(busFired).assertEqual(1);
        expect(authStore.authed).assertFalse();
        expect(authStore.token).assertEqual('');
        expect(authStore.userInfo).assertNull();
        expect(storage.clearCount >= 1).assertTrue();
        expect(fakeRouter.countReplace('pages/LoginPage')).assertEqual(1);
      });

    it('multiple_401_publish_each_time_and_replace_each_time', 0,
      async (): Promise<void> => {
        unsubscribe = LoginExpiredBus.subscribe((): void => {
          authStore.clear();
          NavigationService.replace(RouteName.Login);
        });

        await HttpManager.getFetch<Object>('https://api.github.com/user');
        HttpManager.setAuthorization('token re-acquired');
        await HttpManager.getFetch<Object>('https://api.github.com/notifications');

        expect(fakeRouter.countReplace('pages/LoginPage')).assertEqual(2);
      });

    it('non_401_does_not_trigger_login_expired_bus', 0, async (): Promise<void> => {
      let busFired: number = 0;
      unsubscribe = LoginExpiredBus.subscribe((): void => {
        busFired = busFired + 1;
      });
      provider.nextStatus = 500;
      provider.nextBody = '{"message":"server"}';

      await HttpManager.getFetch<Object>('https://api.github.com/user');

      expect(busFired).assertEqual(0);
      expect(fakeRouter.countReplace('pages/LoginPage')).assertEqual(0);
    });
  });
}
