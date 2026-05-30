import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/IssueDetailHostPage';

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

export default function IssueDetailUiTest(): void {
  describe('IssueDetailUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(HOST_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_issue_detail_root_and_appbar', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(1200);
      const root: Component = await driver.findComponent(ON.id('issue_detail_root'));
      expect(root !== null).assertTrue();

      const appbar: Component = await driver.findComponent(ON.id('issue_detail_appbar'));
      expect(appbar !== null).assertTrue();
    });

    it('should_render_issue_header_title_and_state', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const title: Component = await driver.findComponent(ON.id('issue_detail_title'));
      expect(title !== null).assertTrue();
      const state: Component = await driver.findComponent(ON.id('issue_detail_state'));
      expect(state !== null).assertTrue();
      const number: Component = await driver.findComponent(ON.id('issue_detail_number'));
      expect(number !== null).assertTrue();
    });

    it('should_render_issue_user_and_created_at', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(400);
      const userLogin: Component = await driver.findComponent(ON.id('issue_detail_user_login'));
      expect(userLogin !== null).assertTrue();
      const createdAt: Component = await driver.findComponent(ON.id('issue_detail_created_at'));
      expect(createdAt !== null).assertTrue();
      const body: Component = await driver.findComponent(ON.id('issue_detail_body_html'));
      expect(body !== null).assertTrue();
    });

    it('should_render_pull_list_and_first_comment', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const list: Component = await driver.findComponent(ON.id('issue_detail_pull_list'));
      expect(list !== null).assertTrue();
      const commentRow: Component = await driver.findComponent(ON.id('issue_comment_row_0'));
      expect(commentRow !== null).assertTrue();
    });

    it('should_render_bottom_bar_with_input_send_and_state_buttons', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(400);
      const bar: Component = await driver.findComponent(ON.id('issue_detail_bottom_bar'));
      expect(bar !== null).assertTrue();
      const input: Component = await driver.findComponent(ON.id('issue_detail_comment_input'));
      expect(input !== null).assertTrue();
      const send: Component = await driver.findComponent(ON.id('issue_detail_send_button'));
      expect(send !== null).assertTrue();
      const stateBtn: Component = await driver.findComponent(ON.id('issue_detail_state_button'));
      expect(stateBtn !== null).assertTrue();
    });

    it('should_increment_send_count_on_comment_send', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(400);
      const before: Component = await driver.findComponent(ON.id('issue_detail_send_count_text'));
      expect(before !== null).assertTrue();
      const beforeText: string = await before.getText();
      const beforeNum: number = parseInt(beforeText.substring('send-count:'.length), 10);

      const input: Component = await driver.findComponent(ON.id('issue_detail_comment_input'));
      expect(input !== null).assertTrue();
      await input.inputText('hello');
      await driver.delayMs(200);

      const send: Component = await driver.findComponent(ON.id('issue_detail_send_button'));
      expect(send !== null).assertTrue();
      await send.click();
      await driver.delayMs(600);

      const after: Component = await driver.findComponent(ON.id('issue_detail_send_count_text'));
      expect(after !== null).assertTrue();
      const afterText: string = await after.getText();
      const afterNum: number = parseInt(afterText.substring('send-count:'.length), 10);
      expect(afterNum >= beforeNum + 1).assertTrue();
    });

    it('should_increment_state_count_on_state_button_taps', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(400);
      const before: Component = await driver.findComponent(ON.id('issue_detail_state_count_text'));
      expect(before !== null).assertTrue();
      const beforeText: string = await before.getText();
      const beforeNum: number = parseInt(beforeText.substring('state-count:'.length), 10);

      const stateBtn: Component = await driver.findComponent(ON.id('issue_detail_state_button'));
      expect(stateBtn !== null).assertTrue();
      await stateBtn.click();
      await driver.delayMs(600);

      const after: Component = await driver.findComponent(ON.id('issue_detail_state_count_text'));
      expect(after !== null).assertTrue();
      const afterText: string = await after.getText();
      const afterNum: number = parseInt(afterText.substring('state-count:'.length), 10);
      expect(afterNum >= beforeNum + 1).assertTrue();
    });
  });
}
