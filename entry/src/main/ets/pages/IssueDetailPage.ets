import { I18n } from '../i18n/I18n';
import { AppBar, AppBarAction } from '../common/AppBar';
import { MarkdownText } from '../common/MarkdownText';
import { PullLoadMoreList, PullLoadMoreController } from '../common/PullLoadMoreList';
import { Logger } from '../ai-debug/Logger';
import { BOOT_ISSUE_KEY } from '../entryability/EntryAbility';
import { NavigationService } from '../navigation/NavigationService';
import { RouteParamStore } from '../navigation/RouteParamStore';
import { RouteName } from '../navigation/Routes';
import { GSYColor, GSYFontSize, GSYIconSize, GSYSpacing, GSYShadow } from '../style/Theme';
import {
  IssueDetailStore,
  IssueDetailModel,
  IssueCommentModel,
  ISSUE_STATE_OPEN
} from '../store/IssueDetailStore';
import { IssueService, IssueServiceResult } from '../service/IssueService';
import { TimeUtil } from '../utils/TimeUtil';
import { renderEmoji } from '../utils/EmojiText';
import { IssuePermissionUtil } from '../utils/IssuePermissionUtil';
import { CommonBottomBar, CommonBottomBarItem } from '../common/CommonBottomBar';
import { CommonToast } from '../common/CommonToast';
import { CommonModal, CommonOptionItem } from '../common/CommonModal';
import { APP_STORAGE_KEY_USER_LOGIN } from '../store/AuthStore';
import { ExternalUrlUtil } from '../utils/ExternalUrlUtil';
import pasteboard from '@ohos.pasteboard';
import {
  FA_COMMENT_O,
  FA_INFO_CIRCLE,
  FA_CHECK,
  FA_PLUS,
  FA_LOCK,
  FA_UNLOCK,
  IconFont
} from '../common/IconFont';

@CustomDialog
struct IssueEditDialog {
  controller?: CustomDialogController;
  title: string = '';
  showTitleField: boolean = true;
  defaultTitle: string = '';
  defaultBody: string = '';
  titlePlaceholder: string = '';
  bodyPlaceholder: string = '';
  okText: string = 'OK';
  cancelText: string = 'Cancel';
  rootId: string = 'issue_edit_dialog_root';
  titleTextId: string = 'issue_edit_dialog_title';
  titleInputId: string = 'issue_edit_dialog_title_input';
  bodyInputId: string = 'issue_edit_dialog_body_input';
  toolbarId: string = 'issue_markdown_toolbar';
  cancelButtonId: string = 'issue_edit_dialog_cancel_btn';
  okButtonId: string = 'issue_edit_dialog_ok_btn';
  onConfirm: (title: string, body: string) => void = (): void => {};
  onCancel: () => void = (): void => {};
  @State currentTitle: string = '';
  @State currentBody: string = '';

  aboutToAppear(): void {
    this.currentTitle = this.defaultTitle;
    this.currentBody = this.defaultBody;
  }

  private appendMarkdown(insertion: string): void {
    this.currentBody = this.currentBody + insertion;
  }

  @Builder
  private buildMarkdownAction(actionId: string, label: string, insertion: string): void {
    Button(label)
      .id(actionId)
      .type(ButtonType.Normal)
      .fontSize(GSYFontSize.min)
      .fontColor(GSYColor.darkText)
      .backgroundColor(GSYColor.surfaceGray)
      .borderRadius(6)
      .height(32)
      .padding({ left: 10, right: 10 })
      .onClick((): void => {
        this.appendMarkdown(insertion);
      });
  }

  build(): void {
    Column() {
      if (this.title.length > 0) {
        Text(this.title)
          .id(this.titleTextId)
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.darkText)
          .margin({ bottom: GSYSpacing.normalEdge });
      }
      if (this.showTitleField) {
        TextInput({ text: this.currentTitle, placeholder: this.titlePlaceholder })
          .id(this.titleInputId)
          .maxLength(255)
          .height(44)
          .fontSize(GSYFontSize.small)
          .backgroundColor(GSYColor.surfaceGray)
          .borderRadius(6)
          .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge })
          .onChange((value: string): void => {
            this.currentTitle = value;
          });
      }
      TextArea({ text: this.currentBody, placeholder: this.bodyPlaceholder })
        .id(this.bodyInputId)
        .maxLength(8192)
        .height(200)
        .fontSize(GSYFontSize.small)
        .backgroundColor(GSYColor.surfaceGray)
        .borderRadius(6)
        .padding(GSYSpacing.normalEdge)
        .margin({ top: this.showTitleField ? GSYSpacing.normalEdge : 0 })
        .onChange((value: string): void => {
          this.currentBody = value;
        });
      Scroll() {
        Row() {
          this.buildMarkdownAction(`${this.toolbarId}_h1`, 'H1', '# ');
          this.buildMarkdownAction(`${this.toolbarId}_h2`, 'H2', '## ');
          this.buildMarkdownAction(`${this.toolbarId}_h3`, 'H3', '### ');
          this.buildMarkdownAction(`${this.toolbarId}_bold`, 'B', '****');
          this.buildMarkdownAction(`${this.toolbarId}_italic`, 'I', '**');
          this.buildMarkdownAction(`${this.toolbarId}_ul`, 'UL', '- ');
          this.buildMarkdownAction(`${this.toolbarId}_quote`, 'Quote', '> ');
          this.buildMarkdownAction(`${this.toolbarId}_code`, 'Code', '``');
          this.buildMarkdownAction(`${this.toolbarId}_image`, 'IMG', '![]()');
          this.buildMarkdownAction(`${this.toolbarId}_link`, 'Link', '[]()');
        }
        .id(this.toolbarId)
        .height(36)
        .alignItems(VerticalAlign.Center);
      }
      .width('100%')
      .height(40)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .margin({ top: GSYSpacing.halfEdge });
      Row() {
        Button(this.cancelText)
          .id(this.cancelButtonId)
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor(GSYColor.mediumText)
          .onClick((): void => {
            if (this.controller) {
              this.controller.close();
            }
            this.onCancel();
          });
        Divider().vertical(true).height(20).color(GSYColor.pillDivider);
        Button(this.okText)
          .id(this.okButtonId)
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor(GSYColor.materialBlue)
          .onClick((): void => {
            const t: string = this.currentTitle;
            const b: string = this.currentBody;
            if (this.controller) {
              this.controller.close();
            }
            this.onConfirm(t, b);
          });
      }
      .width('100%')
      .height(44)
      .margin({ top: GSYSpacing.normalEdge })
      .alignItems(VerticalAlign.Center);
    }
    .id(this.rootId)
    .padding(GSYSpacing.normalEdge)
    .borderRadius(8)
    .width('86%')
    .backgroundColor(Color.White);
  }
}

@CustomDialog
struct IssueCommentOptionsDialog {
  controller?: CustomDialogController;
  editText: string = 'Edit';
  deleteText: string = 'Delete';
  cancelText: string = 'Cancel';
  onEdit: () => void = (): void => {};
  onDelete: () => void = (): void => {};

  build(): void {
    Column() {
      Column() {
        Row() {
          Text(this.editText)
            .id('issue_comment_option_edit_text')
            .fontSize(GSYFontSize.middleWhite)
            .fontColor(GSYColor.materialBlue)
            .width('100%')
            .textAlign(TextAlign.Center);
        }
        .id('issue_comment_option_edit')
        .width('100%')
        .height(48)
        .justifyContent(FlexAlign.Center)
        .onClick((): void => {
          if (this.controller) {
            this.controller.close();
          }
          this.onEdit();
        });

        Divider().color(GSYColor.pillDivider).strokeWidth(0.5);

        Row() {
          Text(this.deleteText)
            .id('issue_comment_option_delete_text')
            .fontSize(GSYFontSize.middleWhite)
            .fontColor(GSYColor.issueClosedRed)
            .width('100%')
            .textAlign(TextAlign.Center);
        }
        .id('issue_comment_option_delete')
        .width('100%')
        .height(48)
        .justifyContent(FlexAlign.Center)
        .onClick((): void => {
          if (this.controller) {
            this.controller.close();
          }
          this.onDelete();
        });
      }
      .id('issue_comment_options_panel')
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(12);

      Row() {
        Text(this.cancelText)
          .id('issue_comment_option_cancel_text')
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Medium)
          .fontColor(GSYColor.darkText)
          .width('100%')
          .textAlign(TextAlign.Center);
      }
      .id('issue_comment_option_cancel')
      .width('100%')
      .height(48)
      .margin({ top: GSYSpacing.padding12 })
      .backgroundColor(Color.White)
      .borderRadius(12)
      .onClick((): void => {
        if (this.controller) {
          this.controller.close();
        }
      });
    }
    .id('issue_comment_options_dialog')
    .width('86%')
    .backgroundColor(Color.Transparent);
  }
}

interface IssueDetailRouteParam {
  fullName: string;
  number: number;
}

const FALLBACK_FULL_NAME: string = '';
const FALLBACK_NUMBER: number = 0;

const HEADER_AVATAR_SIZE: number = GSYIconSize.big;
const COMMENT_AVATAR_SIZE: number = GSYIconSize.normal;
const HEADER_STATE_ICON_SIZE: number = 16;
const COMMENT_CARD_RADIUS: number = 3;
const STATE_PILL_RADIUS: number = 10;
const HEADER_STATE_GAP: number = 6;
const HEADER_NUMBER_GAP: number = 8;
const COMMENT_NAME_TIME_GAP: number = 4;
const COMMENT_BODY_GAP: number = 8;
const HEADER_BODY_GAP: number = 12;
const HEADER_DIVIDER_GAP: number = 12;
const HEADER_LABEL_GAP: number = 4;
const EMPTY_HEIGHT: number = 180;

@Component
export struct IssueDetailPage {
  @State fullName: string = FALLBACK_FULL_NAME;
  @State issueNumber: number = FALLBACK_NUMBER;
  @State store: IssueDetailStore = new IssueDetailStore();
  @State commentController: PullLoadMoreController = new PullLoadMoreController();
  @State pendingTitle: string = '';
  @State pendingBody: string = '';
  @State pendingCommentBody: string = '';
  private pendingCommentId: number = 0;
  private pendingCommentRowIndex: number = -1;
  private service: IssueService = new IssueService(this.store);
  private pathStack: NavPathStack = new NavPathStack();

  // KI-046 修复：CustomDialogController 必须挂在 @Component scope，
  // 不能从 static 函数内 new。LoginPage 已采用同一 pattern。
  private commentReplyController: CustomDialogController = new CustomDialogController({
    builder: IssueEditDialog({
      title: I18n('issueComment'),
      showTitleField: false,
      defaultBody: this.pendingCommentBody,
      bodyPlaceholder: I18n('issueInputTip'),
      okText: I18n('ok'),
      cancelText: I18n('cancel'),
      rootId: 'issue_reply_dialog_root',
      titleTextId: 'issue_reply_dialog_title',
      bodyInputId: 'issue_reply_dialog_body_input',
      toolbarId: 'issue_reply_markdown_toolbar',
      cancelButtonId: 'issue_reply_dialog_cancel_btn',
      okButtonId: 'issue_reply_dialog_ok_btn',
      onConfirm: (_title: string, body: string): void => {
        Logger.i('issue/comment', `reply onConfirm len=${body.length}`);
        this.runCreateComment(body);
      },
      onCancel: (): void => {
        Logger.i('issue/comment', 'reply onCancel');
      },
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true,
  });

  private commentEditController: CustomDialogController = new CustomDialogController({
    builder: IssueEditDialog({
      title: I18n('issueCommentEdit'),
      showTitleField: false,
      defaultBody: this.pendingCommentBody,
      bodyPlaceholder: I18n('issueInputTip'),
      okText: I18n('ok'),
      cancelText: I18n('cancel'),
      rootId: 'issue_comment_edit_dialog_root',
      titleTextId: 'issue_comment_edit_dialog_title',
      bodyInputId: 'issue_comment_edit_dialog_body_input',
      toolbarId: 'issue_comment_edit_markdown_toolbar',
      cancelButtonId: 'issue_comment_edit_dialog_cancel_btn',
      okButtonId: 'issue_comment_edit_dialog_ok_btn',
      onConfirm: (_title: string, body: string): void => {
        Logger.i('comment/edit', `onConfirm cid=${this.pendingCommentId} len=${body.length}`);
        this.runEditComment(body);
      },
      onCancel: (): void => {
        Logger.i('comment/edit', 'onCancel');
      },
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true,
  });

  private issueEditController: CustomDialogController = new CustomDialogController({
    builder: IssueEditDialog({
      title: I18n('editIssue'),
      defaultTitle: this.pendingTitle,
      defaultBody: this.pendingBody,
      titlePlaceholder: I18n('issueInputTitleTip'),
      bodyPlaceholder: I18n('issueInputTip'),
      okText: I18n('ok'),
      cancelText: I18n('cancel'),
      onConfirm: (title: string, body: string): void => {
        Logger.i('issue/edit', `onConfirm titleLen=${title.length} bodyLen=${body.length}`);
        this.runEditIssue(title, body);
      },
      onCancel: (): void => {
        Logger.i('issue/edit', 'onCancel');
      },
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true,
  });

  private commentOptionsController: CustomDialogController = new CustomDialogController({
    builder: IssueCommentOptionsDialog({
      editText: I18n('issueCommentEdit'),
      deleteText: I18n('issueCommentDelete'),
      cancelText: I18n('cancel'),
      onEdit: (): void => {
        Logger.i('comment/options', `edit selected cid=${this.pendingCommentId} row=${this.pendingCommentRowIndex}`);
        this.commentEditController.open();
      },
      onDelete: (): void => {
        Logger.i('comment/options', `delete selected cid=${this.pendingCommentId} row=${this.pendingCommentRowIndex}`);
        if (this.pendingCommentId <= 0 || this.pendingCommentRowIndex < 0) {
          return;
        }
        CommonModal.confirm({
          message: I18n('issueCommentDelete'),
          okText: I18n('ok'),
          cancelText: I18n('cancel'),
        }, (): void => {
          this.runDeleteComment(this.pendingCommentId, this.pendingCommentRowIndex);
        });
      },
    }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true,
  });

  aboutToAppear(): void {
    this.service = new IssueService(this.store);
  }

  private resolveParamFromStack(stack: NavPathStack): IssueDetailRouteParam | null {
    try {
      const all: string[] = stack.getAllPathName();
      if (all === undefined || all === null || all.length === 0) {
        return null;
      }
      const param: Object | undefined = stack.getParamByIndex(all.length - 1) as Object | undefined;
      if (param === undefined || param === null) {
        return null;
      }
      return param as IssueDetailRouteParam;
    } catch (_e) {
      return null;
    }
  }

  private async loadAll(): Promise<void> {
    if (this.fullName.length === 0 || this.issueNumber <= 0) {
      return;
    }
    await this.service.getIssue(this.fullName, this.issueNumber);
    await this.refreshComments();
  }

  private async refreshComments(): Promise<void> {
    if (this.fullName.length === 0 || this.issueNumber <= 0) {
      return;
    }
    this.commentController.showRefreshState();
    await this.service.getComments(this.fullName, this.issueNumber, 1);
    this.commentController.refreshComplete(this.store.hasMore, false);
  }

  private async loadMoreComments(): Promise<void> {
    if (!this.store.hasMore) {
      this.commentController.loadMoreComplete(false);
      return;
    }
    const next: number = this.store.page + 1;
    await this.service.getComments(this.fullName, this.issueNumber, next);
    this.commentController.loadMoreComplete(this.store.hasMore);
  }

  private currentLogin(): string {
    try {
      const v: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_USER_LOGIN);
      return (v === undefined || v === null) ? '' : v;
    } catch (_e) {
      return '';
    }
  }

  private isIssueOwner(): boolean {
    if (this.store.issue === null) {
      return false;
    }
    const login: string = this.currentLogin();
    if (login.length === 0) {
      return false;
    }
    return (this.store.issue as IssueDetailModel).user.login === login;
  }

  private isRepoOwner(): boolean {
    return IssuePermissionUtil.isRepoOwner(this.fullName, this.currentLogin());
  }

  private isIssueLocked(): boolean {
    return this.store.issue !== null ? (this.store.issue as IssueDetailModel).locked : false;
  }

  private canReply(): boolean {
    return this.store.issue !== null &&
      IssuePermissionUtil.canReply(this.isRepoOwner(), this.isIssueOwner(), this.isIssueLocked());
  }

  private canEditIssue(): boolean {
    return this.store.issue !== null &&
      IssuePermissionUtil.canEdit(this.isRepoOwner(), this.isIssueOwner(), this.isIssueLocked());
  }

  private canOpenCloseIssue(): boolean {
    return this.store.issue !== null &&
      IssuePermissionUtil.canOpenClose(this.isRepoOwner(), this.isIssueOwner());
  }

  private canLockUnlockIssue(): boolean {
    return this.store.issue !== null && IssuePermissionUtil.canLockUnlock(this.isRepoOwner());
  }

  private shouldShowBottomBar(): boolean {
    return this.canReply() || this.canEditIssue() || this.canOpenCloseIssue() || this.canLockUnlockIssue();
  }

  private issueTitleForAppBar(): string {
    if (this.store.issue !== null) {
      return '#' + this.issueNumber.toString() + ' ' + (this.store.issue as IssueDetailModel).title;
    }
    return this.issueNumber > 0 ? '#' + this.issueNumber.toString() : I18n('reposIssue');
  }

  private resolveHtmlUrl(): string {
    if (this.fullName.length === 0 || this.issueNumber <= 0) {
      return '';
    }
    return 'https://github.com/' + this.fullName + '/issues/' + this.issueNumber.toString();
  }

  private showMoreMenu(): void {
    const htmlUrl: string = this.resolveHtmlUrl();
    const items: CommonOptionItem[] = [
      { itemName: I18n('browserOpen') } as CommonOptionItem,
      { itemName: I18n('copy') } as CommonOptionItem,
      { itemName: I18n('share') } as CommonOptionItem,
    ];
    CommonModal.options(
      { title: this.issueTitleForAppBar(), items: items },
      (index: number, _item: CommonOptionItem): void => {
        if (htmlUrl.length === 0) {
          return;
        }
        if (index === 0) {
          ExternalUrlUtil.openUrlInBrowser(this, htmlUrl, 'IssueDetailPage');
        } else if (index === 1) {
          this.copyToPasteboard(htmlUrl);
        } else if (index === 2) {
          ExternalUrlUtil.openUrlInBrowser(this, htmlUrl, 'IssueDetailPage');
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

  private renderIssueBody(value: string): string {
    const safe: string = value !== null && value !== undefined ? value : '';
    return renderEmoji(safe);
  }

  private isCommentOwner(item: IssueCommentModel): boolean {
    const login: string = this.currentLogin();
    if (login.length === 0) {
      return false;
    }
    return item.user.login === login;
  }

  private canManageComment(item: IssueCommentModel): boolean {
    return this.isRepoOwner() || this.isCommentOwner(item);
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

  private async runCreateComment(text: string): Promise<void> {
    const safe: string = text !== null && text !== undefined ? text.trim() : '';
    if (safe.length === 0 || this.fullName.length === 0 || this.issueNumber <= 0) {
      return;
    }
    const res: IssueServiceResult<IssueCommentModel> =
      await this.service.createComment(this.fullName, this.issueNumber, safe);
    Logger.i('issue/comment', `create result=${res.result} code=${res.code}`);
    if (!res.result) {
      const msg: string = res.msg.length > 0 ? res.msg : I18n('errorUnKnow');
      CommonToast.showShort(msg);
    }
  }

  private async runEditIssue(title: string, body: string): Promise<void> {
    const safeTitle: string = title !== null && title !== undefined ? title.trim() : '';
    if (safeTitle.length === 0 || this.fullName.length === 0 || this.issueNumber <= 0) {
      return;
    }
    const safeBody: string = body !== null && body !== undefined ? body : '';
    const res: IssueServiceResult<IssueDetailModel> =
      await this.service.editIssue(this.fullName, this.issueNumber, safeTitle, safeBody);
    Logger.i('issue/edit', `result=${res.result} code=${res.code}`);
    if (!res.result) {
      const msg: string = res.msg.length > 0 ? res.msg : I18n('errorUnKnow');
      CommonToast.showShort(msg);
    }
  }

  private async runEditComment(text: string): Promise<void> {
    const safe: string = text !== null && text !== undefined ? text.trim() : '';
    if (safe.length === 0 || this.pendingCommentRowIndex < 0 || this.pendingCommentId <= 0) {
      return;
    }
    const res: IssueServiceResult<IssueCommentModel> =
      await this.service.editComment(this.fullName, this.issueNumber,
        this.pendingCommentId, safe, this.pendingCommentRowIndex);
    Logger.i('comment/edit', `result=${res.result} code=${res.code} cid=${this.pendingCommentId}`);
    if (!res.result) {
      const msg: string = res.msg.length > 0 ? res.msg : I18n('errorUnKnow');
      CommonToast.showShort(msg);
    }
  }

  private async runDeleteComment(commentId: number, rowIndex: number): Promise<void> {
    const res: IssueServiceResult<boolean> =
      await this.service.deleteComment(this.fullName, this.issueNumber, commentId, rowIndex);
    Logger.i('comment/delete', `result=${res.result} code=${res.code} cid=${commentId} row=${rowIndex}`);
    if (!res.result) {
      const msg: string = res.msg.length > 0 ? res.msg : I18n('errorUnKnow');
      CommonToast.showShort(msg);
    }
  }

  private async toggleIssueState(): Promise<void> {
    if (this.fullName.length === 0 || this.issueNumber <= 0) {
      return;
    }
    const isOpen: boolean = this.store.state === ISSUE_STATE_OPEN;
    const tip: string = isOpen ? I18n('closeIssueTip') : I18n('openIssueTip');
    Logger.i('issue/state', `confirm prepare isOpen=${isOpen}`);
    CommonModal.confirm({
      message: tip,
      okText: I18n('ok'),
      cancelText: I18n('cancel'),
    }, (): void => {
      this.runToggleIssueState(isOpen);
    });
  }

  private async runToggleIssueState(isOpen: boolean): Promise<void> {
    let res: IssueServiceResult<IssueDetailModel>;
    if (isOpen) {
      res = await this.service.closeIssue(this.fullName, this.issueNumber);
    } else {
      res = await this.service.reopenIssue(this.fullName, this.issueNumber);
    }
    Logger.i('issue/state', `result=${res.result} code=${res.code} wasOpen=${isOpen}`);
    if (res.result) {
      await this.service.getIssue(this.fullName, this.issueNumber);
    } else {
      const msg: string = res.msg.length > 0 ? res.msg : I18n('errorUnKnow');
      CommonToast.showShort(msg);
    }
  }

  private onCommentMenuTap(): void {
    if (this.fullName.length === 0 || this.issueNumber <= 0) {
      return;
    }
    this.pendingCommentBody = '';
    Logger.i('issue/comment', 'reply markdown dialog open');
    this.commentReplyController.open();
  }

  private onEditMenuTap(): void {
    if (this.store.issue === null) {
      return;
    }
    if (!this.canEditIssue()) {
      CommonToast.showShort(I18n('noPower'));
      return;
    }
    const detail: IssueDetailModel = this.store.issue as IssueDetailModel;
    this.pendingTitle = detail.title !== null && detail.title !== undefined ? detail.title : '';
    this.pendingBody = detail.body !== null && detail.body !== undefined ? detail.body : '';
    Logger.i('issue/edit', `markdown dialog open titleLen=${this.pendingTitle.length} bodyLen=${this.pendingBody.length}`);
    this.issueEditController.open();
  }

  private onLockMenuTap(): void {
    if (this.store.issue === null || this.fullName.length === 0 || this.issueNumber <= 0) {
      return;
    }
    const isLocked: boolean = (this.store.issue as IssueDetailModel).locked;
    const tip: string = isLocked ? I18n('unLockIssueTip') : I18n('lockIssueTip');
    Logger.i('issue/lock', `confirm prepare locked=${isLocked}`);
    CommonModal.confirm({
      message: tip,
      okText: I18n('ok'),
      cancelText: I18n('cancel'),
    }, (): void => {
      this.runToggleIssueLock(isLocked);
    });
  }

  private async runToggleIssueLock(currentLocked: boolean): Promise<void> {
    const res: IssueServiceResult<boolean> =
      await this.service.toggleIssueLock(this.fullName, this.issueNumber, currentLocked);
    Logger.i('issue/lock', `result=${res.result} code=${res.code} wasLocked=${currentLocked}`);
    if (!res.result) {
      const msg: string = res.msg.length > 0 ? res.msg : I18n('errorUnKnow');
      CommonToast.showShort(msg);
    }
  }

  private selectComment(item: IssueCommentModel, index: number): void {
    this.pendingCommentId = item.id;
    this.pendingCommentRowIndex = index;
    this.pendingCommentBody = item.body !== null && item.body !== undefined ? item.body : '';
  }

  private onCommentTap(item: IssueCommentModel, index: number): void {
    const canManage: boolean = this.canManageComment(item);
    Logger.i('comment/tap', `index=${index} cid=${item.id} canManage=${canManage}`);
    if (!canManage) {
      return;
    }
    this.selectComment(item, index);
    this.commentOptionsController.open();
  }

  private onCommentLongPress(item: IssueCommentModel, index: number): void {
    Logger.i('comment/longpress', `copy index=${index} cid=${item.id}`);
    this.copyToPasteboard(item.body !== null && item.body !== undefined ? item.body : '');
  }

  private buildBottomBarItems(): CommonBottomBarItem[] {
    const isOpen: boolean = this.store.state === ISSUE_STATE_OPEN;
    const isLocked: boolean = this.store.issue !== null
      ? (this.store.issue as IssueDetailModel).locked : false;
    const items: CommonBottomBarItem[] = [];

    const commentItem: CommonBottomBarItem = new CommonBottomBarItem();
    commentItem.itemName = I18n('issueComment');
    commentItem.icon = FA_COMMENT_O;
    commentItem.itemId = 'comment';
    commentItem.itemClick = (): void => {
      this.onCommentMenuTap();
    };
    if (this.canReply()) {
      items.push(commentItem);
    }

    const editItem: CommonBottomBarItem = new CommonBottomBarItem();
    editItem.itemName = I18n('editIssue');
    editItem.icon = FA_INFO_CIRCLE;
    editItem.itemId = 'edit';
    editItem.itemClick = (): void => {
      this.onEditMenuTap();
    };
    if (this.canEditIssue()) {
      items.push(editItem);
    }

    const stateItem: CommonBottomBarItem = new CommonBottomBarItem();
    stateItem.itemName = isOpen ? I18n('issueClose') : I18n('issueOpen');
    stateItem.icon = isOpen ? FA_CHECK : FA_PLUS;
    stateItem.iconColor = isOpen ? GSYColor.issueClosedRed : GSYColor.issueOpenGreen;
    stateItem.itemTextColor = isOpen ? GSYColor.issueClosedRed : GSYColor.issueOpenGreen;
    stateItem.itemId = 'state';
    stateItem.itemClick = (): void => {
      this.toggleIssueState();
    };
    if (this.canOpenCloseIssue()) {
      items.push(stateItem);
    }

    const lockItem: CommonBottomBarItem = new CommonBottomBarItem();
    lockItem.itemName = isLocked ? I18n('issueUnlock') : I18n('issueLocked');
    lockItem.icon = isLocked ? FA_UNLOCK : FA_LOCK;
    lockItem.itemId = 'lock';
    lockItem.itemClick = (): void => {
      this.onLockMenuTap();
    };
    if (this.canLockUnlockIssue()) {
      items.push(lockItem);
    }

    return items;
  }

  @Builder
  buildHeader(): void {
    Column() {
      if (this.store.issue !== null) {
        Column() {
          Row() {
            Image((this.store.issue as IssueDetailModel).user.avatar_url)
              .id('issue_detail_user_avatar')
              .width(HEADER_AVATAR_SIZE)
              .height(HEADER_AVATAR_SIZE)
              .borderRadius(HEADER_AVATAR_SIZE / 2)
              .objectFit(ImageFit.Cover);

            Column() {
              Row() {
                Text((this.store.issue as IssueDetailModel).state === ISSUE_STATE_OPEN
                  ? I18n('issueOpenText') : I18n('issueCloseText'))
                  .id('issue_detail_state')
                  .fontSize(GSYFontSize.min)
                  .fontWeight(FontWeight.Bold)
                  .fontColor((this.store.issue as IssueDetailModel).state === ISSUE_STATE_OPEN
                    ? GSYColor.issueOpenGreen : GSYColor.issueClosedRed)
                  .padding({
                    left: 0,
                    right: GSYSpacing.halfEdge,
                    top: 0,
                    bottom: 0,
                  })
                  .margin({ left: 0 });

                Text('#' + (this.store.issue as IssueDetailModel).number.toString())
                  .id('issue_detail_number')
                  .fontSize(GSYFontSize.small)
                  .fontColor(GSYColor.mediumText)
                  .margin({ left: HEADER_NUMBER_GAP });

                Text(I18n('issueComment') + '(' + (this.store.issue as IssueDetailModel).comments.toString() + ')')
                  .id('issue_detail_comment_count')
                  .fontSize(GSYFontSize.small)
                  .fontColor(GSYColor.mediumText)
                  .margin({ left: HEADER_NUMBER_GAP });
              }
              .alignItems(VerticalAlign.Center);

              Text((this.store.issue as IssueDetailModel).user.login)
                .id('issue_detail_user_login')
                .fontSize(GSYFontSize.small)
                .fontWeight(FontWeight.Bold)
                .fontColor(GSYColor.mainText)
                .margin({ top: COMMENT_NAME_TIME_GAP });
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: GSYSpacing.normalEdge })
            .layoutWeight(1);

            Text(TimeUtil.resolveTime((this.store.issue as IssueDetailModel).created_at))
              .id('issue_detail_created_time')
              .fontSize(GSYFontSize.min)
              .fontColor(GSYColor.mediumText);
          }
          .width('100%')
          .alignItems(VerticalAlign.Center);

          Text((this.store.issue as IssueDetailModel).title)
            .id('issue_detail_title')
            .fontSize(GSYFontSize.normal)
            .fontWeight(FontWeight.Bold)
            .fontColor(GSYColor.mainText)
            .width('100%')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: GSYSpacing.normalEdge });

          MarkdownText({
            markdown: this.renderIssueBody((this.store.issue as IssueDetailModel).body),
            rootId: 'issue_detail_body_html',
            textColor: GSYColor.mainText,
            textFontSize: GSYFontSize.small,
          })
            .margin({ top: HEADER_BODY_GAP });
        }
        .id('issue_detail_head_card')
        .width('auto')
        .margin({
          left: GSYSpacing.halfEdge,
          right: GSYSpacing.halfEdge,
          top: GSYSpacing.halfEdge,
          bottom: GSYSpacing.halfEdge,
        })
        .padding({
          left: GSYSpacing.normalEdge,
          right: GSYSpacing.normalEdge,
          top: GSYSpacing.normalEdge,
          bottom: GSYSpacing.normalEdge,
        })
        .borderRadius(8)
        .backgroundColor(GSYColor.cardBackground)
        .shadow({
          radius: GSYShadow.radius,
          color: GSYShadow.cardShadowAlpha,
          offsetX: 0,
          offsetY: GSYShadow.elevation,
        })
        .alignItems(HorizontalAlign.Start);
      } else {
        Text(this.store.error.length > 0 ? this.store.error : I18n('loading'))
          .id('issue_detail_loading_text')
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.subText)
          .padding({
            left: GSYSpacing.normalEdge,
            right: GSYSpacing.normalEdge,
            top: GSYSpacing.normalEdge,
            bottom: GSYSpacing.normalEdge,
          });
      }

      Divider()
        .id('issue_detail_header_divider')
        .strokeWidth(1)
        .color(GSYColor.lightDivider)
        .margin({ top: HEADER_DIVIDER_GAP, bottom: HEADER_LABEL_GAP });

      Text(I18n('issueComment') + ' (' + this.store.comments.length.toString() + ')')
        .id('issue_detail_comments_label')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.subText)
        .margin({
          left: GSYSpacing.normalEdge,
          top: HEADER_LABEL_GAP,
          bottom: HEADER_LABEL_GAP,
        });
    }
    .id('issue_detail_header_root')
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  buildCommentRow(item: IssueCommentModel, index: number): void {
    Column() {
      Row() {
        Image(item.user.avatar_url)
          .id('issue_comment_avatar_' + index.toString())
          .width(COMMENT_AVATAR_SIZE)
          .height(COMMENT_AVATAR_SIZE)
          .borderRadius(COMMENT_AVATAR_SIZE / 2)
          .objectFit(ImageFit.Cover);
        Column() {
          Text(item.user.login)
            .id('issue_comment_user_' + index.toString())
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.actionBlue)
            .fontWeight(FontWeight.Bold);
          Text(TimeUtil.resolveTime(item.created_at))
            .id('issue_comment_time_' + index.toString())
            .fontSize(GSYFontSize.min)
            .fontColor(GSYColor.subText)
            .margin({ top: COMMENT_NAME_TIME_GAP });
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: GSYSpacing.normalEdge })
        .layoutWeight(1);
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      MarkdownText({
        markdown: this.renderIssueBody(item.body),
        rootId: 'issue_comment_body_' + index.toString(),
        textColor: GSYColor.mainText,
        textFontSize: GSYFontSize.small,
      })
        .margin({ top: COMMENT_BODY_GAP });
    }
    .id('issue_comment_row_' + index.toString())
    .width('100%')
    .padding({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.normalEdge,
      bottom: GSYSpacing.normalEdge,
    })
    .margin({
      left: GSYSpacing.halfEdge,
      right: GSYSpacing.halfEdge,
      top: GSYSpacing.halfEdge,
      bottom: GSYSpacing.halfEdge,
    })
    .borderRadius(COMMENT_CARD_RADIUS)
    .backgroundColor(GSYColor.cardBackground)
    .shadow({
      radius: GSYShadow.radius,
      color: GSYShadow.cardShadowAlpha,
      offsetX: 0,
      offsetY: GSYShadow.elevation,
    })
    .gesture(
      GestureGroup(GestureMode.Exclusive,
        TapGesture({ count: 1 })
          .onAction((_event: GestureEvent): void => {
            this.onCommentTap(item, index);
          }),
        LongPressGesture({ repeat: false })
        .onAction((_e: GestureEvent): void => {
          this.onCommentLongPress(item, index);
        })
      )
    )
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  buildEmpty(): void {
    Column() {
      Text(I18n('listEmpty'))
        .id('issue_detail_empty_text')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.subText);
    }
    .id('issue_detail_empty_root')
    .width('100%')
    .height(EMPTY_HEIGHT)
    .justifyContent(FlexAlign.Center);
  }

  build(): void {
    NavDestination() {
      Column() {
        AppBar({
          title: this.issueTitleForAppBar(),
          titleStart: true,
          showBack: true,
          rightActions: this.buildRightActions(),
          onBack: (): void => {
            NavigationService.pop();
          },
        })
          .id('issue_detail_appbar');

        PullLoadMoreList({
          dataSource: this.store.comments,
          controller: this.commentController,
          renderRow: (item: Object, index: number): void =>
            this.buildCommentRow(item as IssueCommentModel, index),
          renderHeader: (): void => this.buildHeader(),
          renderEmpty: (): void => this.buildEmpty(),
          refresh: (): void => {
            this.refreshComments();
          },
          loadMore: (): void => {
            this.loadMoreComments();
          },
        })
          .id('issue_detail_pull_list')
          .layoutWeight(1);

        if (this.shouldShowBottomBar()) {
          CommonBottomBar({
            dataList: this.buildBottomBarItems(),
            rootId: 'issue_detail_bottom_bar',
          })
            .id('issue_detail_bottom_bar_wrap');
        }
      }
      .id('issue_detail_root')
      .width('100%')
      .height('100%')
      .backgroundColor(GSYColor.mainBackground);
    }
    .onReady((ctx: NavDestinationContext): void => {
      const stack: NavPathStack | undefined = ctx.pathStack;
      if (stack !== undefined && stack !== null) {
        this.pathStack = stack;
      }
      // 优先级 1：RouteParamStore（NavigationService.push 同步写入，覆盖所有 push 入口）
      const routeRaw: Object | null = RouteParamStore.consume(RouteName.IssueDetail);
      if (routeRaw !== null) {
        const routeParam: IssueDetailRouteParam = routeRaw as IssueDetailRouteParam;
        let adopted: boolean = false;
        if (routeParam.fullName !== undefined && routeParam.fullName !== null && routeParam.fullName.length > 0) {
          this.fullName = routeParam.fullName;
          adopted = true;
        }
        if (routeParam.number !== undefined && routeParam.number !== null && routeParam.number > 0) {
          this.issueNumber = routeParam.number;
          adopted = true;
        }
        if (adopted) {
          Logger.i('issue/route', `IssueDetailPage adopted via RouteParamStore fullName=${this.fullName} number=${this.issueNumber}`);
          this.loadAll();
          return;
        }
      }
      let param: IssueDetailRouteParam | null = null;
      try {
        const info: NavPathInfo | undefined = ctx.pathInfo;
        if (info !== undefined && info !== null && info.param !== undefined && info.param !== null) {
          param = info.param as IssueDetailRouteParam;
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
        if (param.number !== undefined && param.number !== null && param.number > 0) {
          this.issueNumber = param.number;
        }
      }
      // KI-045 同款：BOOT_ISSUE_KEY 旁路优先级最高（NavDestination 复用时
      // 上一次的 fullName/number 还在状态里，需要 BOOT 强制覆盖）。
      const boot: string | undefined = AppStorage.get<string>(BOOT_ISSUE_KEY);
      const raw: string = (boot === undefined || boot === null) ? '' : boot.trim();
      if (raw.length > 0) {
        const sep: number = raw.indexOf('|');
        if (sep > 0 && sep < raw.length - 1) {
          const fn: string = raw.substring(0, sep);
          const numStr: string = raw.substring(sep + 1);
          const n: number = parseInt(numStr, 10);
          if (!isNaN(n) && n > 0) {
            this.fullName = fn;
            this.issueNumber = n;
            Logger.i('boot/ts', `IssueDetailPage.onReady bootKey-priority fullName='${this.fullName}' number=${this.issueNumber}`);
          }
        }
      }
      this.loadAll();
    });
  }
}
