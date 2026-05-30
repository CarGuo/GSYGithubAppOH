import { describe, beforeAll, afterAll, beforeEach, afterEach, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
  TokenStorage,
  LoginExpiredBus,
  DEFAULT_USER_AGENT,
  HttpMethod,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS, UNAUTHORIZED } from '../../../main/ets/net/NetworkCode';
import {
  LoginUseCase,
  PreferencesLike,
  OAuthClientConfig,
  LoginOutcome,
} from '../../../main/ets/auth/LoginUseCase';
import { OauthService } from '../../../main/ets/auth/OauthService';
import { AuthDeepLinkBus } from '../../../main/ets/auth/AuthDeepLinkBus';
import {
  AuthStore,
  GlobalAuthStore,
  APP_STORAGE_KEY_TOKEN,
  APP_STORAGE_KEY_AUTHED,
} from '../../../main/ets/store/AuthStore';
import { OauthHostBridge } from '../pages/OauthHostPage';
import { EventBus } from '../../../main/ets/utils/EventBus';
import { NavigationService } from '../../../main/ets/navigation/NavigationService';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/OauthHostPage';

const USER_JSON: string =
  '{"login":"CarGuo","name":"gsy","avatar_url":"https://x/y.png","html_url":"https://github.com/CarGuo"}';

class ScriptedResponse {
  status: number;
  body: string;
  headers: HttpHeaders;

  constructor(status: number, body: string, headers: HttpHeaders = {}) {
    this.status = status;
    this.body = body;
    this.headers = headers;
  }
}

class CapturedRequest {
  url: string;
  method: string;
  headers: HttpHeaders;
  body: string | null;

  constructor(url: string, method: string, headers: HttpHeaders, body: string | null) {
    this.url = url;
    this.method = method;
    this.headers = headers;
    this.body = body;
  }
}

class FakeHttpProvider implements HttpProvider {
  scripted: Map<string, ScriptedResponse[]> = new Map<string, ScriptedResponse[]>();
  fallback: ScriptedResponse = new ScriptedResponse(SUCCESS, '{}');
  captured: CapturedRequest[] = [];

  enqueue(method: HttpMethod, urlContains: string, response: ScriptedResponse): void {
    const key: string = `${method}|${urlContains}`;
    let arr: ScriptedResponse[] | undefined = this.scripted.get(key);
    if (arr === undefined) {
      arr = [];
      this.scripted.set(key, arr);
    }
    arr.push(response);
  }

  async request(url: string,
                method: string,
                headers: HttpHeaders,
                body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.captured.push(new CapturedRequest(url, method, headers, body));
    const keys: string[] = Array.from(this.scripted.keys());
    for (let i = 0; i < keys.length; i++) {
      const key: string = keys[i];
      const sep: number = key.indexOf('|');
      const m: string = key.substring(0, sep);
      const u: string = key.substring(sep + 1);
      if (m === method && url.indexOf(u) >= 0) {
        const arr: ScriptedResponse[] = this.scripted.get(key) as ScriptedResponse[];
        if (arr.length > 0) {
          const next: ScriptedResponse = arr.shift() as ScriptedResponse;
          return new RawResponse(next.status, next.body, next.headers);
        }
      }
    }
    return new RawResponse(this.fallback.status, this.fallback.body, this.fallback.headers);
  }
}

class FakeTokenStorage implements TokenStorage {
  value: string | null = null;

  async load(): Promise<string | null> {
    return this.value;
  }

  async save(token: string): Promise<void> {
    this.value = token;
  }

  async clear(): Promise<void> {
    this.value = null;
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

async function startHostPage(): Promise<void> {
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

export default function OauthDeepLinkUiTest(): void {
  describe('OauthDeepLinkUiTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let prefs: FakePreferences;
    let testStore: AuthStore;
    let useCase: LoginUseCase;

    beforeAll(async (): Promise<void> => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      prefs = new FakePreferences();
      testStore = GlobalAuthStore;
      testStore.clear();
      useCase = new LoginUseCase(testStore, null, prefs, new OAuthClientConfig('cid', 'csec'));

      HttpManager.setMockProvider(provider);
      HttpManager.setTokenStorage(storage);
      HttpManager.setTimeout(15000);
      HttpManager.setUserAgent(DEFAULT_USER_AGENT);
      HttpManager.setAuthorization(null);

      OauthService.setUseCase(useCase);
      OauthService.resetState();
      LoginExpiredBus.clear();
      EventBus.removeAll();
      OauthHostBridge.reset();
      await startHostPage();
    });

    afterAll((): void => {
      HttpManager.setMockProvider(null);
      OauthService.resetUseCase();
      OauthService.resetState();
      LoginExpiredBus.clear();
      EventBus.removeAll();
      NavigationService.setRouter(null);
    });

    beforeEach((): void => {
      provider.scripted.clear();
      provider.captured = [];
      storage.value = null;
      prefs.data.clear();
      testStore.clear();
      OauthHostBridge.reset();
      OauthService.resetState();
    });

    afterEach((): void => {
    });

    it('host_page_should_render_root_and_buttons', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      const root: Component = await driver.findComponent(ON.id('oauth_host_root'));
      expect(root !== null).assertTrue();
      const emit: Component = await driver.findComponent(ON.id('oauth_host_emit_btn'));
      expect(emit !== null).assertTrue();
      const gen: Component = await driver.findComponent(ON.id('oauth_host_gen_state_btn'));
      expect(gen !== null).assertTrue();
    });

    it('emit_deeplink_runs_oauth_exchange_writes_token_and_replaces_to_home',
      0, async (): Promise<void> => {
        const driver: Driver = Driver.create();
        provider.enqueue('GET', 'login/oauth/access_token',
          new ScriptedResponse(SUCCESS, '{"access_token":"deeplink_tk"}'));
        provider.enqueue('GET', '/user', new ScriptedResponse(SUCCESS, USER_JSON));

        const genBtn: Component = await driver.findComponent(ON.id('oauth_host_gen_state_btn'));
        await genBtn.click();
        await driver.delayMs(200);

        const emitBtn: Component = await driver.findComponent(ON.id('oauth_host_emit_btn'));
        await emitBtn.click();
        await driver.delayMs(800);

        const exchange: Component = await driver.findComponent(ON.id('oauth_host_exchange_count'));
        const exchangeText: string = await exchange.getText();
        const num: number = Number.parseInt(exchangeText.replace('exchange:', ''), 10);
        expect(num >= 1).assertTrue();

        const codeText: string = await (await driver.findComponent(ON.id('oauth_host_last_code'))).getText();
        expect(codeText.indexOf('host_code') >= 0).assertTrue();

        const tokenInStorage: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_TOKEN);
        expect(tokenInStorage !== undefined).assertTrue();
        expect((tokenInStorage as string).indexOf('deeplink_tk') >= 0).assertTrue();
        const authedInStorage: boolean | undefined = AppStorage.get<boolean>(APP_STORAGE_KEY_AUTHED);
        expect(authedInStorage === true).assertTrue();

        expect(testStore.authed).assertTrue();
        expect(testStore.token.indexOf('deeplink_tk') >= 0).assertTrue();

        expect(OauthHostBridge.replacedToHome()).assertTrue();
      });

    it('emit_deeplink_with_bad_state_is_rejected', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const genBtn: Component = await driver.findComponent(ON.id('oauth_host_gen_state_btn'));
      await genBtn.click();
      await driver.delayMs(200);

      const badBtn: Component = await driver.findComponent(ON.id('oauth_host_emit_bad_btn'));
      await badBtn.click();
      await driver.delayMs(400);

      const result: Component = await driver.findComponent(ON.id('oauth_host_result'));
      const text: string = await result.getText();
      expect(text.indexOf('state-invalid') >= 0).assertTrue();
      expect(provider.captured.length).assertEqual(0);
    });

    it('emit_deeplink_when_oauth_returns_401_emits_login_expired',
      0, async (): Promise<void> => {
        const driver: Driver = Driver.create();
        provider.enqueue('GET', 'login/oauth/access_token',
          new ScriptedResponse(UNAUTHORIZED, '{"message":"bad"}'));
        let expired: number = 0;
        const off: () => void = LoginExpiredBus.subscribe((): void => {
          expired = expired + 1;
        });

        const genBtn: Component = await driver.findComponent(ON.id('oauth_host_gen_state_btn'));
        await genBtn.click();
        await driver.delayMs(200);

        const emitBtn: Component = await driver.findComponent(ON.id('oauth_host_emit_btn'));
        await emitBtn.click();
        await driver.delayMs(600);

        expect(expired >= 1).assertTrue();
        const result: Component = await driver.findComponent(ON.id('oauth_host_result'));
        const text: string = await result.getText();
        expect(text.indexOf('fail:') >= 0).assertTrue();
        off();
      });
  });
}
