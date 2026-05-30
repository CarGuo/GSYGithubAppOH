import webview from '@ohos.web.webview';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import fs from '@ohos.file.fs';
import { I18n } from '../../i18n/I18n';
import { CommonToast } from '../../common/CommonToast';
import { NavigationService } from '../../navigation/NavigationService';
import { RouteName } from '../../navigation/Routes';
import { GSYColor, GSYFontSize, GSYSpacing } from '../../style/Theme';
import { Logger } from '../../ai-debug/Logger';
import { RepositoryDetailStore } from '../../store/RepositoryDetailStore';

interface ReadmeTabUserRouteParam {
  login: string;
}

interface ReadmeTabRepoRouteParam {
  owner: string;
  name: string;
  fullName: string;
}

interface ReadmeTabWebRouteParam {
  uri: string;
}

const README_TAB_FALLBACK_BRANCH: string = 'master';

@Component
export struct ReadmeTab {
  @ObjectLink store: RepositoryDetailStore;
  @Prop fullName: string = '';
  @Prop branch: string = README_TAB_FALLBACK_BRANCH;
  @Watch('onReadmeHtmlChange') @Prop readmeHtml: string = '';
  @Prop readmeLoading: boolean = false;
  @Prop readmeError: string = '';
  @State loadedHtml: string = '';
  @State webSrc: string = 'about:blank';
  @State controllerAttached: boolean = false;
  private webController: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    if (this.readmeHtml.length > 0) {
      this.safeLoad(this.readmeHtml);
    }
  }

  onReadmeHtmlChange(): void {
    Logger.i('ReadmeTab', `onReadmeHtmlChange len=${this.readmeHtml.length}`
      + ` attached=${this.controllerAttached}`);
    if (this.readmeHtml.length > 0 && this.loadedHtml !== this.readmeHtml) {
      this.safeLoad(this.readmeHtml);
    }
  }

  private buildHtmlDoc(html: string, baseUrl: string): string {
    if (html === null || html === undefined || html.length === 0) {
      return '<html><body></body></html>';
    }
    const baseTag: string = '<base href="' + baseUrl + '">';
    const mobileStyle: string = '<style>'
      + 'body{padding:15px;}'
      + 'img{max-width:100% !important;height:auto !important;}'
      + 'pre{background-color:#f6f8fa;padding:16px;overflow:auto;border-radius:6px;}'
      + '</style>';
    const headEnd: number = html.indexOf('</head>');
    if (headEnd > -1) {
      return html.substring(0, headEnd) + baseTag + mobileStyle + html.substring(headEnd);
    }
    return '<html><head>' + baseTag + mobileStyle + '</head><body>' + html + '</body></html>';
  }

  private resolveBaseUrl(): string {
    // README 里的相对路径资源（如 <img src="static/image/logo.png">）需要一个 baseUrl
    // 才能解析到正确的 GitHub raw 地址；对齐 Compose loadDataWithBaseURL 行为。
    if (this.fullName.length === 0) {
      return 'https://github.com/';
    }
    const branch: string = this.branch.length > 0 ? this.branch : README_TAB_FALLBACK_BRANCH;
    return `https://raw.githubusercontent.com/${this.fullName}/${branch}/`;
  }

  private ensureReadmeDir(dir: string): void {
    try {
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir, true);
      }
    } catch (_e) {
      fs.mkdirSync(dir, true);
    }
  }

  private safeReadmeFileName(): string {
    const source: string = this.fullName.length > 0 ? this.fullName : 'repository';
    return source.replace(/[^A-Za-z0-9_.-]/g, '_') + '_readme.html';
  }

  private writeHtmlDoc(doc: string): string {
    const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const dir: string = ctx.cacheDir + '/readme';
    this.ensureReadmeDir(dir);
    const filePath: string = dir + '/' + this.safeReadmeFileName();
    const file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, doc);
    } finally {
      fs.closeSync(file);
    }
    return filePath;
  }

  private safeLoad(html: string): void {
    const baseUrl: string = this.resolveBaseUrl();
    Logger.i('ReadmeFlow',
      `ReadmeTab.safeLoad called htmlLen=${html.length} attached=${this.controllerAttached}`
        + ` baseUrl=${baseUrl}`);
    if (html === this.loadedHtml && this.webSrc.length > 0 && this.webSrc !== 'about:blank') {
      return;
    }
    const doc: string = this.buildHtmlDoc(html, baseUrl);
    // 在 Tabs 内 `WebviewController.loadData` 有时不会反映到 Web 的 src/画面；
    // 写入本地 HTML 并切换 file:// 源更稳定，也便于截图断言真实内容。
    try {
      const filePath: string = this.writeHtmlDoc(doc);
      this.webSrc = 'file://' + filePath;
      this.loadedHtml = html;
      Logger.i('ReadmeFlow',
        `ReadmeTab.safeLoad fileUrl ok path=${filePath} loadedLen=${html.length}`);
      return;
    } catch (e) {
      const err: Error = e as Error;
      Logger.w('ReadmeFlow', `ReadmeTab.safeLoad fileUrl throw msg=${err.message}`);
      this.webSrc = 'data:text/html;charset=utf-8,' + encodeURIComponent(doc);
      Logger.i('ReadmeFlow',
        `ReadmeTab.safeLoad dataUrl fallback loadedLen=${html.length} srcLen=${this.webSrc.length}`);
    }
    this.loadedHtml = html;
  }

  /**
   * WebView 内部链接统一分发：仓库 → RepositoryDetail；用户 → UserDetail；其他/图片 → 系统浏览器或 OH WebPage。
   * 复刻自 [CodeDetailPage.interceptUrl](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/CodeDetailPage.ets#L129-L172)。
   */
  private interceptUrl(url: string): boolean {
    if (url === null || url === undefined || url.length === 0) {
      return false;
    }
    if (url === 'about:blank' || url.indexOf('data:') === 0) {
      return false;
    }
    let target: string = url;
    if (url.indexOf('gsygithub://') === 0) {
      const tail: string = url.substring('gsygithub://'.length).replace(/^\.\//, '');
      const branch: string = this.branch.length > 0 ? this.branch : README_TAB_FALLBACK_BRANCH;
      if (this.fullName.length === 0) {
        Logger.w('ReadmeTab', `interceptUrl gsygithub no fullName url=${url}`);
        CommonToast.showShort(I18n('webRelativeLinkNeedRepoContext'));
        return true;
      }
      target = `https://github.com/${this.fullName}/blob/${branch}/${tail}`;
      Logger.i('ReadmeTab', `interceptUrl gsygithub mapped url=${target}`);
    }
    if (target.indexOf('https://github.com/') !== 0) {
      if (target.indexOf('http://') === 0 || target.indexOf('https://') === 0) {
        this.openUrlInBrowser(target);
        return true;
      }
      return false;
    }
    const path: string = target.substring('https://github.com/'.length);
    const segs: string[] = path.split('/');
    if (segs.length === 1 && segs[0].length > 0) {
      const userParam: ReadmeTabUserRouteParam = { login: segs[0] };
      Logger.i('ReadmeTab', `interceptUrl push UserDetail login=${segs[0]}`);
      NavigationService.push(RouteName.UserDetail, userParam as Object);
      return true;
    }
    if (segs.length >= 2 && segs[0].length > 0 && segs[1].length > 0) {
      if (segs.length === 2) {
        const repoParam: ReadmeTabRepoRouteParam = {
          owner: segs[0],
          name: segs[1],
          fullName: `${segs[0]}/${segs[1]}`,
        };
        Logger.i('ReadmeTab', `interceptUrl push RepositoryDetail fullName=${repoParam.fullName}`);
        NavigationService.push(RouteName.RepositoryDetail, repoParam as Object);
        return true;
      }
      const webParam: ReadmeTabWebRouteParam = { uri: target };
      Logger.i('ReadmeTab', `interceptUrl push WebPage uri=${target}`);
      NavigationService.push(RouteName.WebPage, webParam as Object);
      return true;
    }
    return false;
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
      ctx.startAbility(want)
        .then((): void => {
          Logger.i('ReadmeTab', `openUrlInBrowser ok url=${url}`);
        })
        .catch((err: Error): void => {
          Logger.w('ReadmeTab', `openUrlInBrowser fail msg=${err.message}`);
          CommonToast.showShort(I18n('browserOpen'));
        });
    } catch (e) {
      const err = e as Error;
      Logger.e('ReadmeTab', `openUrlInBrowser throw`, err);
    }
  }

  @Builder
  private buildLoading(): void {
    Column() {
      LoadingProgress()
        .id('readme_tab_loading_indicator')
        .width(28)
        .height(28)
        .color(GSYColor.primary);
      Text(I18n('loading'))
        .id('readme_tab_loading_text')
        .fontSize(GSYFontSize.middleNormal)
        .fontColor(GSYColor.subText)
        .margin({ top: GSYSpacing.halfEdge });
    }
    .id('readme_tab_loading_root')
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(GSYColor.white);
  }

  @Builder
  private buildEmpty(): void {
    Column() {
      Text(I18n('reposReadme'))
        .id('readme_tab_empty_title')
        .fontSize(GSYFontSize.middleNormal)
        .fontColor(GSYColor.subText);
      Text(this.readmeError.length > 0 ? this.readmeError : I18n('userInfoNoting'))
        .id('readme_tab_empty_desc')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.tabUnSelect)
        .margin({ top: GSYSpacing.halfEdge });
    }
    .id('readme_tab_empty_root')
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(GSYColor.white);
  }

  build(): void {
    Stack() {
      Web({
        src: this.webSrc,
        controller: this.webController,
      })
        .id('readme_tab_web')
        .width('100%')
        .height('100%')
        .javaScriptAccess(true)
        .fileAccess(true)
        .domStorageAccess(true)
        .mixedMode(MixedMode.All)
        .onControllerAttached((): void => {
          this.controllerAttached = true;
          Logger.i('ReadmeFlow',
            `ReadmeTab.onControllerAttached propLen=${this.readmeHtml.length}`);
          if (this.readmeHtml.length > 0 && this.loadedHtml !== this.readmeHtml) {
            this.safeLoad(this.readmeHtml);
          }
        })
        .onPageBegin((event: OnPageBeginEvent): void => {
          Logger.i('ReadmeFlow', `ReadmeTab.onPageBegin url=${event.url}`);
        })
        .onPageEnd((event: OnPageEndEvent): void => {
          Logger.i('ReadmeFlow',
            `ReadmeTab.onPageEnd url=${event.url} propLen=${this.readmeHtml.length}`
              + ` loadedLen=${this.loadedHtml.length}`);
          if (this.readmeHtml.length > 0 && this.loadedHtml !== this.readmeHtml) {
            this.safeLoad(this.readmeHtml);
          }
        })
        .onErrorReceive((event: OnErrorReceiveEvent): void => {
          const req: WebResourceRequest = event.request;
          const errInfo: WebResourceError = event.error;
          Logger.w('ReadmeFlow',
            `ReadmeTab.onErrorReceive url=${req.getRequestUrl()}`
              + ` mainFrame=${req.isMainFrame()} code=${errInfo.getErrorCode()}`
              + ` msg=${errInfo.getErrorInfo()}`);
        })
        .onHttpErrorReceive((event: OnHttpErrorReceiveEvent): void => {
          const req: WebResourceRequest = event.request;
          const resp: WebResourceResponse = event.response;
          Logger.w('ReadmeFlow',
            `ReadmeTab.onHttpErrorReceive url=${req.getRequestUrl()}`
              + ` mainFrame=${req.isMainFrame()} status=${resp.getResponseCode()}`);
        })
        .onConsole((event: OnConsoleEvent): boolean => {
          const msg: ConsoleMessage = event.message;
          Logger.i('ReadmeFlow',
            `ReadmeTab.onConsole [${msg.getMessageLevel()}] ${msg.getMessage()}`);
          return false;
        })
        .onLoadIntercept((event: OnLoadInterceptEvent): boolean => {
          const request: WebResourceRequest = event.data;
          // README HTML 里包含大量子资源（图片 camo.githubusercontent.com、
          // highlight.js cdn css/js、raw.githubusercontent.com 等）。
          // onLoadIntercept 会对所有子资源也回调，这里必须只拦截主框架导航，
          // 否则子资源会被当成"站外链接"唤起浏览器并被阻断，导致 README 空白。
          if (!request.isMainFrame()) {
            return false;
          }
          return this.interceptUrl(request.getRequestUrl());
        });
      // Compose 的 GSYGeneralLoadState：内容为空且仍在请求时显示加载中，
      // 只有请求结束并失败后才显示空/错误态，避免 Web about:blank 白屏或误报失败。
      if (this.readmeHtml.length === 0) {
        if (this.readmeLoading || this.readmeError.length === 0) {
          this.buildLoading();
        } else {
          this.buildEmpty();
        }
      }
    }
    .id('readme_tab_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.white);
  }
}
