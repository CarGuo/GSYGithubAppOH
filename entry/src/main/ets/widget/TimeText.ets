/**
 * TimeText —— 对齐 RN 端
 * [components/widget/TimeText.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/TimeText.js)
 * 仅渲染 [TimeUtil.resolveTime](../utils/TimeUtil.ets) 的本地化结果。
 */

import { TimeUtil } from '../utils/TimeUtil';
import { GSYColor, GSYFontSize } from '../style/Theme';

@Component
export struct TimeText {
  time: string = '';
  marginTopValue: number = 0;
  textId: string = '';

  build(): void {
    Text(TimeUtil.resolveTime(this.time))
      .id(this.textId.length > 0 ? this.textId : 'time_text')
      .fontSize(GSYFontSize.small)
      .fontColor(GSYColor.subText)
      .margin({ top: this.marginTopValue });
  }
}
