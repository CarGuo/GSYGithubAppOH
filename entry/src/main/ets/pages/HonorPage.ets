import { AppBar } from '../common/AppBar';
import { I18n } from '../i18n/I18n';
import { NavigationService } from '../navigation/NavigationService';
import { GSYColor, GSYFontSize } from '../style/Theme';

export class HonorEntry {
  name: string;
  desc: string;

  constructor(name: string, desc: string) {
    this.name = name;
    this.desc = desc;
  }
}

export const HONOR_LIST: HonorEntry[] = [
  new HonorEntry('CarGuo', 'GSYGithubApp 项目作者'),
  new HonorEntry('OpenHarmony', 'OpenHarmony / ArkTS 框架'),
  new HonorEntry('GitHub REST API', 'github.com/api/v3'),
  new HonorEntry('hypium', 'OpenHarmony 单元测试 / UI 测试框架'),
  new HonorEntry('Contributors', 'GSYGithubApp 全体贡献者'),
];

@Component
export struct HonorPage {
  @State items: HonorEntry[] = HONOR_LIST;

  @Builder
  buildItem(item: HonorEntry, index: number): void {
    Row() {
      Text((index + 1).toString())
        .id('honor_index_' + index.toString())
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.white)
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .borderRadius(14)
        .backgroundColor(GSYColor.linkBlue);
      Column() {
        Text(item.name)
          .id('honor_name_' + index.toString())
          .fontSize(15) // TODO: 字号 15 暂无 token 映射
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.primary);
        Text(item.desc)
          .id('honor_desc_' + index.toString())
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.textSubtle)
          .margin({ top: 4 });
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 });
    }
    .id('honor_row_' + index.toString())
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .backgroundColor(GSYColor.white)
    .border({ width: { bottom: 0.5 }, color: GSYColor.borderSubtle })
    .alignItems(VerticalAlign.Center);
  }

  build(): void {
    Column() {
      AppBar({
        title: I18n('beStaredText'),
        showBack: true,
        onBack: (): void => {
          NavigationService.pop();
        },
      });
      Column() {
        Text('CarGuo / GSYGithubApp')
          .id('honor_header_title')
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.primary);
        Text(I18n('beStared100Title'))
          .id('honor_header_subtitle')
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.textSubtle)
          .margin({ top: 4 });
      }
      .id('honor_header')
      .width('100%')
      .padding({ top: 24, bottom: 16, left: 16, right: 16 })
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(GSYColor.white);

      List() {
        ForEach(this.items, (item: HonorEntry, index: number): void => {
          ListItem() {
            this.buildItem(item, index);
          }
          .id('honor_item_' + index.toString());
        }, (item: HonorEntry, index: number): string => 'h_' + index.toString() + '_' + item.name);
      }
      .id('honor_list')
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0, color: Color.Transparent });
    }
    .id('honor_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.pageBackground);
  }
}
