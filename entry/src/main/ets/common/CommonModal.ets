import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';

export interface CommonOptionItem {
  itemName: string;
  itemTextColor?: ResourceColor;
}

export interface ConfirmOptions {
  title?: string;
  message: string;
  okText?: string;
  cancelText?: string;
  cancelable?: boolean;
}

export interface OptionListOptions {
  title?: string;
  items: CommonOptionItem[];
}

/**
 * PromptDialog 必须在 @Component 实例 build 上下文里 new CustomDialogController 起来才能弹。
 * 用法范式见 [LoginPage.ets#L81-L98](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/LoginPage.ets#L81-L98)
 * 和 [IssueDetailPage.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/pages/IssueDetailPage.ets) 里的 commentReplyController/issueEditController/commentEditController。
 *
 * 注意：不要在 static 方法内 `new CustomDialogController({ builder: PromptDialog(...) })`，
 * 这样 dialog.open() 静默不弹（KI-046 已暴露过）。详情见 [KI-047 收尾](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md)。
 */
@CustomDialog
export struct PromptDialog {
  controller?: CustomDialogController;
  title: string = '';
  defaultValue: string = '';
  placeholder: string = '';
  okText: string = 'OK';
  cancelText: string = 'Cancel';
  maxLength: number = 200;
  onConfirm: (text: string) => void = (): void => {};
  onCancel: () => void = (): void => {};
  @State current: string = '';

  aboutToAppear(): void {
    this.current = this.defaultValue;
  }

  build(): void {
    Column() {
      if (this.title.length > 0) {
        Text(this.title)
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.darkText)
          .margin({ bottom: 12 });
      }
      TextInput({ text: this.current, placeholder: this.placeholder })
        .maxLength(this.maxLength)
        .height(44)
        .fontSize(GSYFontSize.small)
        .backgroundColor(GSYColor.surfaceGray)
        .borderRadius(6)
        .padding({ left: 12, right: 12 })
        .onChange((value: string): void => {
          this.current = value;
        });
      Row() {
        Button(this.cancelText)
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
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor(GSYColor.materialBlue)
          .onClick((): void => {
            const value: string = this.current;
            if (this.controller) {
              this.controller.close();
            }
            this.onConfirm(value);
          });
      }
      .width('100%')
      .height(44)
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center);
    }
    .padding(20)
    .borderRadius(8)
    .width(300)
    .backgroundColor(Color.White);
  }
}

/**
 * 自定义居中选项弹窗——替代系统 ActionSheet（OH 系统 ActionSheet 在小屏上左对齐、行距过大、无分隔线，
 * 视觉很丑）。这里仿 iOS/RN 风格：圆角卡片 + 居中标题 + 单行 item + 1px 分隔线 + 取消按钮独立成块。
 */
@CustomDialog
export struct OptionsDialog {
  controller?: CustomDialogController;
  title: string = '';
  items: CommonOptionItem[] = [];
  cancelText: string = '取消';
  onSelect: (index: number, item: CommonOptionItem) => void
    = (_i: number, _it: CommonOptionItem): void => {};

  build(): void {
    Column() {
      Column() {
        if (this.title.length > 0) {
          Text(this.title)
            .fontSize(GSYFontSize.middleWhite)
            .fontWeight(FontWeight.Bold)
            .fontColor(GSYColor.darkText)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 16, bottom: 12, left: 16, right: 16 });
          Divider().color(GSYColor.pillDivider).strokeWidth(0.5);
        }
        ForEach(this.items, (item: CommonOptionItem, idx: number) => {
          Row() {
            Text(item.itemName)
              .fontSize(GSYFontSize.middleWhite)
              .fontColor(item.itemTextColor !== undefined
                ? item.itemTextColor : GSYColor.materialBlue)
              .width('100%')
              .textAlign(TextAlign.Center);
          }
          .width('100%')
          .height(48)
          .justifyContent(FlexAlign.Center)
          .onClick((): void => {
            if (this.controller) {
              this.controller.close();
            }
            this.onSelect(idx, item);
          });
          if (idx < this.items.length - 1) {
            Divider().color(GSYColor.pillDivider).strokeWidth(0.5);
          }
        }, (item: CommonOptionItem, idx: number): string => `${idx}-${item.itemName}`);
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(12);

      Row() {
        Text(this.cancelText)
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Medium)
          .fontColor(GSYColor.darkText)
          .width('100%')
          .textAlign(TextAlign.Center);
      }
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
    .width('86%')
    .padding({ top: 0, bottom: 0 })
    .backgroundColor(Color.Transparent);
  }
}

export class CommonModal {
  static confirm(options: ConfirmOptions, onConfirm: () => void, onCancel?: () => void): void {
    AlertDialog.show({
      title: options.title ?? '',
      message: options.message,
      autoCancel: options.cancelable ?? true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: options.cancelText ?? 'Cancel',
        action: (): void => {
          if (onCancel) {
            onCancel();
          }
        },
      },
      secondaryButton: {
        value: options.okText ?? 'OK',
        fontColor: GSYColor.materialBlue,
        action: (): void => {
          onConfirm();
        },
      },
      cancel: (): void => {
        if (onCancel) {
          onCancel();
        }
      },
    });
  }

  static options(options: OptionListOptions, onSelect: (index: number, item: CommonOptionItem) => void): void {
    const sheets: SheetInfo[] = options.items.map((item: CommonOptionItem, idx: number): SheetInfo => {
      return {
        title: item.itemName,
        action: (): void => {
          onSelect(idx, item);
        },
      };
    });
    ActionSheet.show({
      title: options.title ?? '',
      message: '',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      sheets: sheets,
    });
  }
}
