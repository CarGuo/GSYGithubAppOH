import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
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
import {
  OauthService,
  DEFAULT_OAUTH_REDIRECT_URI,
  DEFAULT_OAUTH_SCOPE,
} from '../../../main/ets/auth/OauthService';
import { AuthStore } from '../../../main/ets/store/AuthStore';
import { Url } from '../../../main/ets/utils/Url';
import { Address, HOST_WEB } from '../../../main/ets/net/Address';
import { EventBus } from '../../../main/ets/utils/EventBus';
import { AuthDeepLinkBus } from '../../../main/ets/auth/AuthDeepLinkBus';

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

  countByUrlContains(method: string, urlPart: string): number {
    let n: number = 0;
    for (let i = 0; i < this.captured.length; i++) {
      const r: CapturedRequest = this.captured[i];
      if (r.method === method && r.url.indexOf(urlPart) >= 0) {
        n = n + 1;
      }
    }
    return n;
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

const USER_JSON: string =
  '{"login":"CarGuo","name":"gsy","avatar_url":"https://x/y.png","html_url":"https://github.com/CarGuo"}';

export default function OauthServiceTest(): void {
  describe('OauthService', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let prefs: FakePreferences;
    let store: AuthStore;
    let useCase: LoginUseCase;
    let loginExpiredCount: number = 0;
    let offExpired: () => void = (): void => {
    };

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      prefs = new FakePreferences();
      store = new AuthStore();
      store.clear();
      useCase = new LoginUseCase(store, null, prefs, new OAuthClientConfig('cid', 'csec'));

      HttpManager.setMockProvider(provider);
      HttpManager.setTokenStorage(storage);
      HttpManager.setTimeout(15000);
      HttpManager.setUserAgent(DEFAULT_USER_AGENT);
      HttpManager.setAuthorization(null);

      LoginExpiredBus.clear();
      EventBus.removeAll();
      AuthDeepLinkBus.resetForTest();

      loginExpiredCount = 0;
      offExpired = LoginExpiredBus.subscribe((): void => {
        loginExpiredCount = loginExpiredCount + 1;
      });

      OauthService.setUseCase(useCase);
      OauthService.resetState();
    });

    afterEach((): void => {
      offExpired();
      HttpManager.setMockProvider(null);
      LoginExpiredBus.clear();
      EventBus.removeAll();
      AuthDeepLinkBus.resetForTest();
      OauthService.resetUseCase();
      OauthService.resetState();
    });

    it('build_authorize_url_contains_required_params_and_encodes', 0, (): void => {
      const url: string = OauthService.buildAuthorizeUrl(
        'CLIENT123',
        DEFAULT_OAUTH_REDIRECT_URI,
        DEFAULT_OAUTH_SCOPE,
        'STATE_X');
      expect(url.indexOf(`${HOST_WEB}login/oauth/authorize?`) === 0).assertTrue();
      expect(url.indexOf('client_id=CLIENT123') >= 0).assertTrue();
      const encodedRedirect: string = encodeURIComponent(DEFAULT_OAUTH_REDIRECT_URI);
      expect(url.indexOf(`redirect_uri=${encodedRedirect}`) >= 0).assertTrue();
      const encodedScope: string = encodeURIComponent(DEFAULT_OAUTH_SCOPE);
      expect(url.indexOf(`scope=${encodedScope}`) >= 0).assertTrue();
      expect(url.indexOf('state=STATE_X') >= 0).assertTrue();
    });

    it('oauth_defaults_match_compose_authorization_url', 0, (): void => {
      expect(DEFAULT_OAUTH_REDIRECT_URI).assertEqual('gsygithubapp://authed');
      expect(DEFAULT_OAUTH_SCOPE).assertEqual('user,repo,gist,notifications,read:org,workflow');

      const url: string = OauthService.buildAuthorizeUrl('CLIENT123');
      expect(url.indexOf(`redirect_uri=${encodeURIComponent(DEFAULT_OAUTH_REDIRECT_URI)}`) >= 0).assertTrue();
      expect(url.indexOf(`scope=${encodeURIComponent(DEFAULT_OAUTH_SCOPE)}`) >= 0).assertTrue();

      const legacyUrl: string = Address.getAuthorizationWeb('CLIENT123');
      expect(legacyUrl.indexOf('redirect_uri=gsygithubapp://authed') >= 0).assertTrue();
      expect(legacyUrl.indexOf('scope=user,repo,gist,notifications,read:org,workflow') >= 0).assertTrue();
    });

    it('build_authorize_url_uses_defaults_when_missing', 0, (): void => {
      OauthService.resetState();
      const url: string = OauthService.buildAuthorizeUrl('cid');
      expect(url.indexOf('client_id=cid') >= 0).assertTrue();
      const encodedRedirect: string = encodeURIComponent(DEFAULT_OAUTH_REDIRECT_URI);
      expect(url.indexOf(`redirect_uri=${encodedRedirect}`) >= 0).assertTrue();
      const encodedScope: string = encodeURIComponent(DEFAULT_OAUTH_SCOPE);
      expect(url.indexOf(`scope=${encodedScope}`) >= 0).assertTrue();
      const last: string = OauthService.getLastState();
      expect(last.length === 16).assertTrue();
      expect(url.indexOf(`state=${last}`) >= 0).assertTrue();
    });

    it('generate_state_returns_16_chars_and_unique', 0, (): void => {
      const a: string = OauthService.generateState();
      const b: string = OauthService.generateState();
      expect(a.length === 16).assertTrue();
      expect(b.length === 16).assertTrue();
      const re: RegExp = /^[a-zA-Z0-9]+$/;
      expect(re.test(a)).assertTrue();
      expect(re.test(b)).assertTrue();
      expect(a !== b).assertTrue();
    });

    it('validate_state_only_accepts_last_generated', 0, (): void => {
      const s: string = OauthService.generateState();
      expect(OauthService.validateState(s)).assertTrue();
      expect(OauthService.validateState('other')).assertFalse();
      expect(OauthService.validateState('')).assertFalse();
    });

    it('validate_state_returns_false_when_no_state_generated', 0, (): void => {
      OauthService.resetState();
      expect(OauthService.validateState('whatever')).assertFalse();
    });

    it('exchange_oauth_code_pass_through_to_use_case', 0, async (): Promise<void> => {
      provider.enqueue('GET', 'login/oauth/access_token',
        new ScriptedResponse(SUCCESS, '{"access_token":"oauth_tk_ok"}'));
      provider.enqueue('GET', '/user', new ScriptedResponse(SUCCESS, USER_JSON));

      const res: LoginOutcome = await OauthService.exchangeOAuthCode('the_code');

      expect(res.result).assertTrue();
      expect(provider.countByUrlContains('GET', 'login/oauth/access_token') === 1).assertTrue();
      const tokenCall: CapturedRequest = provider.captured[0];
      expect(tokenCall.url.indexOf('code=the_code') >= 0).assertTrue();
      expect(tokenCall.url.indexOf('client_id=cid') >= 0).assertTrue();
      expect(tokenCall.url.indexOf('client_secret=csec') >= 0).assertTrue();
      expect(loginExpiredCount).assertEqual(0);
    });

    it('exchange_oauth_code_401_emits_login_expired_bus', 0, async (): Promise<void> => {
      provider.enqueue('GET', 'login/oauth/access_token',
        new ScriptedResponse(UNAUTHORIZED, '{"message":"bad"}'));

      const res: LoginOutcome = await OauthService.exchangeOAuthCode('the_code');

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(loginExpiredCount >= 1).assertTrue();
    });

    it('exchange_oauth_code_empty_short_circuits', 0, async (): Promise<void> => {
      const res: LoginOutcome = await OauthService.exchangeOAuthCode('   ');
      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(provider.captured.length).assertEqual(0);
    });

    it('invalid_state_is_rejected_before_exchange', 0, async (): Promise<void> => {
      OauthService.generateState();
      const ok: boolean = OauthService.validateState('not_the_one');
      expect(ok).assertFalse();
      expect(provider.captured.length).assertEqual(0);
    });

    it('pending_deeplink_exchange_is_consumed_once', 0, async (): Promise<void> => {
      provider.enqueue('GET', 'login/oauth/access_token',
        new ScriptedResponse(SUCCESS, '{"access_token":"pending_tk"}'));
      provider.enqueue('GET', '/user', new ScriptedResponse(SUCCESS, USER_JSON));

      AuthDeepLinkBus.publish('gsygithubapp://authed?code=pending_code');

      let delivered: number = 0;
      const exchanges: Promise<LoginOutcome>[] = [];
      const off: () => void = AuthDeepLinkBus.subscribe((uri: string): void => {
        delivered += 1;
        const code: string = Url.parseQuery(uri).get('code') || '';
        exchanges.push(OauthService.exchangeOAuthCode(code));
      });

      expect(delivered).assertEqual(1);
      expect(exchanges.length).assertEqual(1);
      const res: LoginOutcome = await exchanges[0];
      expect(res.result).assertTrue();
      expect(provider.countByUrlContains('GET', 'login/oauth/access_token')).assertEqual(1);
      expect(provider.captured[0].url.indexOf('code=pending_code') >= 0).assertTrue();
      off();
    });
  });

  describe('UrlUtil', (): void => {
    it('parse_query_handles_basic_pairs', 0, (): void => {
      const map: Map<string, string> = Url.parseQuery('a=1&b=hello%20world&c=');
      expect(map.get('a')).assertEqual('1');
      expect(map.get('b')).assertEqual('hello world');
      expect(map.get('c')).assertEqual('');
    });

    it('parse_query_handles_question_prefix_and_hash', 0, (): void => {
      const map: Map<string, string> = Url.parseQuery('?code=abc&state=xy#frag');
      expect(map.get('code')).assertEqual('abc');
      expect(map.get('state')).assertEqual('xy');
    });

    it('parse_query_empty_returns_empty_map', 0, (): void => {
      expect(Url.parseQuery('').size === 0).assertTrue();
    });

    it('build_query_encodes_keys_and_values', 0, (): void => {
      const params: Record<string, string> = {
        'redirect_uri': 'gsygithubapp://authed',
        'scope': DEFAULT_OAUTH_SCOPE,
      };
      const q: string = Url.buildQuery(params);
      expect(q.indexOf(`redirect_uri=${encodeURIComponent('gsygithubapp://authed')}`) >= 0).assertTrue();
      expect(q.indexOf(`scope=${encodeURIComponent(DEFAULT_OAUTH_SCOPE)}`) >= 0).assertTrue();
    });

    it('parse_deep_link_extracts_scheme_host_and_query', 0, (): void => {
      const info = Url.parseDeepLink('gsygithubapp://authed?code=ABC&state=xyz');
      expect(info.scheme).assertEqual('gsygithubapp');
      expect(info.host).assertEqual('authed');
      expect(info.query.get('code')).assertEqual('ABC');
      expect(info.query.get('state')).assertEqual('xyz');
    });

    it('parse_deep_link_with_path', 0, (): void => {
      const info = Url.parseDeepLink('gsygithubapp://authed/oauth?code=1');
      expect(info.host).assertEqual('authed');
      expect(info.path).assertEqual('/oauth');
      expect(info.query.get('code')).assertEqual('1');
    });

    it('parse_deep_link_invalid_returns_empty_fields', 0, (): void => {
      const info = Url.parseDeepLink('');
      expect(info.scheme).assertEqual('');
      expect(info.host).assertEqual('');
      expect(info.query.size === 0).assertTrue();
    });
  });
}
