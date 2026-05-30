import { DrawerHeader } from '../../../main/ets/common/DrawerHeader';
import { DrawerMenu } from '../../../main/ets/common/DrawerMenu';
import { APP_STORAGE_KEY_USER_INFO } from '../../../main/ets/store/AuthStore';

const DRAWER_HOST_USER_BODY: string =
  '{"login":"DrawerLogin","name":"DrawerName","avatar_url":"",' +
  '"html_url":"https://github.com/DrawerLogin","bio":"drawer-bio",' +
  '"followers":12,"following":34,"public_repos":5}';

@Entry
@Component
struct DrawerHostPage {
  aboutToAppear(): void {
    AppStorage.setOrCreate<string>(APP_STORAGE_KEY_USER_INFO, DRAWER_HOST_USER_BODY);
  }

  build(): void {
    Column() {
      DrawerHeader();
      DrawerMenu();
    }
    .id('drawer_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#24292E');
  }
}
