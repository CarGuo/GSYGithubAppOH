import { ThemePalette, LIGHT_PALETTE, DARK_PALETTE } from '../theme/ThemeManager';
import { GSYColor } from './Theme';

export const miWhite: string = GSYColor.miWhite;
export const white: string = '#FFF'; // TODO: #FFF 不严格匹配 GSYColor.white(#FFFFFF)，保留字面量
export const transparentColor: string = GSYColor.transparent;

export const mainBackgroundColor: string = miWhite;
export const tabBackgroundColor: string = GSYColor.tabBackground;
export const cardBackgroundColor: string = GSYColor.cardBackground;
export const cardShadowColor: string = GSYColor.cardShadow;
export const actionBlue: string = GSYColor.actionBlue;

export const lineColor: string = GSYColor.line;

export const primaryColor: string = GSYColor.primary;
export const primaryDarkColor: string = GSYColor.primaryDark;
export const primaryLightColor: string = GSYColor.primaryLight;

export const webDraculaBackgroundColor: string = GSYColor.webDraculaBackground;

export const selectedColor: string = primaryDarkColor;

export const titleTextColor: string = miWhite;
export const mainTextColor: string = primaryDarkColor;
export const subTextColor: string = GSYColor.subText;
export const subLightTextColor: string = GSYColor.subLightText;
export const TextColorWhite: string = GSYColor.white;
export const TextColorMiWhtte: string = miWhite;

export const tabSelectedColor: string = primaryColor;
export const tabUnSelectColor: string = GSYColor.tabUnSelect;

export const iosnavHeaderHeight: number = 70;
export const andrnavHeaderHeight: number = 70;

export const largetTextSize: number = 30;
export const bigTextSize: number = 23;
export const normalTextSize: number = 18;
export const middleTextWhite: number = 16;
export const smallTextSize: number = 14;
export const minTextSize: number = 12;

export const tabBarHeight: number = 44;
export const tabIconSize: number = 20;

export const normalIconSize: number = 40;
export const bigIconSize: number = 50;
export const largeIconSize: number = 80;
export const smallIconSize: number = 30;
export const minIconSize: number = 20;
export const littleIconSize: number = 10;

export const normalMarginEdge: number = 10;
export const normalNumberOfLine: number = 4;

export const nextIcon: string = 'chevron-right';
export const tabRecommended: string = 'activity';
export const tabDynamic: string = 'aperture';
export const tabMy: string = 'users';

export const TOKEN_KEY: string = 'token';
export const USER_NAME_KEY: string = 'user-name';
export const PW_KEY: string = 'user-pw';
export const USER_BASIC_CODE: string = 'user-basic-code';
export const USER_INFO: string = 'user-info';
export const LANGUAGE_SELECT: string = 'language-select';
export const LANGUAGE_SELECT_NAME: string = 'language-select-name';
export const REFRESH_LANGUAGE: string = 'refreshLanguageApp';

export interface ThemesMap {
  light: ThemePalette;
  dark: ThemePalette;
}

export const Themes: ThemesMap = {
  light: LIGHT_PALETTE,
  dark: DARK_PALETTE,
};
