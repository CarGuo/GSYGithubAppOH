import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import { CommonToast } from '../common/CommonToast';
import { I18n } from '../i18n/I18n';
import { Logger } from '../ai-debug/Logger';

export class ExternalUrlUtil {
  static openUrlInBrowser(host: Object, url: string, tag: string = 'ExternalUrl'): boolean {
    if (url.length === 0) {
      return false;
    }
    try {
      const ctx: common.UIAbilityContext = getContext(host) as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: url,
      };
      ctx.startAbility(want)
        .then((): void => {
          Logger.i(tag, 'startAbility viewData ok url=' + url);
        })
        .catch((err: Error): void => {
          Logger.w(tag, 'startAbility viewData fail msg=' + err.message);
          CommonToast.showShort(I18n('openLinkFailed'));
        });
      return true;
    } catch (e) {
      const err: Error = e as Error;
      Logger.w(tag, 'startAbility viewData throw msg=' + err.message);
      CommonToast.showShort(I18n('openLinkFailed'));
      return false;
    }
  }
}
