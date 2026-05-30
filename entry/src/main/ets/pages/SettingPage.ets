import { AppBar } from '../common/AppBar';
import { CommonToast } from '../common/CommonToast';
import { I18n, changeLocale, LocaleKey } from '../i18n/I18n';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import {
  Preferences,
  KEY_LANGUAGE_SELECT,
  KEY_LANGUAGE_SELECT_NAME,
  KEY_THEME,
  KEY_USER_TOKEN,
  KEY_USER_BASIC,
  KEY_USER_NAME,
  KEY_USER_PASSWORD,
} from '../dao/db/Preferences';
import { RdbStore } from '../dao/db/RdbStore';
import {
  EventBus,
  EVENT_LANGUAGE_CHANGED,
  EVENT_THEME_CHANGED,
} from '../utils/EventBus';
import { LoginUseCase, DefaultLoginUseCase } from '../auth/LoginUseCase';
import {
  ThemeManager,
  ThemeMode,
  ThemePalette,
  LIGHT_PALETTE,
  THEME_PALETTE_KEY,
} from '../theme/ThemeManager';
import { GSYColor, GSYFontSize } from '../style/Theme';

export const LANGUAGE_OPTION_ZH: string = 'zh-CN';
export const LANGUAGE_OPTION_EN: string = 'en';
export const LANGUAGE_OPTION_SYSTEM: string = 'local';

export const THEME_OPTION_LIGHT: string = 'light';
export const THEME_OPTION_DARK: string = 'dark';
export const THEME_OPTION_SYSTEM: string = 'system';

export const SETTING_CACHE_KEYS: string[] = [
  KEY_LANGUAGE_SELECT,
  KEY_LANGUAGE_SELECT_NAME,
  KEY_THEME,
];

export interface PreferencesPort {
  putString(key: string, value: string): Promise<void>;
  getString(key: string, defValue: string): Promise<string>;
  remove(key: string): Promise<void>;
}

export interface RdbPort {
  clearAll(): Promise<void>;
}

class DefaultPreferencesPort implements PreferencesPort {
  putString(key: string, value: string): Promise<void> {
    return Preferences.putString(key, value);
  }

  getString(key: string, defValue: string): Promise<string> {
    return Preferences.getString(key, defValue);
  }

  remove(key: string): Promise<void> {
    return Preferences.remove(key);
  }
}

class DefaultRdbPort implements RdbPort {
  clearAll(): Promise<void> {
    return RdbStore.clearAll();
  }
}

export class SettingPageDeps {
  private static useCaseImpl: LoginUseCase = DefaultLoginUseCase;
  private static prefsImpl: PreferencesPort = new DefaultPreferencesPort();
  private static rdbImpl: RdbPort = new DefaultRdbPort();

  static setUseCase(useCase: LoginUseCase): void {
    SettingPageDeps.useCaseImpl = useCase;
  }

  static setPrefs(prefs: PreferencesPort): void {
    SettingPageDeps.prefsImpl = prefs;
  }

  static setRdb(rdb: RdbPort): void {
    SettingPageDeps.rdbImpl = rdb;
  }

  static getUseCase(): LoginUseCase {
    return SettingPageDeps.useCaseImpl;
  }

  static getPrefs(): PreferencesPort {
    return SettingPageDeps.prefsImpl;
  }

  static getRdb(): RdbPort {
    return SettingPageDeps.rdbImpl;
  }

  static reset(): void {
    SettingPageDeps.useCaseImpl = DefaultLoginUseCase;
    SettingPageDeps.prefsImpl = new DefaultPreferencesPort();
    SettingPageDeps.rdbImpl = new DefaultRdbPort();
  }
}

export class SettingPageHelper {
  static resolveLocale(option: string): LocaleKey {
    return changeLocale(option);
  }

  static async applyLanguage(option: string, prefs: PreferencesPort): Promise<LocaleKey> {
    const applied: LocaleKey = SettingPageHelper.resolveLocale(option);
    await prefs.putString(KEY_LANGUAGE_SELECT, option);
    await prefs.putString(KEY_LANGUAGE_SELECT_NAME, applied);
    EventBus.emit(EVENT_LANGUAGE_CHANGED, applied);
    return applied;
  }

  static async applyTheme(option: string, prefs: PreferencesPort): Promise<void> {
    await prefs.putString(KEY_THEME, option);
    EventBus.emit(EVENT_THEME_CHANGED, option);
  }

  static async applyThemeMode(option: string): Promise<ThemePalette> {
    const mode: ThemeMode = SettingPageHelper.toThemeMode(option);
    await ThemeManager.setMode(mode);
    return ThemeManager.current();
  }

  static toThemeMode(option: string): ThemeMode {
    if (option === 'dark') {
      return 'dark';
    }
    if (option === 'system') {
      return 'system';
    }
    return 'light';
  }

  static async clearCache(prefs: PreferencesPort, rdb: RdbPort): Promise<void> {
    await rdb.clearAll();
    for (let i: number = 0; i < SETTING_CACHE_KEYS.length; i++) {
      const key: string = SETTING_CACHE_KEYS[i];
      try {
        await prefs.remove(key);
      } catch (_e) {
      }
    }
  }

  static async logout(useCase: LoginUseCase, prefs: PreferencesPort): Promise<void> {
    await useCase.logout();
    const authKeys: string[] = [KEY_USER_TOKEN, KEY_USER_BASIC, KEY_USER_NAME, KEY_USER_PASSWORD];
    for (let i: number = 0; i < authKeys.length; i++) {
      try {
        await prefs.remove(authKeys[i]);
      } catch (_e) {
      }
    }
  }
}

@Component
export struct SettingPage {
  @State currentLanguage: string = LANGUAGE_OPTION_SYSTEM;
  @State currentTheme: string = THEME_OPTION_SYSTEM;
  @State okLabel: string = I18n('ok');
  @State cancelLabel: string = I18n('cancel');
  @State languageLabel: string = I18n('language');
  @State clearCacheLabel: string = I18n('clearCache');
  @State logoutLabel: string = I18n('LoginOut');
  @State languageEventCount: number = 0;
  @State themeEventCount: number = 0;
  @StorageProp(THEME_PALETTE_KEY) palette: ThemePalette = LIGHT_PALETTE;
  private offLanguage: (() => void) | null = null;
  private offTheme: (() => void) | null = null;

  aboutToAppear(): void {
    this.offLanguage = EventBus.on(EVENT_LANGUAGE_CHANGED, (): void => {
      this.languageEventCount = this.languageEventCount + 1;
      this.refreshLabels();
    });
    this.offTheme = EventBus.on(EVENT_THEME_CHANGED, (): void => {
      this.themeEventCount = this.themeEventCount + 1;
    });
    this.refreshLabels();
  }

  aboutToDisappear(): void {
    if (this.offLanguage !== null) {
      this.offLanguage();
      this.offLanguage = null;
    }
    if (this.offTheme !== null) {
      this.offTheme();
      this.offTheme = null;
    }
  }

  private refreshLabels(): void {
    this.okLabel = I18n('ok');
    this.cancelLabel = I18n('cancel');
    this.languageLabel = I18n('language');
    this.clearCacheLabel = I18n('clearCache');
    this.logoutLabel = I18n('LoginOut');
  }

  private async chooseLanguage(option: string): Promise<void> {
    this.currentLanguage = option;
    await SettingPageHelper.applyLanguage(option, SettingPageDeps.getPrefs());
  }

  private async chooseTheme(option: string): Promise<void> {
    this.currentTheme = option;
    await SettingPageHelper.applyThemeMode(option);
    await SettingPageHelper.applyTheme(option, SettingPageDeps.getPrefs());
    CommonToast.showShort('切换成功');
  }

  private async runClearCache(): Promise<void> {
    try {
      await SettingPageHelper.clearCache(SettingPageDeps.getPrefs(), SettingPageDeps.getRdb());
      CommonToast.showShort(this.okLabel);
    } catch (_e) {
    }
  }

  private async runLogout(): Promise<void> {
    try {
      await SettingPageHelper.logout(SettingPageDeps.getUseCase(), SettingPageDeps.getPrefs());
    } catch (_e) {
    }
    NavigationService.replace(RouteName.Login);
  }

  @Builder
  buildLanguageOption(idValue: string, label: string, option: string): void {
    Button(label)
      .id(idValue)
      .type(ButtonType.Capsule)
      .height(36)
      .fontSize(GSYFontSize.small)
      .fontColor(this.currentLanguage === option ? GSYColor.white : GSYColor.primary)
      .backgroundColor(this.currentLanguage === option ? GSYColor.linkBlue : GSYColor.surfacePill)
      .margin({ right: 8 })
      .onClick((): void => {
        this.chooseLanguage(option);
      });
  }

  @Builder
  buildThemeOption(idValue: string, label: string, option: string): void {
    Button(label)
      .id(idValue)
      .type(ButtonType.Capsule)
      .height(36)
      .fontSize(GSYFontSize.small)
      .fontColor(this.currentTheme === option ? GSYColor.white : GSYColor.primary)
      .backgroundColor(this.currentTheme === option ? GSYColor.linkBlue : GSYColor.surfacePill)
      .margin({ right: 8 })
      .onClick((): void => {
        this.chooseTheme(option);
      });
  }

  build(): void {
    Column() {
      AppBar({
        title: I18n('setting'),
        showBack: true,
        onBack: (): void => {
          NavigationService.pop();
        },
      });
      Scroll() {
        Column() {
          Button(I18n('infoName'))
            .id('setting_person_info_btn')
            .type(ButtonType.Capsule)
            .width('90%')
            .height(46)
            .fontSize(GSYFontSize.middleWhite)
            .fontColor(GSYColor.white)
            .backgroundColor(GSYColor.linkBlue)
            .margin({ top: 16 })
            .onClick((): void => {
              NavigationService.push(RouteName.PersonInfo);
            });

          Text(this.languageLabel)
            .id('setting_language_title')
            .fontSize(15) // TODO: 字号 15 暂无 token 映射
            .fontWeight(FontWeight.Bold)
            .fontColor(GSYColor.primary)
            .width('100%')
            .padding({ top: 16, bottom: 8, left: 16, right: 16 });
          Row() {
            this.buildLanguageOption('setting_language_zh_btn', I18n('zhLanguage'), LANGUAGE_OPTION_ZH);
            this.buildLanguageOption('setting_language_en_btn', I18n('enLanguage'), LANGUAGE_OPTION_EN);
            this.buildLanguageOption('setting_language_system_btn', I18n('systemLanguage'), LANGUAGE_OPTION_SYSTEM);
          }
          .id('setting_language_row')
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 })
          .alignItems(VerticalAlign.Center);

          Text('ok-label:' + this.okLabel)
            .id('setting_ok_label_text')
            .fontSize(GSYFontSize.min)
            .fontColor(GSYColor.textSubtle)
            .padding({ left: 16, right: 16, bottom: 8 });

          Text('Theme')
            .id('setting_theme_title')
            .fontSize(15) // TODO: 字号 15 暂无 token 映射
            .fontWeight(FontWeight.Bold)
            .fontColor(GSYColor.primary)
            .width('100%')
            .padding({ top: 16, bottom: 8, left: 16, right: 16 });
          Row() {
            this.buildThemeOption('setting_theme_light_btn', 'Light', THEME_OPTION_LIGHT);
            this.buildThemeOption('setting_theme_dark_btn', 'Dark', THEME_OPTION_DARK);
            this.buildThemeOption('setting_theme_system_btn', 'System', THEME_OPTION_SYSTEM);
          }
          .id('setting_theme_row')
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 })
          .alignItems(VerticalAlign.Center);

          Button(this.clearCacheLabel)
            .id('setting_clear_cache_btn')
            .type(ButtonType.Capsule)
            .width('90%')
            .height(46)
            .fontSize(15) // TODO: 字号 15 暂无 token 映射
            .fontColor(GSYColor.white)
            .backgroundColor(GSYColor.warningOrange)
            .margin({ top: 16 })
            .onClick((): void => {
              this.runClearCache();
            });

          Button(this.logoutLabel)
            .id('setting_logout_btn')
            .type(ButtonType.Capsule)
            .width('90%')
            .height(46)
            .fontSize(15) // TODO: 字号 15 暂无 token 映射
            .fontColor(GSYColor.white)
            .backgroundColor(GSYColor.dangerRed)
            .margin({ top: 12, bottom: 24 })
            .onClick((): void => {
              this.runLogout();
            });

          Text('language-event:' + this.languageEventCount.toString())
            .id('setting_language_event_count')
            .fontSize(GSYFontSize.min)
            .fontColor(GSYColor.subText);
          Text('theme-event:' + this.themeEventCount.toString())
            .id('setting_theme_event_count')
            .fontSize(GSYFontSize.min)
            .fontColor(GSYColor.subText)
            .margin({ bottom: 24 });
        }
        .id('setting_content')
        .width('100%')
        .alignItems(HorizontalAlign.Center);
      }
      .id('setting_scroll')
      .layoutWeight(1)
      .width('100%');
    }
    .id('setting_root')
    .width('100%')
    .height('100%')
    .backgroundColor(this.palette ? this.palette.background : GSYColor.pageBackground);
  }
}
