import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const EMPTY_PAGE_PATH: string = 'pages/DynamicTabEmptyHostPage';
const LIST_PAGE_PATH: string = 'pages/DynamicTabListHostPage';

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

export default function DynamicUiTest(): void {
  describe('DynamicUiTest_Empty', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(EMPTY_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_dynamic_root', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const root: Component = await driver.findComponent(ON.id('tab_page_root_dynamic'));
      expect(root !== null).assertTrue();
    });

    it('should_render_pull_list_for_empty', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const list: Component = await driver.findComponent(ON.id('dynamic_pull_list'));
      expect(list !== null).assertTrue();
    });

    it('should_render_empty_state_when_no_data', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(600);
      const emptyRoot: Component = await driver.findComponent(ON.id('dynamic_empty_root'));
      expect(emptyRoot !== null).assertTrue();
    });

  });

  describe('DynamicUiTest_List', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(LIST_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_first_row_with_compose_event_item_shape', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(1000);
      const row0: Component = await driver.findComponent(ON.id('dynamic_row_0'));
      expect(row0 !== null).assertTrue();

      const actorText: Component = await driver.findComponent(ON.id('dynamic_row_0_user'));
      expect(actorText !== null).assertTrue();
      expect(await actorText.getText()).assertEqual('CarGuoUI');

      const targetText: Component = await driver.findComponent(ON.id('dynamic_row_0_target'));
      expect(targetText !== null).assertTrue();
      expect(await targetText.getText()).assertEqual('pushed to CarGuoUI/RepoZero');

      const timeText: Component = await driver.findComponent(ON.id('dynamic_row_0_time'));
      expect(timeText !== null).assertTrue();
      const timeValue: string = await timeText.getText();
      expect(timeValue.length > 0).assertTrue();
    });

    it('should_render_second_row_for_pagination_visual', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const row1: Component = await driver.findComponent(ON.id('dynamic_row_1'));
      expect(row1 !== null).assertTrue();
      const targetText: Component = await driver.findComponent(ON.id('dynamic_row_1_target'));
      expect(await targetText.getText()).assertEqual('started watching CarGuoUI/RepoOne');
    });
  });
}
