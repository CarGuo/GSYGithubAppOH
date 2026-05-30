/**
 * NetworkMonitor —— 网络可达性单例。
 *
 * - 基于 [@ohos.net.connection](https://developer.huawei.com/consumer/cn/) 的
 *   `NetConnection` 句柄监听 `netAvailable` / `netLost` 回调，并把原始的鸿蒙
 *   事件归一化为 `boolean` 给上层（`true` = 在线，`false` = 离线）。
 * - 提供 `onChange(handler)` 让 UI 层（HomePage 等）订阅；返回 unsubscribe 函数。
 * - 暴露 `setProvider(...)` 方便单测注入 fake 实现，避免在未授权 CI 上访问
 *   真实网络栈。
 *
 * 注意：HarmonyOS 的 `connection.createNetConnection().register()` 调用需要
 *   `ohos.permission.GET_NETWORK_INFO`，这里通过 try/catch 防御性处理，未授权
 *   或 mock 环境下默认视为「在线」。
 */

import connection from '@ohos.net.connection';

export type NetworkChangeListener = (online: boolean) => void;

/**
 * 抽象的网络监视提供者。生产环境使用 `OhosNetworkProvider`，测试环境注入 mock。
 */
export interface NetworkProvider {
  start(onAvailable: () => void, onLost: () => void): void;
  stop(): void;
}

class OhosNetworkProvider implements NetworkProvider {
  private handle: connection.NetConnection | null = null;

  start(onAvailable: () => void, onLost: () => void): void {
    try {
      const handle: connection.NetConnection = connection.createNetConnection();
      handle.on('netAvailable', (): void => {
        onAvailable();
      });
      handle.on('netLost', (): void => {
        onLost();
      });
      handle.register((_err: Object): void => {
      });
      this.handle = handle;
    } catch (_e) {
      this.handle = null;
    }
  }

  stop(): void {
    if (this.handle === null) {
      return;
    }
    try {
      this.handle.unregister((_err: Object): void => {
      });
    } catch (_e) {
    }
    this.handle = null;
  }
}

class NetworkMonitorImpl {
  private listeners: Set<NetworkChangeListener> = new Set<NetworkChangeListener>();
  private provider: NetworkProvider = new OhosNetworkProvider();
  private online: boolean = true;
  private started: boolean = false;

  setProvider(provider: NetworkProvider | null): void {
    this.stop();
    this.provider = provider ? provider : new OhosNetworkProvider();
  }

  isOnline(): boolean {
    return this.online;
  }

  start(): void {
    if (this.started) {
      return;
    }
    this.started = true;
    this.provider.start((): void => {
      this.handleChange(true);
    }, (): void => {
      this.handleChange(false);
    });
  }

  stop(): void {
    if (!this.started) {
      return;
    }
    this.provider.stop();
    this.started = false;
  }

  onChange(handler: NetworkChangeListener): () => void {
    this.listeners.add(handler);
    if (!this.started) {
      this.start();
    }
    return (): void => {
      this.listeners.delete(handler);
    };
  }

  /**
   * 仅供测试 / 内部模拟使用：人工触发一次状态变化。
   */
  emit(online: boolean): void {
    this.handleChange(online);
  }

  clear(): void {
    this.listeners.clear();
    this.stop();
    this.online = true;
  }

  private handleChange(online: boolean): void {
    if (this.online === online) {
      return;
    }
    this.online = online;
    this.listeners.forEach((l): void => l(online));
  }
}

export const NetworkMonitor: NetworkMonitorImpl = new NetworkMonitorImpl();
export default NetworkMonitor;
