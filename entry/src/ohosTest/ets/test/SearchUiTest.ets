import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const SEARCH_PAGE_PATH: string = 'pages/SearchHostPage';

async function startSearchPage(): Promise<void> {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  await delegator.startAbility({
    bundleName: BUNDLE,
    abilityName: ABILITY,
    parameters: {
      targetPage: SEARCH_PAGE_PATH,
    },
  });
  const driver: Driver = Driver.create();
  await driver.delayMs(1500);
}

export default function SearchUiTest(): void {
  describe('SearchUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      await startSearchPage();
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_show_history_only_after_empty_input_focus', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(500);
      const root: Component = await driver.findComponent(ON.id('search_page_root'));
      expect(root !== null).assertTrue();

      const input: Component = await driver.findComponent(ON.id('search_input'));
      expect(input !== null).assertTrue();

      const repoButton: Component = await driver.findComponent(ON.id('search_type_repo_btn'));
      expect(repoButton !== null).assertTrue();
      const userButton: Component = await driver.findComponent(ON.id('search_type_user_btn'));
      expect(userButton !== null).assertTrue();

      await input.click();
      await driver.delayMs(500);
      const history: Component = await driver.findComponent(ON.id('search_history_list'));
      expect(history !== null).assertTrue();

      const historyRow: Component = await driver.findComponent(ON.id('search_history_row_0'));
      expect(historyRow !== null).assertTrue();
    });

    it('should_search_after_input_and_click_repo_button', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const input: Component = await driver.findComponent(ON.id('search_input'));
      await input.inputText('rxjava');
      await driver.delayMs(300);

      const clearIcon: Component = await driver.findComponent(ON.id('search_clear_icon'));
      expect(clearIcon !== null).assertTrue();

      const repoButton: Component = await driver.findComponent(ON.id('search_type_repo_btn'));
      await repoButton.click();
      await driver.delayMs(800);

      const list: Component = await driver.findComponent(ON.id('search_pull_list_repo'));
      expect(list !== null).assertTrue();

      const userButton: Component = await driver.findComponent(ON.id('search_type_user_btn'));
      expect(repoButton !== null).assertTrue();
      expect(userButton !== null).assertTrue();

      const row0: Component = await driver.findComponent(ON.id('search_repo_0'));
      expect(row0 !== null).assertTrue();
      const repoName: Component = await driver.findComponent(ON.id('search_repo_0_name'));
      expect(await repoName.getText()).assertEqual('CarGuoUI/GSYGithubApp');
      const repoOwner: Component = await driver.findComponent(ON.id('search_repo_0_owner_text'));
      expect(await repoOwner.getText()).assertEqual('CarGuoUI');
    });

    it('should_switch_to_user_segment_and_show_users', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const userButton: Component = await driver.findComponent(ON.id('search_type_user_btn'));
      await userButton.click();
      await driver.delayMs(800);

      const list: Component = await driver.findComponent(ON.id('search_pull_list_user'));
      expect(list !== null).assertTrue();
      const userRow: Component = await driver.findComponent(ON.id('search_user_0'));
      expect(userRow !== null).assertTrue();
      const userLogin: Component = await driver.findComponent(ON.id('search_user_0_login'));
      expect(await userLogin.getText()).assertEqual('CarGuo');
    });
  });
}
