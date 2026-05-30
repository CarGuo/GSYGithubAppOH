import { GITHUB_EMOJI_MAP, emojiNames } from '../utils/EmojiMap';
import { buildEmojiToken } from '../utils/EmojiText';
import { GSYColor, GSYFontSize } from '../style/Theme';

@Component
export struct EmojiKeyboard {
  visible: boolean = false;
  onPick: (token: string) => void = (_token: string): void => {};
  onClose: () => void = (): void => {};
  @State names: string[] = emojiNames();

  private resolveDisplay(name: string): string {
    const value: string | undefined = GITHUB_EMOJI_MAP[name];
    if (value === undefined || value === null) {
      return ':' + name + ':';
    }
    return value;
  }

  build(): void {
    if (this.visible) {
      Column() {
        Row() {
          Text('Emoji')
            .id('emoji_keyboard_title')
            .fontSize(GSYFontSize.small)
            .fontColor(GSYColor.primary)
            .layoutWeight(1);
          Button('x')
            .id('emoji_close')
            .type(ButtonType.Normal)
            .backgroundColor(Color.Transparent)
            .fontColor(GSYColor.subText)
            .fontSize(GSYFontSize.small)
            .height(28)
            .onClick((): void => {
              this.onClose();
            });
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .alignItems(VerticalAlign.Center);

        Grid() {
          ForEach(this.names, (name: string, _index: number): void => {
            GridItem() {
              Text(this.resolveDisplay(name))
                .id('emoji_item_' + name)
                .fontSize(20) // TODO: 字号 20 暂无 token 映射
                .fontColor(GSYColor.primary)
                .textAlign(TextAlign.Center)
                .width('100%')
                .height('100%')
                .onClick((): void => {
                  this.onPick(buildEmojiToken(name));
                });
            }
            .height(40);
          }, (name: string, _index: number): string => 'emoji_grid_' + name);
        }
        .id('emoji_grid')
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsGap(6)
        .columnsGap(6)
        .width('100%')
        .height(220)
        .padding({ left: 8, right: 8, top: 4, bottom: 8 });
      }
      .id('emoji_keyboard_root')
      .width('100%')
      .backgroundColor(GSYColor.surfaceSubtle)
      .border({ width: { top: 1 }, color: GSYColor.divider });
    }
  }
}
