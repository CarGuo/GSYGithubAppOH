import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/PushDetailHostPage';

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

export default function PushDetailUiTest(): void {
  describe('PushDetailUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(HOST_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_push_detail_root_and_appbar', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(1500);
      const root: Component = await driver.findComponent(ON.id('push_detail_root'));
      expect(root !== null).assertTrue();
      const appbar: Component = await driver.findComponent(ON.id('push_detail_appbar'));
      expect(appbar !== null).assertTrue();
    });

    it('should_render_commit_card_with_message_and_author', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const card: Component = await driver.findComponent(ON.id('push_detail_commit_card'));
      expect(card !== null).assertTrue();
      const headerItem: Component = await driver.findComponent(ON.id('push_detail_header_list_item'));
      expect(headerItem !== null).assertTrue();

      const stats: Component = await driver.findComponent(ON.id('push_detail_stats_row'));
      expect(stats !== null).assertTrue();

      const message: Component = await driver.findComponent(ON.id('push_detail_message_text'));
      expect(message !== null).assertTrue();
      const messageText: string = await message.getText();
      expect(messageText.indexOf('host commit') >= 0).assertTrue();
    });

    it('should_render_commit_stats_row', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(500);
      const additions: Component = await driver.findComponent(ON.id('push_detail_additions_text'));
      expect(additions !== null).assertTrue();
      const additionsText: string = await additions.getText();
      expect(additionsText.indexOf('+18') >= 0).assertTrue();

      const deletions: Component = await driver.findComponent(ON.id('push_detail_deletions_text'));
      expect(deletions !== null).assertTrue();
      const deletionsText: string = await deletions.getText();
      expect(deletionsText.indexOf('-2') >= 0).assertTrue();

      const fileCount: Component = await driver.findComponent(ON.id('push_detail_file_count_text'));
      expect(fileCount !== null).assertTrue();
      const fileCountText: string = await fileCount.getText();
      expect(fileCountText.indexOf('20') >= 0).assertTrue();
    });

    it('should_render_first_file_row_with_filename_card', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(500);
      const filename: Component = await driver.findComponent(ON.id('push_detail_file_filename_0'));
      expect(filename !== null).assertTrue();
      const filenameText: string = await filename.getText();
      expect(filenameText.indexOf('README.md') >= 0).assertTrue();

      const card: Component = await driver.findComponent(ON.id('push_detail_file_card_0'));
      expect(card !== null).assertTrue();
    });

    it('should_render_second_file_row', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
      const filename: Component = await driver.findComponent(ON.id('push_detail_file_filename_1'));
      expect(filename !== null).assertTrue();
      const filenameText: string = await filename.getText();
      expect(filenameText.indexOf('index.ts') >= 0).assertTrue();

      const path: Component = await driver.findComponent(ON.id('push_detail_file_path_1'));
      expect(path !== null).assertTrue();
      const pathText: string = await path.getText();
      expect(pathText.indexOf('src') >= 0).assertTrue();
    });

    it('should_navigate_to_code_detail_after_clicking_file_row', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const row: Component = await driver.findComponent(ON.id('push_detail_file_row_0'));
      expect(row !== null).assertTrue();
      await row.click();
      await driver.delayMs(1200);
      const codeRoot: Component = await driver.findComponent(ON.id('code_detail_root'));
      expect(codeRoot !== null).assertTrue();
    });
  });
}
