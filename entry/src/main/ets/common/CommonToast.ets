import promptAction from '@ohos.promptAction';

const SHORT_DURATION: number = 2000;
const LONG_DURATION: number = 3500;

export class CommonToast {
  static showShort(text: string): void {
    CommonToast.show(text, SHORT_DURATION);
  }

  static showLong(text: string): void {
    CommonToast.show(text, LONG_DURATION);
  }

  static show(text: string, duration: number): void {
    if (!text) {
      return;
    }
    try {
      promptAction.showToast({
        message: text,
        duration: duration,
        bottom: '64vp',
      });
    } catch (_e) {
    }
  }
}
