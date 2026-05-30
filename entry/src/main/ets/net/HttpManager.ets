/**
 * HTTP 请求门面，对齐 RN 端
 * [net/index.js](../../../../../../../reactnative/GSYGithubApp/app/net/index.js)
 * 但适配 ArkTS / 鸿蒙：
 *
 * - 默认底层基于 `@ohos.net.http`，超时 15s（connect/read 双侧均 15s + Promise 超时兜底）。
 * - 401 时清空内存 token + 持久化 token，并通过 `LoginExpiredBus` 派发
 *   `LoginExpired` 事件，由 UI 层（如 LoginPage）订阅做跳转。
 * - 自动注入 `Authorization`（Basic / token …）与 `User-Agent`（GitHub API
 *   要求每个请求必须带 UA，否则会 403）。
 * - 通过 `setMockProvider(...)` 注入 mock 实现，便于单测与离线开发，
 *   生产代码与 mock 路径走同一套结果归一化逻辑，避免行为漂移。
 */

import http from '@ohos.net.http';
import { HttpResult, HttpHeaders } from './Result';
import {
  NetworkCode,
  NETWORK_ERROR,
  NETWORK_TIMEOUT,
  NETWORK_JSON_EXCEPTION,
  SUCCESS,
  CREATED,
  NO_CONTENT,
  UNAUTHORIZED,
} from './NetworkCode';

export const CONTENT_TYPE_JSON: string = 'application/json';
export const CONTENT_TYPE_FORM: string = 'application/x-www-form-urlencoded';
export const DEFAULT_TIMEOUT_MS: number = 15000;
export const DEFAULT_USER_AGENT: string = 'GSYGithubAppOH';

export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';

/**
 * 底层网络请求结果（已脱敏到与具体 http 栈无关的形态）。
 */
export class RawResponse {
  status: number;
  body: string;
  headers: HttpHeaders;

  constructor(status: number, body: string, headers: HttpHeaders) {
    this.status = status;
    this.body = body;
    this.headers = headers;
  }
}

/**
 * 抽象的请求执行器。生产环境使用 `OhosHttpProvider`，测试环境注入 mock。
 */
export interface HttpProvider {
  request(url: string,
          method: HttpMethod,
          headers: HttpHeaders,
          body: string | null,
          timeoutMs: number): Promise<RawResponse>;
}

/**
 * Token 持久化抽象。生产环境可由 preferences 实现并在 App 启动时注入；
 * 默认内存实现保证 HttpManager 在未注入时仍能工作，且单测无需 Context。
 */
export interface TokenStorage {
  load(): Promise<string | null>;
  save(token: string): Promise<void>;
  clear(): Promise<void>;
}

class MemoryTokenStorage implements TokenStorage {
  private token: string | null = null;

  async load(): Promise<string | null> {
    return this.token;
  }

  async save(token: string): Promise<void> {
    this.token = token;
  }

  async clear(): Promise<void> {
    this.token = null;
  }
}

/**
 * 登录过期事件总线。与 [AuthDeepLinkBus](../auth/AuthDeepLinkBus.ets) 同风格，
 * 让 UI 层订阅 `LoginExpired` 事件后跳转到 LoginPage。
 */
type LoginExpiredListener = () => void;

class LoginExpiredBusImpl {
  private listeners: Set<LoginExpiredListener> = new Set<LoginExpiredListener>();

  subscribe(listener: LoginExpiredListener): () => void {
    this.listeners.add(listener);
    return (): void => {
      this.listeners.delete(listener);
    };
  }

  publish(): void {
    this.listeners.forEach((l): void => l());
  }

  clear(): void {
    this.listeners.clear();
  }
}

export const LoginExpiredBus: LoginExpiredBusImpl = new LoginExpiredBusImpl();
export const LOGIN_EXPIRED_EVENT: string = 'LoginExpired';

/**
 * 默认基于 @ohos.net.http 的实现。
 */
class OhosHttpProvider implements HttpProvider {
  async request(url: string,
                method: HttpMethod,
                headers: HttpHeaders,
                body: string | null,
                timeoutMs: number): Promise<RawResponse> {
    const httpRequest: http.HttpRequest = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: OhosHttpProvider.toRequestMethod(method),
        header: headers,
        extraData: body === null ? undefined : body,
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs,
        expectDataType: http.HttpDataType.STRING,
      };
      const resp: http.HttpResponse = await httpRequest.request(url, options);
      const respBody: string = typeof resp.result === 'string' ? resp.result as string : JSON.stringify(resp.result);
      const respHeaders: HttpHeaders = OhosHttpProvider.normalizeHeaders(resp.header);
      return new RawResponse(resp.responseCode, respBody, respHeaders);
    } finally {
      httpRequest.destroy();
    }
  }

  private static toRequestMethod(method: HttpMethod): http.RequestMethod {
    switch (method) {
      case 'GET':
        return http.RequestMethod.GET;
      case 'POST':
        return http.RequestMethod.POST;
      case 'PUT':
        return http.RequestMethod.PUT;
      case 'PATCH':
        return 'PATCH' as http.RequestMethod;
      case 'DELETE':
        return http.RequestMethod.DELETE;
      default:
        return http.RequestMethod.GET;
    }
  }

  private static normalizeHeaders(raw: Object): HttpHeaders {
    const out: HttpHeaders = {};
    if (!raw) {
      return out;
    }
    const obj: Record<string, Object> = raw as Record<string, Object>;
    const keys: string[] = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      const k: string = keys[i];
      const v: Object = obj[k];
      out[k] = typeof v === 'string' ? v as string : String(v);
    }
    return out;
  }
}

class HttpManagerImpl {
  private provider: HttpProvider = new OhosHttpProvider();
  private tokenStorage: TokenStorage = new MemoryTokenStorage();
  private timeoutMs: number = DEFAULT_TIMEOUT_MS;
  private userAgent: string = DEFAULT_USER_AGENT;
  private authorizationCode: string | null = null;

  setMockProvider(provider: HttpProvider | null): void {
    this.provider = provider ? provider : new OhosHttpProvider();
  }

  setTokenStorage(storage: TokenStorage): void {
    this.tokenStorage = storage;
  }

  setTimeout(ms: number): void {
    this.timeoutMs = ms > 0 ? ms : DEFAULT_TIMEOUT_MS;
  }

  setUserAgent(ua: string): void {
    if (ua && ua.length > 0) {
      this.userAgent = ua;
    }
  }

  setAuthorization(code: string | null): void {
    this.authorizationCode = code;
  }

  getAuthorizationInMemory(): string | null {
    return this.authorizationCode;
  }

  async loadAuthorization(): Promise<string | null> {
    if (this.authorizationCode) {
      return this.authorizationCode;
    }
    const cached: string | null = await this.tokenStorage.load();
    if (cached) {
      this.authorizationCode = cached;
    }
    return this.authorizationCode;
  }

  async clearAuthorization(): Promise<void> {
    this.authorizationCode = null;
    await this.tokenStorage.clear();
  }

  async getFetch<T>(url: string, header: HttpHeaders | null = null): Promise<HttpResult<T>> {
    return this.netFetch<T>(url, 'GET', null, false, header);
  }

  async netFetch<T>(url: string,
                    method: HttpMethod = 'GET',
                    params: Record<string, Object> | null = null,
                    json: boolean = false,
                    header: HttpHeaders | null = null): Promise<HttpResult<T>> {
    const headers: HttpHeaders = {};
    headers['User-Agent'] = this.userAgent;
    headers['Accept'] = CONTENT_TYPE_JSON;

    if (header) {
      const keys: string[] = Object.keys(header);
      for (let i = 0; i < keys.length; i++) {
        headers[keys[i]] = header[keys[i]];
      }
    }

    const auth: string | null = await this.loadAuthorization();
    if (auth) {
      headers['Authorization'] = auth;
    }

    let body: string | null = null;
    if (method !== 'GET' && params) {
      if (json) {
        headers['Content-Type'] = CONTENT_TYPE_JSON;
        body = JSON.stringify(params);
      } else {
        headers['Content-Type'] = CONTENT_TYPE_FORM;
        body = HttpManagerImpl.encodeForm(params);
      }
    }

    let raw: RawResponse | null = null;
    try {
      raw = await this.requestWithTimeout(url, method, headers, body);
    } catch (e) {
      const msg: string = (e && (e as Error).message) ? (e as Error).message : 'network error';
      return HttpResult.fail<T>(NETWORK_ERROR, msg);
    }

    if (raw.status === NETWORK_TIMEOUT) {
      return HttpResult.fail<T>(NETWORK_TIMEOUT, NetworkCode.handleError(NETWORK_TIMEOUT, null));
    }

    if (raw.status === UNAUTHORIZED) {
      await this.clearAuthorization();
      LoginExpiredBus.publish();
      return HttpResult.fail<T>(UNAUTHORIZED, NetworkCode.handleError(UNAUTHORIZED, null));
    }

    if (raw.status === NO_CONTENT) {
      return HttpResult.ok<T>(raw.status, null as T, raw.headers);
    }

    if (raw.status === SUCCESS || raw.status === CREATED) {
      const parsed: T | null = HttpManagerImpl.tryParseJson<T>(raw.body);
      if (parsed === null && raw.body.length > 0) {
        return new HttpResult<T>(true, raw.status, raw.body as Object as T, null, raw.headers);
      }
      if (raw.status === CREATED && parsed !== null) {
        const tokenField: string | null = HttpManagerImpl.extractTokenField(parsed as Object);
        if (tokenField) {
          const newAuth: string = `token ${tokenField}`;
          this.authorizationCode = newAuth;
          await this.tokenStorage.save(newAuth);
        }
      }
      return HttpResult.ok<T>(raw.status, parsed as T, raw.headers);
    }

    return HttpResult.fail<T>(raw.status, NetworkCode.handleError(raw.status, raw.body));
  }

  private async requestWithTimeout(url: string,
                                   method: HttpMethod,
                                   headers: HttpHeaders,
                                   body: string | null): Promise<RawResponse> {
    const timeoutMs: number = this.timeoutMs;
    const provider: HttpProvider = this.provider;
    return new Promise<RawResponse>((resolve): void => {
      let settled: boolean = false;
      const timer = setTimeout((): void => {
        if (settled) {
          return;
        }
        settled = true;
        resolve(new RawResponse(NETWORK_TIMEOUT, '', {}));
      }, timeoutMs);
      provider.request(url, method, headers, body, timeoutMs).then((res: RawResponse): void => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(timer);
        resolve(res);
      }, (_err: Object): void => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(timer);
        resolve(new RawResponse(NETWORK_ERROR, '', {}));
      });
    });
  }

  private static encodeForm(params: Record<string, Object>): string {
    const parts: string[] = [];
    const keys: string[] = Object.keys(params);
    for (let i = 0; i < keys.length; i++) {
      const k: string = keys[i];
      const v: Object = params[k];
      parts.push(`${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`);
    }
    return parts.join('&');
  }

  private static tryParseJson<T>(body: string): T | null {
    if (!body || body.length === 0) {
      return null;
    }
    try {
      return JSON.parse(body) as T;
    } catch (_e) {
      return null;
    }
  }

  private static extractTokenField(parsed: Object): string | null {
    const obj: Record<string, Object> = parsed as Record<string, Object>;
    const v: Object | undefined = obj['token'];
    if (typeof v === 'string' && (v as string).length > 0) {
      return v as string;
    }
    return null;
  }
}

export const HttpManager: HttpManagerImpl = new HttpManagerImpl();
export default HttpManager;
