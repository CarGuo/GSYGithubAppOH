import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/ContributionHeatmapHostPage';

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

export default function ContributionHeatmapUiTest(): void {
  describe('ContributionHeatmapUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(HOST_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_contribution_heatmap_root', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const root: Component = await driver.findComponent(ON.id('contribution_heatmap_root'));
      expect(root !== null).assertTrue();
    });

    it('should_render_contribution_canvas', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(400);
      const canvas: Component = await driver.findComponent(ON.id('contribution_canvas'));
      expect(canvas !== null).assertTrue();
    });

    it('should_render_host_root_and_inner_heatmap', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const host: Component = await driver.findComponent(ON.id('contribution_host_root'));
      expect(host !== null).assertTrue();
      const inner: Component = await driver.findComponent(ON.id('host_contribution'));
      expect(inner !== null).assertTrue();
    });
  });
}
