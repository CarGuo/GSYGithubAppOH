import webview from '@ohos.web.webview';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import fs from '@ohos.file.fs';
import pasteboard from '@ohos.pasteboard';
import { AppBar, AppBarAction } from '../common/AppBar';
import { CommonToast } from '../common/CommonToast';
import { CommonModal, CommonOptionItem } from '../common/CommonModal';
import { BOOT_CODE_KEY } from '../entryability/EntryAbility';
import { I18n } from '../i18n/I18n';
import { NavigationService } from '../navigation/NavigationService';
import { RouteParamStore } from '../navigation/RouteParamStore';
import { RouteName } from '../navigation/Routes';
import { CodeDetailStore } from '../store/CodeDetailStore';
import { CodeService } from '../service/CodeService';
import { GSYColor, GSYFontSize } from '../style/Theme';
import { Logger } from '../ai-debug/Logger';

interface CodeDetailUserRouteParam {
  login: string;
}

interface CodeDetailRepoRouteParam {
  owner: string;
  name: string;
  fullName: string;
}

interface CodeDetailRouteParam {
  fullName?: string;
  branch?: string;
  sha?: string;
  path?: string;
}

const FALLBACK_FULL_NAME: string = '';
const FALLBACK_BRANCH: string = 'master';

@Component
export struct CodeDetailPage {
  @State fullName: string = FALLBACK_FULL_NAME;
  @State branch: string = FALLBACK_BRANCH;
  @State sha: string = '';
  @State path: string = '';
  @State store: CodeDetailStore = new CodeDetailStore();
  @State loadedHtml: string = '';
  @State webSrc: string = 'about:blank';
  @State controllerAttached: boolean = false;
  private service: CodeService = new CodeService(this.store);
  private webController: webview.WebviewController = new webview.WebviewController();
  private pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.service = new CodeService(this.store);
    if (this.tryAdoptRouteStore()) {
      return;
    }
    this.tryAdoptBootCode();
  }

  /**
   * 优先级 1：RouteParamStore（NavigationService.push 同步写入，覆盖所有 push 入口）。
   * 命中即赋值 @State 并返回 true，跳过后续 BOOT_CODE_KEY 兜底。
   */
  private tryAdoptRouteStore(): boolean {
    const routeRaw: Object | null = RouteParamStore.consume(RouteName.CodeDetail);
    if (routeRaw === null) {
      return false;
    }
    const routeParam: CodeDetailRouteParam = routeRaw as CodeDetailRouteParam;
    let adopted: boolean = false;
    this.sha = '';
    if (routeParam.fullName !== undefined && routeParam.fullName !== null && routeParam.fullName.length > 0) {
      this.fullName = routeParam.fullName;
      adopted = true;
    }
    if (routeParam.branch !== undefined && routeParam.branch !== null && routeParam.branch.length > 0) {
      this.branch = routeParam.branch;
      adopted = true;
    }
    if (routeParam.sha !== undefined && routeParam.sha !== null && routeParam.sha.length > 0) {
      this.sha = routeParam.sha;
      adopted = true;
    }
    if (routeParam.path !== undefined && routeParam.path !== null && routeParam.path.length > 0) {
      this.path = routeParam.path;
      adopted = true;
    }
    if (adopted) {
      Logger.i('CodeDetail',
        `aboutToAppear adoptRouteStore fullName=${this.fullName} branch=${this.branch} sha=${this.sha} path=${this.path}`);
    }
    return adopted;
  }

  /**
   * boot 通道兜底：当 NavPathStack push 的 param 丢失字段时（参考 KI-029 RepoDetail 同款时序竞争），
   * 从 AppStorage BOOT_CODE_KEY 直读 fullName|branch|path 兜底，读到后立即清空避免污染下次进入。
   */
  private tryAdoptBootCode(): void {
    const raw: string = (AppStorage.get<string>(BOOT_CODE_KEY) || '').trim();
    if (raw.length === 0) {
      return;
    }
    const sep1: number = raw.indexOf('|');
    if (sep1 <= 0 || sep1 >= raw.length - 1) {
      return;
    }
    const sep2: number = raw.indexOf('|', sep1 + 1);
    if (sep2 <= sep1 + 1 || sep2 >= raw.length - 1) {
      return;
    }
    const fullName: string = raw.substring(0, sep1);
    const branch: string = raw.substring(sep1 + 1, sep2);
    const path: string = raw.substring(sep2 + 1);
    if (fullName.length === 0 || branch.length === 0 || path.length === 0) {
      return;
    }
    this.fullName = fullName;
    this.branch = branch;
    this.sha = '';
    this.path = path;
    AppStorage.setOrCreate<string>(BOOT_CODE_KEY, '');
    Logger.i('CodeDetail', `aboutToAppear adoptBootCode fullName=${fullName} branch=${branch} path=${path}`);
  }

  private resolveParamFromStack(stack: NavPathStack): CodeDetailRouteParam | null {
    try {
      const all: string[] = stack.getAllPathName();
      if (all === undefined || all === null || all.length === 0) {
        return null;
      }
      const param: Object | undefined = stack.getParamByIndex(all.length - 1) as Object | undefined;
      if (param === undefined || param === null) {
        return null;
      }
      return param as CodeDetailRouteParam;
    } catch (_e) {
      return null;
    }
  }

  private async loadAll(): Promise<void> {
    if (this.fullName.length === 0 || this.path.length === 0) {
      this.store.setError('invalid params');
      return;
    }
    Logger.i('CodeDetail',
      `loadAll BEGIN fullName=${this.fullName} branch=${this.branch} sha=${this.sha} path=${this.path}`);
    if (this.sha.length > 0) {
      await this.service.getCommitFile(this.fullName, this.sha, this.path);
    } else {
      await this.service.getRawContent(this.fullName, this.branch, this.path);
    }
    this.updateWebSrc();
    Logger.i('CodeDetail', `loadAll END htmlLen=${this.store.htmlContent.length} err=${this.store.error}`);
  }

  private updateWebSrc(): void {
    const sourceHtml: string = this.store.htmlContent;
    if (sourceHtml === null || sourceHtml === undefined || sourceHtml.length === 0) {
      return;
    }
    if (sourceHtml === this.loadedHtml && this.webSrc.length > 0 && this.webSrc !== 'about:blank') {
      return;
    }
    const html: string = this.buildHtmlDoc();
    const baseUrl: string = this.resolveBaseUrl();
    if (this.controllerAttached) {
      try {
        this.webController.loadData(html, 'text/html', 'UTF-8', baseUrl, baseUrl);
        this.loadedHtml = sourceHtml;
        Logger.i('CodeDetail', `loadData ok sourceLen=${sourceHtml.length}`);
        return;
      } catch (e) {
        const err: Error = e as Error;
        Logger.w('CodeDetail', `loadData throw msg=${err.message}`);
      }
    }
    try {
      const filePath: string = this.writeHtmlDoc(html);
      this.webSrc = 'file://' + filePath;
      Logger.i('CodeDetail', `fileUrl fallback ok path=${filePath} sourceLen=${sourceHtml.length}`);
    } catch (e) {
      const err: Error = e as Error;
      Logger.w('CodeDetail', `fileUrl fallback throw msg=${err.message}`);
      this.webSrc = 'data:text/html;charset=utf-8,' + encodeURIComponent(html);
    }
    this.loadedHtml = sourceHtml;
    Logger.i('CodeDetail', `updateWebSrc fallback sourceLen=${sourceHtml.length} srcLen=${this.webSrc.length}`);
  }

  private ensureCodeDir(dir: string): void {
    try {
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir, true);
      }
    } catch (_e) {
      fs.mkdirSync(dir, true);
    }
  }

  private safeCodeFileName(): string {
    const source: string = (this.fullName.length > 0 ? this.fullName : 'repository')
      + '_' + (this.path.length > 0 ? this.path : 'file');
    return source.replace(/[^A-Za-z0-9_.-]/g, '_') + '_code.html';
  }

  private writeHtmlDoc(doc: string): string {
    const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const dir: string = ctx.cacheDir + '/code';
    this.ensureCodeDir(dir);
    const filePath: string = dir + '/' + this.safeCodeFileName();
    const file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, doc);
    } finally {
      fs.closeSync(file);
    }
    return filePath;
  }

  private resolveBaseUrl(): string {
    if (this.fullName.length === 0) {
      return 'https://github.com/';
    }
    const branch: string = this.branch.length > 0 ? this.branch : FALLBACK_BRANCH;
    return `https://raw.githubusercontent.com/${this.fullName}/${branch}/`;
  }

  private titleFileName(): string {
    if (this.path.length === 0) {
      return I18n('reposFile');
    }
    const idx: number = this.path.lastIndexOf('/');
    return idx >= 0 ? this.path.substring(idx + 1) : this.path;
  }

  private resolveHtmlUrl(): string {
    if (this.fullName.length === 0 || this.path.length === 0) {
      return '';
    }
    const branch: string = this.branch.length > 0 ? this.branch : FALLBACK_BRANCH;
    return 'https://github.com/' + this.fullName + '/blob/' + branch + '/' + this.path;
  }

  private copyToPasteboard(text: string): void {
    if (text.length === 0) {
      return;
    }
    try {
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const board: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      board.setData(data);
      CommonToast.showShort(I18n('hadCopy'));
    } catch (_e) {
      CommonToast.showShort(I18n('hadCopy'));
    }
  }

  private showMoreMenu(): void {
    const htmlUrl: string = this.resolveHtmlUrl();
    const items: CommonOptionItem[] = [
      { itemName: I18n('browserOpen') } as CommonOptionItem,
      { itemName: I18n('copy') } as CommonOptionItem,
      { itemName: I18n('share') } as CommonOptionItem,
    ];
    CommonModal.options(
      { title: this.titleFileName(), items: items },
      (index: number, _item: CommonOptionItem): void => {
        if (htmlUrl.length === 0) {
          return;
        }
        if (index === 0) {
          this.openUrlInBrowser(htmlUrl);
        } else if (index === 1) {
          this.copyToPasteboard(htmlUrl);
        } else if (index === 2) {
          this.openUrlInBrowser(htmlUrl);
        }
      }
    );
  }

  private buildRightActions(): AppBarAction[] {
    return [
      {
        iconKey: 'more',
        onAction: (): void => {
          this.showMoreMenu();
        },
      } as AppBarAction,
    ];
  }

  private buildHtmlDoc(): string {
    const html: string = this.store.htmlContent;
    if (html.length === 0) {
      return '<html><body></body></html>';
    }
    const baseUrl: string = this.resolveBaseUrl();
    const baseTag: string = '<base href="' + baseUrl + '">';
    const mobileStyle: string = '<style>'
      + 'img{max-width:100% !important;height:auto !important;}'
      + 'pre{overflow:auto;}'
      + '</style>';
    const headEnd: number = html.indexOf('</head>');
    if (headEnd > -1) {
      return html.substring(0, headEnd) + baseTag + mobileStyle + html.substring(headEnd);
    }
    return '<html><head><meta name="viewport" content="width=device-width, initial-scale=1.0">'
      + baseTag + mobileStyle + '</head><body>' + html + '</body></html>';
  }

  /**
   * WebView 内部链接统一分发：仓库 → RepositoryDetail；用户 → UserDetail；其他/图片 → 系统浏览器。
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
      const tail: string = url.substring('gsygithub://'.length);
      target = `https://github.com/${this.fullName}/blob/${this.branch}/${tail}`;
      Logger.i('CodeDetail', `interceptUrl gsygithub mapped url=${target}`);
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
      const userParam: CodeDetailUserRouteParam = { login: segs[0] };
      Logger.i('CodeDetail', `interceptUrl push UserDetail login=${segs[0]}`);
      NavigationService.push(RouteName.UserDetail, userParam as Object);
      return true;
    }
    if (segs.length >= 2 && segs[0].length > 0 && segs[1].length > 0) {
      if (segs.length === 2) {
        const repoParam: CodeDetailRepoRouteParam = {
          owner: segs[0],
          name: segs[1],
          fullName: `${segs[0]}/${segs[1]}`,
        };
        Logger.i('CodeDetail', `interceptUrl push RepositoryDetail fullName=${repoParam.fullName}`);
        NavigationService.push(RouteName.RepositoryDetail, repoParam as Object);
        return true;
      }
      this.openUrlInBrowser(target);
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
          Logger.i('CodeDetail', `openUrlInBrowser ok url=${url}`);
        })
        .catch((err: Error): void => {
          Logger.w('CodeDetail', `openUrlInBrowser fail msg=${err.message}`);
          CommonToast.showShort(I18n('browserOpen'));
        });
    } catch (e) {
      const err = e as Error;
      Logger.e('CodeDetail', `openUrlInBrowser throw`, err);
    }
  }

  @Builder
  buildLoading(): void {
    Column() {
      LoadingProgress()
        .id('code_detail_loading_indicator')
        .width(28)
        .height(28)
        .color(GSYColor.primary);
      Text(I18n('loading'))
        .id('code_detail_loading_text')
        .fontSize(GSYFontSize.middleNormal)
        .fontColor(GSYColor.subText)
        .margin({ top: 12 });
    }
    .id('code_detail_loading_root')
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  buildEmpty(): void {
    Column() {
      Text(I18n('fileNotSupport'))
        .id('code_detail_empty_title')
        .fontSize(GSYFontSize.middleNormal)
        .fontColor(GSYColor.subText);
      if (this.store.error.length > 0) {
        Text(this.store.error)
          .id('code_detail_empty_error')
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.issueClosedRed)
          .margin({ top: 8 });
      }
    }
    .id('code_detail_empty_root')
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  build(): void {
    NavDestination() {
      Column() {
        AppBar({
          title: this.titleFileName(),
          titleId: 'code_detail_title_text',
          titleStart: true,
          showBack: true,
          rightActions: this.buildRightActions(),
          onBack: (): void => {
            NavigationService.pop();
          },
        })
          .id('code_detail_appbar');

        if (this.store.htmlContent.length === 0) {
          if (this.store.loading || this.store.error.length === 0) {
            this.buildLoading();
          } else {
            this.buildEmpty();
          }
        } else {
          Web({
            src: this.webSrc,
            controller: this.webController,
          })
            .id('code_detail_web')
            .width('100%')
            .layoutWeight(1)
            .javaScriptAccess(true)
            .fileAccess(true)
            .domStorageAccess(true)
            .mixedMode(MixedMode.All)
            .zoomAccess(true)
            .backgroundColor(GSYColor.white)
            .onControllerAttached((): void => {
              this.controllerAttached = true;
              Logger.i('CodeDetail', `onControllerAttached htmlLen=${this.store.htmlContent.length}`);
              this.updateWebSrc();
            })
            .onPageBegin((event: OnPageBeginEvent): void => {
              Logger.i('CodeDetail', `onPageBegin url=${event.url}`);
            })
            .onPageEnd((event: OnPageEndEvent): void => {
              Logger.i('CodeDetail', `onPageEnd url=${event.url} htmlLen=${this.store.htmlContent.length}`);
              if (this.store.htmlContent.length > 0 && this.loadedHtml !== this.store.htmlContent) {
                this.updateWebSrc();
              }
            })
            .onErrorReceive((event: OnErrorReceiveEvent): void => {
              const req: WebResourceRequest = event.request;
              const errInfo: WebResourceError = event.error;
              Logger.w('CodeDetail',
                `onErrorReceive url=${req.getRequestUrl()} mainFrame=${req.isMainFrame()}`
                  + ` code=${errInfo.getErrorCode()} msg=${errInfo.getErrorInfo()}`);
            })
            .onLoadIntercept((event: OnLoadInterceptEvent): boolean => {
              const request: WebResourceRequest = event.data;
              const url: string = request.getRequestUrl();
              return this.interceptUrl(url);
            });
        }
      }
      .id('code_detail_root')
      .width('100%')
      .height('100%')
      .backgroundColor(GSYColor.white);
    }
    .onReady((ctx: NavDestinationContext): void => {
      const stack: NavPathStack | undefined = ctx.pathStack;
      if (stack !== undefined && stack !== null) {
        this.pathStack = stack;
      }
      let param: CodeDetailRouteParam | null = null;
      try {
        const info: NavPathInfo | undefined = ctx.pathInfo;
        if (info !== undefined && info !== null && info.param !== undefined && info.param !== null) {
          param = info.param as CodeDetailRouteParam;
        }
      } catch (_e) {
        param = null;
      }
      if (param === null && stack !== undefined && stack !== null) {
        param = this.resolveParamFromStack(stack);
      }
      if (param !== null) {
        if (param.fullName !== undefined && param.fullName !== null && param.fullName.length > 0) {
          this.fullName = param.fullName;
        }
        if (param.branch !== undefined && param.branch !== null && param.branch.length > 0) {
          this.branch = param.branch;
        }
        this.sha = '';
        if (param.sha !== undefined && param.sha !== null && param.sha.length > 0) {
          this.sha = param.sha;
        }
        if (param.path !== undefined && param.path !== null && param.path.length > 0) {
          this.path = param.path;
        }
      }
      Logger.i('CodeDetail',
        `onReady fullName=${this.fullName} branch=${this.branch} sha=${this.sha} path=${this.path}`);
      this.loadAll();
    });
  }
}
