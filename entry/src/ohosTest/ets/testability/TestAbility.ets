import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

const TAG: string = 'TestAbility';
const DEFAULT_PAGE: string = 'pages/CommonComponentsPage';

export default class TestAbility extends UIAbility {
  private targetPage: string = DEFAULT_PAGE;
  private windowStageRef: window.WindowStage | null = null;

  onCreate(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, 'onCreate');
    this.targetPage = this.resolveTargetPage(want);
  }

  onNewWant(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, 'onNewWant');
    this.targetPage = this.resolveTargetPage(want);
    this.loadTargetPage();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.windowStageRef = windowStage;
    this.loadTargetPage();
  }

  private loadTargetPage(): void {
    if (this.windowStageRef === null) {
      return;
    }
    hilog.info(0x0000, TAG, 'loadTargetPage page=%{public}s', this.targetPage);
    this.windowStageRef.loadContent(this.targetPage, (err): void => {
      if (err.code) {
        hilog.error(0x0000, TAG, 'loadContent fail %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, TAG, 'loadContent ok');
    });
  }

  private resolveTargetPage(want: Want): string {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      const value: Object | undefined = params['targetPage'];
      if (typeof value === 'string' && (value as string).length > 0) {
        return value as string;
      }
    }
    return DEFAULT_PAGE;
  }
}
