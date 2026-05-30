/**
 * 简易事件总线 —— OAuth 深链回调（gsygithubapp://authed?code=...）唤起 App 后通知 LoginWebPage。
 * 与 RN 端 [LoginWebPage.js](../../../../../../../reactnative/GSYGithubApp/app/components/LoginWebPage.js) 的回调语义对齐。
 */
type Listener = (uri: string) => void;

class AuthDeepLinkBusImpl {
  private listeners: Set<Listener> = new Set<Listener>();
  private pending: string | null = null;

  subscribe(listener: Listener): () => void {
    this.listeners.add(listener);
    if (this.pending) {
      const uri: string = this.pending;
      this.pending = null;
      listener(uri);
    }
    return (): void => {
      this.listeners.delete(listener);
    };
  }

  publish(uri: string): void {
    if (this.listeners.size === 0) {
      this.pending = uri;
      return;
    }
    this.listeners.forEach((l): void => l(uri));
  }

  clearPendingForTest(): void {
    this.pending = null;
  }

  resetForTest(): void {
    this.listeners.clear();
    this.pending = null;
  }
}

export const AuthDeepLinkBus: AuthDeepLinkBusImpl = new AuthDeepLinkBusImpl();
