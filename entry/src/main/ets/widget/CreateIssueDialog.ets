/**
 * CreateIssueDialog —— 对齐 Compose GSYMarkdownInputDialog。
 * 反馈与创建 Issue 共用 title + markdown body 输入弹层。
 */

import { I18n } from '../i18n/I18n';
import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';

@CustomDialog
export struct CreateIssueDialog {
  controller: CustomDialogController;
  onConfirm: (title: string, body: string) => void = (_t: string, _b: string): void => {};
  dialogTitle: string = I18n('createIssue');
  titlePlaceholder: string = I18n('issueInputTipTitle');
  bodyPlaceholder: string = I18n('issueInputTip');
  @State titleText: string = '';
  @State bodyText: string = '';

  private appendMarkdown(insertion: string): void {
    this.bodyText = this.bodyText + insertion;
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
      Text(this.dialogTitle)
        .id('create_issue_dialog_title')
        .fontSize(GSYFontSize.middleNormal)
        .fontWeight(FontWeight.Bold)
        .fontColor(GSYColor.primary)
        .margin({ bottom: GSYSpacing.normalEdge });

      TextInput({ placeholder: this.titlePlaceholder, text: this.titleText })
        .id('create_issue_dialog_title_input')
        .fontSize(GSYFontSize.normal)
        .fontColor(GSYColor.primary)
        .placeholderColor(GSYColor.subText)
        .backgroundColor(GSYColor.surfaceSubtle)
        .borderRadius(4)
        .height(40)
        .padding({ left: GSYSpacing.halfEdge, right: GSYSpacing.halfEdge })
        .onChange((value: string): void => {
          this.titleText = value;
        });

      TextArea({ placeholder: this.bodyPlaceholder, text: this.bodyText })
        .id('create_issue_dialog_body_input')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.primary)
        .placeholderColor(GSYColor.subText)
        .backgroundColor(GSYColor.surfaceSubtle)
        .borderRadius(4)
        .height(200)
        .margin({ top: GSYSpacing.normalEdge })
        .padding(GSYSpacing.halfEdge)
        .onChange((value: string): void => {
          this.bodyText = value;
        });

      Scroll() {
        Row() {
          this.buildMarkdownAction('create_issue_markdown_toolbar_h1', 'H1', '# ');
          this.buildMarkdownAction('create_issue_markdown_toolbar_h2', 'H2', '## ');
          this.buildMarkdownAction('create_issue_markdown_toolbar_h3', 'H3', '### ');
          this.buildMarkdownAction('create_issue_markdown_toolbar_bold', 'B', '****');
          this.buildMarkdownAction('create_issue_markdown_toolbar_italic', 'I', '**');
          this.buildMarkdownAction('create_issue_markdown_toolbar_ul', 'UL', '- ');
          this.buildMarkdownAction('create_issue_markdown_toolbar_quote', 'Quote', '> ');
          this.buildMarkdownAction('create_issue_markdown_toolbar_code', 'Code', '``');
          this.buildMarkdownAction('create_issue_markdown_toolbar_image', 'IMG', '![]()');
          this.buildMarkdownAction('create_issue_markdown_toolbar_link', 'Link', '[]()');
        }
        .id('create_issue_markdown_toolbar')
        .height(36)
        .alignItems(VerticalAlign.Center);
      }
      .width('100%')
      .height(40)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .margin({ top: GSYSpacing.halfEdge });

      Row() {
        Button(I18n('cancel'))
          .id('create_issue_dialog_cancel')
          .fontSize(GSYFontSize.normal)
          .fontColor(GSYColor.subText)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onClick((): void => {
            this.controller.close();
          });
        Button(I18n('ok'))
          .id('create_issue_dialog_confirm')
          .fontSize(GSYFontSize.normal)
          .fontColor(GSYColor.miWhite)
          .backgroundColor(GSYColor.primary)
          .layoutWeight(1)
          .margin({ left: GSYSpacing.normalEdge })
          .onClick((): void => {
            const t: string = this.titleText.trim();
            if (t.length === 0) {
              return;
            }
            this.controller.close();
            this.onConfirm(t, this.bodyText);
          });
      }
      .width('100%')
      .margin({ top: GSYSpacing.normalEdge });
    }
    .id('create_issue_dialog_root')
    .width('90%')
    .padding(GSYSpacing.normalEdge)
    .backgroundColor(GSYColor.white)
    .borderRadius(8);
  }
}
