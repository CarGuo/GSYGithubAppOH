import pasteboard from '@ohos.pasteboard';
import { AppBar, AppBarAction } from '../common/AppBar';
import { I18n } from '../i18n/I18n';
import { Logger } from '../ai-debug/Logger';
import { CommonModal, CommonOptionItem } from '../common/CommonModal';
import { CommonToast } from '../common/CommonToast';
import { BOOT_PUSH_KEY } from '../entryability/EntryAbility';
import { NavigationService } from '../navigation/NavigationService';
import { RouteParamStore } from '../navigation/RouteParamStore';
import { RouteName } from '../navigation/Routes';
import { GSYColor, GSYFontSize, GSYIconSize, GSYShadow, GSYSpacing } from '../style/Theme';
import { IconFont } from '../common/IconFont';
import { TimeUtil } from '../utils/TimeUtil';
import {
  CommitAuthorInfo,
  CommitDetail,
  CommitFileItem,
  CommitInner,
  PushDetailStore,
} from '../store/PushDetailStore';
import { CommitService } from '../service/CommitService';
import { ExternalUrlUtil } from '../utils/ExternalUrlUtil';

interface PushDetailRouteParam {
  fullName?: string;
  sha?: string;
}

const FALLBACK_FULL_NAME: string = '';
const FALLBACK_SHA: string = '';
const FA_EDIT: string = '\uf044';

@Component
export struct PushDetailPage {
  @State fullName: string = FALLBACK_FULL_NAME;
  @State sha: string = FALLBACK_SHA;
  @State store: PushDetailStore = new PushDetailStore();
  private service: CommitService = new CommitService(this.store);
  private pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.service = new CommitService(this.store);
  }

  private resolveParamFromStack(stack: NavPathStack): PushDetailRouteParam | null {
    try {
      const all: string[] = stack.getAllPathName();
      if (all === undefined || all === null || all.length === 0) {
        return null;
      }
      const param: Object | undefined = stack.getParamByIndex(all.length - 1) as Object | undefined;
      if (param === undefined || param === null) {
        return null;
      }
      return param as PushDetailRouteParam;
    } catch (_e) {
      return null;
    }
  }

  private async loadAll(): Promise<void> {
    if (this.fullName.length === 0 || this.sha.length === 0) {
      Logger.i('boot/ts', `PushDetailPage.loadAll skip empty fullName='${this.fullName}' sha='${this.sha}'`);
      return;
    }
    Logger.i('boot/ts', `PushDetailPage.loadAll BEGIN fullName='${this.fullName}' sha='${this.sha}'`);
    const r = await this.service.getCommitDetail(this.fullName, this.sha);
    const c = this.store.commit;
    Logger.i('boot/ts', `PushDetailPage.loadAll done result=${r.result} code=${r.code} commit=${c !== null} files=${this.store.files.length}`);
  }

  private openFile(item: CommitFileItem): void {
    NavigationService.push(RouteName.CodeDetail, {
      'fullName': this.fullName,
      'sha': this.sha,
      'path': item.filename,
    } as Record<string, Object>);
  }

  private titleOwnerRepo(): string {
    return this.fullName.length > 0 ? this.fullName : I18n('reposPush');
  }

  private resolveHtmlUrl(): string {
    if (this.fullName.length === 0 || this.sha.length === 0) {
      return '';
    }
    return 'https://github.com/' + this.fullName + '/commit/' + this.sha;
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
      { title: this.titleOwnerRepo(), items: items },
      (index: number, _item: CommonOptionItem): void => {
        if (htmlUrl.length === 0) {
          return;
        }
        if (index === 0) {
          ExternalUrlUtil.openUrlInBrowser(this, htmlUrl, 'PushDetailPage');
        } else if (index === 1) {
          this.copyToPasteboard(htmlUrl);
        } else if (index === 2) {
          ExternalUrlUtil.openUrlInBrowser(this, htmlUrl, 'PushDetailPage');
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

  private getAuthorAvatar(): string {
    const c: CommitDetail | null = this.store.commit;
    if (c !== null && c.author !== null && c.author !== undefined) {
      return c.author.avatar_url;
    }
    if (c !== null && c.committer !== null && c.committer !== undefined) {
      return c.committer.avatar_url;
    }
    return '';
  }

  private getAuthorName(): string {
    const c: CommitDetail | null = this.store.commit;
    if (c === null) {
      return '';
    }
    if (c.author !== null && c.author !== undefined && c.author.login.length > 0) {
      return c.author.login;
    }
    if (c.commit !== null && c.commit !== undefined
      && c.commit.author !== null && c.commit.author !== undefined) {
      return c.commit.author.name;
    }
    return '';
  }

  private getAuthorDate(): string {
    const c: CommitDetail | null = this.store.commit;
    if (c === null || c.commit === null || c.commit === undefined) {
      return '';
    }
    const inner: CommitInner = c.commit;
    if (inner.committer !== null && inner.committer !== undefined && inner.committer.date.length > 0) {
      return inner.committer.date;
    }
    if (inner.author !== null && inner.author !== undefined) {
      return inner.author.date;
    }
    return '';
  }

  private getAuthorEmail(): string {
    const c: CommitDetail | null = this.store.commit;
    if (c === null || c.commit === null || c.commit === undefined) {
      return '';
    }
    const author: CommitAuthorInfo = c.commit.author;
    if (author !== null && author !== undefined) {
      return author.email;
    }
    return '';
  }

  private getMessage(): string {
    const c: CommitDetail | null = this.store.commit;
    if (c === null || c.commit === null || c.commit === undefined) {
      return '';
    }
    return c.commit.message !== null ? c.commit.message : '';
  }

  private filePathOf(filename: string): string {
    const safe: string = filename !== null && filename !== undefined ? filename : '';
    const idx: number = safe.lastIndexOf('/');
    return idx > -1 ? safe.substring(0, idx) : '';
  }

  private fileNameOf(filename: string): string {
    const safe: string = filename !== null && filename !== undefined ? filename : '';
    const idx: number = safe.lastIndexOf('/');
    return idx > -1 ? safe.substring(idx + 1) : safe;
  }

  @Builder
  buildCommitCard(): void {
    Column() {
      Row() {
        Image(this.getAuthorAvatar())
          .id('push_detail_author_avatar')
          .width(GSYIconSize.normal)
          .height(GSYIconSize.normal)
          .borderRadius(GSYIconSize.normal / 2)
          .objectFit(ImageFit.Cover);

        Column() {
          if (this.store.commit !== null) {
            Row() {
              IconFont({
                char: FA_EDIT,
                glyphSize: 16,
                glyphColor: GSYColor.primary,
              });
              Text((this.store.commit as CommitDetail).stats.total.toString())
                .id('push_detail_file_count_text')
                .fontSize(GSYFontSize.min)
                .fontColor(GSYColor.primary)
                .margin({ left: GSYSpacing.halfEdge, right: GSYSpacing.normalEdge });
              Text('+' + (this.store.commit as CommitDetail).stats.additions.toString())
                .id('push_detail_additions_text')
                .fontSize(GSYFontSize.min)
                .fontColor(GSYColor.issueOpenGreen)
                .margin({ right: GSYSpacing.normalEdge });
              Text('-' + (this.store.commit as CommitDetail).stats.deletions.toString())
                .id('push_detail_deletions_text')
                .fontSize(GSYFontSize.min)
                .fontColor(GSYColor.issueClosedRed);
            }
            .id('push_detail_stats_row')
            .alignItems(VerticalAlign.Center);
          }
          Text(TimeUtil.resolveTime(this.getAuthorDate()))
            .id('push_detail_date_text')
            .fontSize(GSYFontSize.min)
            .fontColor(GSYColor.mediumText)
            .margin({ top: GSYSpacing.halfEdge });
        }
        .layoutWeight(1)
        .margin({ left: GSYSpacing.normalEdge })
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      Text(this.getMessage().length > 0 ? this.getMessage() : I18n('userInfoNoting'))
        .id('push_detail_message_text')
        .fontSize(GSYFontSize.small)
        .fontWeight(FontWeight.Bold)
        .fontColor(GSYColor.mainText)
        .margin({ top: GSYSpacing.normalEdge })
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .id('push_detail_commit_card')
    .width('auto')
    .margin({
      left: GSYSpacing.composeCardHorizontal,
      right: GSYSpacing.composeCardHorizontal,
      top: GSYSpacing.composeCardVertical,
      bottom: GSYSpacing.composeCardVertical,
    })
    .padding({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.normalEdge,
      bottom: GSYSpacing.normalEdge
    })
    .borderRadius(8)
    .border({ width: 1, color: GSYColor.borderSubtle })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(GSYColor.composePrimaryContainer)
    .shadow({
      radius: GSYShadow.radius,
      color: GSYShadow.cardShadowAlpha,
      offsetX: 0,
      offsetY: GSYShadow.elevation,
    });
  }

  @Builder
  buildFileItem(item: CommitFileItem, idx: number): void {
    Column() {
      if (this.filePathOf(item.filename).length > 0) {
        Text(this.filePathOf(item.filename))
          .id('push_detail_file_path_' + idx.toString())
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.mediumText)
          .margin({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge, bottom: 2 });
      }

      Column() {
        Row() {
          IconFont({
            char: FA_EDIT,
            glyphSize: GSYIconSize.cardIcon,
            glyphColor: GSYColor.mainText,
          });
          Text(this.fileNameOf(item.filename))
            .id('push_detail_file_filename_' + idx.toString())
            .fontSize(GSYFontSize.normal)
            .fontColor(GSYColor.mainText)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ left: GSYSpacing.normalEdge });
        }
        .id('push_detail_file_card_' + idx.toString())
        .width('100%')
        .padding({
          left: GSYSpacing.normalEdge,
          right: GSYSpacing.normalEdge,
          top: GSYSpacing.normalEdge,
          bottom: GSYSpacing.normalEdge
        })
        .borderRadius(8)
        .border({ width: 1, color: GSYColor.borderSubtle })
        .backgroundColor(GSYColor.cardBackground)
        .shadow({
          radius: GSYShadow.radius,
          color: GSYShadow.cardShadowAlpha,
          offsetX: 0,
          offsetY: GSYShadow.elevation,
        })
        .alignItems(VerticalAlign.Center);
      }
      .width('100%')
      .padding({
        left: GSYSpacing.composeCardHorizontal,
        right: GSYSpacing.composeCardHorizontal,
        top: GSYSpacing.composeCardVertical,
        bottom: GSYSpacing.composeCardVertical,
      });
    }
    .id('push_detail_file_row_' + idx.toString())
    .width('100%')
    .onClick((): void => {
      this.openFile(item);
    });
  }

  build(): void {
    NavDestination() {
      Column() {
        AppBar({
          title: this.titleOwnerRepo(),
          titleStart: true,
          showBack: true,
          rightActions: this.buildRightActions(),
          onBack: (): void => {
            NavigationService.pop();
          },
        })
          .id('push_detail_appbar');

        List() {
          ListItem() {
            this.buildCommitCard();
          }
          .id('push_detail_header_list_item');

          ForEach(this.store.files, (item: CommitFileItem, idx: number): void => {
            ListItem() {
              this.buildFileItem(item, idx);
            }
            .id('push_detail_file_list_item_' + idx.toString());
          }, (item: CommitFileItem, idx: number): string => 'pf_' + idx.toString() + '_' + item.sha);
        }
        .id('push_detail_file_list')
        .width('100%')
        .layoutWeight(1);
      }
      .id('push_detail_root')
      .width('100%')
      .height('100%')
      .backgroundColor(GSYColor.composeBackgroundLight);
    }
    .onReady((ctx: NavDestinationContext): void => {
      const stack: NavPathStack | undefined = ctx.pathStack;
      if (stack !== undefined && stack !== null) {
        this.pathStack = stack;
      }
      // 优先级 1：RouteParamStore（NavigationService.push 同步写入，覆盖所有 push 入口）
      const routeRaw: Object | null = RouteParamStore.consume(RouteName.PushDetail);
      if (routeRaw !== null) {
        const routeParam: PushDetailRouteParam = routeRaw as PushDetailRouteParam;
        let adopted: boolean = false;
        if (routeParam.fullName !== undefined && routeParam.fullName !== null && routeParam.fullName.length > 0) {
          this.fullName = routeParam.fullName;
          adopted = true;
        }
        if (routeParam.sha !== undefined && routeParam.sha !== null && routeParam.sha.length > 0) {
          this.sha = routeParam.sha;
          adopted = true;
        }
        if (adopted) {
          Logger.i('push/route', `PushDetailPage adopted via RouteParamStore fullName=${this.fullName} sha=${this.sha}`);
          this.loadAll();
          return;
        }
      }
      let param: PushDetailRouteParam | null = null;
      let src: string = 'none';
      let stackSize: number = -1;
      let stackNames: string = '';
      let rawType: string = 'none';
      if (stack !== undefined && stack !== null) {
        try {
          const all: string[] = stack.getAllPathName();
          stackSize = all === null || all === undefined ? 0 : all.length;
          stackNames = all !== null && all !== undefined ? all.join(',') : '';
          if (stackSize > 0) {
            const raw: Object | undefined = stack.getParamByIndex(stackSize - 1) as Object | undefined;
            rawType = raw === undefined ? 'undef' : (raw === null ? 'null' : typeof raw);
          }
        } catch (_e) {
          stackSize = -2;
        }
      }
      try {
        const info: NavPathInfo | undefined = ctx.pathInfo;
        if (info !== undefined && info !== null && info.param !== undefined && info.param !== null) {
          param = info.param as PushDetailRouteParam;
          src = 'pathInfo';
        }
      } catch (_e) {
        param = null;
      }
      if (param === null && stack !== undefined && stack !== null) {
        param = this.resolveParamFromStack(stack);
        if (param !== null) {
          src = 'stack';
        }
      }
      const pFull: string = param !== null && param.fullName !== undefined && param.fullName !== null ? param.fullName : '<null>';
      const pSha: string = param !== null && param.sha !== undefined && param.sha !== null ? param.sha : '<null>';
      Logger.i('boot/ts', `PushDetailPage.onReady src=${src} stackSize=${stackSize} stackNames=${stackNames} rawType=${rawType} pFull='${pFull}' pSha='${pSha}'`);
      if (param !== null) {
        if (param.fullName !== undefined && param.fullName !== null && param.fullName.length > 0) {
          this.fullName = param.fullName;
        }
        if (param.sha !== undefined && param.sha !== null && param.sha.length > 0) {
          this.sha = param.sha;
        }
      }
      // KI-045 同款：BOOT_PUSH_KEY 旁路兜底；优先级最高（NavDestination 复用时
      // 上一次的 fullName/sha 还在状态里，需要 BOOT 强制覆盖）。
      const boot: string | undefined = AppStorage.get<string>(BOOT_PUSH_KEY);
      const raw: string = (boot === undefined || boot === null) ? '' : boot.trim();
      if (raw.length > 0) {
        const sep: number = raw.indexOf('|');
        if (sep > 0 && sep < raw.length - 1) {
          this.fullName = raw.substring(0, sep);
          this.sha = raw.substring(sep + 1);
          src = src + '+bootKey';
          Logger.i('boot/ts', `PushDetailPage.onReady bootKey-priority fullName='${this.fullName}' sha='${this.sha}'`);
        }
      }
      this.loadAll();
    });
  }
}
