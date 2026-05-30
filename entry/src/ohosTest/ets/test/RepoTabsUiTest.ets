import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/RepoTabsHostPage';

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

export default function RepoTabsUiTest(): void {
  describe('RepoTabsUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(HOST_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_repo_issue_root_and_chips', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(1200);
      const list: Component = await driver.findComponent(ON.id('repo_issue_list'));
      expect(list !== null).assertTrue();
      const chipOpen: Component = await driver.findComponent(ON.id('repo_issue_chip_open'));
      expect(chipOpen !== null).assertTrue();
      const chipClosed: Component = await driver.findComponent(ON.id('repo_issue_chip_closed'));
      expect(chipClosed !== null).assertTrue();
      const chipAll: Component = await driver.findComponent(ON.id('repo_issue_chip_all'));
      expect(chipAll !== null).assertTrue();
      const searchInput: Component = await driver.findComponent(ON.id('repo_issue_search_input'));
      expect(searchInput !== null).assertTrue();
      const searchButton: Component = await driver.findComponent(ON.id('repo_issue_search_submit_btn'));
      expect(searchButton !== null).assertTrue();
    });

    it('should_render_first_issue_row_and_navigate_on_tap', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const row0: Component = await driver.findComponent(ON.id('repo_issue_row_0'));
      expect(row0 !== null).assertTrue();
      const icon: Component = await driver.findComponent(ON.id('repo_issue_row_icon_0'));
      expect(icon !== null).assertTrue();
      const title: Component = await driver.findComponent(ON.id('repo_issue_row_title_0'));
      expect(await title.getText()).assertEqual('#101 [all] tab issue 1');
      const body: Component = await driver.findComponent(ON.id('repo_issue_row_body_0'));
      expect(await body.getText()).assertEqual('Issue body from mock one');
      const openedBy: Component = await driver.findComponent(ON.id('repo_issue_row_opened_by_0'));
      expect((await openedBy.getText()).indexOf('CarGuoUI') >= 0).assertTrue();
      const date: Component = await driver.findComponent(ON.id('repo_issue_row_date_0'));
      expect(await date.getText()).assertEqual('2024-01-01');
      await row0.click();
      await driver.delayMs(800);
      const detail: Component = await driver.findComponent(ON.id('repo_tabs_host_issue_detail_text'));
      expect(detail !== null).assertTrue();
      await driver.pressBack();
      await driver.delayMs(500);
    });

    it('should_switch_to_closed_chip_and_keep_list', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(500);
      const chipClosed: Component = await driver.findComponent(ON.id('repo_issue_chip_closed'));
      expect(chipClosed !== null).assertTrue();
      await chipClosed.click();
      await driver.delayMs(800);
      const list: Component = await driver.findComponent(ON.id('repo_issue_list'));
      expect(list !== null).assertTrue();
      const row0: Component = await driver.findComponent(ON.id('repo_issue_row_0'));
      expect(row0 !== null).assertTrue();
    });

    it('should_update_issue_search_box_and_show_clear_icon', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(500);
      const input: Component = await driver.findComponent(ON.id('repo_issue_search_input'));
      expect(input !== null).assertTrue();
      await input.inputText('search');
      await driver.delayMs(300);
      const clearIcon: Component = await driver.findComponent(ON.id('repo_issue_search_clear_icon'));
      expect(clearIcon !== null).assertTrue();
    });

    it('should_switch_to_activity_tab_and_render_event_list', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(500);
      const tabActivity: Component = await driver.findComponent(ON.id('repo_tabs_host_tab_activity'));
      expect(tabActivity !== null).assertTrue();
      await tabActivity.click();
      await driver.delayMs(800);
      const list: Component = await driver.findComponent(ON.id('repo_event_list'));
      expect(list !== null).assertTrue();
      const row0: Component = await driver.findComponent(ON.id('repo_event_row_0'));
      expect(row0 !== null).assertTrue();
    });

    it('should_switch_to_commit_segment_and_open_push_detail', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(500);
      const tabActivity: Component = await driver.findComponent(ON.id('repo_tabs_host_tab_activity'));
      expect(tabActivity !== null).assertTrue();
      await tabActivity.click();
      await driver.delayMs(500);
      const pushSegment: Component = await driver.findComponent(ON.id('common_bottom_bar_item_push'));
      expect(pushSegment !== null).assertTrue();
      await pushSegment.click();
      await driver.delayMs(1000);
      const row0: Component = await driver.findComponent(ON.id('repo_commit_row_0'));
      expect(row0 !== null).assertTrue();
      const message: Component = await driver.findComponent(ON.id('repo_commit_row_0_message'));
      expect(message !== null).assertTrue();
      const author: Component = await driver.findComponent(ON.id('repo_commit_row_0_author'));
      expect(author !== null).assertTrue();
      const time: Component = await driver.findComponent(ON.id('repo_commit_row_0_time'));
      expect(time !== null).assertTrue();
      await row0.click();
      await driver.delayMs(800);
      const detail: Component = await driver.findComponent(ON.id('repo_tabs_host_push_detail_text'));
      expect(detail !== null).assertTrue();
      await driver.pressBack();
      await driver.delayMs(500);
    });

    it('should_switch_to_files_tab_and_render_breadcrumb', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(500);
      const tabFiles: Component = await driver.findComponent(ON.id('repo_tabs_host_tab_files'));
      expect(tabFiles !== null).assertTrue();
      await tabFiles.click();
      await driver.delayMs(800);
      const list: Component = await driver.findComponent(ON.id('repo_file_list'));
      expect(list !== null).assertTrue();
      const crumb: Component = await driver.findComponent(ON.id('repo_file_breadcrumb'));
      expect(crumb !== null).assertTrue();
      const rootCrumb: Component = await driver.findComponent(ON.id('repo_file_breadcrumb_seg_0'));
      expect(rootCrumb !== null).assertTrue();
    });

    it('should_navigate_into_dir_and_back_via_breadcrumb', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(500);
      const dirRow: Component = await driver.findComponent(ON.id('repo_file_row_0'));
      expect(dirRow !== null).assertTrue();
      await dirRow.click();
      await driver.delayMs(800);
      const rootCrumb: Component = await driver.findComponent(ON.id('repo_file_breadcrumb_seg_0'));
      expect(rootCrumb !== null).assertTrue();
      await rootCrumb.click();
      await driver.delayMs(800);
      const list: Component = await driver.findComponent(ON.id('repo_file_list'));
      expect(list !== null).assertTrue();
    });
  });
}
