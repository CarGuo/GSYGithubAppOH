import { AuthDeepLinkBus } from '../../../main/ets/auth/AuthDeepLinkBus';
import {
  OauthService,
  DEFAULT_OAUTH_REDIRECT_URI,
  DEFAULT_OAUTH_SCOPE,
} from '../../../main/ets/auth/OauthService';
import { LoginOutcome } from '../../../main/ets/auth/LoginUseCase';
import { Url } from '../../../main/ets/utils/Url';
import {
  AuthStore,
  GlobalAuthStore,
  APP_STORAGE_KEY_TOKEN,
  APP_STORAGE_KEY_AUTHED,
} from '../../../main/ets/store/AuthStore';
import { NavigationService, RouterLike } from '../../../main/ets/navigation/NavigationService';
import { RouteName } from '../../../main/ets/navigation/Routes';
import router from '@ohos.router';

class OauthHostCapturedRoute {
  kind: string;
  url: string;

  constructor(kind: string, url: string) {
    this.kind = kind;
    this.url = url;
  }
}

class OauthHostFakeRouter implements RouterLike {
  routes: OauthHostCapturedRoute[] = [];

  pushUrl(options: router.RouterOptions): Promise<void> {
    this.routes.push(new OauthHostCapturedRoute('push', options.url));
    return Promise.resolve();
  }

  replaceUrl(options: router.RouterOptions): Promise<void> {
    this.routes.push(new OauthHostCapturedRoute('replace', options.url));
    return Promise.resolve();
  }

  back(): void {
  }

  clear(): void {
  }
}

export class OauthHostBridge {
  private static fakeRouter: OauthHostFakeRouter = new OauthHostFakeRouter();

  static install(): void {
    NavigationService.setRouter(OauthHostBridge.fakeRouter);
  }

  static replacedToHome(): boolean {
    const target: string = `pages/${RouteName.Home}Page`;
    for (let i: number = 0; i < OauthHostBridge.fakeRouter.routes.length; i++) {
      const r: OauthHostCapturedRoute = OauthHostBridge.fakeRouter.routes[i];
      if (r.kind === 'replace' && r.url === target) {
        return true;
      }
    }
    return false;
  }

  static reset(): void {
    OauthHostBridge.fakeRouter.routes = [];
  }
}

@Entry
@Component
struct OauthHostPage {
  @State currentState: string = '';
  @State exchangeCount: number = 0;
  @State lastCode: string = '';
  @State lastResultText: string = '';
  @StorageLink('auth.token') token: string = '';
  @StorageLink('auth.authed') authed: boolean = false;
  private store: AuthStore = GlobalAuthStore;
  private offDeepLink: (() => void) | null = null;

  aboutToAppear(): void {
    OauthHostBridge.install();
    AppStorage.setOrCreate<string>(APP_STORAGE_KEY_TOKEN, '');
    AppStorage.setOrCreate<boolean>(APP_STORAGE_KEY_AUTHED, false);
    this.offDeepLink = AuthDeepLinkBus.subscribe((uri: string): void => {
      this.handleDeepLink(uri);
    });
  }

  aboutToDisappear(): void {
    if (this.offDeepLink !== null) {
      this.offDeepLink();
      this.offDeepLink = null;
    }
  }

  private async handleDeepLink(uri: string): Promise<void> {
    const query: Map<string, string> = Url.parseQuery(uri);
    const code: string | undefined = query.get('code');
    const state: string | undefined = query.get('state');
    if (code === undefined || code.length === 0) {
      return;
    }
    if (state !== undefined && state.length > 0 && !OauthService.validateState(state)) {
      this.lastResultText = 'state-invalid';
      return;
    }
    this.lastCode = code;
    this.exchangeCount = this.exchangeCount + 1;
    const res: LoginOutcome = await OauthService.exchangeOAuthCode(code);
    this.lastResultText = res.result ? 'ok' : `fail:${res.code}`;
    if (res.result) {
      NavigationService.replace(RouteName.Home);
    }
  }

  private genState(): void {
    OauthService.buildAuthorizeUrl(
      'cid_in_host',
      DEFAULT_OAUTH_REDIRECT_URI,
      DEFAULT_OAUTH_SCOPE,
    );
    this.currentState = OauthService.getLastState();
  }

  build(): void {
    Column() {
      Text('OauthHost')
        .id('oauth_host_title')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 8 });

      Text('state:' + this.currentState)
        .id('oauth_host_state')
        .fontSize(12)
        .fontColor('#959595');

      Text('exchange:' + this.exchangeCount.toString())
        .id('oauth_host_exchange_count')
        .fontSize(12)
        .fontColor('#959595');

      Text('last-code:' + this.lastCode)
        .id('oauth_host_last_code')
        .fontSize(12)
        .fontColor('#959595');

      Text('result:' + this.lastResultText)
        .id('oauth_host_result')
        .fontSize(12)
        .fontColor('#959595');

      Text('token:' + this.token)
        .id('oauth_host_token')
        .fontSize(12)
        .fontColor('#959595');

      Text('authed:' + (this.authed ? 'yes' : 'no'))
        .id('oauth_host_authed')
        .fontSize(12)
        .fontColor('#959595');

      Button('gen-state')
        .id('oauth_host_gen_state_btn')
        .type(ButtonType.Capsule)
        .margin({ top: 12 })
        .onClick((): void => {
          this.genState();
        });

      Button('emit-deeplink')
        .id('oauth_host_emit_btn')
        .type(ButtonType.Capsule)
        .margin({ top: 12 })
        .onClick((): void => {
          const state: string = OauthService.getLastState();
          const uri: string = state.length > 0
            ? `gsygithub://authed?code=host_code&state=${encodeURIComponent(state)}`
            : 'gsygithub://authed?code=host_code';
          AuthDeepLinkBus.publish(uri);
        });

      Button('emit-bad-state')
        .id('oauth_host_emit_bad_btn')
        .type(ButtonType.Capsule)
        .margin({ top: 12 })
        .onClick((): void => {
          AuthDeepLinkBus.publish('gsygithub://authed?code=any&state=NOT_MATCH');
        });
    }
    .id('oauth_host_root')
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor('#FFFFFF');
  }
}
