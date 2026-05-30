import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const HOST_PAGE_PATH: string = 'pages/UserDetailHostPage';

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

export default function UserDetailUiTest(): void {
  describe('UserDetailUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      await startPage(HOST_PAGE_PATH);
    });

    afterAll(async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    it('should_render_user_detail_root', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(1200);
      const root: Component = await driver.findComponent(ON.id('user_detail_root'));
      expect(root !== null).assertTrue();
    });

    it('should_render_avatar_and_name_and_login', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const avatar: Component = await driver.findComponent(ON.id('user_detail_avatar'));
      expect(avatar !== null).assertTrue();

      const name: Component = await driver.findComponent(ON.id('user_detail_name'));
      expect(name !== null).assertTrue();
      expect(await name.getText()).assertEqual('GuoUI');

      const login: Component = await driver.findComponent(ON.id('user_detail_login'));
      expect(login !== null).assertTrue();
      expect(await login.getText()).assertEqual('CarGuoUI');
    });

    it('should_render_bio', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const bio: Component = await driver.findComponent(ON.id('user_detail_bio'));
      expect(bio !== null).assertTrue();
      expect(await bio.getText()).assertEqual('host bio');
    });

    it('should_render_compose_optional_profile_fields_without_legacy_blog_or_org_strip', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const company: Component = await driver.findComponent(ON.id('user_detail_company'));
      expect(company !== null).assertTrue();
      const location: Component = await driver.findComponent(ON.id('user_detail_location'));
      expect(location !== null).assertTrue();
      const joined: Component = await driver.findComponent(ON.id('user_detail_joined'));
      expect(joined !== null).assertTrue();

      let hasBlog: boolean = false;
      try {
        const blog: Component = await driver.findComponent(ON.id('user_detail_blog'));
        hasBlog = blog !== null;
      } catch (_e) {
        hasBlog = false;
      }
      expect(hasBlog).assertFalse();

      let hasOrgStrip: boolean = false;
      try {
        const orgs: Component = await driver.findComponent(ON.id('user_detail_orgs'));
        hasOrgStrip = orgs !== null;
      } catch (_e) {
        hasOrgStrip = false;
      }
      expect(hasOrgStrip).assertFalse();
    });

    it('should_render_counts_for_repos_followers_following', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const repos: Component = await driver.findComponent(ON.id('user_detail_repos_count'));
      expect(repos !== null).assertTrue();
      expect(await repos.getText()).assertEqual('7');

      const followers: Component = await driver.findComponent(ON.id('user_detail_followers_count'));
      expect(followers !== null).assertTrue();
      expect(await followers.getText()).assertEqual('88');

      const following: Component = await driver.findComponent(ON.id('user_detail_following_count'));
      expect(following !== null).assertTrue();
      expect(await following.getText()).assertEqual('22');
    });

    it('should_render_follow_fab_with_followed_state', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(600);
      const fab: Component = await driver.findComponent(ON.id('user_detail_follow_fab'));
      expect(fab !== null).assertTrue();
      const icon: Component = await driver.findComponent(ON.id('user_detail_follow_fab_icon_following'));
      expect(icon !== null).assertTrue();
    });

    it('should_render_pull_list_and_first_repo_row', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      const list: Component = await driver.findComponent(ON.id('user_detail_pull_list'));
      expect(list !== null).assertTrue();

      const row0: Component = await driver.findComponent(ON.id('user_detail_repo_row_0'));
      expect(row0 !== null).assertTrue();

      const repoName0: Component = await driver.findComponent(ON.id('user_detail_repo_name_0'));
      expect(repoName0 !== null).assertTrue();
      expect(await repoName0.getText()).assertEqual('CarGuoUI/RepoZero');

      const repoLang0: Component = await driver.findComponent(ON.id('user_detail_repo_lang_0'));
      expect(repoLang0 !== null).assertTrue();
      expect(await repoLang0.getText()).assertEqual('TypeScript');
    });

    it('should_render_second_repo_row_for_pagination_visual', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const row1: Component = await driver.findComponent(ON.id('user_detail_repo_row_1'));
      expect(row1 !== null).assertTrue();
      const repoName1: Component = await driver.findComponent(ON.id('user_detail_repo_name_1'));
      expect(repoName1 !== null).assertTrue();
      expect(await repoName1.getText()).assertEqual('CarGuoUI/RepoOne');
    });
  });
}
