import webview from '@ohos.web.webview';
import router from '@ohos.router';
import { AuthDeepLinkBus } from '../auth/AuthDeepLinkBus';
import { OauthService, DEFAULT_OAUTH_REDIRECT_URI, DEFAULT_OAUTH_SCOPE } from '../auth/OauthService';
import { NavigationService } from '../navigation/NavigationService';
import { HOST_WEB } from '../net/Address';
import { AppBar } from '../common/AppBar';
import { Url } from '../utils/Url';
import { GSYColor } from '../style/Theme';
import { I18n } from '../i18n/I18n';

const REDIRECT_URI: string = DEFAULT_OAUTH_REDIRECT_URI;

export class LoginWebDeps {
  private static clientId: string = '';

  static setClientId(id: string): void {
    LoginWebDeps.clientId = id;
  }

  static getClientId(): string {
    return LoginWebDeps.clientId;
  }
}

interface LoginWebRouteParams {
  authorizeUrl?: string;
  state?: string;
  redirectUri?: string;
  clientId?: string;
  scope?: string;
}

@Component
export struct LoginWebPage {
  @State currentUrl: string = '';
  @State expectedState: string = '';
  @State expectedRedirect: string = REDIRECT_URI;
  private controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    const params: Object | undefined = router.getParams() as Object | undefined;
    const route: LoginWebRouteParams = (params !== undefined && params !== null
      ? params as LoginWebRouteParams
      : {});
    const redirectUri: string = (route.redirectUri !== undefined && route.redirectUri !== null
      && route.redirectUri.length > 0)
      ? route.redirectUri
      : REDIRECT_URI;
    this.expectedRedirect = redirectUri;
    this.expectedState = (route.state !== undefined && route.state !== null) ? route.state : '';

    if (route.authorizeUrl !== undefined && route.authorizeUrl !== null && route.authorizeUrl.length > 0) {
      this.currentUrl = route.authorizeUrl;
      return;
    }
    const clientId: string = (route.clientId !== undefined && route.clientId !== null && route.clientId.length > 0)
      ? route.clientId
      : LoginWebDeps.getClientId();
    const scope: string = (route.scope !== undefined && route.scope !== null && route.scope.length > 0)
      ? route.scope
      : DEFAULT_OAUTH_SCOPE;
    const fallbackState: string = OauthService.generateState();
    this.expectedState = fallbackState;
    this.currentUrl = OauthService.buildAuthorizeUrl(clientId, redirectUri, scope, fallbackState);
  }

  private interceptDeepLink(url: string): boolean {
    if (!url || url.length === 0) {
      return false;
    }
    const target: string = this.expectedRedirect.length > 0 ? this.expectedRedirect : REDIRECT_URI;
    if (url.indexOf(target) !== 0) {
      return false;
    }
    const query: Map<string, string> = Url.parseQuery(url);
    const code: string | undefined = query.get('code');
    const state: string | undefined = query.get('state');
    if (code === undefined || code.length === 0) {
      return false;
    }
    if (this.expectedState.length > 0) {
      if (state === undefined || state.length === 0 || state !== this.expectedState) {
        return false;
      }
    } else if (state !== undefined && state.length > 0 && !OauthService.validateState(state)) {
      return false;
    }
    const deepLinkUri: string = state !== undefined && state.length > 0
      ? `${target}?code=${encodeURIComponent(code)}&state=${encodeURIComponent(state)}`
      : `${target}?code=${encodeURIComponent(code)}`;
    AuthDeepLinkBus.publish(deepLinkUri);
    NavigationService.pop();
    return true;
  }

  build(): void {
    Column() {
      AppBar({
        title: I18n('GithubAuthorization'),
        showBack: true,
        onBack: (): void => {
          NavigationService.pop();
        },
      })
        .id('login_web_appbar');

      if (this.currentUrl.length > 0) {
        Web({ src: this.currentUrl, controller: this.controller })
          .id('login_web_view')
          .domStorageAccess(true)
          .javaScriptAccess(true)
          .mixedMode(MixedMode.All)
          .layoutWeight(1)
          .onLoadIntercept((event: OnLoadInterceptEvent): boolean => {
            const request: WebResourceRequest = event.data;
            const url: string = request.getRequestUrl();
            return this.interceptDeepLink(url);
          });
      }
    }
    .id('login_web_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.white);
  }
}

export { HOST_WEB };
