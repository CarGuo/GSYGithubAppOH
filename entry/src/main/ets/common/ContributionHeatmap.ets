import { I18n } from '../i18n/I18n';
import { ContributionDay } from '../store/ContributionStore';
import { GSYColor, GSYFontSize } from '../style/Theme';

const HEATMAP_COLUMNS: number = 53;
const HEATMAP_ROWS: number = 7;
const CELL_SIZE: number = 10;
const CELL_GAP: number = 2;
const HEATMAP_WIDTH: number = HEATMAP_COLUMNS * (CELL_SIZE + CELL_GAP);
const HEATMAP_HEIGHT: number = HEATMAP_ROWS * (CELL_SIZE + CELL_GAP);

const LEVEL_COLOR_0: string = GSYColor.heatmapLevel0;
const LEVEL_COLOR_1: string = GSYColor.heatmapLevel1;
const LEVEL_COLOR_2: string = GSYColor.heatmapLevel2;
const LEVEL_COLOR_3: string = GSYColor.heatmapLevel3;
const LEVEL_COLOR_4: string = GSYColor.heatmapLevel4;

export function levelColor(level: number): string {
  switch (level) {
    case 1:
      return LEVEL_COLOR_1;
    case 2:
      return LEVEL_COLOR_2;
    case 3:
      return LEVEL_COLOR_3;
    case 4:
      return LEVEL_COLOR_4;
    default:
      return LEVEL_COLOR_0;
  }
}

@Component
export struct ContributionHeatmap {
  @Prop days: ContributionDay[];
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private drawCells(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    ctx.clearRect(0, 0, HEATMAP_WIDTH, HEATMAP_HEIGHT);

    const list: ContributionDay[] = this.days !== undefined && this.days !== null ? this.days : [];
    const total: number = HEATMAP_COLUMNS * HEATMAP_ROWS;
    const startIndex: number = list.length >= total ? list.length - total : 0;

    for (let col = 0; col < HEATMAP_COLUMNS; col++) {
      for (let row = 0; row < HEATMAP_ROWS; row++) {
        const dataIdx: number = startIndex + col * HEATMAP_ROWS + row;
        let level: number = 0;
        if (dataIdx >= 0 && dataIdx < list.length) {
          const d: ContributionDay = list[dataIdx];
          level = typeof d.level === 'number' ? d.level : 0;
        }
        const x: number = col * (CELL_SIZE + CELL_GAP);
        const y: number = row * (CELL_SIZE + CELL_GAP);
        ctx.fillStyle = levelColor(level);
        ctx.fillRect(x, y, CELL_SIZE, CELL_SIZE);
      }
    }
  }

  build(): void {
    Column() {
      Text(I18n('contributionTitle'))
        .id('contribution_heatmap_title')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.primary)
        .margin({ bottom: 8 });

      if (this.days === undefined || this.days === null || this.days.length === 0) {
        Text(I18n('contributionEmpty'))
          .id('contribution_heatmap_empty')
          .fontSize(GSYFontSize.min)
          .fontColor(GSYColor.subText);
      }

      Canvas(this.context)
        .id('contribution_canvas')
        .width(HEATMAP_WIDTH)
        .height(HEATMAP_HEIGHT)
        .onReady((): void => {
          this.drawCells();
        });
    }
    .id('contribution_heatmap_root')
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(GSYColor.white);
  }
}
