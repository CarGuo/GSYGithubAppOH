import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const LIST_PAGE_PATH: string = 'pages/TrendTabListHostPage';

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

export default function TrendUiTest(): void {
  describe('TrendUiTest_List', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(LIST_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_compose_trending_root_without_filters', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const root: Component = await driver.findComponent(ON.id('tab_page_root_trend'));
      expect(root !== null).assertTrue();
      const list: Component = await driver.findComponent(ON.id('trend_pull_list'));
      expect(list !== null).assertTrue();
    });

    it('should_render_first_row_with_full_name_and_meta', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(1000);
      const row0: Component = await driver.findComponent(ON.id('trend_row_0'));
      expect(row0 !== null).assertTrue();

      const fullText: Component = await driver.findComponent(ON.id('trend_row_full_0'));
      expect(fullText !== null).assertTrue();
      expect(await fullText.getText()).assertEqual('CarGuoUI/TrendDemoZero');

      const descText: Component = await driver.findComponent(ON.id('trend_row_desc_0'));
      expect(descText !== null).assertTrue();
      expect(await descText.getText()).assertEqual('Trend demo description zero');

      const starText: Component = await driver.findComponent(ON.id('trend_row_star_0'));
      expect(starText !== null).assertTrue();
      const starValue: string = await starText.getText();
      expect(starValue.indexOf('1234') >= 0).assertTrue();

      const langText: Component = await driver.findComponent(ON.id('trend_row_lang_0'));
      expect(langText !== null).assertTrue();
      expect(await langText.getText()).assertEqual('TypeScript');

      const forkText: Component = await driver.findComponent(ON.id('trend_row_fork_0'));
      expect(forkText !== null).assertTrue();
    });

    it('should_render_second_row', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const row1: Component = await driver.findComponent(ON.id('trend_row_1'));
      expect(row1 !== null).assertTrue();
      const fullText: Component = await driver.findComponent(ON.id('trend_row_full_1'));
      expect(await fullText.getText()).assertEqual('CarGuoUI/TrendDemoOne');
    });
  });
}
