/**
 * TrendPickerItem —— 严格对齐 RN 端
 * [components/widget/TrendPickerItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/TrendPickerItem.js)
 *
 * 视觉特征：
 *  - 占据父容器 flex:1（一半宽度）
 *  - 中央显示当前选项 Text + 右侧 caret-down 三角
 *  - 点击弹出选项列表
 *
 * 使用 ArkUI 内置 Select 组件即可获得下拉行为，
 * 视觉颜色严格 GSYColor，字号 GSYFontSize.middleWhite。
 */

import { GSYColor, GSYFontSize, GSYSpacing } from '../style/Theme';

export interface TrendPickerOption {
  name: string;
  value: string;
  label: string;
}

@Component
export struct TrendPickerItem {
  options: TrendPickerOption[] = [];
  selectedIndex: number = 0;
  pickerId: string = 'trend_picker';
  onSelect: (index: number, option: TrendPickerOption) => void = (): void => {};

  private toSelectOptions(): SelectOption[] {
    const list: SelectOption[] = [];
    for (let i: number = 0; i < this.options.length; i++) {
      list.push({ value: this.options[i].label } as SelectOption);
    }
    return list;
  }

  build(): void {
    Row() {
      Select(this.toSelectOptions())
        .id(this.pickerId)
        .selected(this.selectedIndex)
        .value(this.selectedIndex >= 0 && this.selectedIndex < this.options.length
          ? this.options[this.selectedIndex].label
          : '')
        .font({ size: GSYFontSize.middleWhite })
        .fontColor(GSYColor.mainText)
        .selectedOptionFont({ size: GSYFontSize.middleWhite })
        .selectedOptionFontColor(GSYColor.selected)
        .optionFont({ size: GSYFontSize.middleWhite })
        .optionFontColor(GSYColor.mainText)
        .backgroundColor(GSYColor.white)
        .onSelect((index: number, value: string): void => {
          if (index >= 0 && index < this.options.length) {
            this.onSelect(index, this.options[index]);
          }
        });
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center);
  }
}
