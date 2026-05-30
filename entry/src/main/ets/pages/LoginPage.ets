import font from '@ohos.font';
import hilog from '@ohos.hilog';
import { LoginUseCase, DefaultLoginUseCase, LoginOutcome } from '../auth/LoginUseCase';
import { OauthService, DEFAULT_OAUTH_REDIRECT_URI, DEFAULT_OAUTH_SCOPE } from '../auth/OauthService';
import { OAuthLocalConfigLoader, OAuthRuntimeConfig } from '../auth/OAuthLocalConfig';
import { AuthDeepLinkBus } from '../auth/AuthDeepLinkBus';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { CommonToast } from '../common/CommonToast';
import { LoadingModal } from '../common/LoadingModal';
import { I18n } from '../i18n/I18n';
import {
  AuthStore,
  GlobalAuthStore,
} from '../store/AuthStore';
import { EventBus, EVENT_USER_LOGGED_IN } from '../utils/EventBus';
import { Url } from '../utils/Url';
import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';
import { FA_KEY } from '../common/IconFont';
import { HarmonyLogoMark } from '../common/HarmonyLogoMark';
import { KEY_LANGUAGE_SELECT } from '../dao/db/Preferences';
import {
  LANGUAGE_OPTION_EN,
  LANGUAGE_OPTION_SYSTEM,
  LANGUAGE_OPTION_ZH,
  SettingPageDeps,
  SettingPageHelper,
} from './SettingPage';

export class LoginOauthRouteParams {
  authorizeUrl: string;
  state: string;
  redirectUri: string;

  constructor(authorizeUrl: string, state: string, redirectUri: string) {
    this.authorizeUrl = authorizeUrl;
    this.state = state;
    this.redirectUri = redirectUri;
  }
}

export class LoginOauthClient {
  private static clientIdImpl: string = '';

  static setClientId(id: string): void {
    LoginOauthClient.clientIdImpl = id ? id : '';
  }

  static getClientId(): string {
    return LoginOauthClient.clientIdImpl;
  }
}

export class LoginPageDeps {
  private static useCaseImpl: LoginUseCase = DefaultLoginUseCase;
  private static storeImpl: AuthStore = GlobalAuthStore;

  static setUseCase(useCase: LoginUseCase): void {
    LoginPageDeps.useCaseImpl = useCase;
  }

  static setStore(store: AuthStore): void {
    LoginPageDeps.storeImpl = store;
  }

  static getUseCase(): LoginUseCase {
    return LoginPageDeps.useCaseImpl;
  }

  static getStore(): AuthStore {
    return LoginPageDeps.storeImpl;
  }

  static reset(): void {
    LoginPageDeps.useCaseImpl = DefaultLoginUseCase;
    LoginPageDeps.storeImpl = GlobalAuthStore;
  }
}

const LOGIN_LOGO_PHASE_MS: number = 160;
const LOGIN_LOGO_MARK_SIZE: number = 180;
const LOGIN_LOGO_IMAGE_HEIGHT: number = LOGIN_LOGO_MARK_SIZE * 0.75;
const LOGIN_LOGO_BOTTOM_MARGIN: number = 24;

@Component
export struct LoginPage {
  @Prop showLogo: boolean = true;
  @State token: string = '';
  @State showLanguageDialog: boolean = false;
  @State currentLanguage: string = LANGUAGE_OPTION_SYSTEM;
  @State logoPhase: number = 0;
  @StorageLink('auth.loading') loading: boolean = false;
  @StorageLink('auth.error') errorMessage: string = '';
  private offLoggedIn: (() => void) | null = null;
  private offDeepLink: (() => void) | null = null;
  private logoTimerId: number = -1;

  aboutToAppear(): void {
    this.registerIconFonts();
    this.loadLanguage();
    this.startLogoAnimation();
    this.offLoggedIn = EventBus.on(EVENT_USER_LOGGED_IN, (): void => {
      LoadingModal.hide();
      NavigationService.replace(RouteName.Home);
    });
    this.offDeepLink = AuthDeepLinkBus.subscribe((uri: string): void => {
      this.handleDeepLink(uri);
    });
  }

  aboutToDisappear(): void {
    if (this.offLoggedIn !== null) {
      this.offLoggedIn();
      this.offLoggedIn = null;
    }
    if (this.offDeepLink !== null) {
      this.offDeepLink();
      this.offDeepLink = null;
    }
    if (this.logoTimerId !== -1) {
      clearInterval(this.logoTimerId);
      this.logoTimerId = -1;
    }
  }

  private registerIconFonts(): void {
    try {
      font.registerFont({
        familyName: 'FontAwesome',
        familySrc: $rawfile('fonts/FontAwesome.ttf'),
      });
    } catch (e) {
      const err = e as Error;
      hilog.warn(0x0000, 'LoginPage', 'registerFont fail %{public}s', err.message);
    }
  }

  private async handleDeepLink(uri: string): Promise<void> {
    if (!uri || uri.length === 0) {
      return;
    }
    const query: Map<string, string> = Url.parseQuery(uri);
    const code: string | undefined = query.get('code');
    const state: string | undefined = query.get('state');
    if (code === undefined || code.length === 0) {
      return;
    }
    if (state !== undefined && state.length > 0 && !OauthService.validateState(state)) {
      CommonToast.showShort(I18n('LoginFailTip'));
      return;
    }
    LoadingModal.show(I18n('loading'), false);
    const res: LoginOutcome = await OauthService.exchangeOAuthCode(code);
    LoadingModal.hide();
    if (!res.result) {
      CommonToast.showShort(I18n('LoginFailTip'));
    }
  }

  private async runTokenLogin(token: string): Promise<void> {
    const trimmed: string = (token ? token : '').trim();
    if (trimmed.length === 0) {
      CommonToast.showShort(I18n('TokenInputTip'));
      return;
    }
    LoadingModal.show(I18n('loading'), false);
    const res: LoginOutcome = await LoginPageDeps.getUseCase().loginWithPersonalAccessToken(trimmed);
    LoadingModal.hide();
    if (!res.result) {
      CommonToast.showShort(I18n('TokenLoginFailTip'));
    }
  }

  private async chooseLanguage(option: string): Promise<void> {
    this.currentLanguage = option;
    await SettingPageHelper.applyLanguage(option, SettingPageDeps.getPrefs());
    this.showLanguageDialog = false;
  }

  private async loadLanguage(): Promise<void> {
    try {
      this.currentLanguage = await SettingPageDeps.getPrefs()
        .getString(KEY_LANGUAGE_SELECT, LANGUAGE_OPTION_SYSTEM);
    } catch (_e) {
      this.currentLanguage = LANGUAGE_OPTION_SYSTEM;
    }
  }

  @Builder
  private buildLanguageOption(value: string, label: string): void {
    Row() {
      Text(this.currentLanguage === value ? '●' : '○')
        .id('login_language_radio_' + value)
        .fontSize(GSYFontSize.middleWhite)
        .fontColor(this.currentLanguage === value ? GSYColor.linkBlue : GSYColor.textSubtle)
        .width(32)
        .textAlign(TextAlign.Center);

      Text(label)
        .id('login_language_label_' + value)
        .fontSize(GSYFontSize.normal)
        .fontColor(GSYColor.primary)
        .layoutWeight(1)
        .margin({ left: GSYSpacing.halfEdge });
    }
    .id('login_language_option_' + value)
    .width('100%')
    .height(48)
    .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge })
    .alignItems(VerticalAlign.Center)
    .onClick((): void => {
      this.chooseLanguage(value);
    });
  }

  private startLogoAnimation(): void {
    if (this.logoTimerId !== -1) {
      return;
    }
    this.logoTimerId = setInterval((): void => {
      this.logoPhase = (this.logoPhase + 1) % 12;
    }, LOGIN_LOGO_PHASE_MS);
  }

  @Builder
  private buildAnimatedLogo(): void {
    if (this.showLogo) {
      HarmonyLogoMark({
        phase: this.logoPhase,
        markSize: LOGIN_LOGO_MARK_SIZE,
        rootId: 'login_logo',
        letterId: 'login_logo_harmony_letter',
        darkSurface: false,
        contained: false,
      })
        .margin({ bottom: LOGIN_LOGO_BOTTOM_MARGIN });
    } else {
      Blank()
        .id('login_logo_placeholder')
        .width(LOGIN_LOGO_MARK_SIZE)
        .height(LOGIN_LOGO_IMAGE_HEIGHT)
        .margin({ bottom: LOGIN_LOGO_BOTTOM_MARGIN });
    }
  }

  private async openOAuthWeb(): Promise<void> {
    const cfg: OAuthRuntimeConfig = await OAuthLocalConfigLoader.load(this);
    if (!cfg.isValid()) {
      CommonToast.showShort(I18n('OAuthConfigMissingTip'));
      return;
    }
    LoginPageDeps.getUseCase().setOAuthConfig(cfg.toClientConfig());
    LoginOauthClient.setClientId(cfg.clientId);
    const state: string = OauthService.generateState();
    const authorizeUrl: string = OauthService.buildAuthorizeUrl(
      cfg.clientId,
      cfg.redirectUri,
      DEFAULT_OAUTH_SCOPE,
      state,
    );
    const params: LoginOauthRouteParams = new LoginOauthRouteParams(
      authorizeUrl, state, cfg.redirectUri);
    NavigationService.push(RouteName.LoginWeb, params);
  }

  build(): void {
    Stack() {
      Column() {
        this.buildAnimatedLogo();

        Column() {
          Text(I18n('LoginTitle'))
            .id('login_title')
            .fontSize(GSYFontSize.big)
            .fontWeight(FontWeight.Bold)
            .fontColor(GSYColor.primary)
            .textAlign(TextAlign.Center);

          Text(I18n('LoginSubtitle'))
            .id('login_subtitle')
            .fontSize(GSYFontSize.middleWhite)
            .fontColor(GSYColor.textSubtle)
            .textAlign(TextAlign.Center)
            .margin({ top: 8, bottom: 32 });

          Text(I18n('LoginTokenLabel'))
            .id('login_token_label')
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.primary)
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ bottom: GSYSpacing.halfEdge });

          Row() {
            Text(FA_KEY)
              .id('login_token_leading_icon')
              .fontFamily('FontAwesome')
              .fontSize(GSYFontSize.middleWhite)
              .fontColor(GSYColor.textSubtle)
              .textAlign(TextAlign.Center)
              .width(40);

            TextInput({ text: this.token, placeholder: I18n('LoginTokenHint') })
              .id('login_token_input')
              .type(InputType.Password)
              .layoutWeight(1)
              .height(48)
              .fontSize(GSYFontSize.small)
              .backgroundColor(GSYColor.transparent)
              .onChange((value: string): void => {
                this.token = value;
              });
          }
            .id('login_token_field')
            .width('100%')
            .height(52)
            .backgroundColor(GSYColor.surfaceSubtle)
            .borderRadius(8)
            .alignItems(VerticalAlign.Center);

          Text(I18n('LoginTokenHelper'))
            .id('login_token_helper')
            .fontSize(GSYFontSize.min)
            .fontColor(GSYColor.textSubtle)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 8, bottom: 24 });

          Row() {
            Button(I18n('LoginButton'))
              .id('login_submit_btn')
              .type(ButtonType.Normal)
              .width('48%')
              .height(50)
              .fontSize(GSYFontSize.middleWhite)
              .fontColor(GSYColor.textWhite)
              .backgroundColor(GSYColor.primary)
              .borderRadius(8)
              .enabled(!this.loading && this.token.trim().length > 0)
              .onClick((): void => {
                this.runTokenLogin(this.token);
              });

            Button(I18n('OAuthLogin'))
              .id('login_oauth_btn')
              .type(ButtonType.Normal)
              .width('48%')
              .height(50)
              .fontSize(GSYFontSize.middleWhite)
              .fontColor(GSYColor.textWhite)
              .backgroundColor(GSYColor.primary)
              .borderRadius(8)
              .enabled(!this.loading)
              .onClick((): void => {
                this.openOAuthWeb();
              });
          }
          .id('login_buttons_row')
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center);

          Text(I18n('language'))
            .id('login_language_btn')
            .fontSize(GSYFontSize.middleWhite)
            .fontColor(GSYColor.primary)
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 16, bottom: 8 })
            .onClick((): void => {
              this.showLanguageDialog = true;
            });

          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .id('login_error_text')
              .fontSize(GSYFontSize.min)
              .fontColor(GSYColor.primary)
              .margin({ top: GSYSpacing.halfEdge });
          }
        }
        .id('login_form')
        .width('100%')
        .alignItems(HorizontalAlign.Center);
      }
      .id('login_root')
      .width('86%')
      .constraintSize({ minHeight: 520 })
      .padding({
        top: 30,
        bottom: 30,
        left: 30,
        right: 30,
      })
      .backgroundColor(GSYColor.cardBackground)
      .borderRadius(8)
      .alignItems(HorizontalAlign.Center);

      if (this.showLanguageDialog) {
        Column() {
          Column() {
            Text(I18n('language'))
              .id('login_language_title')
              .fontSize(GSYFontSize.middleWhite)
              .fontWeight(FontWeight.Bold)
              .fontColor(GSYColor.darkText)
              .width('100%')
              .textAlign(TextAlign.Start)
              .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge, top: 16, bottom: 12 });

            this.buildLanguageOption(LANGUAGE_OPTION_SYSTEM, I18n('systemLanguage'));
            Divider().color(GSYColor.pillDivider).strokeWidth(0.5);
            this.buildLanguageOption(LANGUAGE_OPTION_ZH, I18n('zhLanguage'));
            Divider().color(GSYColor.pillDivider).strokeWidth(0.5);
            this.buildLanguageOption(LANGUAGE_OPTION_EN, I18n('enLanguage'));
          }
          .id('login_language_dialog')
          .width('86%')
          .backgroundColor(GSYColor.cardBackground)
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start);
        }
        .id('login_language_overlay')
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(GSYColor.loadingMaskBg);
      }

      if (this.loading) {
        Column() {
          Column() {
            LoadingProgress()
              .id('login_loading_progress')
              .width(36)
              .height(36)
              .color(GSYColor.white);
          }
          .width(72)
          .height(72)
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(GSYColor.loadingMaskBg);
        }
        .id('login_loading_overlay')
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(GSYColor.loadingLightMaskBg);
      }
    }
    .id('login_stack_root')
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
    .backgroundColor(GSYColor.primary);
  }
}
