import { ContributionHeatmap } from '../../../main/ets/common/ContributionHeatmap';
import { ContributionDay } from '../../../main/ets/store/ContributionStore';

function buildMockDays(): ContributionDay[] {
  const out: ContributionDay[] = [];
  const dates: string[] = [
    '2026-05-18',
    '2026-05-19',
    '2026-05-20',
    '2026-05-21',
    '2026-05-22',
    '2026-05-23',
    '2026-05-24',
  ];
  const levels: number[] = [0, 1, 2, 3, 4, 2, 1];
  const counts: number[] = [0, 1, 5, 10, 20, 4, 2];
  for (let i = 0; i < dates.length; i++) {
    out.push({
      'date': dates[i],
      'count': counts[i],
      'level': levels[i],
    } as ContributionDay);
  }
  return out;
}

@Entry
@Component
struct ContributionHeatmapHostPage {
  @State days: ContributionDay[] = buildMockDays();

  build(): void {
    Column() {
      ContributionHeatmap({ days: this.days })
        .id('host_contribution');
    }
    .id('contribution_host_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}
