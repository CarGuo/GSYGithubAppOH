/**
 * 网络错误码与错误消息映射，对齐 RN 端
 * [netwrokCode.js](../../../../../../../reactnative/GSYGithubApp/app/net/netwrokCode.js)。
 *
 * 与 RN 不同：401 不再直接 reset 路由，而是让上层（HttpManager）发布
 * `LoginExpired` 事件，UI 层负责导航。本文件保持纯函数、无副作用，
 * 避免与 UI / 路由耦合，便于单测。
 */

export const NETWORK_ERROR: number = 1;
export const NETWORK_TIMEOUT: number = 2;
export const NETWORK_JSON_EXCEPTION: number = 3;

export const SUCCESS: number = 200;
export const CREATED: number = 201;
export const NO_CONTENT: number = 204;

export const UNAUTHORIZED: number = 401;
export const FORBIDDEN: number = 403;
export const NOT_FOUND: number = 404;
export const GONE: number = 410;

export class NetworkCode {
  static handleError(code: number, statusText: string | null): string {
    switch (code) {
      case UNAUTHORIZED:
        return '未授权或授权失败';
      case FORBIDDEN:
        return '403权限错误';
      case NOT_FOUND:
        return '404错误';
      case GONE:
        return '410错误';
      case NETWORK_TIMEOUT:
        return '网络请求超时';
      case NETWORK_ERROR:
        return '网络异常，请检查网络';
      case NETWORK_JSON_EXCEPTION:
        return '数据解析异常';
      default:
        if (statusText && statusText.length > 0) {
          return statusText;
        }
        return '未知错误';
    }
  }

  static isSuccess(code: number): boolean {
    return code === SUCCESS || code === CREATED || code === NO_CONTENT;
  }

  static isUnauthorized(code: number): boolean {
    return code === UNAUTHORIZED;
  }
}
