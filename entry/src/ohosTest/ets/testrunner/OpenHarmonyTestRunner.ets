import hilog from '@ohos.hilog';
import TestRunner from '@ohos.application.testRunner';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const TAG: string = 'OpenHarmonyTestRunner';

export default class OpenHarmonyTestRunner implements TestRunner {
  onPrepare(): void {
    hilog.info(0x0000, TAG, 'OpenHarmonyTestRunner OnPrepare');
  }

  onRun(): void {
    hilog.info(0x0000, TAG, 'OpenHarmonyTestRunner OnRun start');
    const abilityDelegatorArguments = AbilityDelegatorRegistry.getArguments();
    const abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
    const moduleName: string = abilityDelegatorArguments.parameters['-m'];
    const cmd: string = 'aa test -b ' + abilityDelegatorArguments.bundleName
      + ' -m ' + moduleName
      + ' -s unittest OpenHarmonyTestRunner'
      + ' -s class CommonComponentsTest';
    abilityDelegator.executeShellCommand(cmd, (err, data): void => {
      hilog.info(0x0000, TAG, 'executeShellCommand done %{public}s', JSON.stringify({ err, data }));
    });
  }
}
