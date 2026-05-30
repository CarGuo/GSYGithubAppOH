/**
 * IconTextAutoLinkItem —— 严格对齐 RN 端
 * [components/widget/IconTextAutoLinkItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/IconTextAutoLinkItem.js)
 *
 * 结构：Row(centerH) - 可选图标(littleIconSize+2, miWhite) + Autolink文本(miLightSmallText)
 * 交互：点击若文本以 http/www 开头 → 触发 onLinkPress(link)；否则 onPressItem。
 *      长按：复制文本到剪贴板 + Toast(I18n('hadCopy'))。
 */

import { GSYColor, GSYFontSize, GSYIconSize, GSYSpacing } from '../style/Theme';
import { IconFont } from '../common/IconFont';
import { I18n } from '../i18n/I18n';
import { CommonToast } from '../common/CommonToast';
import pasteboard from '@ohos.pasteboard';

@Component
export struct IconTextAutoLinkItem {
  text: string = '';
  iconChar: string = '';
  textColorOverride: string = '';
  rowId: string = '';
  onLinkPress: (link: string) => void = (): void => {};

  private isLink(value: string): boolean {
    if (!value) {
      return false;
    }
    return value.indexOf('http://') === 0 || value.indexOf('https://') === 0 || value.indexOf('www') === 0;
  }

  private copyText(): void {
    if (!this.text || this.text.length === 0) {
      return;
    }
    try {
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.text);
      const board: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      board.setData(data);
    } catch (_e) {
    }
    CommonToast.showShort(I18n('hadCopy'));
  }

  build(): void {
    Row() {
      if (this.iconChar.length > 0) {
        IconFont({
          char: this.iconChar,
          glyphSize: GSYIconSize.little + 2,
          glyphColor: GSYColor.miWhite,
        });
      }

      Text(this.text)
        .id(this.rowId.length > 0 ? this.rowId + '_text' : 'icon_text_autolink_text')
        .fontSize(GSYFontSize.small)
        .fontColor(this.textColorOverride.length > 0 ? this.textColorOverride : GSYColor.subLightText)
        .margin({ left: this.iconChar.length > 0 ? GSYSpacing.halfEdge : 0 })
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .onClick((): void => {
          if (this.isLink(this.text)) {
            this.onLinkPress(this.text);
          }
        });
    }
    .id(this.rowId.length > 0 ? this.rowId : 'icon_text_autolink_root')
    .alignItems(VerticalAlign.Center)
    .gesture(
      LongPressGesture()
        .onAction((): void => {
          this.copyText();
        })
    );
  }
}
