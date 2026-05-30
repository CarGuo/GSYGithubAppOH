import { CommonToast } from './CommonToast';
import { GSYColor, GSYFontSize } from '../style/Theme';

@Component
export struct ImagePreview {
  url: string = '';
  visible: boolean = false;
  onClose: () => void = (): void => {};
  @State scaleValue: number = 1.0;
  @State lastScaleValue: number = 1.0;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State lastOffsetX: number = 0;
  @State lastOffsetY: number = 0;

  private resetTransform(): void {
    this.scaleValue = 1.0;
    this.lastScaleValue = 1.0;
    this.offsetX = 0;
    this.offsetY = 0;
    this.lastOffsetX = 0;
    this.lastOffsetY = 0;
  }

  build(): void {
    if (this.visible) {
      Stack() {
        Image(this.url)
          .id('image_preview_image')
          .objectFit(ImageFit.Contain)
          .width('100%')
          .height('100%')
          .scale({ x: this.scaleValue, y: this.scaleValue })
          .translate({ x: this.offsetX, y: this.offsetY })
          .gesture(
            GestureGroup(GestureMode.Parallel,
              PinchGesture({ fingers: 2 })
                .onActionStart((): void => {
                  this.lastScaleValue = this.scaleValue;
                })
                .onActionUpdate((event: GestureEvent): void => {
                  let next: number = this.lastScaleValue * event.scale;
                  if (next < 0.5) {
                    next = 0.5;
                  }
                  if (next > 4.0) {
                    next = 4.0;
                  }
                  this.scaleValue = next;
                })
                .onActionEnd((): void => {
                  this.lastScaleValue = this.scaleValue;
                }),
              PanGesture({ fingers: 1 })
                .onActionStart((): void => {
                  this.lastOffsetX = this.offsetX;
                  this.lastOffsetY = this.offsetY;
                })
                .onActionUpdate((event: GestureEvent): void => {
                  this.offsetX = this.lastOffsetX + event.offsetX;
                  this.offsetY = this.lastOffsetY + event.offsetY;
                })
                .onActionEnd((): void => {
                  this.lastOffsetX = this.offsetX;
                  this.lastOffsetY = this.offsetY;
                }),
              TapGesture({ count: 2 })
                .onAction((): void => {
                  this.resetTransform();
                }),
              LongPressGesture({ repeat: false })
                .onAction((): void => {
                  CommonToast.showShort('Save to Album (placeholder)');
                })
            )
          );

        Button('x')
          .id('image_preview_close')
          .type(ButtonType.Circle)
          .width(36)
          .height(36)
          .fontSize(GSYFontSize.middleWhite)
          .fontColor(GSYColor.white)
          .backgroundColor(GSYColor.imageMaskBg)
          .position({ x: '88%', y: '4%' })
          .onClick((): void => {
            this.resetTransform();
            this.onClose();
          });
      }
      .id('image_preview_root')
      .width('100%')
      .height('100%')
      .backgroundColor(GSYColor.solidBlack);
    }
  }
}
