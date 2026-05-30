/**
 * NavigationService —— R7 Phase A 重写
 *
 * 设计说明（参考 [r7-rebuild-blueprint.md § 1.1](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/r7-rebuild-blueprint.md)）：
 *  - 全局唯一 NavPathStack，由 [AppNavigator.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/AppNavigator.ets)
 *    在 build 时通过 setStack 注入，所有页面共享。
 *  - 废弃 R6 时代的 page-level bind/unbind 机制（KI-020 crash 根因：
 *    detail page 销毁后 stack 悬空，HomePage 再 push 触发 `undefined is not callable`）。
 *  - 废弃 @ohos.router fallback：单根 Navigation 模型下 router.pushUrl 会
 *    打开新 ability 实例，与 NavPathStack 不在同一个上下文，会出现双栈。
 *
 * 对应 RN 端 [NavigationService.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/navigation/NavigationService.js)
 * 的语义：navigate / replace / pop / popTo / clear。
 */
import { RouteName } from './Routes';
import { RouteParamStore } from './RouteParamStore';
import hilog from '@ohos.hilog';
import router from '@ohos.router';

export interface NavRouteSnapshot {
  name: string;
  param: Object | null;
}

export interface RouterLike {
  pushUrl(options: router.RouterOptions): Promise<void>;
  replaceUrl(options: router.RouterOptions): Promise<void>;
  back(): void;
  clear(): void;
}

class NavigationServiceImpl {
  private stack: NavPathStack | null = null;
  private routerLike: RouterLike | null = null;
  private fallbackRoutes: NavRouteSnapshot[] = [];

  /**
   * 由 AppNavigator 在 Navigation(stack) 构造时调用一次，注入唯一 NavPathStack。
   * 不允许 page-level 反复 bind，只允许 AppNavigator 注入一次。
   */
  setStack(stack: NavPathStack): void {
    this.stack = stack;
  }

  setRouter(routerLike: RouterLike | null): void {
    this.routerLike = routerLike;
    this.fallbackRoutes = [];
  }

  getStack(): NavPathStack | null {
    return this.stack;
  }

  push(name: RouteName | string, param?: Object): void {
    const safeParam: Object = param !== undefined ? param : new Object();
    hilog.info(0x0666, 'NavigationService',
      'push name=%{public}s param=%{public}s',
      String(name), JSON.stringify(safeParam));
    // 与 routerMap 透传方案等效的旁路：避免双层 NavDestination 嵌套时内层 pathInfo.param 取不到。
    RouteParamStore.put(name, param);
    if (this.stack === null) {
      this.fallbackRoutes.push({ name: String(name), param: param !== undefined ? param : null });
      if (this.routerLike !== null) {
        this.routerLike.pushUrl({ url: this.routeToPageUrl(name), params: safeParam });
      }
      return;
    }
    const info: NavPathInfo = new NavPathInfo(name, safeParam);
    this.stack.pushPath(info);
  }

  replace(name: RouteName | string, param?: Object): void {
    const safeParam: Object = param !== undefined ? param : new Object();
    RouteParamStore.put(name, param);
    if (this.stack === null) {
      const next: NavRouteSnapshot = { name: String(name), param: param !== undefined ? param : null };
      if (this.fallbackRoutes.length > 0) {
        this.fallbackRoutes[this.fallbackRoutes.length - 1] = next;
      } else {
        this.fallbackRoutes.push(next);
      }
      if (this.routerLike !== null) {
        this.routerLike.replaceUrl({ url: this.routeToPageUrl(name), params: safeParam });
      }
      return;
    }
    const info: NavPathInfo = new NavPathInfo(name, safeParam);
    this.stack.replacePath(info);
  }

  pop(): void {
    if (this.stack === null) {
      if (this.fallbackRoutes.length > 0) {
        this.fallbackRoutes.pop();
      }
      if (this.routerLike !== null) {
        this.routerLike.back();
      }
      return;
    }
    this.stack.pop();
  }

  popTo(name: RouteName | string): void {
    if (this.stack === null) {
      for (let i: number = this.fallbackRoutes.length - 1; i >= 0; i--) {
        if (this.fallbackRoutes[i].name === String(name)) {
          this.fallbackRoutes = this.fallbackRoutes.slice(0, i + 1);
          return;
        }
      }
      return;
    }
    this.stack.popToName(name);
  }

  clear(): void {
    if (this.stack === null) {
      this.fallbackRoutes = [];
      if (this.routerLike !== null) {
        this.routerLike.clear();
      }
      return;
    }
    this.stack.clear();
  }

  size(): number {
    if (this.stack === null) {
      return this.fallbackRoutes.length;
    }
    const names: string[] = this.stack.getAllPathName();
    return names.length;
  }

  getAllPathName(): string[] {
    if (this.stack === null) {
      const names: string[] = [];
      for (let i: number = 0; i < this.fallbackRoutes.length; i++) {
        names.push(this.fallbackRoutes[i].name);
      }
      return names;
    }
    return this.stack.getAllPathName();
  }

  snapshot(): NavRouteSnapshot[] {
    if (this.stack === null) {
      const list: NavRouteSnapshot[] = [];
      for (let i: number = 0; i < this.fallbackRoutes.length; i++) {
        list.push({ name: this.fallbackRoutes[i].name, param: this.fallbackRoutes[i].param });
      }
      return list;
    }
    const names: string[] = this.stack.getAllPathName();
    const list: NavRouteSnapshot[] = [];
    for (let i: number = 0; i < names.length; i++) {
      const param: Object | undefined = this.stack.getParamByIndex(i) as Object | undefined;
      list.push({ name: names[i], param: param !== undefined ? param : null });
    }
    return list;
  }

  private routeToPageUrl(name: RouteName | string): string {
    return 'pages/' + String(name) + 'Page';
  }
}

export const NavigationService: NavigationServiceImpl = new NavigationServiceImpl();
