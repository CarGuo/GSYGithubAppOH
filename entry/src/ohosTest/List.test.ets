import abilityTest from './ets/test/Ability.test';
import utilsTest from './ets/test/UtilsTest';
import themeManagerTest from './ets/test/ThemeManagerTest';
import themeUiTest from './ets/test/ThemeUiTest';
import readHistoryServiceTest from './ets/test/ReadHistoryServiceTest';
import readHistoryUiTest from './ets/test/ReadHistoryUiTest';

export default function testsuite(): void {
  abilityTest();
  utilsTest();
  themeManagerTest();
  themeUiTest();
  readHistoryServiceTest();
  readHistoryUiTest();
}
