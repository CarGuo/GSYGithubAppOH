import { GITHUB_EMOJI_MAP } from './EmojiMap';

const EMOJI_TOKEN_PATTERN: RegExp = /:([a-zA-Z0-9_+\-]+):/g;

export function renderEmoji(text: string | null | undefined): string {
  if (text === null || text === undefined) {
    return '';
  }
  if (text.length === 0) {
    return '';
  }
  return text.replace(EMOJI_TOKEN_PATTERN, (match: string, name: string): string => {
    const value: string | undefined = GITHUB_EMOJI_MAP[name];
    if (value === undefined || value === null) {
      return match;
    }
    return value;
  });
}

export function buildEmojiToken(name: string): string {
  if (name === null || name === undefined || name.length === 0) {
    return '';
  }
  return ':' + name + ':';
}
