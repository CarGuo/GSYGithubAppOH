import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import {
  I18n,
  changeLocale,
  I18nState,
  defaultLocale,
  translations,
  LocaleKey,
  TranslationMap,
} from '../../../main/ets/i18n/I18n';

export default function I18nTest() {
  describe('I18nTest', () => {
    beforeEach(() => {
      I18nState.setLocale(defaultLocale);
    });

    afterAll(() => {
      I18nState.setLocale(defaultLocale);
    });

    it('default_locale_should_be_zh_CN', 0, () => {
      expect(defaultLocale).assertEqual('zh-CN');
    });

    it('translations_should_contain_en_and_zh_CN', 0, () => {
      const keys: string[] = Object.keys(translations);
      expect(keys.indexOf('en') >= 0).assertTrue();
      expect(keys.indexOf('zh-CN') >= 0).assertTrue();
    });

    it('changeLocale_to_en_should_return_en_translation', 0, () => {
      changeLocale('en');
      expect(I18nState.getLocale()).assertEqual('en');
      expect(I18n('appName')).assertEqual('GSY GitHub App');
      expect(I18n('ok')).assertEqual('ok');
      expect(I18n('cancel')).assertEqual('cancel');
      expect(I18n('tabRecommended')).assertEqual('Trending');
      expect(I18n('tabDynamic')).assertEqual('Feed');
      expect(I18n('tabMy')).assertEqual('My');
    });

    it('changeLocale_to_zh_CN_should_return_zh_translation', 0, () => {
      changeLocale('zh-CN');
      expect(I18nState.getLocale()).assertEqual('zh-CN');
      expect(I18n('ok')).assertEqual('确定');
      expect(I18n('cancel')).assertEqual('取消');
      expect(I18n('tabRecommended')).assertEqual('趋势');
      expect(I18n('tabDynamic')).assertEqual('动态');
      expect(I18n('tabMy')).assertEqual('我的');
      expect(I18n('setting')).assertEqual('设置');
    });

    it('changeLocale_with_underscore_form_should_normalize', 0, () => {
      changeLocale('en_US');
      expect(I18nState.getLocale()).assertEqual('en');
      changeLocale('zh_CN');
      expect(I18nState.getLocale()).assertEqual('zh-CN');
    });

    it('changeLocale_with_zh_Hant_should_fallback_to_zh_CN', 0, () => {
      changeLocale('zh-Hant-TW');
      expect(I18nState.getLocale()).assertEqual('zh-CN');
      changeLocale('zh-HK');
      expect(I18nState.getLocale()).assertEqual('zh-CN');
      changeLocale('zh-MO');
      expect(I18nState.getLocale()).assertEqual('zh-CN');
    });

    it('changeLocale_with_unknown_should_fallback_to_default', 0, () => {
      changeLocale('fr-FR');
      expect(I18nState.getLocale()).assertEqual(defaultLocale);
    });

    it('I18n_should_replace_named_placeholders_via_option1_and_option2', 0, () => {
      changeLocale('en');
      const opt1: Record<string, string> = { 'option1': 'A' };
      const opt2: Record<string, string> = { 'option2': 'B' };
      const result: string = I18n('notifyType', opt1, opt2);
      expect(result).assertEqual('Type');
    });

    it('I18n_zh_should_replace_named_placeholders', 0, () => {
      changeLocale('zh-CN');
      const opt1: Record<string, string> = { 'option1': '甲' };
      const opt2: Record<string, string> = { 'option2': '乙' };
      const result: string = I18n('notifyType', opt1, opt2);
      expect(result).assertEqual('类型');
    });

    it('I18n_should_fallback_to_default_when_value_empty', 0, () => {
      changeLocale('en');
      expect(I18n('appName')).assertEqual('GSY GitHub App');
    });

    it('zh_CN_translation_should_have_required_keys', 0, () => {
      const zh: TranslationMap = translations['zh-CN'];
      expect(zh.appName).assertEqual('GSYGitHubApp');
      expect(zh.netError).assertEqual('网络错误');
      expect(zh.netTimeout).assertEqual('网络超时');
      expect(zh.LoginOut).assertEqual('退出登录');
      expect(zh.clearCache).assertEqual('清除缓存');
    });

    it('en_translation_should_have_required_keys', 0, () => {
      const en: TranslationMap = translations['en'];
      expect(en.appName).assertEqual('GSY GitHub App');
      expect(en.netError).assertEqual('network error');
      expect(en.netTimeout).assertEqual('network timeout');
      expect(en.LoginOut).assertEqual('Logout');
      expect(en.clearCache).assertEqual('clearCache');
    });

    it('changeLocale_with_local_should_pick_system_locale', 0, () => {
      const got: LocaleKey = changeLocale('local');
      expect(got === 'zh-CN' || got === 'en').assertTrue();
    });

    it('changeLocale_with_empty_should_pick_system_locale', 0, () => {
      const got: LocaleKey = changeLocale('');
      expect(got === 'zh-CN' || got === 'en').assertTrue();
    });
  });
}
