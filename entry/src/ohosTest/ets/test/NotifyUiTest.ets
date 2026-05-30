import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/NotifyHostPage';

async function startPage(targetPage: string): Promise<void> {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  await delegator.startAbility({
    bundleName: BUNDLE,
    abilityName: ABILITY,
    parameters: {
      targetPage: targetPage,
    },
  });
  const driver: Driver = Driver.create();
  await driver.delayMs(1500);
}

export default function NotifyUiTest(): void {
  describe('NotifyUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(HOST_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_notify_root_and_app_bar', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(1200);
      const root: Component = await driver.findComponent(ON.id('notify_root'));
      expect(root !== null).assertTrue();
      const appBar: Component = await driver.findComponent(ON.id('notify_app_bar'));
      expect(appBar !== null).assertTrue();
    });

    it('should_render_three_tabs', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const tabBar: Component = await driver.findComponent(ON.id('notify_tab_bar'));
      expect(tabBar !== null).assertTrue();
      const tab0: Component = await driver.findComponent(ON.id('notify_tab_0'));
      expect(tab0 !== null).assertTrue();
      const tab1: Component = await driver.findComponent(ON.id('notify_tab_1'));
      expect(tab1 !== null).assertTrue();
      const tab2: Component = await driver.findComponent(ON.id('notify_tab_2'));
      expect(tab2 !== null).assertTrue();
    });

    it('should_render_pull_list_and_first_row', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const list: Component = await driver.findComponent(ON.id('notify_pull_list'));
      expect(list !== null).assertTrue();

      const row0: Component = await driver.findComponent(ON.id('notify_row_0'));
      expect(row0 !== null).assertTrue();

      const title0: Component = await driver.findComponent(ON.id('notify_row_title_0'));
      expect(title0 !== null).assertTrue();
      expect(await title0.getText()).assertEqual('host-thread-zero');

      const repo0: Component = await driver.findComponent(ON.id('notify_row_repo_0'));
      expect(repo0 !== null).assertTrue();
      expect(await repo0.getText()).assertEqual('CarGuoUI/RepoZero');

      const time0: Component = await driver.findComponent(ON.id('notify_row_time_0'));
      expect(time0 !== null).assertTrue();
      const timeValue: string = await time0.getText();
      expect(timeValue.length > 0).assertTrue();
    });

    it('should_render_compose_status_text_for_unread_thread', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const status0: Component = await driver.findComponent(ON.id('notify_row_status_0'));
      expect(status0 !== null).assertTrue();
      const value: string = await status0.getText();
      expect(value.indexOf('Type') >= 0 || value.indexOf('类型') >= 0).assertTrue();
      expect(value.indexOf('Status') >= 0 || value.indexOf('状态') >= 0).assertTrue();
    });

    it('should_render_second_row', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const row1: Component = await driver.findComponent(ON.id('notify_row_1'));
      expect(row1 !== null).assertTrue();
      const title1: Component = await driver.findComponent(ON.id('notify_row_title_1'));
      expect(title1 !== null).assertTrue();
      expect(await title1.getText()).assertEqual('host-thread-one');
    });

    it('should_switch_segment_without_debug_counter_ui', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const tab1: Component = await driver.findComponent(ON.id('notify_tab_1'));
      await tab1.click();
      await driver.delayMs(900);

      const counter: Component | null = await driver.findComponent(ON.id('notify_refresh_count'));
      expect(counter === null).assertTrue();
      const list: Component = await driver.findComponent(ON.id('notify_pull_list'));
      expect(list !== null).assertTrue();
    });

    it('should_keep_page_available_when_press_mark_all_button', 0,
      async (): Promise<void> => {
        const driver: Driver = Driver.create();
        const markBtn: Component = await driver.findComponent(ON.id('appbar_action_r_done_all'));
        expect(markBtn !== null).assertTrue();
        await markBtn.click();
        await driver.delayMs(900);
        const root: Component = await driver.findComponent(ON.id('notify_root'));
        expect(root !== null).assertTrue();
      });
  });
}
