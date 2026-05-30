/**
 * RouteParamStore —— 统一路由参数旁路（替代散落的 BOOT_*_KEY）
 *
 * 背景：项目 [AppNavigator.routerMap](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/AppNavigator.ets#L51-L107)
 *      历史上把每个子页面外包了一层 `NavDestination(){...}`，造成 ArkUI 双层 NavDestination 嵌套，
 *      内层 `ctx.pathInfo.param` 在 push 时取不到（KI-029 / KI-042 / KI-045）。
 *      之前每个详情页各自维护一个 BOOT_<X>_KEY 旁路，散乱且容易漏。
 *
 * 设计：
 *   - NavigationService.push 时同步写 AppStorage('gsy_route_param_<RouteName>')，
 *     供子页 aboutToAppear 同步消费（一次性，读完即清）。
 *   - 仅作为「最近一次跳转参数」临时槽，不是状态管理；详情页拿到后立即应用到自身 @State，
 *     不留长期引用。
 *   - Key 按 RouteName 区分，多入口跳转互不串台。
 *
 * 与官方推荐的 `routerMap @Builder(name, _param)` 透传方案等价；本仓库选择 AppStorage 旁路
 * 是为了不必改动 25+ 个老页面 struct 入参签名。
 */
import { RouteName } from './Routes';

const ROUTE_PARAM_PREFIX: string = 'gsy_route_param_';

class RouteParamStoreImpl {
  /**
   * NavigationService.push 调用：写入 AppStorage，供子页 aboutToAppear 消费。
   */
  put(name: RouteName | string, param: Object | undefined): void {
    if (param === undefined || param === null) {
      AppStorage.delete(ROUTE_PARAM_PREFIX + String(name));
      return;
    }
    AppStorage.setOrCreate<Object>(ROUTE_PARAM_PREFIX + String(name), param);
  }

  /**
   * 详情页 aboutToAppear 调用：拿到参数并立即清除（避免下次跳转复用脏数据）。
   */
  consume(name: RouteName | string): Object | null {
    const key: string = ROUTE_PARAM_PREFIX + String(name);
    const v: Object | undefined = AppStorage.get<Object>(key);
    if (v === undefined || v === null) {
      return null;
    }
    AppStorage.delete(key);
    return v;
  }

  /**
   * 仅 peek 不清除——用于调试 / 异常时恢复。
   */
  peek(name: RouteName | string): Object | null {
    const v: Object | undefined = AppStorage.get<Object>(ROUTE_PARAM_PREFIX + String(name));
    return v !== undefined && v !== null ? v : null;
  }
}

export const RouteParamStore: RouteParamStoreImpl = new RouteParamStoreImpl();
