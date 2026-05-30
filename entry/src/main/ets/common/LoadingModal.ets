import { GSYColor, GSYFontSize } from '../style/Theme';

@CustomDialog
struct LoadingDialog {
  controller?: CustomDialogController;
  text: string = 'Loading…';

  build(): void {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(Color.White);
      Text(this.text)
        .fontSize(GSYFontSize.small)
        .fontColor(Color.White)
        .margin({ top: 12 });
    }
    .padding(24)
    .borderRadius(8)
    .backgroundColor(GSYColor.loadingMaskBg)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}

class LoadingHolder {
  controller: CustomDialogController | null = null;
  visible: boolean = false;
}

export class LoadingModal {
  private static holder: LoadingHolder = new LoadingHolder();

  static show(text: string = 'Loading…', cancelable: boolean = true): void {
    if (LoadingModal.holder.visible && LoadingModal.holder.controller) {
      return;
    }
    const dialog: CustomDialogController = new CustomDialogController({
      builder: LoadingDialog({ text: text }),
      autoCancel: cancelable,
      alignment: DialogAlignment.Center,
      customStyle: true,
      cancel: (): void => {
        LoadingModal.holder.visible = false;
        LoadingModal.holder.controller = null;
      },
    });
    LoadingModal.holder.controller = dialog;
    LoadingModal.holder.visible = true;
    dialog.open();
  }

  static hide(): void {
    if (LoadingModal.holder.controller) {
      LoadingModal.holder.controller.close();
    }
    LoadingModal.holder.controller = null;
    LoadingModal.holder.visible = false;
  }

  static isShowing(): boolean {
    return LoadingModal.holder.visible;
  }
}
