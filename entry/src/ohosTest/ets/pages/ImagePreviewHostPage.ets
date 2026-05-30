import { ImagePreview } from '../../../main/ets/common/ImagePreview';

@Entry
@Component
struct ImagePreviewHostPage {
  @State visible: boolean = true;

  build(): void {
    Column() {
      ImagePreview({
        url: 'https://avatars.githubusercontent.com/u/1024025?v=4',
        visible: this.visible,
        onClose: (): void => {
          this.visible = false;
        },
      });
    }
    .id('image_preview_host_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#000000');
  }
}
