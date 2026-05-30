import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { AuthDeepLinkBus } from '../auth/AuthDeepLinkBus';
import { Url, DeepLinkInfo } from '../utils/Url';
import { Preferences, KEY_USER_TOKEN, PREF_NAME } from '../dao/db/Preferences';
import { RdbStore } from '../dao/db/RdbStore';
import { HttpManager } from '../net/HttpManager';
import { GlobalAuthStore } from '../store/AuthStore';
import { enableImmersive } from '../utils/SafeAreaInsets';
import { Logger } from '../ai-debug/Logger';
import { changeLocale, LocaleKey } from '../i18n/I18n';
import { KEY_SEARCH_HISTORY } from '../utils/SearchHistory';

const TAG: string = 'EntryAbility';
const AUTH_SCHEME: string = 'gsygithubapp';
const AUTH_HOST: string = 'authed';
const PARAM_BOOT_TOKEN: string = 'bootToken';
const PARAM_BOOT_LOGIN: string = 'bootLogin';
const PARAM_BOOT_WELCOME_HOLD: string = 'bootWelcomeHold';
const PARAM_BOOT_TAB: string = 'bootTab';
const PARAM_BOOT_REPO: string = 'bootRepo';
const PARAM_BOOT_PUSH: string = 'bootPush';
const PARAM_BOOT_ISSUE: string = 'bootIssue';
const PARAM_BOOT_CODE: string = 'bootCode';
const PARAM_BOOT_USER: string = 'bootUser';
const PARAM_BOOT_PHOTO: string = 'bootPhoto';
const PARAM_BOOT_WEB: string = 'bootWeb';
const PARAM_BOOT_COMMON_LIST: string = 'bootCommonList';
const PARAM_BOOT_LOCALE: string = 'bootLocale';
const PARAM_BOOT_NOTIFY_ISSUE: string = 'bootNotifyIssue';
const PARAM_BOOT_SEARCH_HISTORY: string = 'bootSearchHistory';
export const BOOT_TAB_KEY: string = 'gsy_boot_tab';
export const BOOT_LOGIN_KEY: string = 'gsy_boot_login';
export const BOOT_WELCOME_HOLD_KEY: string = 'gsy_boot_welcome_hold';
export const BOOT_REPO_KEY: string = 'gsy_boot_repo';
export const BOOT_PUSH_KEY: string = 'gsy_boot_push';
export const BOOT_ISSUE_KEY: string = 'gsy_boot_issue';
export const BOOT_CODE_KEY: string = 'gsy_boot_code';
export const BOOT_USER_KEY: string = 'gsy_boot_user';
export const BOOT_PHOTO_KEY: string = 'gsy_boot_photo';
export const BOOT_WEB_KEY: string = 'gsy_boot_web';
export const BOOT_NOTIFY_ISSUE_KEY: string = 'gsy_boot_notify_issue';
export const BOOT_COMMON_LIST_KEY: string = 'gsy_boot_common_list';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, 'onCreate');
    this.initRdbStore();
    this.handleOAuthDeepLink(want);
    this.handleBootLocaleInjection(want);
    this.handleBootTokenInjection(want);
    this.handleBootLoginInjection(want);
    this.handleBootWelcomeHoldInjection(want);
    this.handleBootTabInjection(want);
    this.handleBootRepoInjection(want);
    this.handleBootPushInjection(want);
    this.handleBootIssueInjection(want);
    this.handleBootCodeInjection(want);
    this.handleBootUserInjection(want);
    this.handleBootPhotoInjection(want);
    this.handleBootWebInjection(want);
    this.handleBootCommonListInjection(want);
    this.handleBootNotifyIssueInjection(want);
    this.handleBootSearchHistoryInjection(want);
  }

  onNewWant(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, 'onNewWant');
    this.handleOAuthDeepLink(want);
    this.handleBootLocaleInjection(want);
    this.handleBootLoginInjection(want);
    this.handleBootWelcomeHoldInjection(want);
    this.handleBootTabInjection(want);
    this.handleBootRepoInjection(want);
    this.handleBootPushInjection(want);
    this.handleBootIssueInjection(want);
    this.handleBootCodeInjection(want);
    this.handleBootUserInjection(want);
    this.handleBootPhotoInjection(want);
    this.handleBootWebInjection(want);
    this.handleBootCommonListInjection(want);
    this.handleBootNotifyIssueInjection(want);
    this.handleBootSearchHistoryInjection(want);
  }

  private initRdbStore(): void {
    RdbStore.init(this.context).catch((e: Error): void => {
      hilog.error(0x0000, TAG, 'rdb init fail %{public}s', e.message);
    });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, TAG, 'onWindowStageCreate');
    enableImmersive(windowStage).catch((e: Error): void => {
      hilog.warn(0x0000, TAG, 'enableImmersive fail %{public}s', e.message);
    });
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, TAG, 'loadContent fail %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, TAG, 'loadContent ok');
    });
  }

  onWindowStageRestore(_windowStage: window.WindowStage): void {
    hilog.info(0x0000, TAG, 'onWindowStageRestore');
  }

  private handleOAuthDeepLink(want: Want): void {
    const uri: string | undefined = want.uri;
    if (!uri || uri.length === 0) {
      return;
    }
    const info: DeepLinkInfo = Url.parseDeepLink(uri);
    if (info.scheme !== AUTH_SCHEME || info.host !== AUTH_HOST) {
      return;
    }
    AuthDeepLinkBus.publish(uri);
  }

  /**
   * 测试通道：want.parameters.bootLocale=en|zh-CN|local，
   * 用于生成 Compose/OH 同语言截图证据，不改变生产默认语言选择。
   */
  private handleBootLocaleInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_LOCALE];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim();
    if (value.length === 0) {
      return;
    }
    const applied: LocaleKey = changeLocale(value);
    hilog.info(0x0000, TAG, 'bootLocale applied %{public}s', applied);
  }

  /**
   * 测试通道：当 want.parameters.bootToken 存在时，
   * 直接把它写入 Preferences，使 WelcomePage 检测到 token 后跳过 LoginPage。
   * 仅用于真机回归（aa start --PS bootToken xxxx），生产路径不会带该参数。
   */
  private handleBootTokenInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_TOKEN];
    if (typeof raw !== 'string') {
      return;
    }
    const tokenInput: string = (raw as string).trim();
    if (tokenInput.length === 0) {
      return;
    }
    const authorization: string = tokenInput.toLowerCase().indexOf('token ') === 0
      ? tokenInput
      : `token ${tokenInput}`;
    hilog.info(0x0000, TAG, 'bootToken injected (len=%{public}d)', authorization.length);
    GlobalAuthStore.token = authorization;
    HttpManager.setAuthorization(authorization);
    Preferences.init(this.context, PREF_NAME)
      .then((): Promise<void> => Preferences.putString(KEY_USER_TOKEN, authorization))
      .catch((e: Error): void => {
        hilog.error(0x0000, TAG, 'bootToken persist fail %{public}s', e.message);
      });
  }

  /**
   * 测试通道：want.parameters.bootSearchHistory=react|flutter，
   * 用于 Search 首屏/聚焦态对照截图。生产路径不会带该参数。
   */
  private handleBootSearchHistoryInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_SEARCH_HISTORY];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim();
    if (value.length === 0) {
      return;
    }
    const parts: string[] = value.split('|');
    const items: string[] = [];
    for (let i = 0; i < parts.length; i++) {
      const item: string = parts[i].trim();
      if (item.length > 0) {
        items.push(item);
      }
    }
    if (items.length === 0) {
      return;
    }
    Preferences.init(this.context, PREF_NAME)
      .then((): Promise<void> => Preferences.putString(KEY_SEARCH_HISTORY, JSON.stringify(items)))
      .then((): void => {
        hilog.info(0x0000, TAG, 'bootSearchHistory injected count=%{public}d', items.length);
      })
      .catch((e: Error): void => {
        hilog.error(0x0000, TAG, 'bootSearchHistory persist fail %{public}s', e.message);
      });
  }

  /**
   * 测试通道：want.parameters.bootLogin=true，
   * 仅强制 WelcomePage 进入 LoginPage，不清除现有 token，方便保留登录态做 UI 回归。
   */
  private handleBootLoginInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_LOGIN];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim().toLowerCase();
    if (value.length === 0 || value === 'false' || value === '0') {
      return;
    }
    hilog.info(0x0000, TAG, 'bootLogin injected');
    AppStorage.setOrCreate<string>(BOOT_LOGIN_KEY, '1');
  }

  /**
   * 测试通道：want.parameters.bootWelcomeHold=true，
   * 保持 WelcomePage 不自动路由，用于短时间动画截图对比。
   */
  private handleBootWelcomeHoldInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_WELCOME_HOLD];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim().toLowerCase();
    if (value.length === 0 || value === 'false' || value === '0') {
      return;
    }
    hilog.info(0x0000, TAG, 'bootWelcomeHold injected');
    AppStorage.setOrCreate<string>(BOOT_WELCOME_HOLD_KEY, '1');
  }

  /**
   * 测试通道：want.parameters.bootTab=dynamic|trend|my，
   * 通过 AppStorage 推送给 HomePage，绕开 uinput 在 navIndicator 区误触桌面的问题。
   */
  private handleBootTabInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_TAB];
    if (typeof raw !== 'string') {
      return;
    }
    const tab: string = (raw as string).trim().toLowerCase();
    if (tab.length === 0) {
      return;
    }
    hilog.info(0x0000, TAG, 'bootTab injected %{public}s', tab);
    AppStorage.setOrCreate<string>(BOOT_TAB_KEY, tab);
  }

  /**
   * 测试通道：want.parameters.bootRepo=owner/name，
   * HomePage 启动后会读取该值并 push 到 RepositoryDetailPage，方便对详情页做真机回归。
   * 用完即清，避免下次冷启动残留。
   */
  private handleBootRepoInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_REPO];
    if (typeof raw !== 'string') {
      return;
    }
    const repo: string = (raw as string).trim();
    if (repo.length === 0) {
      return;
    }
    hilog.info(0x0000, TAG, 'bootRepo injected %{public}s', repo);
    AppStorage.setOrCreate<string>(BOOT_REPO_KEY, repo);
    Logger.i('boot/ts', `EntryAbility.handleBootRepoInjection done t=${Date.now()} repo=${repo}`);
  }

  /**
   * 测试通道：want.parameters.bootPush=owner/name|sha，
   * HomePage 启动后会读取该值并 push 到 PushDetailPage，方便对详情页做真机回归。
   */
  private handleBootPushInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_PUSH];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim();
    if (value.length === 0) {
      return;
    }
    hilog.info(0x0000, TAG, 'bootPush injected %{public}s', value);
    AppStorage.setOrCreate<string>(BOOT_PUSH_KEY, value);
    Logger.i('boot/ts', `EntryAbility.handleBootPushInjection done t=${Date.now()} value=${value}`);
  }

  /**
   * 测试通道：want.parameters.bootIssue=fullName|number，
   * HomePage 启动后会读取该值并 push 到 IssueDetailPage，方便对详情页做真机回归。
   */
  private handleBootIssueInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_ISSUE];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim();
    if (value.length === 0) {
      return;
    }
    hilog.info(0x0000, TAG, 'bootIssue injected %{public}s', value);
    AppStorage.setOrCreate<string>(BOOT_ISSUE_KEY, value);
    Logger.i('boot/ts', `EntryAbility.handleBootIssueInjection done t=${Date.now()} value=${value}`);
  }

  /**
   * 测试通道：want.parameters.bootCode=fullName|branch|path，
   * HomePage 启动后会读取该值并 push 到 CodeDetailPage，方便对详情页做真机回归。
   */
  private handleBootCodeInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_CODE];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim();
    if (value.length === 0) {
      return;
    }
    hilog.info(0x0000, TAG, 'bootCode injected %{public}s', value);
    AppStorage.setOrCreate<string>(BOOT_CODE_KEY, value);
    Logger.i('boot/ts', `EntryAbility.handleBootCodeInjection done t=${Date.now()} value=${value}`);
  }

  /**
   * 测试通道：want.parameters.bootUser=login，
   * HomePage 启动后会读取该值并 push 到 UserDetailPage，方便对详情页做真机回归。
   */
  private handleBootUserInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_USER];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim();
    if (value.length === 0) {
      return;
    }
    hilog.info(0x0000, TAG, 'bootUser injected %{public}s', value);
    AppStorage.setOrCreate<string>(BOOT_USER_KEY, value);
    Logger.i('boot/ts', `EntryAbility.handleBootUserInjection done t=${Date.now()} value=${value}`);
  }

  /**
   * 测试通道：want.parameters.bootPhoto=<image url>，
   * HomePage 启动后会读取该值并 push 到 PhotoPage，方便对大图预览页做真机回归。
   */
  private handleBootPhotoInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_PHOTO];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim();
    if (value.length === 0) {
      return;
    }
    hilog.info(0x0000, TAG, 'bootPhoto injected %{public}s', value);
    AppStorage.setOrCreate<string>(BOOT_PHOTO_KEY, value);
    Logger.i('boot/ts', `EntryAbility.handleBootPhotoInjection done t=${Date.now()} value=${value}`);
  }

  /**
   * 测试通道：want.parameters.bootWeb=<http(s) url>，
   * HomePage 启动后会读取该值并 push 到 WebPage，方便对通用 Web 页做真机回归。
   * 与 [handleBootPhotoInjection](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/entryability/EntryAbility.ets) 同款做法。
   */
  private handleBootWebInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_WEB];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim();
    if (value.length === 0) {
      return;
    }
    hilog.info(0x0000, TAG, 'bootWeb injected %{public}s', value);
    AppStorage.setOrCreate<string>(BOOT_WEB_KEY, value);
    Logger.i('boot/ts', `EntryAbility.handleBootWebInjection done t=${Date.now()} value=${value}`);
  }

  /**
   * 测试通道：want.parameters.bootCommonList=dataType|showType|currentUser|repoName，
   * HomePage 启动后会 push 到 CommonListPage，补足无自然入口的 Compose list 类型回归。
   */
  private handleBootCommonListInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_COMMON_LIST];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim();
    if (value.length === 0) {
      return;
    }
    hilog.info(0x0000, TAG, 'bootCommonList injected %{public}s', value);
    AppStorage.setOrCreate<string>(BOOT_COMMON_LIST_KEY, value);
    Logger.i('boot/ts', `EntryAbility.handleBootCommonListInjection done t=${Date.now()} value=${value}`);
  }

  /**
   * 测试通道：want.parameters.bootNotifyIssue=fullName|number，
   * HomePage 启动后会进入 NotifyPage，NotifyPage 注入一条 Issue 通知用于点击路由回归。
   */
  private handleBootNotifyIssueInjection(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const raw: Object | undefined = params[PARAM_BOOT_NOTIFY_ISSUE];
    if (typeof raw !== 'string') {
      return;
    }
    const value: string = (raw as string).trim();
    if (value.length === 0) {
      return;
    }
    hilog.info(0x0000, TAG, 'bootNotifyIssue injected %{public}s', value);
    AppStorage.setOrCreate<string>(BOOT_NOTIFY_ISSUE_KEY, value);
    Logger.i('boot/ts', `EntryAbility.handleBootNotifyIssueInjection done t=${Date.now()} value=${value}`);
  }
}
