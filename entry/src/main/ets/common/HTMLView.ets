import { GSYColor, GSYFontSize } from '../style/Theme';

@Component
export struct HTMLView {
  @Prop value: string = '';
  @Prop html: string = '';
  @Prop fontSize: number = 0;
  @Prop fontColor: ResourceColor = '';
  @Prop textFontSize: number = 0;
  @Prop textColor: ResourceColor = '';
  @Prop maxLines: number = 0;
  @Prop rootId: string = '';
  @Prop viewId: string = '';

  private stripTags(input: string): string {
    if (!input || input.length === 0) {
      return '';
    }
    let text: string = input;
    text = text.replace(/<style[\s\S]*?<\/style>/gi, '');
    text = text.replace(/<script[\s\S]*?<\/script>/gi, '');
    text = text.replace(/<br\s*\/?\s*>/gi, '\n');
    text = text.replace(/<\/p\s*>/gi, '\n');
    text = text.replace(/<\/div\s*>/gi, '\n');
    text = text.replace(/<\/li\s*>/gi, '\n');
    text = text.replace(/<[^>]+>/g, '');
    text = text.replace(/&nbsp;/g, ' ');
    text = text.replace(/&amp;/g, '&');
    text = text.replace(/&lt;/g, '<');
    text = text.replace(/&gt;/g, '>');
    text = text.replace(/&quot;/g, '"');
    text = text.replace(/&#39;/g, "'");
    text = text.replace(/\n{3,}/g, '\n\n');
    return text.trim();
  }

  private resolveText(): string {
    return this.value && this.value.length > 0 ? this.value : this.html;
  }

  private resolveFontSize(): number {
    if (this.fontSize > 0) {
      return this.fontSize;
    }
    if (this.textFontSize > 0) {
      return this.textFontSize;
    }
    return GSYFontSize.small;
  }

  private resolveFontColor(): ResourceColor {
    if (this.fontColor && (this.fontColor as string).length > 0) {
      return this.fontColor;
    }
    if (this.textColor && (this.textColor as string).length > 0) {
      return this.textColor;
    }
    return GSYColor.subText;
  }

  private resolveMaxLines(): number {
    return this.maxLines > 0 ? this.maxLines : -1;
  }

  private resolveId(): string {
    if (this.viewId && this.viewId.length > 0) {
      return this.viewId;
    }
    if (this.rootId && this.rootId.length > 0) {
      return this.rootId;
    }
    return 'html_view';
  }

  build(): void {
    Text(this.stripTags(this.resolveText()))
      .id(this.resolveId())
      .fontSize(this.resolveFontSize())
      .fontColor(this.resolveFontColor())
      .maxLines(this.resolveMaxLines() > 0 ? this.resolveMaxLines() : undefined)
      .textOverflow({ overflow: TextOverflow.Ellipsis });
  }
}
