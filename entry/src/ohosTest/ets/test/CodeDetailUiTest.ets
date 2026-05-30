import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/CodeDetailHostPage';

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

export default function CodeDetailUiTest(): void {
  describe('CodeDetailUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(HOST_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_code_detail_root_and_appbar', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(1200);
      const root: Component = await driver.findComponent(ON.id('code_detail_root'));
      expect(root !== null).assertTrue();
      const appbar: Component = await driver.findComponent(ON.id('code_detail_appbar'));
      expect(appbar !== null).assertTrue();
    });

    it('should_show_filename_only_in_appbar_title', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const title: Component = await driver.findComponent(ON.id('code_detail_title_text'));
      expect(title !== null).assertTrue();
      const text: string = await title.getText();
      expect(text).assertEqual('README.md');
    });

    it('should_render_code_detail_web_when_html_loaded', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(1500);
      const web: Component = await driver.findComponent(ON.id('code_detail_web'));
      expect(web !== null).assertTrue();
    });
  });
}
