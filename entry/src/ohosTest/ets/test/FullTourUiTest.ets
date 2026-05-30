/**
 * FullTourUiTest —— 全 App 场景巡检 UITest
 *
 * 与 [scenario-tour.sh](https://github.com/CarGuo/GSYGithubAppOH/blob/main/scripts/scenario-tour.sh) 配套：
 *   - 自动模式：UITest 顺序把每个 Host 页推到前台 + 等待稳定 + key root 断言
 *   - 同时段 scenario-tour.sh 在另一终端跑（hilog 后台抓 + 截图 + dump layout）
 *   - 二者共用 hilog domain 0x0666，UITest 通过 Logger.i('FullTour', ...) 标注每个场景边界，
 *     方便把 hilog_business.log 按 GSY_TOUR/FullTour 关键字切片到具体场景
 *
 * 设计要点：
 *   1. 12 场景与 scenario-tour.sh 的 ALL_SCENARIOS 一一对应（key 严格一致）
 *   2. 不依赖网络成功（用 Host 页 root id 断言渲染即可，列表是否非空交给各 *UiTest）
 *   3. 单测每条 it() 单独 startAbility，失败不影响后续 case（与既有 *UiTest 风格一致）
 *   4. dwell 时间用 driver.delayMs(1500)，与 scenario-tour.sh dwell=3..8 留余量
 *   5. 不调用 Driver.takeScreenShot / 不写本地截图：截图职责由 scenario-tour.sh 统一收口
 *
 * 详见 [harness/playbooks/scenario-tour.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/scenario-tour.md)
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { Logger } from '../../../main/ets/ai-debug/Logger';

const BUNDLE: string = 'cn.gsy.githubapp';
const ABILITY: string = 'TestAbility';
const TAG: string = 'FullTour';

interface ScenarioCase {
  key: string;
  title: string;
  targetPage: string;
  expectId: string;
}

const SCENARIOS: ScenarioCase[] = [
  { key: 'launch',      title: '启动 / Common 组件清单',        targetPage: 'pages/CommonComponentsPage',     expectId: 'common_components_root' },
  { key: 'login',       title: '登录页（未登录态）',             targetPage: 'pages/LoginPage',                expectId: 'login_root' },
  { key: 'dynamic',     title: '动态流（DynamicTab 列表）',     targetPage: 'pages/DynamicTabListHostPage',   expectId: 'dynamic_host_list_root' },
  { key: 'trend',       title: '趋势榜（TrendTab 列表）',       targetPage: 'pages/TrendTabListHostPage',     expectId: 'trend_host_list_root' },
  { key: 'my',          title: '个人中心（MyTab）',              targetPage: 'pages/MyTabPageHost',            expectId: 'my_host_root' },
  { key: 'search',      title: '搜索页（输入 + 分段 + 结果）',  targetPage: 'pages/SearchHostPage',           expectId: 'search_host_root' },
  { key: 'repoDetail',  title: '仓库详情（4 Tab）',              targetPage: 'pages/RepositoryDetailHostPage', expectId: 'repo_detail_host_root' },
  { key: 'issueDetail', title: 'Issue 详情（评论 / 状态）',     targetPage: 'pages/IssueDetailHostPage',      expectId: 'issue_detail_host_root' },
  { key: 'userDetail',  title: '用户详情（profile + repo）',     targetPage: 'pages/UserDetailHostPage',       expectId: 'user_detail_host_root' },
  { key: 'notify',      title: '通知中心（未读 / 已读）',        targetPage: 'pages/NotifyHostPage',           expectId: 'notify_host_root' },
  { key: 'readHistory', title: '阅读历史（本地 RDB）',           targetPage: 'pages/ReadHistoryHostPage',      expectId: 'read_history_host_root' },
  { key: 'setting',     title: '设置页（语言 / 主题 / 登出）',  targetPage: 'pages/SettingPage',              expectId: 'setting_root' },
];

async function startTargetPage(targetPage: string): Promise<void> {
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

export default function FullTourUiTest(): void {
  describe('FullTourUiTest', (): void => {
    beforeAll(async (): Promise<void> => {
      Logger.i(TAG, 'BEGIN full-tour scenarios=' + SCENARIOS.length);
    });

    afterAll(async (): Promise<void> => {
      Logger.i(TAG, 'END   full-tour scenarios=' + SCENARIOS.length);
      const driver: Driver = Driver.create();
      await driver.delayMs(300);
    });

    SCENARIOS.forEach((scenario: ScenarioCase, idx: number): void => {
      const padded: string = (idx + 1).toString().padStart(2, '0');
      const caseName: string = 'scenario_' + padded + '_' + scenario.key + '_should_render_root';
      it(caseName, 0, async (): Promise<void> => {
        Logger.i(TAG, 'BEGIN scenario=' + scenario.key + ' index=' + padded + ' title=' + scenario.title);
        await startTargetPage(scenario.targetPage);
        const driver: Driver = Driver.create();
        await driver.delayMs(800);
        const root: Component = await driver.findComponent(ON.id(scenario.expectId));
        expect(root !== null).assertTrue();
        await driver.delayMs(400);
        Logger.i(TAG, 'END   scenario=' + scenario.key + ' index=' + padded + ' status=ok');
      });
    });
  });
}
