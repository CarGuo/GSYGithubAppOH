import { AppBar } from '../common/AppBar';
import { I18n } from '../i18n/I18n';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { GSYColor, GSYFontSize } from '../style/Theme';

export const APP_VERSION: string = '1.0.0';
export const APP_AUTHOR: string = 'CarGuo';
export const APP_PROJECT_URL: string = 'https://github.com/CarGuo/GSYGithubAppOH';
export const APP_LICENSE: string = 'MIT License';

@Component
export struct AboutPage {
  @State versionText: string = APP_VERSION;
  @State authorText: string = APP_AUTHOR;
  @State projectUrlText: string = APP_PROJECT_URL;
  @State licenseText: string = APP_LICENSE;

  private goHonor(): void {
    NavigationService.push(RouteName.Honor);
  }

  private goCustom(): void {
    NavigationService.push(RouteName.Custom);
  }

  @Builder
  buildRow(idValue: string, label: string, value: string): void {
    Row() {
      Text(label)
        .id(idValue + '_label')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.textSubtle)
        .width(96);
      Text(value)
        .id(idValue + '_value')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.primary)
        .layoutWeight(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(2);
    }
    .id(idValue + '_row')
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .backgroundColor(GSYColor.white)
    .border({ width: { bottom: 0.5 }, color: GSYColor.borderSubtle });
  }

  build(): void {
    Column() {
      AppBar({
        title: I18n('about'),
        showBack: true,
        onBack: (): void => {
          NavigationService.pop();
        },
      });
      Scroll() {
        Column() {
          Column() {
            Text('GSY')
              .id('about_logo')
              .fontSize(40) // TODO: 字号 40 暂无 token 映射
              .fontWeight(FontWeight.Bold)
              .fontColor(GSYColor.white)
              .width(96)
              .height(96)
              .textAlign(TextAlign.Center)
              .borderRadius(48)
              .backgroundColor(GSYColor.linkBlue);
            Text(I18n('appName'))
              .id('about_app_name')
              .fontSize(GSYFontSize.normal)
              .fontWeight(FontWeight.Bold)
              .fontColor(GSYColor.primary)
              .margin({ top: 12 });
          }
          .id('about_logo_block')
          .width('100%')
          .padding({ top: 32, bottom: 24 })
          .alignItems(HorizontalAlign.Center);

          this.buildRow('about_version', I18n('version'), this.versionText);
          this.buildRow('about_author', I18n('author'), this.authorText);
          this.buildRow('about_project_url', I18n('projectUrl'), this.projectUrlText);
          this.buildRow('about_license', 'License', this.licenseText);

          Button(I18n('beStaredText'))
            .id('about_honor_btn')
            .type(ButtonType.Capsule)
            .width('90%')
            .height(46)
            .fontSize(15) // TODO: 字号 15 暂无 token 映射
            .fontColor(GSYColor.white)
            .backgroundColor(GSYColor.successGreen)
            .margin({ top: 24 })
            .onClick((): void => {
              this.goHonor();
            });

          Button('Custom')
            .id('about_custom_btn')
            .type(ButtonType.Capsule)
            .width('90%')
            .height(46)
            .fontSize(15) // TODO: 字号 15 暂无 token 映射
            .fontColor(GSYColor.white)
            .backgroundColor(GSYColor.linkBlue)
            .margin({ top: 12, bottom: 24 })
            .onClick((): void => {
              this.goCustom();
            });
        }
        .id('about_content')
        .width('100%')
        .alignItems(HorizontalAlign.Center);
      }
      .id('about_scroll')
      .layoutWeight(1)
      .width('100%');
    }
    .id('about_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.pageBackground);
  }
}
