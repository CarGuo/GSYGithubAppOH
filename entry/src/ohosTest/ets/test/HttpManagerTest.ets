/**
 * HttpManager 单测：完全使用 mock provider 注入，不发起真实网络请求，
 * 覆盖以下关键行为（与 RN 端 net/index.js 对齐 + 鸿蒙特化）：
 *
 *  1. GET 200 正常返回 JSON，header 透传。
 *  2. UA 与 Authorization 自动注入。
 *  3. 401 时清空持久化 token + 派发 LoginExpired 事件。
 *  4. 15s 超时映射为 NETWORK_TIMEOUT 码。
 *  5. mock provider 注入后默认实现不会被调用（隔离副作用）。
 *  6. POST + json=true 时 Content-Type=application/json 并序列化 body。
 *  7. 201 + token 字段时自动写入持久化（token 前缀）。
 */

import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
  TokenStorage,
  LoginExpiredBus,
  DEFAULT_USER_AGENT,
  CONTENT_TYPE_JSON,
  CONTENT_TYPE_FORM,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { NETWORK_TIMEOUT, UNAUTHORIZED, SUCCESS, CREATED } from '../../../main/ets/net/NetworkCode';

class CapturedRequest {
  url: string = '';
  method: string = '';
  headers: HttpHeaders = {};
  body: string | null = null;
  timeoutMs: number = 0;
}

class FakeProvider implements HttpProvider {
  nextStatus: number = SUCCESS;
  nextBody: string = '{}';
  nextHeaders: HttpHeaders = {};
  delayMs: number = 0;
  shouldThrow: boolean = false;
  captured: CapturedRequest = new CapturedRequest();
  callCount: number = 0;

  async request(url: string,
                method: string,
                headers: HttpHeaders,
                body: string | null,
                timeoutMs: number): Promise<RawResponse> {
    this.callCount += 1;
    this.captured.url = url;
    this.captured.method = method;
    this.captured.headers = headers;
    this.captured.body = body;
    this.captured.timeoutMs = timeoutMs;

    if (this.shouldThrow) {
      throw new Error('boom');
    }
    if (this.delayMs > 0) {
      await new Promise<void>((resolve): void => {
        setTimeout((): void => resolve(), this.delayMs);
      });
    }
    return new RawResponse(this.nextStatus, this.nextBody, this.nextHeaders);
  }
}

class FakeTokenStorage implements TokenStorage {
  value: string | null = null;
  saveCount: number = 0;
  clearCount: number = 0;

  async load(): Promise<string | null> {
    return this.value;
  }

  async save(token: string): Promise<void> {
    this.value = token;
    this.saveCount += 1;
  }

  async clear(): Promise<void> {
    this.value = null;
    this.clearCount += 1;
  }
}

export default function HttpManagerTest(): void {
  describe('HttpManagerTest', (): void => {
    let provider: FakeProvider;
    let storage: FakeTokenStorage;

    beforeEach((): void => {
      provider = new FakeProvider();
      storage = new FakeTokenStorage();
      HttpManager.setMockProvider(provider);
      HttpManager.setTokenStorage(storage);
      HttpManager.setTimeout(15000);
      HttpManager.setUserAgent(DEFAULT_USER_AGENT);
      HttpManager.setAuthorization(null);
      LoginExpiredBus.clear();
    });

    afterEach((): void => {
      HttpManager.setMockProvider(null);
      LoginExpiredBus.clear();
    });

    it('get_200_returns_parsed_json_with_headers', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = '{"login":"guoshuyu","id":1}';
      provider.nextHeaders = { 'X-RateLimit-Remaining': '4999' };

      const res = await HttpManager.getFetch<Record<string, Object>>('https://api.github.com/user');

      expect(res.result).assertTrue();
      expect(res.code).assertEqual(SUCCESS);
      expect(res.data !== null).assertTrue();
      const data: Record<string, Object> = res.data as Record<string, Object>;
      expect(data['login'] as string).assertEqual('guoshuyu');
      expect(res.headers !== null).assertTrue();
      const headers: HttpHeaders = res.headers as HttpHeaders;
      expect(headers['X-RateLimit-Remaining']).assertEqual('4999');
      expect(provider.callCount).assertEqual(1);
    });

    it('injects_user_agent_and_authorization_header', 0, async (): Promise<void> => {
      HttpManager.setUserAgent('GSYGithubAppOH/Test');
      HttpManager.setAuthorization('token abc123');
      provider.nextStatus = SUCCESS;
      provider.nextBody = '{}';

      await HttpManager.getFetch<Object>('https://api.github.com/user');

      expect(provider.captured.headers['User-Agent']).assertEqual('GSYGithubAppOH/Test');
      expect(provider.captured.headers['Authorization']).assertEqual('token abc123');
      expect(provider.captured.headers['Accept']).assertEqual(CONTENT_TYPE_JSON);
    });

    it('loads_authorization_from_storage_when_memory_empty', 0, async (): Promise<void> => {
      storage.value = 'Basic dXNlcjpwYXNz';
      provider.nextStatus = SUCCESS;
      provider.nextBody = '{}';

      await HttpManager.getFetch<Object>('https://api.github.com/user');

      expect(provider.captured.headers['Authorization']).assertEqual('Basic dXNlcjpwYXNz');
    });

    it('on_401_clears_token_and_publishes_login_expired', 0, async (): Promise<void> => {
      HttpManager.setAuthorization('token expired');
      storage.value = 'token expired';
      let fired: number = 0;
      LoginExpiredBus.subscribe((): void => {
        fired += 1;
      });
      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '{"message":"Bad credentials"}';

      const res = await HttpManager.getFetch<Object>('https://api.github.com/user');

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(fired).assertEqual(1);
      expect(storage.value).assertNull();
      expect(storage.clearCount >= 1).assertTrue();
      expect(HttpManager.getAuthorizationInMemory()).assertNull();
    });

    it('timeout_maps_to_network_timeout_code', 0, async (): Promise<void> => {
      HttpManager.setTimeout(50);
      provider.delayMs = 200;
      provider.nextStatus = SUCCESS;

      const res = await HttpManager.getFetch<Object>('https://api.github.com/slow');

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(NETWORK_TIMEOUT);
    });

    it('mock_provider_isolates_default_implementation', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = '{"ok":true}';

      await HttpManager.getFetch<Object>('https://api.github.com/anything');

      expect(provider.callCount).assertEqual(1);
      expect(provider.captured.url).assertEqual('https://api.github.com/anything');
      expect(provider.captured.method).assertEqual('GET');
    });

    it('post_json_sends_json_content_type_and_serialized_body', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = '{}';
      const params: Record<string, Object> = { 'name': 'gsy', 'age': 18 };

      await HttpManager.netFetch<Object>('https://api.github.com/echo', 'POST', params, true, null);

      expect(provider.captured.method).assertEqual('POST');
      expect(provider.captured.headers['Content-Type']).assertEqual(CONTENT_TYPE_JSON);
      expect(provider.captured.body !== null).assertTrue();
      const sent: Record<string, Object> = JSON.parse(provider.captured.body as string) as Record<string, Object>;
      expect(sent['name'] as string).assertEqual('gsy');
    });

    it('post_form_sends_urlencoded_body', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = '{}';
      const params: Record<string, Object> = { 'a': '1', 'b': 'hello world' };

      await HttpManager.netFetch<Object>('https://api.github.com/echo', 'POST', params, false, null);

      expect(provider.captured.headers['Content-Type']).assertEqual(CONTENT_TYPE_FORM);
      const body: string = provider.captured.body as string;
      expect(body.indexOf('a=1') >= 0).assertTrue();
      expect(body.indexOf('b=hello%20world') >= 0).assertTrue();
    });

    it('on_201_with_token_field_persists_token_with_token_prefix', 0, async (): Promise<void> => {
      provider.nextStatus = CREATED;
      provider.nextBody = '{"token":"newtoken"}';

      const res = await HttpManager.netFetch<Object>(
        'https://api.github.com/authorizations', 'POST', { 'scopes': 'repo' }, true, null);

      expect(res.result).assertTrue();
      expect(res.code).assertEqual(CREATED);
      expect(storage.value).assertEqual('token newtoken');
      expect(HttpManager.getAuthorizationInMemory()).assertEqual('token newtoken');
    });

    it('extra_header_overrides_and_merges_with_defaults', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = '{}';
      const extra: HttpHeaders = { 'X-Trace-Id': 'abc', 'Accept': 'application/vnd.github.v3+json' };

      await HttpManager.getFetch<Object>('https://api.github.com/x', extra);

      expect(provider.captured.headers['X-Trace-Id']).assertEqual('abc');
      expect(provider.captured.headers['Accept']).assertEqual('application/vnd.github.v3+json');
      expect(provider.captured.headers['User-Agent']).assertEqual(DEFAULT_USER_AGENT);
    });
  });
}
