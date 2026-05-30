/**
 * SafeAreaInsets —— 沉浸式布局下读取系统安全区（状态栏 / 底部手势条），
 * 通过 AppStorage 订阅给 ArkUI struct 用：
 *   @StorageProp(SAFE_AREA_TOP_KEY) safeTop: number = 0;
 *   @StorageProp(SAFE_AREA_BOTTOM_KEY) safeBottom: number = 0;
 *
 * 数据单位：vp（已转换，可直接用作 padding/height）
 *
 * 沉浸式开关在 [EntryAbility.onWindowStageCreate](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets) 调
 * `enableImmersive(windowStage)` 即可。
 */
import window from '@ohos.window';
import display from '@ohos.display';
import hilog from '@ohos.hilog';
import { GSYColor } from '../style/Theme';

const TAG: string = 'SafeAreaInsets';

export const SAFE_AREA_TOP_KEY: string = 'gsy_safe_area_top_vp';
export const SAFE_AREA_BOTTOM_KEY: string = 'gsy_safe_area_bottom_vp';

/**
 * 沉浸式 + 安全区初始化（HarmonyOS 6.x 光感 UI）。
 * - setWindowLayoutFullScreen(true)：内容延伸到 statusBar / navIndicator 区域
 * - setWindowSystemBarProperties：
 *   - statusBar 透明 + LightIcon=true（白字图标）—— AppBar 是深色 GitHub primary，需要白图标
 *   - navigationBar 透明 + LightIcon=false（深字图标）—— TabBar 是白底，需要黑图标
 * - 监听 avoidArea 变化，把 top / bottom 推给 AppStorage（vp）
 */
export async function enableImmersive(windowStage: window.WindowStage): Promise<void> {
  try {
    const win: window.Window = await windowStage.getMainWindow();
    await win.setWindowLayoutFullScreen(true);

    const sysBarProps: window.SystemBarProperties = {
      statusBarColor: GSYColor.transparent,
      navigationBarColor: GSYColor.transparent,
      isStatusBarLightIcon: true,
      isNavigationBarLightIcon: false,
      statusBarContentColor: GSYColor.white,
      navigationBarContentColor: GSYColor.primary,
    };
    await win.setWindowSystemBarProperties(sysBarProps);

    publishInsets(win);

    win.on('avoidAreaChange', (data: window.AvoidAreaOptions): void => {
      if (data.type === window.AvoidAreaType.TYPE_SYSTEM
        || data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        publishInsets(win);
      }
    });
  } catch (e) {
    hilog.error(0x0000, TAG, 'enableImmersive fail %{public}s', (e as Error).message);
  }
}

function publishInsets(win: window.Window): void {
  try {
    const sysArea: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    const navArea: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);

    const topPx: number = sysArea.topRect.height;
    const bottomPx: number = navArea.bottomRect.height;

    const dpInfo: display.Display = display.getDefaultDisplaySync();
    const density: number = dpInfo.densityPixels > 0 ? dpInfo.densityPixels : 1;

    const topVp: number = Math.round(topPx / density);
    const bottomVp: number = Math.round(bottomPx / density);

    AppStorage.setOrCreate<number>(SAFE_AREA_TOP_KEY, topVp);
    AppStorage.setOrCreate<number>(SAFE_AREA_BOTTOM_KEY, bottomVp);

    hilog.info(0x0000, TAG, 'insets top=%{public}dvp bottom=%{public}dvp', topVp, bottomVp);
  } catch (e) {
    hilog.error(0x0000, TAG, 'publishInsets fail %{public}s', (e as Error).message);
  }
}
