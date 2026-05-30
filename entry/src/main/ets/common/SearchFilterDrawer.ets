/**
 * SearchFilterDrawer —— 1:1 对齐 RN
 *   [SearchDrawerFilter.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/SearchDrawerFilter.js)
 *   [SearchFilterSelectList.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/SearchFilterSelectList.js)
 *
 * 数据来源：[filterUtils.js#L121-L144](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/filterUtils.js#L121-L144)
 *   - SearchFilterType: best_match / stars / forks / updated
 *   - SortType:        desc / asc
 *   - SearchLanguageType: trendAll / Java / Objective-C / Swift / JavaScript / PHP / C++ / C / HTML / CSS
 *
 * 使用：
 *   父组件 SearchPage 使用 SideBarContainer(sideBarPosition=End) 嵌入本 Drawer
 *   onSelect(section, value) 由父组件接住，用于触发 SearchService 的 sort/language 重新查询
 */

import { I18n } from '../i18n/I18n';
import type { TranslationMap } from '../i18n/I18n';
import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';
import { SAFE_AREA_TOP_KEY } from '../utils/SafeAreaInsets';

export type SearchFilterI18nKey = keyof TranslationMap;

export const SEARCH_FILTER_SECTION_TYPE: SearchFilterI18nKey = 'filerType';
export const SEARCH_FILTER_SECTION_SORT: SearchFilterI18nKey = 'filterSort';
export const SEARCH_FILTER_SECTION_LANGUAGE: SearchFilterI18nKey = 'filterLanguage';

export class SearchFilterOption {
  name: SearchFilterI18nKey = 'trendAll';
  value: string | null = null;
  select: boolean = false;
}

export function buildDefaultFilterTypes(): SearchFilterOption[] {
  const a: SearchFilterOption = { name: 'best_match', value: 'best%20match', select: true };
  const b: SearchFilterOption = { name: 'stars', value: 'stars', select: false };
  const c: SearchFilterOption = { name: 'forks', value: 'forks', select: false };
  const d: SearchFilterOption = { name: 'updated', value: 'updated', select: false };
  return [a, b, c, d];
}

export function buildDefaultFilterSorts(): SearchFilterOption[] {
  const a: SearchFilterOption = { name: 'desc', value: 'desc', select: true };
  const b: SearchFilterOption = { name: 'asc', value: 'asc', select: false };
  return [a, b];
}

export function buildDefaultFilterLanguages(): SearchFilterOption[] {
  const items: SearchFilterOption[] = [];
  const names: SearchFilterI18nKey[] = [
    'trendAll', 'Java', 'Objective_C', 'Swift', 'JavaScript',
    'PHP', 'C__', 'C', 'HTML', 'CSS',
  ];
  const values: (string | null)[] = [
    null, 'Java', 'Objective-C', 'Swift', 'JavaScript',
    'PHP', 'C++', 'C', 'HTML', 'CSS',
  ];
  for (let i = 0; i < names.length; i++) {
    const opt: SearchFilterOption = { name: names[i], value: values[i], select: i === 0 };
    items.push(opt);
  }
  return items;
}

@Component
export struct SearchFilterDrawer {
  @Link types: SearchFilterOption[];
  @Link sorts: SearchFilterOption[];
  @Link languages: SearchFilterOption[];
  /**
   * 选项变更版本号（@Link，由父级 SearchPage 通过 @Watch 监听）。
   * 每次 row 被点击 += 1，从而避开跨组件的 onSelect 闭包失效问题。
   */
  @Link rev: number;
  /** section 取值：filerType / filterSort / filterLanguage —— 仅作兼容回调，
   * 真正的事件源是 @Link rev 自增，父级用 @Watch 接住。 */
  onSelect: (section: string, value: string | null) => void = (): void => {};

  @StorageProp(SAFE_AREA_TOP_KEY) safeAreaTop: number = 0;

  private setSelected(list: SearchFilterOption[], target: SearchFilterOption): SearchFilterOption[] {
    const next: SearchFilterOption[] = [];
    for (let i = 0; i < list.length; i++) {
      const o: SearchFilterOption = list[i];
      const item: SearchFilterOption = { name: o.name, value: o.value, select: o === target };
      next.push(item);
    }
    return next;
  }

  @Builder
  buildSectionHeader(titleKey: SearchFilterI18nKey): void {
    Row() {
      Text(I18n(titleKey))
        .id('search_filter_section_' + (titleKey as string))
        .fontSize(GSYFontSize.min)
        .fontColor(GSYColor.white);
    }
    .width('100%')
    .height(40)
    .padding({ left: GSYSpacing.normalEdge })
    .margin({ top: GSYSpacing.normalEdge })
    .backgroundColor(GSYColor.primaryLight)
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  buildRow(section: string, list: SearchFilterOption[], opt: SearchFilterOption, index: number): void {
    Row() {
      Text(I18n(opt.name))
        .id('search_filter_row_' + section + '_' + index.toString())
        .fontSize(opt.select ? GSYFontSize.small : GSYFontSize.min)
        .fontColor(opt.select ? GSYColor.mainText : GSYColor.subText)
        .textAlign(TextAlign.Center);
    }
    .width('100%')
    .height(50)
    .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge })
    .margin({ top: GSYSpacing.normalEdge })
    .backgroundColor(opt.select ? GSYColor.miWhite : GSYColor.transparent)
    .borderRadius(4)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .hitTestBehavior(HitTestMode.Block)
    .onClick((): void => {
      if (section === SEARCH_FILTER_SECTION_TYPE) {
        this.types = this.setSelected(this.types, opt);
      } else if (section === SEARCH_FILTER_SECTION_SORT) {
        this.sorts = this.setSelected(this.sorts, opt);
      } else if (section === SEARCH_FILTER_SECTION_LANGUAGE) {
        this.languages = this.setSelected(this.languages, opt);
      }
      // 触发父级 @Watch（即使 onSelect 闭包失效也会通过 rev 自增传递信号）
      this.rev = this.rev + 1;
      this.onSelect(section, opt.value);
    });
  }

  build(): void {
    Column() {
      // 状态栏占位（对齐 RN SearchDrawerFilter 的 statusBar bg=primaryDarkColor）
      Row()
        .id('search_filter_status_spacer')
        .width('100%')
        .height(this.safeAreaTop)
        .backgroundColor(GSYColor.primaryDark);

      Scroll() {
        Column() {
          this.buildSectionHeader(SEARCH_FILTER_SECTION_TYPE);
          ForEach(this.types, (opt: SearchFilterOption, idx: number): void => {
            this.buildRow(SEARCH_FILTER_SECTION_TYPE, this.types, opt, idx);
          }, (opt: SearchFilterOption, idx: number): string => 't_' + idx.toString() + '_' + opt.name);

          this.buildSectionHeader(SEARCH_FILTER_SECTION_SORT);
          ForEach(this.sorts, (opt: SearchFilterOption, idx: number): void => {
            this.buildRow(SEARCH_FILTER_SECTION_SORT, this.sorts, opt, idx);
          }, (opt: SearchFilterOption, idx: number): string => 's_' + idx.toString() + '_' + opt.name);

          this.buildSectionHeader(SEARCH_FILTER_SECTION_LANGUAGE);
          ForEach(this.languages, (opt: SearchFilterOption, idx: number): void => {
            this.buildRow(SEARCH_FILTER_SECTION_LANGUAGE, this.languages, opt, idx);
          }, (opt: SearchFilterOption, idx: number): string => 'l_' + idx.toString() + '_' + opt.name);

          Row()
            .id('search_filter_bottom_spacer')
            .width('100%')
            .height(GSYSpacing.tabBarHeight);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      }
      .id('search_filter_scroll')
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off);
    }
    .id('search_filter_drawer_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.white);
  }
}
