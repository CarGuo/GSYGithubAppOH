/**
 * WebPage —— L6.5 通用 Web 浏览页（github 站外链兜底 + gsygithub:// 业务深链回归）
 *
 * RN 基准 [WebPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/WebPage.js)：
 *   - 顶部地址栏 Row（chevron-back + URL TextInput + search-circle，primaryColor 背景）
 *   - WebView 主体（javaScriptEnabled / domStorageEnabled / mixedContentMode='always'）
 *   - resolveUrl 兜底加 'http://'
 *   - BackHandler 拦截硬件返回（webview.canGoBack ? webview.goBack() : Actions.pop()）
 *   - 入口：[htmlUtils.launchUrl#L380-L399](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js#L380-L399)
 *           + [CustomWebComponent#L69](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/CustomWebComponent.js#L69)
 *
 * OH 端 v1（OH 增强：地址栏 → AppBar）：
 *   - 顶部 AppBar（title=webController.getTitle 或 host fallback，rightActions=reload）
 *   - Web 组件主体（layoutWeight(1)）
 *   - onLoadIntercept：gsygithub:// 占位 hilog [web/anchor]；其他链接 return false 让 Web 自处理
 *   - 入口参数：{ uri: string }（与 RN 字段对齐）
 *   - boot 通道：want.parameters.bootWeb=<url>（KI-042 / KI-045 同款 BOOT_*_KEY 范式）
 *
 * HARD-LAW 自检：
 *   - LAW-1 RN-FIRST：抽源 ui-parity/WebPage.md §1
 *   - LAW-2 token-only：颜色/字号/间距全走 GSYColor / GSYFontSize / GSYSpacing
 *   - LAW-3 NO-DEBUG-PROBE：UI 树仅 AppBar + Web；3 个 hilog tag [web/page]/[web/anchor]/[web/intercept]
 *   - R-UI-05：无 @Builder 值参；onLoadIntercept 内 inline 求值
 */
import webview from '@ohos.web.webview';
import hilog from '@ohos.hilog';
import { NavigationService } from '../navigation/NavigationService';
import { RouteParamStore } from '../navigation/RouteParamStore';
import { RouteName } from '../navigation/Routes';
import { BOOT_WEB_KEY } from '../entryability/EntryAbility';
import { AppBar, AppBarAction } from '../common/AppBar';
import { CommonToast } from '../common/CommonToast';
import { I18n } from '../i18n/I18n';
import { GSYColor } from '../style/Theme';
import { Logger } from '../ai-debug/Logger';

const TAG: string = 'WebPage';
const DOMAIN: number = 0x0666;

interface WebPageRouteParam {
  uri: string;
}

@Component
export struct WebPage {
  @State uri: string = '';
  @State pageTitle: string = '';
  @State pageHost: string = '';
  private controller: webview.WebviewController = new webview.WebviewController();

  private adoptUri(initial: string): void {
    let candidate: string = initial;
    if (candidate.length === 0) {
      const fallback: string | undefined = AppStorage.get<string>(BOOT_WEB_KEY);
      if (fallback !== undefined && fallback.length > 0) {
        candidate = fallback;
        Logger.i('boot/ts', `WebPage adopt BOOT_WEB_KEY fallback uri=${candidate}`);
      }
    }
    this.uri = WebPage.resolveUrl(candidate);
    this.pageHost = WebPage.parseHost(this.uri);
    hilog.info(DOMAIN, TAG, '[web/page] init uri=%{public}s', this.uri);
  }

  private static resolveUrl(raw: string): string {
    if (raw.length === 0) {
      return '';
    }
    if (/^[a-zA-Z][a-zA-Z0-9+\-.]*:/.test(raw)) {
      return raw;
    }
    return 'http://' + raw;
  }

  private static parseHost(url: string): string {
    if (url.length === 0) {
      return '';
    }
    const schemeEnd: number = url.indexOf('://');
    if (schemeEnd < 0) {
      return url;
    }
    const rest: string = url.substring(schemeEnd + 3);
    const slash: number = rest.indexOf('/');
    return slash < 0 ? rest : rest.substring(0, slash);
  }

  private resolveTitle(): string {
    if (this.pageTitle.length > 0) {
      return this.pageTitle;
    }
    return this.pageHost.length > 0 ? this.pageHost : 'WebPage';
  }

  private onReload(): void {
    hilog.info(DOMAIN, TAG, '[web/page] reload');
    try {
      this.controller.refresh();
    } catch (e) {
      const err: Error = e as Error;
      hilog.warn(DOMAIN, TAG, '[web/page] reload fail %{public}s', err.message);
    }
  }

  private onInterceptUrl(url: string): boolean {
    if (url.length === 0) {
      return false;
    }
    if (url.indexOf('gsygithub://') === 0) {
      hilog.info(DOMAIN, TAG, '[web/anchor] gsygithub anchor url=%{public}s', url);
      CommonToast.showShort(I18n('webRelativeLinkNeedRepoContext'));
      return true;
    }
    if (url.indexOf('https://github.com/') === 0 || url.indexOf('http://github.com/') === 0) {
      hilog.info(DOMAIN, TAG, '[web/intercept] github candidate url=%{public}s', url);
      return false;
    }
    return false;
  }

  build(): void {
    NavDestination() {
      Column() {
        AppBar({
          title: this.resolveTitle(),
          titleStart: true,
          showBack: true,
          onBack: (): void => {
            NavigationService.pop();
          },
          rightActions: [
            {
              iconKey: 'reload',
              onAction: (): void => {
                this.onReload();
              },
            } as AppBarAction,
          ],
        })
          .id('web_page_appbar');

        if (this.uri.length > 0) {
          Web({ src: this.uri, controller: this.controller })
            .id('web_page_view')
            .domStorageAccess(true)
            .javaScriptAccess(true)
            .mixedMode(MixedMode.All)
            .zoomAccess(true)
            .layoutWeight(1)
            .onTitleReceive((event: OnTitleReceiveEvent): void => {
              this.pageTitle = event.title;
            })
            .onPageEnd((event: OnPageEndEvent): void => {
              this.pageHost = WebPage.parseHost(event.url);
              hilog.info(DOMAIN, TAG, '[web/page] onPageEnd url=%{public}s', event.url);
            })
            .onLoadIntercept((event: OnLoadInterceptEvent): boolean => {
              const request: WebResourceRequest = event.data;
              const url: string = request.getRequestUrl();
              return this.onInterceptUrl(url);
            });
        }
      }
      .id('web_page_root')
      .width('100%')
      .height('100%')
      .backgroundColor(GSYColor.mainBackground);
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext): void => {
      // 优先级 1：RouteParamStore（NavigationService.push 同步写入，覆盖所有 push 入口）
      const routeRaw: Object | null = RouteParamStore.consume(RouteName.WebPage);
      if (routeRaw !== null) {
        const routeParam: WebPageRouteParam = routeRaw as WebPageRouteParam;
        if (routeParam.uri !== undefined && routeParam.uri !== null && routeParam.uri.length > 0) {
          Logger.i('web/route', `WebPage adopted via RouteParamStore uri=${routeParam.uri}`);
          this.adoptUri(routeParam.uri);
          return;
        }
      }
      let initial: string = '';
      try {
        const info: NavPathInfo | undefined = ctx.pathInfo;
        if (info !== undefined && info !== null && info.param !== undefined && info.param !== null) {
          const route: WebPageRouteParam = info.param as WebPageRouteParam;
          if (route.uri !== undefined && route.uri !== null && route.uri.length > 0) {
            initial = route.uri;
          }
        }
      } catch (_e) {
        initial = '';
      }
      this.adoptUri(initial);
    });
  }
}
