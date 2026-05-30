import { AppBar } from '../common/AppBar';
import { I18n } from '../i18n/I18n';
import { NavigationService } from '../navigation/NavigationService';
import { GSYColor, GSYFontSize } from '../style/Theme';

export class CustomScriptItem {
  name: string;
  hint: string;

  constructor(name: string, hint: string) {
    this.name = name;
    this.hint = hint;
  }
}

export function buildCustomPlaceholderList(): CustomScriptItem[] {
  return [
    new CustomScriptItem(I18n('customScriptItem1'), I18n('customScriptHint1')),
    new CustomScriptItem(I18n('customScriptItem2'), I18n('customScriptHint2')),
    new CustomScriptItem(I18n('customScriptItem3'), I18n('customScriptHint3')),
  ];
}

@Component
export struct CustomPage {
  @State items: CustomScriptItem[] = buildCustomPlaceholderList();

  @Builder
  buildItem(item: CustomScriptItem, index: number): void {
    Column() {
      Text(item.name)
        .id('custom_item_name_' + index.toString())
        .fontSize(GSYFontSize.middleNormal)
        .fontWeight(FontWeight.Bold)
        .fontColor(GSYColor.primary);
      Text(item.hint)
        .id('custom_item_hint_' + index.toString())
        .fontSize(GSYFontSize.min)
        .fontColor(GSYColor.textSubtle)
        .margin({ top: 4 });
    }
    .id('custom_item_' + index.toString())
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .backgroundColor(GSYColor.white)
    .border({ width: { bottom: 0.5 }, color: GSYColor.borderSubtle });
  }

  build(): void {
    Column() {
      AppBar({
        title: I18n('custom'),
        showBack: true,
        onBack: (): void => {
          NavigationService.pop();
        },
      });
      Column() {
        Text(I18n('customHeaderTitle'))
          .id('custom_header_title')
          .fontSize(GSYFontSize.middleWhite)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.primary);
        Text(I18n('feedback'))
          .id('custom_header_subtitle')
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.textSubtle)
          .margin({ top: 4 });
      }
      .id('custom_header')
      .width('100%')
      .padding({ top: 24, bottom: 16, left: 16, right: 16 })
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(GSYColor.white);

      List() {
        ForEach(this.items, (item: CustomScriptItem, index: number): void => {
          ListItem() {
            this.buildItem(item, index);
          }
          .id('custom_list_item_' + index.toString());
        }, (item: CustomScriptItem, index: number): string => 'c_' + index.toString() + '_' + item.name);
      }
      .id('custom_list')
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0, color: Color.Transparent });

      Button(I18n('customComingSoon'))
        .id('custom_placeholder_btn')
        .type(ButtonType.Capsule)
        .width('80%')
        .height(44)
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.white)
        .backgroundColor(GSYColor.subText)
        .margin({ top: 12, bottom: 12 })
        .onClick((): void => {
        });
    }
    .id('custom_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.pageBackground);
  }
}
