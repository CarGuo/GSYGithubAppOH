// RN 源对照: GSYGithubApp/app/components/widget/CustomWebComponent.js L1-L95
import { webview } from '@kit.ArkWeb';
import { GSYColor, GSYSpacing } from '../style/Theme';

@Component
export struct CommonWebView {
  @Prop url: string = '';
  onLoadComplete: () => void = (): void => {};

  @State progress: number = 0;
  @State loading: boolean = true;
  controller: webview.WebviewController = new webview.WebviewController();

  reload(): void {
    try {
      this.controller.refresh();
    } catch (_e) {
    }
  }

  build(): void {
    Stack() {
      Column() {
        Web({ src: this.url, controller: this.controller })
          .domStorageAccess(true)
          .javaScriptAccess(true)
          .mixedMode(MixedMode.All)
          .mediaPlayGestureAccess(true)
          .fileAccess(true)
          .width('100%')
          .layoutWeight(1)
          .onProgressChange((event): void => {
            if (event) {
              this.progress = event.newProgress;
            }
          })
          .onPageEnd((): void => {
            this.loading = false;
            this.progress = 100;
            this.onLoadComplete();
          })
          .onPageBegin((): void => {
            this.loading = true;
          });
      }
      .width('100%')
      .height('100%');

      if (this.loading && this.progress < 100) {
        Column() {
          Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
            .color(GSYColor.actionBlue)
            .backgroundColor(GSYColor.transparent)
            .width('100%')
            .height(GSYSpacing.halfEdge / 2);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      }
    }
    .alignContent(Alignment.Top)
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.cardBackground);
  }
}
