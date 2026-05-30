import bundleManager from '@ohos.bundle.bundleManager';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import { I18n } from '../i18n/I18n';
import { CommonModal } from './CommonModal';
import { CommonToast } from './CommonToast';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { RepositoryService, ReleaseListItem } from '../service/RepositoryService';
import { RepositoryDetailStore } from '../store/RepositoryDetailStore';
import { CreateIssueDialog } from '../widget/CreateIssueDialog';
import {
  AuthStore,
  GlobalAuthStore,
  APP_STORAGE_KEY_USER_INFO,
} from '../store/AuthStore';
import { KEY_LANGUAGE_SELECT } from '../dao/db/Preferences';
import {
  LoginUseCase,
  DefaultLoginUseCase,
} from '../auth/LoginUseCase';
import {
  SettingPageDeps,
  SettingPageHelper,
  LANGUAGE_OPTION_EN,
  LANGUAGE_OPTION_SYSTEM,
  LANGUAGE_OPTION_ZH,
} from '../pages/SettingPage';
import {
  FA_USER,
  FA_COMMENT,
  FA_INFO_CIRCLE,
  FA_HISTORY,
  FA_COG,
  FA_REFRESH,
  FA_SIGN_OUT,
} from './IconFont';
import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';

export class DrawerMenuItem {
  key: string;
  title: string;
  icon: string;

  constructor(key: string, title: string, icon: string) {
    this.key = key;
    this.title = title;
    this.icon = icon;
  }
}

export class DrawerMenuDeps {
  private static useCaseImpl: LoginUseCase = DefaultLoginUseCase;
  private static storeImpl: AuthStore = GlobalAuthStore;

  static setLoginUseCase(useCase: LoginUseCase): void {
    DrawerMenuDeps.useCaseImpl = useCase;
  }

  static setStore(store: AuthStore): void {
    DrawerMenuDeps.storeImpl = store;
  }

  static getLoginUseCase(): LoginUseCase {
    return DrawerMenuDeps.useCaseImpl;
  }

  static getStore(): AuthStore {
    return DrawerMenuDeps.storeImpl;
  }

  static reset(): void {
    DrawerMenuDeps.useCaseImpl = DefaultLoginUseCase;
    DrawerMenuDeps.storeImpl = GlobalAuthStore;
  }
}

export const DRAWER_MENU_KEY_HISTORY: string = 'history';
export const DRAWER_MENU_KEY_FEEDBACK: string = 'feedback';
export const DRAWER_MENU_KEY_PERSONAL_INFO: string = 'personal_info';
export const DRAWER_MENU_KEY_LANGUAGE: string = 'language';
export const DRAWER_MENU_KEY_CHECK_UPDATE: string = 'check_update';
export const DRAWER_MENU_KEY_ABOUT: string = 'about';
export const DRAWER_MENU_KEY_LOGOUT: string = 'logout';
export const DRAWER_MENU_KEY_PROFILE: string = DRAWER_MENU_KEY_PERSONAL_INFO;
export const DRAWER_MENU_KEY_SETTING: string = DRAWER_MENU_KEY_LANGUAGE;
const DRAWER_CLOSE_ACTION_DELAY_MS: number = 1800;

class DrawerLanguageOption {
  value: string;
  label: string;

  constructor(value: string, label: string) {
    this.value = value;
    this.label = label;
  }
}

function buildDrawerLanguageOptions(): DrawerLanguageOption[] {
  return [
    new DrawerLanguageOption(LANGUAGE_OPTION_SYSTEM, I18n('systemLanguage')),
    new DrawerLanguageOption(LANGUAGE_OPTION_ZH, I18n('zhLanguage')),
    new DrawerLanguageOption(LANGUAGE_OPTION_EN, I18n('enLanguage')),
  ];
}

@CustomDialog
struct DrawerAboutDialog {
  controller?: CustomDialogController;
  versionText: string = '0.0.0';

  build(): void {
    Column() {
      Text(I18n('appName'))
        .id('drawer_about_dialog_title')
        .fontSize(GSYFontSize.middleWhite)
        .fontWeight(FontWeight.Bold)
        .fontColor(GSYColor.darkText)
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge, top: 18, bottom: 8 });
      Text(I18n('appVersionPrefix') + this.versionText)
        .id('drawer_about_dialog_text')
        .fontSize(GSYFontSize.normal)
        .fontColor(GSYColor.primary)
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge, top: 4, bottom: 18 });
      Row() {
        Button(I18n('update'))
          .id('drawer_about_dialog_confirm')
          .type(ButtonType.Capsule)
          .fontSize(GSYFontSize.normal)
          .fontColor(GSYColor.white)
          .backgroundColor(GSYColor.linkBlue)
          .height(40)
          .width(96)
          .onClick((): void => {
            if (this.controller) {
              this.controller.close();
            }
          });
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge, bottom: 16 });
    }
    .id('drawer_about_dialog_root')
    .width('86%')
    .backgroundColor(Color.White)
    .borderRadius(12);
  }
}

@CustomDialog
struct DrawerLanguageDialog {
  controller?: CustomDialogController;
  currentLanguage: string = LANGUAGE_OPTION_SYSTEM;
  onSelect: (option: string) => void = (_option: string): void => {};
  private options: DrawerLanguageOption[] = buildDrawerLanguageOptions();

  @Builder
  buildLanguageRow(item: DrawerLanguageOption, index: number): void {
    Row() {
      Text(this.currentLanguage === item.value ? '●' : '○')
        .id('drawer_language_radio_' + item.value)
        .fontSize(GSYFontSize.middleWhite)
        .fontColor(this.currentLanguage === item.value ? GSYColor.linkBlue : GSYColor.textSubtle)
        .width(32)
        .textAlign(TextAlign.Center);
      Text(item.label)
        .id('drawer_language_label_' + item.value)
        .fontSize(GSYFontSize.normal)
        .fontColor(GSYColor.primary)
        .layoutWeight(1)
        .margin({ left: GSYSpacing.halfEdge });
    }
    .id('drawer_language_option_' + item.value)
    .width('100%')
    .height(48)
    .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge })
    .alignItems(VerticalAlign.Center)
    .onClick((): void => {
      if (this.controller) {
        this.controller.close();
      }
      this.onSelect(item.value);
    });
    if (index < this.options.length - 1) {
      Divider().color(GSYColor.pillDivider).strokeWidth(0.5);
    }
  }

  build(): void {
    Column() {
      Text(I18n('drawerLanguage'))
        .id('drawer_language_dialog_title')
        .fontSize(GSYFontSize.middleWhite)
        .fontWeight(FontWeight.Bold)
        .fontColor(GSYColor.darkText)
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge, top: 16, bottom: 12 });
      ForEach(this.options, (item: DrawerLanguageOption, index: number): void => {
        this.buildLanguageRow(item, index);
      }, (item: DrawerLanguageOption): string => item.value);
    }
    .id('drawer_language_dialog_root')
    .width('86%')
    .backgroundColor(Color.White)
    .borderRadius(12);
  }
}

export function buildDrawerMenuItems(): DrawerMenuItem[] {
  return [
    new DrawerMenuItem(DRAWER_MENU_KEY_HISTORY, I18n('drawerHistory'), FA_HISTORY),
    new DrawerMenuItem(DRAWER_MENU_KEY_FEEDBACK, I18n('drawerFeedback'), FA_COMMENT),
    new DrawerMenuItem(DRAWER_MENU_KEY_PERSONAL_INFO, I18n('drawerPersonalInfo'), FA_USER),
    new DrawerMenuItem(DRAWER_MENU_KEY_LANGUAGE, I18n('drawerLanguage'), FA_COG),
    new DrawerMenuItem(DRAWER_MENU_KEY_CHECK_UPDATE, I18n('drawerCheckUpdate'), FA_REFRESH),
    new DrawerMenuItem(DRAWER_MENU_KEY_ABOUT, I18n('drawerAbout'), FA_INFO_CIRCLE),
    new DrawerMenuItem(DRAWER_MENU_KEY_LOGOUT, I18n('drawerLogout'), FA_SIGN_OUT),
  ];
}

@Component
export struct DrawerMenu {
  onItemTap: (key: string) => void = (_key: string): void => {
  };

  private items: DrawerMenuItem[] = buildDrawerMenuItems();
  @State currentLanguage: string = LANGUAGE_OPTION_SYSTEM;
  private feedbackService: RepositoryService = new RepositoryService(new RepositoryDetailStore());
  private feedbackDialogController: CustomDialogController = new CustomDialogController({
    builder: CreateIssueDialog({
      dialogTitle: I18n('drawerFeedback'),
      bodyPlaceholder: I18n('feedbackHint'),
      onConfirm: (title: string, body: string): void => {
        this.submitFeedback(title, body);
      },
    }),
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center,
  });
  private languageDialogController: CustomDialogController = new CustomDialogController({
    builder: DrawerLanguageDialog({
      currentLanguage: this.currentLanguage,
      onSelect: (option: string): void => {
        this.selectLanguage(option);
      },
    }),
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center,
  });
  private aboutDialogController: CustomDialogController = new CustomDialogController({
    builder: DrawerAboutDialog({
      versionText: this.getCurrentVersionName(),
    }),
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center,
  });

  aboutToAppear(): void {
    this.loadLanguage();
  }

  private async loadLanguage(): Promise<void> {
    try {
      this.currentLanguage = await SettingPageDeps.getPrefs()
        .getString(KEY_LANGUAGE_SELECT, LANGUAGE_OPTION_SYSTEM);
    } catch (_e) {
      this.currentLanguage = LANGUAGE_OPTION_SYSTEM;
    }
  }

  private async handleLogout(): Promise<void> {
    try {
      await DrawerMenuDeps.getLoginUseCase().logout();
    } catch (_e) {
    }
    AppStorage.setOrCreate<string>(APP_STORAGE_KEY_USER_INFO, '');
    NavigationService.replace(RouteName.Login);
  }

  private handleItem(item: DrawerMenuItem): void {
    this.onItemTap(item.key);
    if (item.key === DRAWER_MENU_KEY_FEEDBACK) {
      setTimeout((): void => {
        this.feedbackDialogController.open();
      }, DRAWER_CLOSE_ACTION_DELAY_MS);
      return;
    }
    if (item.key === DRAWER_MENU_KEY_PERSONAL_INFO) {
      NavigationService.push(RouteName.PersonInfo);
      return;
    }
    if (item.key === DRAWER_MENU_KEY_HISTORY) {
      NavigationService.push(RouteName.ReadHistory);
      return;
    }
    if (item.key === DRAWER_MENU_KEY_LANGUAGE) {
      setTimeout((): void => {
        this.languageDialogController.open();
      }, DRAWER_CLOSE_ACTION_DELAY_MS);
      return;
    }
    if (item.key === DRAWER_MENU_KEY_CHECK_UPDATE) {
      setTimeout((): void => {
        this.checkUpdate();
      }, DRAWER_CLOSE_ACTION_DELAY_MS);
      return;
    }
    if (item.key === DRAWER_MENU_KEY_ABOUT) {
      setTimeout((): void => {
        this.aboutDialogController.open();
      }, DRAWER_CLOSE_ACTION_DELAY_MS);
      return;
    }
    if (item.key === DRAWER_MENU_KEY_LOGOUT) {
      this.handleLogout();
      return;
    }
  }

  private async submitFeedback(title: string, body: string): Promise<void> {
    const res = await this.feedbackService.createIssue('CarGuo/GSYGithubAppCompose', title, body);
    if (res.result) {
      CommonToast.showShort(I18n('issueSubmitSuccess'));
      return;
    }
    const msg: string = res.msg !== null && res.msg !== undefined && res.msg.length > 0
      ? res.msg : I18n('issueSubmitFail');
    CommonToast.showShort(msg);
  }

  private async selectLanguage(option: string): Promise<void> {
    this.currentLanguage = option;
    try {
      await SettingPageHelper.applyLanguage(option, SettingPageDeps.getPrefs());
    } catch (_e) {
      CommonToast.showShort(I18n('netError'));
    }
  }

  private async checkUpdate(): Promise<void> {
    const res = await RepositoryService.fetchRepositoryRelease('CarGuo', 'GSYGithubAppCompose', 1);
    if (!res.result) {
      CommonToast.showShort(res.msg.length > 0 ? res.msg : I18n('netError'));
      return;
    }
    const latest: ReleaseListItem | null = res.data.length > 0 ? res.data[0] : null;
    if (latest === null || latest.tagName.length === 0) {
      CommonToast.showShort(I18n('listEmpty'));
      return;
    }
    const currentVersion: string = this.getCurrentVersionName();
    if (this.compareVersion(latest.tagName, currentVersion) <= 0) {
      CommonToast.showShort(I18n('newestVersion'));
      return;
    }
    const body: string = this.stripHtml(latest.bodyHtml);
    const message: string = `${I18n('updateDialogVersionLabel')}: ${latest.tagName}\n\n${body}`;
    CommonModal.confirm({
      title: I18n('updateDialogTitle'),
      message: message,
      okText: I18n('update'),
      cancelText: I18n('cancel'),
      cancelable: true,
    }, (): void => {
      this.openUrlInBrowser(latest.htmlUrl);
    });
  }

  private getCurrentVersionName(): string {
    try {
      const flags: number = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
      const info: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(flags);
      return info.versionName;
    } catch (_e) {
      return '0.0.0';
    }
  }

  private compareVersion(left: string, right: string): number {
    const leftParts: number[] = this.parseVersion(left);
    const rightParts: number[] = this.parseVersion(right);
    for (let i: number = 0; i < 3; i++) {
      if (leftParts[i] !== rightParts[i]) {
        return leftParts[i] > rightParts[i] ? 1 : -1;
      }
    }
    return 0;
  }

  private parseVersion(value: string): number[] {
    let cleaned: string = '';
    for (let i: number = 0; i < value.length; i++) {
      const ch: string = value.charAt(i);
      if ((ch >= '0' && ch <= '9') || ch === '.') {
        cleaned += ch;
      }
    }
    const rawParts: string[] = cleaned.split('.');
    const result: number[] = [0, 0, 0];
    for (let i: number = 0; i < rawParts.length && i < 3; i++) {
      const part: number = parseInt(rawParts[i], 10);
      result[i] = isNaN(part) ? 0 : part;
    }
    return result;
  }

  private stripHtml(value: string): string {
    let result: string = '';
    let inTag: boolean = false;
    for (let i: number = 0; i < value.length; i++) {
      const ch: string = value.charAt(i);
      if (ch === '<') {
        inTag = true;
        if (result.length > 0 && result.charAt(result.length - 1) !== ' ' && result.charAt(result.length - 1) !== '\n') {
          result += ' ';
        }
        continue;
      }
      if (ch === '>') {
        inTag = false;
        continue;
      }
      if (!inTag) {
        result += ch;
      }
    }
    return result
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .trim();
  }

  private openUrlInBrowser(url: string): void {
    if (url.length === 0) {
      return;
    }
    try {
      const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: url,
      };
      ctx.startAbility(want).catch((_err: Error): void => {
        CommonToast.showShort(I18n('openLinkFailed'));
      });
    } catch (_e) {
      CommonToast.showShort(I18n('openLinkFailed'));
    }
  }

  @Builder
  buildMenuRow(item: DrawerMenuItem): void {
    if (item.key === DRAWER_MENU_KEY_LOGOUT) {
      Button() {
        Text(item.title)
          .id('drawer_menu_label_' + item.key)
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.white);
      }
      .id('drawer_menu_item_' + item.key)
      .type(ButtonType.Capsule)
      .backgroundColor(GSYColor.dangerRed)
      .width('90%')
      .height(56)
      .margin({ left: 18, right: 18, top: 24, bottom: 20 })
      .onClick((): void => {
        this.handleItem(item);
      });
    } else {
      Text(item.title)
        .id('drawer_menu_label_' + item.key)
        .fontSize(GSYFontSize.normal)
        .fontColor(GSYColor.mainText)
        .width('100%')
        .height(64)
        .padding({ left: 32, right: 24 })
        .textAlign(TextAlign.Start)
        .onClick((): void => {
          this.handleItem(item);
        })
        .id('drawer_menu_item_' + item.key);
    }
  }

  build(): void {
    Column() {
      ForEach(this.items.slice(0, this.items.length - 1), (item: DrawerMenuItem): void => {
        this.buildMenuRow(item);
      }, (item: DrawerMenuItem): string => item.key);
      Blank()
        .layoutWeight(1);
      this.buildMenuRow(this.items[this.items.length - 1]);
    }
    .id('drawer_menu')
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(GSYColor.white)
    .border({ width: { top: 1 }, color: GSYColor.divider })
    .padding({ top: GSYSpacing.padding12 });
  }
}
