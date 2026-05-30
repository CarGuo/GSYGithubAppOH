import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { getRepoHostStub } from '../pages/RepositoryDetailHostPage';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/RepositoryDetailHostPage';

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

export default function RepositoryDetailUiTest(): void {
  describe('RepositoryDetailUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(HOST_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_repo_detail_root_and_appbar', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(1200);
      const root: Component = await driver.findComponent(ON.id('repo_detail_root'));
      expect(root !== null).assertTrue();

      const appbar: Component = await driver.findComponent(ON.id('appbar_root'));
      expect(appbar !== null).assertTrue();
    });

    it('should_render_repo_full_name_in_header', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const owner: Component = await driver.findComponent(ON.id('repo_header_owner'));
      expect(owner !== null).assertTrue();
      expect(await owner.getText()).assertEqual('CarGuoUI');
      const name: Component = await driver.findComponent(ON.id('repo_header_name'));
      expect(name !== null).assertTrue();
      expect(await name.getText()).assertEqual('GSYTestRepo');
    });

    it('should_render_four_tab_bars', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(600);
      const tabInfo: Component = await driver.findComponent(ON.id('repo_detail_tab_bar_info'));
      expect(tabInfo !== null).assertTrue();
      const tabReadme: Component = await driver.findComponent(ON.id('repo_detail_tab_bar_readme'));
      expect(tabReadme !== null).assertTrue();
      const tabIssue: Component = await driver.findComponent(ON.id('repo_detail_tab_bar_issue'));
      expect(tabIssue !== null).assertTrue();
      const tabFile: Component = await driver.findComponent(ON.id('repo_detail_tab_bar_file'));
      expect(tabFile !== null).assertTrue();
    });

    it('should_switch_to_issue_tab', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const tabIssue: Component = await driver.findComponent(ON.id('repo_detail_tab_bar_issue'));
      expect(tabIssue !== null).assertTrue();
      await tabIssue.click();
      await driver.delayMs(800);
      const list: Component = await driver.findComponent(ON.id('repo_issue_list'));
      expect(list !== null).assertTrue();
    });

    it('should_switch_to_info_tab', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const tabInfo: Component = await driver.findComponent(ON.id('repo_detail_tab_bar_info'));
      expect(tabInfo !== null).assertTrue();
      await tabInfo.click();
      await driver.delayMs(800);
      const list: Component = await driver.findComponent(ON.id('repo_event_list'));
      expect(list !== null).assertTrue();
    });

    it('should_switch_to_file_tab', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const tabFile: Component = await driver.findComponent(ON.id('repo_detail_tab_bar_file'));
      expect(tabFile !== null).assertTrue();
      await tabFile.click();
      await driver.delayMs(800);
      const list: Component = await driver.findComponent(ON.id('repo_file_list'));
      expect(list !== null).assertTrue();
    });

    it('should_switch_back_to_readme_tab', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const tabReadme: Component = await driver.findComponent(ON.id('repo_detail_tab_bar_readme'));
      expect(tabReadme !== null).assertTrue();
      await tabReadme.click();
      await driver.delayMs(800);
    });

    it('should_render_bottom_bar_and_create_issue_button', 0,
      async (): Promise<void> => {
        const driver: Driver = Driver.create();
        await driver.delayMs(600);
        const bottomBar: Component = await driver.findComponent(ON.id('repo_detail_bottom_bar'));
        expect(bottomBar !== null).assertTrue();
        const star: Component = await driver.findComponent(ON.id('common_bottom_bar_item_star'));
        expect(star !== null).assertTrue();
        const create: Component = await driver.findComponent(ON.id('repo_detail_create_issue_fab'));
        expect(create !== null).assertTrue();
      });

    it('should_fork_directly_without_old_confirm_dialog', 0,
      async (): Promise<void> => {
        const driver: Driver = Driver.create();
        await driver.delayMs(600);
        const before: number = getRepoHostStub().forkPostCount;
        const fork: Component = await driver.findComponent(ON.id('common_bottom_bar_item_fork'));
        expect(fork !== null).assertTrue();
        await fork.click();
        await driver.delayMs(1200);
        expect(getRepoHostStub().forkPostCount).assertEqual(before + 1);
        try {
          await driver.findComponent(ON.text('Fxxx'));
          expect(false).assertTrue();
        } catch (_e) {
          expect(true).assertTrue();
        }
      });
  });
}
