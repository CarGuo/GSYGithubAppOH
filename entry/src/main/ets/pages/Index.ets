/**
 * Index —— R7 Phase A 应用唯一 @Entry 根
 *
 * 由 [EntryAbility](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets)
 * windowStage.loadContent('pages/Index') 加载，承载唯一的
 * [AppNavigator](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/AppNavigator.ets)
 * 单根 Navigation 容器。
 */
import { AppNavigator } from '../navigation/AppNavigator';
import { GSYColor } from '../style/Theme';

@Entry
@Component
struct Index {
  build(): void {
    Stack() {
      AppNavigator();
    }
    .id('app_index_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.white);
  }
}
