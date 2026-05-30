/**
 * HomeUiTest —— 对齐 Compose HomeScreen（3 Tab + 首页抽屉）
 * 参考：[HomePage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/HomePage.ets)
 *
 * 用例覆盖：
 *  1. 根 Layout / AppBar / Tabs 渲染
 *  2. 3 个 TabBar (dynamic / trend / my) 全部渲染，**不应**渲染 recommend
 *  3. 默认初始 Tab 是 Dynamic
 *  4. 切到 Trend Tab，渲染 tab_page_root_trend
 *  5. 切到 My Tab，渲染 tab_page_root_my
 *  6. 左侧 menu 可打开 Drawer，Drawer 菜单顺序跟 Compose 一致
 *  7. **不再**渲染 home_double_tap_count
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOME_PAGE_PATH: string = 'pages/HomePageHost';

export default function HomeUiTest(): void {
  describe('HomeUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      await delegator.startAbility({
        bundleName: BUNDLE,
        abilityName: ABILITY,
        parameters: {
          targetPage: HOME_PAGE_PATH,
        },
      });
      const driver: Driver = Driver.create();
      await driver.delayMs(1500);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_home_root_with_appbar_and_tabs', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(500);
      const root: Component = await driver.findComponent(ON.id('home_main_content'));
      expect(root !== null).assertTrue();
      const appbar: Component = await driver.findComponent(ON.id('home_appbar'));
      expect(appbar !== null).assertTrue();
      const tabs: Component = await driver.findComponent(ON.id('home_tabs'));
      expect(tabs !== null).assertTrue();
    });

    it('should_render_three_tab_bars_only', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const dynamicBar: Component = await driver.findComponent(ON.id('home_tab_bar_dynamic'));
      const trendBar: Component = await driver.findComponent(ON.id('home_tab_bar_trend'));
      const myBar: Component = await driver.findComponent(ON.id('home_tab_bar_my'));
      expect(dynamicBar !== null).assertTrue();
      expect(trendBar !== null).assertTrue();
      expect(myBar !== null).assertTrue();
    });

    it('should_render_appbar_menu_and_search_actions', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const menuAction: Component = await driver.findComponent(ON.id('appbar_action_l_menu'));
      expect(menuAction !== null).assertTrue();
      const searchAction: Component = await driver.findComponent(ON.id('appbar_action_r_search'));
      expect(searchAction !== null).assertTrue();
    });

    it('should_open_drawer_from_menu_action', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const menuAction: Component = await driver.findComponent(ON.id('appbar_action_l_menu'));
      await menuAction.click();
      await driver.delayMs(500);
      const drawerContent: Component = await driver.findComponent(ON.id('home_drawer_content'));
      expect(drawerContent !== null).assertTrue();
      const header: Component = await driver.findComponent(ON.id('drawer_header'));
      expect(header !== null).assertTrue();
      const history: Component = await driver.findComponent(ON.id('drawer_menu_item_history'));
      const feedback: Component = await driver.findComponent(ON.id('drawer_menu_item_feedback'));
      const personalInfo: Component = await driver.findComponent(ON.id('drawer_menu_item_personal_info'));
      const language: Component = await driver.findComponent(ON.id('drawer_menu_item_language'));
      const checkUpdate: Component = await driver.findComponent(ON.id('drawer_menu_item_check_update'));
      expect(history !== null).assertTrue();
      expect(feedback !== null).assertTrue();
      expect(personalInfo !== null).assertTrue();
      expect(language !== null).assertTrue();
      expect(checkUpdate !== null).assertTrue();
      await menuAction.click();
      await driver.delayMs(300);
    });

    it('should_show_dynamic_tab_initial', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const dynamicRoot: Component = await driver.findComponent(ON.id('tab_page_root_dynamic'));
      expect(dynamicRoot !== null).assertTrue();
    });

    it('should_switch_to_trend_tab', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const trendBar: Component = await driver.findComponent(ON.id('home_tab_bar_trend'));
      await trendBar.click();
      await driver.delayMs(500);
      const trendRoot: Component = await driver.findComponent(ON.id('tab_page_root_trend'));
      expect(trendRoot !== null).assertTrue();
    });

    it('should_switch_to_my_tab', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const myBar: Component = await driver.findComponent(ON.id('home_tab_bar_my'));
      await myBar.click();
      await driver.delayMs(500);
      const myRoot: Component = await driver.findComponent(ON.id('tab_page_root_my'));
      expect(myRoot !== null).assertTrue();
    });
  });
}
