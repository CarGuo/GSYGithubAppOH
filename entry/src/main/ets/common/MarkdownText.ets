import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';
import {
  MarkdownLine,
  MarkdownUtil,
  MARKDOWN_LINE_BULLET,
  MARKDOWN_LINE_CODE,
  MARKDOWN_LINE_HEADING,
  MARKDOWN_LINE_ORDERED,
  MARKDOWN_LINE_QUOTE,
  MARKDOWN_LINE_TABLE,
  MARKDOWN_LINE_TASK
} from '../utils/MarkdownUtil';

const CODE_RADIUS: number = 4;
const QUOTE_BAR_WIDTH: number = 3;
const LIST_INDENT: number = 16;

@Component
export struct MarkdownText {
  @Prop markdown: string = '';
  @Prop rootId: string = 'markdown_text';
  @Prop textColor: ResourceColor = GSYColor.mainText;
  @Prop textFontSize: number = GSYFontSize.small;

  private lines(): MarkdownLine[] {
    return MarkdownUtil.parseLines(this.markdown);
  }

  private headingSize(level: number): number {
    if (level <= 1) {
      return GSYFontSize.normal;
    }
    if (level === 2) {
      return GSYFontSize.middleWhite;
    }
    return this.textFontSize;
  }

  @Builder
  private buildLine(line: MarkdownLine, index: number): void {
    if (line.kind === MARKDOWN_LINE_HEADING) {
      Text(line.text)
        .id(this.rootId + '_heading_' + index.toString())
        .fontSize(this.headingSize(line.level))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .width('100%')
        .margin({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge });
    } else if (line.kind === MARKDOWN_LINE_BULLET || line.kind === MARKDOWN_LINE_ORDERED
      || line.kind === MARKDOWN_LINE_TASK) {
      Row() {
        Text(line.marker)
          .id(this.rootId + '_marker_' + index.toString())
          .fontSize(this.textFontSize)
          .fontColor(line.kind === MARKDOWN_LINE_TASK && line.checked ? GSYColor.actionBlue : GSYColor.mediumText)
          .width(line.kind === MARKDOWN_LINE_ORDERED ? 28 : 22);
        Text(line.text)
          .id(this.rootId + '_text_' + index.toString())
          .fontSize(this.textFontSize)
          .fontColor(this.textColor)
          .layoutWeight(1);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({ left: line.level * LIST_INDENT, top: 2, bottom: 2 });
    } else if (line.kind === MARKDOWN_LINE_QUOTE) {
      Row() {
        Blank()
          .width(QUOTE_BAR_WIDTH)
          .height('100%')
          .backgroundColor(GSYColor.lightDivider);
        Text(line.text)
          .id(this.rootId + '_quote_' + index.toString())
          .fontSize(this.textFontSize)
          .fontColor(GSYColor.mediumText)
          .layoutWeight(1)
          .margin({ left: GSYSpacing.halfEdge });
      }
      .width('100%')
      .padding({
        left: GSYSpacing.halfEdge,
        right: GSYSpacing.halfEdge,
        top: GSYSpacing.halfEdge,
        bottom: GSYSpacing.halfEdge,
      })
      .backgroundColor(GSYColor.surfaceGray)
      .margin({ top: GSYSpacing.halfEdge, bottom: GSYSpacing.halfEdge });
    } else if (line.kind === MARKDOWN_LINE_CODE) {
      Text(line.text)
        .id(this.rootId + '_code_' + index.toString())
        .fontSize(GSYFontSize.min)
        .fontFamily('monospace')
        .fontColor(GSYColor.mainText)
        .width('100%')
        .padding(GSYSpacing.halfEdge)
        .backgroundColor(GSYColor.surfaceGray)
        .borderRadius(CODE_RADIUS)
        .margin({ top: 2, bottom: 2 });
    } else if (line.kind === MARKDOWN_LINE_TABLE) {
      Row() {
        ForEach(line.cells, (cell: string, cellIndex: number): void => {
          Text(cell)
            .id(this.rootId + '_table_' + index.toString() + '_' + cellIndex.toString())
            .fontSize(this.textFontSize)
            .fontWeight(line.level === 1 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.textColor)
            .layoutWeight(1)
            .padding({
              left: GSYSpacing.halfEdge,
              right: GSYSpacing.halfEdge,
              top: GSYSpacing.halfEdge,
              bottom: GSYSpacing.halfEdge,
            });
        }, (cell: string, cellIndex: number): string => {
          return cellIndex.toString() + '_' + cell;
        });
      }
      .id(this.rootId + '_table_row_' + index.toString())
      .width('100%')
      .backgroundColor(line.level === 1 ? GSYColor.surfaceGray : GSYColor.cardBackground)
      .border({
        width: 1,
        color: GSYColor.lightDivider,
      })
      .alignItems(VerticalAlign.Top);
    } else {
      Text(line.text)
        .id(this.rootId + '_text_' + index.toString())
        .fontSize(this.textFontSize)
        .fontColor(this.textColor)
        .width('100%')
        .margin({ top: 2, bottom: 2 });
    }
  }

  build(): void {
    Column() {
      ForEach(this.lines(), (line: MarkdownLine, index: number): void => {
        this.buildLine(line, index);
      }, (line: MarkdownLine, index: number): string => {
        return index.toString() + '_' + line.kind + '_' + line.text;
      });
    }
    .id(this.rootId)
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }
}
