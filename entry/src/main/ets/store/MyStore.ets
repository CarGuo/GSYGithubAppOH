/**
 * MyStore —— "我的"页签的 UI 状态容器。
 *
 * 与 RN 端 [components/MyPage.js](../../../../../../../reactnative/GSYGithubApp/app/components/MyPage.js)
 * + [widget/BasePersonPage.js](../../../../../../../reactnative/GSYGithubApp/app/components/widget/BasePersonPage.js)
 * 中读取 `state.user.userInfo` 的语义对齐：
 *
 *  - user / loading / error 三个字段满足"刷新中 / 失败提示 / 渲染头像 + bio + 计数"
 *    的视图模型，等价 RN 端 `userActions.getUserInfo()` 的 redux 状态。
 *  - 通过 `syncFromAppStorage()` 主动从 [AuthStore](./AuthStore.ets) 写入的
 *    `auth.userInfo` 镜像反序列化出 `AuthUserInfo`，实现 "刷新登陆态后 My 页自动同步"
 *    的 RN connect 体验，但保持 store 自身可单测、不依赖 ArkUI 装饰器。
 *  - `@Observed` 让该实例可被 `@ObjectLink` / `@Prop` 在 MyTabPage 中直接订阅。
 */

import { AuthUserInfo, APP_STORAGE_KEY_USER_INFO } from './AuthStore';

@Observed
export class MyStore {
  user: AuthUserInfo | null = null;
  loading: boolean = false;
  error: string = '';

  reset(): void {
    this.user = null;
    this.loading = false;
    this.error = '';
  }

  startLoading(): void {
    this.loading = true;
    this.error = '';
  }

  finishLoading(): void {
    this.loading = false;
  }

  setError(message: string): void {
    this.error = message ? message : '';
    this.loading = false;
  }

  setUser(user: AuthUserInfo | null): void {
    this.user = user;
    this.loading = false;
    this.error = '';
  }

  applyRawUserInfo(raw: string): void {
    if (!raw || raw.length === 0) {
      this.user = null;
      return;
    }
    const parsed: AuthUserInfo | null = AuthUserInfo.fromJson(raw);
    if (parsed !== null) {
      this.user = parsed;
    }
  }

  syncFromAppStorage(): void {
    let raw: string | undefined = undefined;
    try {
      raw = AppStorage.get<string>(APP_STORAGE_KEY_USER_INFO);
    } catch (_e) {
      raw = undefined;
    }
    if (raw === undefined || raw === null || raw.length === 0) {
      return;
    }
    this.applyRawUserInfo(raw);
  }
}

export const GlobalMyStore: MyStore = new MyStore();
