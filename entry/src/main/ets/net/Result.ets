/**
 * 统一的 HTTP 返回包装。结构对齐 RN 端 net/index.js 的 `{result, code, data, headers}`，
 * 上层调用者无需关心底层是否使用 @ohos.net.http 还是 mock provider。
 */

export type HttpHeaders = Record<string, string>;

export class HttpResult<T> {
  result: boolean;
  code: number;
  data: T | null;
  msg: string | null;
  headers: HttpHeaders | null;

  constructor(result: boolean,
              code: number,
              data: T | null,
              msg: string | null = null,
              headers: HttpHeaders | null = null) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.msg = msg;
    this.headers = headers;
  }

  static ok<T>(code: number, data: T, headers: HttpHeaders | null = null): HttpResult<T> {
    return new HttpResult<T>(true, code, data, null, headers);
  }

  static fail<T>(code: number, msg: string, data: T | null = null): HttpResult<T> {
    return new HttpResult<T>(false, code, data, msg, null);
  }
}

/**
 * 业务层统一返回包装。
 * 用于 service 层向页面层暴露的结果，附带 `fromCache` 标记以便 UI
 * 决定是否提示用户「使用缓存」或「网络异常」。
 *
 * 与 [HttpResult] 的关系：
 * - HttpResult 描述传输层结果（与 RN 端 net/index.js 对齐）。
 * - ApiResult 描述应用层结果，包含 fromCache 等业务语义字段。
 */
export class ApiResult<T> {
  result: boolean;
  code: number;
  data: T | null;
  fromCache: boolean;
  msg: string;

  constructor(result: boolean,
              code: number,
              data: T | null,
              fromCache: boolean,
              msg: string) {
    this.result = result;
    this.code = code;
    this.data = data;
    this.fromCache = fromCache;
    this.msg = msg;
  }

  static ok<T>(code: number, data: T, fromCache: boolean = false, msg: string = ''): ApiResult<T> {
    return new ApiResult<T>(true, code, data, fromCache, msg);
  }

  static fail<T>(code: number, msg: string, data: T | null = null, fromCache: boolean = false): ApiResult<T> {
    return new ApiResult<T>(false, code, data, fromCache, msg);
  }
}
