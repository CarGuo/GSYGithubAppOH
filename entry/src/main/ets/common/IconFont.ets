/**
 * IconFont —— 通用 FontAwesome 4.x 图标组件（与 RN 端 react-native-vector-icons 同源 ttf）。
 *
 * 字体注册位置：[WelcomePage.ets#L35-L46](../pages/WelcomePage.ets#L35-L46)
 * 字体资源：    [rawfile/fonts/FontAwesome.ttf](../../resources/rawfile/fonts/FontAwesome.ttf)
 * 码点对照表：  [FontAwesome.json glyphmap](https://github.com/CarGuo/GSYGithubApp/blob/master/node_modules/react-native-vector-icons/glyphmaps/FontAwesome.json)
 *
 * 使用：
 *   IconFont({ char: FA_BELL, glyphSize: 15, glyphColor: GSYColor.miWhite })
 *
 * 推荐尺寸：
 *   - RN 端 IconText 字号 ≈ 14 px，OH 端调用方传入 glyphSize = 14~16 即可。
 *   - 若调用方只有"槽位 size"（如 GSYIconSize.small=30），请按 size * 0.5 折算后再传入。
 *
 * 注意：属性命名避开 ArkUI CustomComponent 内置同名通用属性（size/color/width/height/...），
 *       否则会触发 ArkTS 10505001 编译错误（属性签名与基类冲突）。
 */

import { GSYColor } from '../style/Theme';

export const FA_BELL: string = '\uf0f3';
export const FA_GROUP: string = '\uf0c0';
export const FA_LOCATION: string = '\uf041';
export const FA_MAP_MARKER: string = '\uf041';
export const FA_LINK: string = '\uf0c1';
export const FA_STAR: string = '\uf005';
export const FA_STAR_O: string = '\uf006';
export const FA_CODE_FORK: string = '\uf126';
export const FA_USERS: string = '\uf0c0';
export const FA_HEART: string = '\uf004';
export const FA_HEART_O: string = '\uf08a';
export const FA_COMMENT: string = '\uf075';
export const FA_COMMENT_O: string = '\uf0e5';
export const FA_ENVELOPE: string = '\uf0e0';
export const FA_EYE: string = '\uf06e';
export const FA_EYE_SLASH: string = '\uf070';
export const FA_SEARCH: string = '\uf002';
export const FA_BARS: string = '\uf0c9';
export const FA_ELLIPSIS_V: string = '\uf142';
export const FA_ELLIPSIS_H: string = '\uf141';
export const FA_LOCK: string = '\uf023';
export const FA_KEY: string = '\uf084';
export const FA_UNLOCK: string = '\uf09c';
export const FA_QUESTION: string = '\uf128';
export const FA_USER: string = '\uf007';
export const FA_USER_PLUS: string = '\uf234';
export const FA_USER_TIMES: string = '\uf235';
export const FA_REPO: string = '\uf1c9';
export const FA_BRANCH: string = '\uf126';
export const FA_HOME: string = '\uf015';
export const FA_TIMES: string = '\uf00d';
export const FA_CHECK: string = '\uf00c';
export const FA_FILE: string = '\uf016';
export const FA_FOLDER: string = '\uf114';
export const FA_FOLDER_OPEN: string = '\uf115';
export const FA_CODE: string = '\uf121';
export const FA_BUG: string = '\uf188';
export const FA_GITHUB: string = '\uf09b';
export const FA_GITHUB_ALT: string = '\uf113';
export const FA_TAG: string = '\uf02b';
export const FA_DOWNLOAD: string = '\uf019';
export const FA_REFRESH: string = '\uf021';
export const FA_PLUS: string = '\uf067';
export const FA_MINUS: string = '\uf068';
export const FA_INFO: string = '\uf129';
export const FA_INFO_CIRCLE: string = '\uf05a';
export const FA_EXCLAMATION_CIRCLE: string = '\uf06a';
export const FA_CHEVRON_LEFT: string = '\uf053';
export const FA_CHEVRON_RIGHT: string = '\uf054';
export const FA_CHEVRON_UP: string = '\uf077';
export const FA_CHEVRON_DOWN: string = '\uf078';
export const FA_ARROW_LEFT: string = '\uf060';
export const FA_ARROW_RIGHT: string = '\uf061';
export const FA_CLOCK_O: string = '\uf017';
export const FA_HISTORY: string = '\uf1da';
export const FA_COG: string = '\uf013';
export const FA_SIGN_OUT: string = '\uf08b';
export const FA_SIGN_IN: string = '\uf090';
export const FA_AT: string = '\uf1fa';
export const FA_BUILDING: string = '\uf0f7';
export const FA_FILE_TEXT_O: string = '\uf0f6';
export const FA_USER_CIRCLE: string = '\uf2bd';

@Component
export struct IconFont {
  @Prop char: string = '';
  @Prop glyphSize: number = 14;
  @Prop glyphColor: string = GSYColor.miWhite;

  build(): void {
    Text(this.char)
      .fontFamily('FontAwesome')
      .fontSize(this.glyphSize)
      .fontColor(this.glyphColor)
      .textAlign(TextAlign.Center);
  }
}
