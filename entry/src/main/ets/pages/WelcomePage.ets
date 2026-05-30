import common from '@ohos.app.ability.common';
import font from '@ohos.font';
import hilog from '@ohos.hilog';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { Preferences, KEY_USER_TOKEN, KEY_USER_INFO, PREF_NAME } from '../dao/db/Preferences';
import { HttpManager } from '../net/HttpManager';
import { GlobalAuthStore, APP_STORAGE_KEY_TOKEN, APP_STORAGE_KEY_USER_LOGIN, AuthUserInfo } from '../store/AuthStore';
import { DefaultLoginUseCase, LoginOutcome } from '../auth/LoginUseCase';
import { BOOT_LOGIN_KEY, BOOT_WELCOME_HOLD_KEY } from '../entryability/EntryAbility';
import { HarmonyLogoMark } from '../common/HarmonyLogoMark';
import { GSYColor } from '../style/Theme';
import { LoginPage } from './LoginPage';

const WELCOME_DELAY_MS: number = 2200;
const WELCOME_POSTER_PRELOAD_MS: number = 120;
const WELCOME_STILL_MS: number = 180;
const WELCOME_HERO_MS: number = 560;
const WELCOME_REVEAL_MS: number = 260;
const WELCOME_LOGO_SIZE: number = 320;
const LOGIN_LOGO_SIZE: number = 180;
const LOGIN_LOGO_TARGET_Y: number = -162.5;
const TAG: string = 'WelcomePage';

@Component
export struct WelcomePage {
  @State decided: boolean = false;
  @State heroLogoPlaying: boolean = true;
  @State heroPosterBackingVisible: boolean = false;
  @State showLoginLayer: boolean = false;
  @State showWelcomeMask: boolean = true;
  @State showHeroLayer: boolean = true;
  @State heroProgress: number = 0;
  @State welcomeMaskOpacity: number = 1;
  private timerId: number = -1;
  private posterTimerId: number = -1;
  private stillTimerId: number = -1;
  private heroTimerId: number = -1;
  private revealTimerId: number = -1;

  aboutToAppear(): void {
    this.registerIconFonts();
    try {
      const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      Preferences.init(ctx, PREF_NAME).catch((): void => {
      });
    } catch (_e) {
    }
    if (!this.decided) {
      this.schedulePosterPreload();
      this.timerId = setTimeout((): void => {
        this.startExitTransition();
      }, WELCOME_DELAY_MS);
    }
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
    if (this.posterTimerId !== -1) {
      clearTimeout(this.posterTimerId);
      this.posterTimerId = -1;
    }
    if (this.stillTimerId !== -1) {
      clearTimeout(this.stillTimerId);
      this.stillTimerId = -1;
    }
    if (this.heroTimerId !== -1) {
      clearTimeout(this.heroTimerId);
      this.heroTimerId = -1;
    }
    if (this.revealTimerId !== -1) {
      clearTimeout(this.revealTimerId);
      this.revealTimerId = -1;
    }
  }

  /**
   * 注册 FontAwesome 字体族（与 RN 端 react-native-vector-icons FontAwesome.ttf 同源 4.x ttf）。
   * 注册后任意 Text 组件 `.fontFamily('FontAwesome')` 即可显示 FontAwesome 字符（如 \uf0f3 = bell）。
   * 必须在 UI 上下文（@Entry 页面 aboutToAppear）调用，UIAbility 中调用会抛 401。
   */
  private registerIconFonts(): void {
    try {
      font.registerFont({
        familyName: 'FontAwesome',
        familySrc: $rawfile('fonts/FontAwesome.ttf'),
      });
      hilog.info(0x0000, TAG, 'registerFont FontAwesome ok');
    } catch (e) {
      const err = e as Error;
      hilog.error(0x0000, TAG, 'registerFont fail %{public}s', err.message);
    }
  }

  onPageShow(): void {
    if (this.decided) {
      return;
    }
    this.schedulePosterPreload();
    if (this.timerId === -1) {
      this.timerId = setTimeout((): void => {
        this.startExitTransition();
      }, WELCOME_DELAY_MS);
    }
  }

  onPageHide(): void {
  }

  private startExitTransition(): void {
    if (this.decided || this.stillTimerId !== -1) {
      return;
    }
    const welcomeHold: string | undefined = AppStorage.get<string>(BOOT_WELCOME_HOLD_KEY);
    if (welcomeHold !== undefined && welcomeHold !== null && welcomeHold.length > 0) {
      return;
    }
    this.routeByToken();
  }

  private schedulePosterPreload(): void {
    if (this.posterTimerId !== -1 || this.heroPosterBackingVisible) {
      return;
    }
    this.posterTimerId = setTimeout((): void => {
      this.posterTimerId = -1;
      this.heroPosterBackingVisible = true;
    }, WELCOME_DELAY_MS - WELCOME_POSTER_PRELOAD_MS);
  }

  private startLoginHeroTransition(): void {
    if (this.decided || this.stillTimerId !== -1) {
      return;
    }
    this.decided = true;
    this.heroPosterBackingVisible = true;
    this.heroLogoPlaying = false;
    this.heroProgress = 0;
    this.welcomeMaskOpacity = 1;
    this.showWelcomeMask = true;
    this.showLoginLayer = true;
    this.showHeroLayer = true;
    this.stillTimerId = setTimeout((): void => {
      this.stillTimerId = -1;
      this.runLoginHeroAnimation();
    }, WELCOME_STILL_MS);
  }

  private runLoginHeroAnimation(): void {
    animateTo({
      duration: WELCOME_HERO_MS,
      curve: Curve.EaseInOut,
    }, (): void => {
      this.heroProgress = 1;
    });
    this.heroTimerId = setTimeout((): void => {
      this.heroTimerId = -1;
      animateTo({
        duration: WELCOME_REVEAL_MS,
        curve: Curve.EaseInOut,
      }, (): void => {
        this.welcomeMaskOpacity = 0;
      });
      this.revealTimerId = setTimeout((): void => {
        this.revealTimerId = -1;
        this.showWelcomeMask = false;
        this.heroPosterBackingVisible = false;
        this.heroLogoPlaying = true;
      }, WELCOME_REVEAL_MS + 40);
    }, WELCOME_HERO_MS + 20);
  }

  private heroScale(): number {
    const targetScale: number = LOGIN_LOGO_SIZE / WELCOME_LOGO_SIZE;
    return 1 - ((1 - targetScale) * this.heroProgress);
  }

  private heroTranslateY(): number {
    return LOGIN_LOGO_TARGET_Y * this.heroProgress;
  }

  private async routeByToken(): Promise<void> {
    if (this.decided) {
      return;
    }
    const welcomeHold: string | undefined = AppStorage.get<string>(BOOT_WELCOME_HOLD_KEY);
    if (welcomeHold !== undefined && welcomeHold !== null && welcomeHold.length > 0) {
      return;
    }
    const bootLogin: string | undefined = AppStorage.get<string>(BOOT_LOGIN_KEY);
    if (bootLogin !== undefined && bootLogin !== null && bootLogin.length > 0) {
      AppStorage.setOrCreate<string>(BOOT_LOGIN_KEY, '');
      this.startLoginHeroTransition();
      return;
    }
    let token: string = GlobalAuthStore.token ? GlobalAuthStore.token : '';
    if (!token) {
      try {
        const mirrored: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_TOKEN);
        if (mirrored && mirrored.length > 0) {
          token = mirrored;
        }
      } catch (_e) {
      }
    }
    if (!token) {
      try {
        if (!Preferences.isReady()) {
          const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
          await Preferences.init(ctx, PREF_NAME);
        }
        token = await Preferences.getString(KEY_USER_TOKEN, '');
      } catch (_e) {
        token = '';
      }
    }
    if (token && token.length > 0) {
      this.decided = true;
      GlobalAuthStore.token = token;
      HttpManager.setAuthorization(token);
      await this.restoreUserInfo(token);
      NavigationService.replace(RouteName.Home);
      return;
    }
    this.startLoginHeroTransition();
  }

  /**
   * 冷启 token 路径下补恢复 user 信息（KI-051 修法）：
   * 对齐 RN 端 [user.js initUserInfo](https://github.com/CarGuo/GSYGithubApp/blob/master/app/store/actions/user.js)
   * 把 AsyncStorage[USER_INFO] 解出来后 dispatch USER.USER_INFO 的语义。
   * 读 Preferences[KEY_USER_INFO] → AuthUserInfo.fromJson → GlobalAuthStore.setUser，
   * 让 AppStorage[APP_STORAGE_KEY_USER_LOGIN] 与 AuthStore.userInfo 同步恢复，
   * 修复 IssueDetailPage / 其他 owner 判定页面在冷启 bootToken 路径下 owner=false 的问题。
   */
  private async restoreUserInfo(token: string): Promise<void> {
    try {
      const cached: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_USER_LOGIN);
      if (cached !== undefined && cached !== null && cached.length > 0) {
        return;
      }
      if (!Preferences.isReady()) {
        try {
          const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
          await Preferences.init(ctx, PREF_NAME);
        } catch (_e) {
          return;
        }
      }
      const json: string = await Preferences.getString(KEY_USER_INFO, '');
      if (json && json.length > 0) {
        const user: AuthUserInfo | null = AuthUserInfo.fromJson(json);
        if (user !== null && user.login.length > 0) {
          GlobalAuthStore.setUser(token, user);
          hilog.info(0x0000, TAG, 'restoreUserInfo from cache ok login=%{public}s', user.login);
          return;
        }
      }
      // 本地没有 user 缓存（典型场景：bootToken 测试通道首次注入 PAT），
      // 调一次 GET /user 拉回用户信息并写 Preferences；语义对齐 RN 端
      // [login.js doTokenLogin](https://github.com/CarGuo/GSYGithubApp/blob/master/app/store/actions/login.js)。
      const outcome: LoginOutcome = await DefaultLoginUseCase.loginWithPersonalAccessToken(token);
      if (outcome.result && outcome.data !== null) {
        hilog.info(0x0000, TAG, 'restoreUserInfo via /user ok login=%{public}s', outcome.data.login);
      } else {
        hilog.warn(0x0000, TAG, 'restoreUserInfo via /user fail code=%{public}d', outcome.code);
      }
    } catch (e) {
      const err = e as Error;
      hilog.warn(0x0000, TAG, 'restoreUserInfo fail %{public}s', err.message);
    }
  }

  @Builder
  private buildWelcomeAnimation(): void {
    HarmonyLogoMark({
      markSize: WELCOME_LOGO_SIZE,
      rootId: 'welcome_harmony_mark',
      letterId: 'welcome_harmony_letter',
      labelId: 'welcome_harmony_label',
      play: this.heroLogoPlaying,
      showPosterBacking: this.heroPosterBackingVisible,
    })
      .scale({ x: this.heroScale(), y: this.heroScale() })
      .translate({ x: 0, y: this.heroTranslateY(), z: 0 });
  }

  build(): void {
    Stack() {
      if (this.showLoginLayer) {
        LoginPage({ showLogo: false });
      }

      if (this.showWelcomeMask) {
        Column() {
          Text('')
            .id('welcome_image')
            .width(1)
            .height(1)
            .opacity(0.001);

          Text('')
            .id('welcome_harmony_label')
            .width(1)
            .height(1)
            .opacity(0.001);

          Text('')
            .id('welcome_subtitle')
            .width(1)
            .height(1)
            .opacity(0.001);
        }
        .id('welcome_mask')
        .width('100%')
        .height('100%')
        .backgroundColor(GSYColor.white)
        .opacity(this.welcomeMaskOpacity);
      }

      if (this.showHeroLayer) {
        Column() {
          this.buildWelcomeAnimation();
        }
        .id('welcome_hero_layer')
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.Transparent);
      }
    }
    .id('welcome_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.white);
  }
}
