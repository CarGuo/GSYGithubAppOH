import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { renderEmoji, buildEmojiToken } from '../../../main/ets/utils/EmojiText';
import { GITHUB_EMOJI_MAP, lookupEmoji, emojiNames } from '../../../main/ets/utils/EmojiMap';

export default function EmojiKeyboardTest(): void {
  describe('EmojiKeyboardTest', (): void => {
    beforeAll((): void => {
    });

    afterAll((): void => {
    });

    it('EmojiMap_should_contain_core_keys', 0, (): void => {
      const required: string[] = [
        'smile', 'laughing', 'heart', '+1', '-1', 'eyes',
        'rocket', 'tada', 'thinking', 'fire', '100', 'star',
      ];
      for (let i: number = 0; i < required.length; i++) {
        const key: string = required[i];
        const value: string | undefined = GITHUB_EMOJI_MAP[key];
        expect(value !== undefined && value !== null).assertTrue();
        expect((value as string).length > 0).assertTrue();
      }
    });

    it('EmojiMap_should_have_at_least_60_entries', 0, (): void => {
      const names: string[] = emojiNames();
      expect(names.length >= 60).assertTrue();
    });

    it('lookupEmoji_returns_unicode_for_known_keys', 0, (): void => {
      expect(lookupEmoji('smile') !== null).assertTrue();
      expect(lookupEmoji('rocket') !== null).assertTrue();
      expect(lookupEmoji('not_exist_xx') === null).assertTrue();
      expect(lookupEmoji('') === null).assertTrue();
    });

    it('buildEmojiToken_wraps_with_colons', 0, (): void => {
      expect(buildEmojiToken('smile')).assertEqual(':smile:');
      expect(buildEmojiToken('')).assertEqual('');
    });

    it('renderEmoji_replaces_known_tokens', 0, (): void => {
      const out: string = renderEmoji('hello :smile: world');
      expect(out.indexOf(':smile:') < 0).assertTrue();
      expect(out.indexOf('hello ') === 0).assertTrue();
      expect(out.indexOf(' world') > 0).assertTrue();
    });

    it('renderEmoji_keeps_unknown_tokens', 0, (): void => {
      const out: string = renderEmoji('a :totally_unknown_xyz: b');
      expect(out.indexOf(':totally_unknown_xyz:') >= 0).assertTrue();
    });

    it('renderEmoji_replaces_multiple_tokens', 0, (): void => {
      const out: string = renderEmoji(':smile: and :heart: and :rocket:');
      expect(out.indexOf(':smile:') < 0).assertTrue();
      expect(out.indexOf(':heart:') < 0).assertTrue();
      expect(out.indexOf(':rocket:') < 0).assertTrue();
    });

    it('renderEmoji_handles_plus_one_and_minus_one', 0, (): void => {
      const out: string = renderEmoji('vote :+1: or :-1:');
      expect(out.indexOf(':+1:') < 0).assertTrue();
      expect(out.indexOf(':-1:') < 0).assertTrue();
    });

    it('renderEmoji_handles_empty_and_null', 0, (): void => {
      expect(renderEmoji('')).assertEqual('');
      const fromNull: string = renderEmoji(null);
      expect(fromNull).assertEqual('');
      const fromUndefined: string = renderEmoji(undefined);
      expect(fromUndefined).assertEqual('');
    });
  });
}
