import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/ReadHistoryHostPage';

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

export default function ReadHistoryUiTest(): void {
  describe('ReadHistoryUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(HOST_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_read_history_root_and_appbar', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(1200);
      const root: Component = await driver.findComponent(ON.id('read_history_root'));
      expect(root !== null).assertTrue();

      const appbar: Component = await driver.findComponent(ON.id('read_history_appbar'));
      expect(appbar !== null).assertTrue();
    });

    it('should_not_render_old_all_repo_user_tabs', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const tabRow: Component | null = await driver.findComponent(ON.id('read_history_tab_row'));
      expect(tabRow === null).assertTrue();
      const clearBtn: Component | null = await driver.findComponent(ON.id('read_history_clear'));
      expect(clearBtn === null).assertTrue();
    });

    it('should_render_pull_list_and_repo_rows_only', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const list: Component = await driver.findComponent(ON.id('read_history_pull_list'));
      expect(list !== null).assertTrue();

      const row0: Component = await driver.findComponent(ON.id('read_history_row_0'));
      const row1: Component = await driver.findComponent(ON.id('read_history_row_1'));
      expect(row0 !== null).assertTrue();
      expect(row1 !== null).assertTrue();

      const title0: Component = await driver.findComponent(ON.id('read_history_row_0_name'));
      expect(title0 !== null).assertTrue();
      expect(await title0.getText()).assertEqual('CarGuoUI/GSYGithubApp');
    });

    it('should_render_repo_payload_stats_like_compose_history', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const type0: Component = await driver.findComponent(ON.id('read_history_row_0_type'));
      expect(type0 !== null).assertTrue();
      expect(await type0.getText()).assertEqual('Kotlin');

      const star0: Component = await driver.findComponent(ON.id('read_history_row_0_star_text'));
      const fork0: Component = await driver.findComponent(ON.id('read_history_row_0_fork_text'));
      const watch0: Component = await driver.findComponent(ON.id('read_history_row_0_watch_text'));
      expect(star0 !== null).assertTrue();
      expect(fork0 !== null).assertTrue();
      expect(watch0 !== null).assertTrue();
      expect(await star0.getText()).assertEqual('12000');
      expect(await fork0.getText()).assertEqual('3000');
      expect(await watch0.getText()).assertEqual('12000');
    });

    it('should_navigate_to_repository_detail_when_repo_row_clicked', 0,
      async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const row0: Component = await driver.findComponent(ON.id('read_history_row_0'));
      expect(row0 !== null).assertTrue();
      await row0.click();
      await driver.delayMs(1500);

      const repoRoot: Component = await driver.findComponent(ON.id('repo_detail_root'));
      expect(repoRoot !== null).assertTrue();
    });
  });
}
