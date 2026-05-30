import { GSYColor, GSYFontSize } from '../style/Theme';

@Component
export struct HarmonyLogoMark {
  @Prop phase: number = 0;
  @Prop markSize: number = 180;
  @Prop rootId: string = 'harmony_logo';
  @Prop letterId: string = 'harmony_logo_letter';
  @Prop labelId: string = '';
  @Prop labelText: string = '';
  @Prop darkSurface: boolean = false;
  @Prop contained: boolean = false;
  @Prop play: boolean = true;
  @Prop showPosterBacking: boolean = false;

  private imageHeight(): number {
    return this.markSize * 0.75;
  }

  build(): void {
    Column() {
      Stack() {
        Image($r('app.media.oh_logo_poster'))
          .id(this.letterId + '_poster')
          .width(this.markSize)
          .height(this.imageHeight())
          .objectFit(ImageFit.Contain)
          .visibility((!this.play || this.showPosterBacking) ? Visibility.Visible : Visibility.None);

        Image($r('app.media.oh_logo'))
          .id(this.letterId)
          .width(this.markSize)
          .height(this.imageHeight())
          .objectFit(ImageFit.Contain)
          .visibility(this.play ? Visibility.Visible : Visibility.None);
      }
      .width(this.markSize)
      .height(this.imageHeight());

      if (this.labelText.length > 0) {
        Text(this.labelText)
          .id(this.labelId.length > 0 ? this.labelId : this.rootId + '_label')
          .fontSize(this.markSize > 180 ? GSYFontSize.small : GSYFontSize.min)
          .fontColor(this.darkSurface ? GSYColor.textWhite : GSYColor.textSubtle)
          .margin({ top: 4 });
      }
    }
    .id(this.rootId)
    .width(this.markSize)
    .height(this.imageHeight() + (this.labelText.length > 0 ? 28 : 0))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.contained ? GSYColor.transparent : GSYColor.transparent);
  }
}
