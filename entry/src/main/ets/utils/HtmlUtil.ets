import { GSYColor } from '../style/Theme';

const DEFAULT_BACKGROUND: string = GSYColor.white;
const DEFAULT_ACTION_COLOR: string = GSYColor.actionEmphasis;
const DEFAULT_ROW_LIGHT: string = GSYColor.surfaceGray;
const DEFAULT_ROW_PRIMARY: string = GSYColor.primary;
const DEFAULT_DRACULA_BG: string = GSYColor.webDraculaBackground;

const HIGHLIGHT_CSS: string = 'https://cdn.bootcss.com/highlight.js/9.12.0/styles/dracula.min.css';
const HIGHLIGHT_JS: string = 'https://cdn.bootcss.com/highlight.js/9.12.0/highlight.min.js';

export class HtmlUtil {
  static changeServiceResult(data: string | null | undefined): string {
    if (data === null || data === undefined) {
      return '';
    }
    const text: string = data as string;
    return text.replace(/src=*[^>]*>/gi, (match: string): string => {
      return match.replace(/\/blob\//gm, '/raw/');
    });
  }

  static fixGithubBlobUrl(url: string): string {
    if (url.indexOf('https://github.com/') === 0) {
      return url.replace(/\/blob\//gm, '/raw/');
    }
    return url;
  }

  static normalizeAnchorHref(html: string): string {
    if (!html) {
      return '';
    }
    return html.replace(/href="(.*?)"/gi, (match: string, capture: string): string => {
      if (!capture) {
        return match;
      }
      if (capture.indexOf('http://') < 0 && capture.indexOf('https://') < 0 && capture.indexOf('#') !== 0) {
        return 'href="gsygithub://' + capture + '"';
      }
      return match;
    });
  }

  static breakCodeNewLine(html: string): string {
    if (!html) {
      return '';
    }
    let out: string = '';
    for (let i = 0; i < html.length; i++) {
      const ch: string = html.charAt(i);
      out += ch === '\n' ? '\n\r<br>' : ch;
    }
    return out;
  }

  static buildHtmlTemplate(content: string, wrap: boolean,
    backgroundColor: string, actionColor: string, useBR: boolean): string {
    return '<html>\n'
      + '<head>\n'
      + '<meta charset="utf-8" />\n'
      + '<title></title>\n'
      + '<meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;"/>'
      + '<link href="' + HIGHLIGHT_CSS + '" rel="stylesheet">\n'
      + '<script src="' + HIGHLIGHT_JS + '"></script> '
      + '<script>hljs.configure({\'useBR\': ' + useBR + '});hljs.initHighlightingOnLoad();</script> '
      + '<style>'
      + 'body{background: ' + backgroundColor + ';}'
      + 'a {color:' + actionColor + ' !important;}'
      + '.highlight pre, pre {'
      + ' word-wrap: ' + (wrap ? 'break-word' : 'normal') + '; '
      + ' white-space: ' + (wrap ? 'pre-wrap' : 'pre') + '; '
      + '}'
      + 'thead, tr {'
      + 'background:' + DEFAULT_ROW_LIGHT + ';}'
      + 'td, th {'
      + 'padding: 5px 10px;'
      + 'font-size: 12px;'
      + 'direction:hor'
      + '}'
      + '.highlight {overflow: scroll; background: ' + DEFAULT_DRACULA_BG + '}'
      + 'tr:nth-child(even) {'
      + 'background:' + DEFAULT_ROW_PRIMARY + ';'
      + 'color:' + DEFAULT_ROW_LIGHT + ';'
      + '}'
      + 'tr:nth-child(odd) {'
      + 'background: ' + DEFAULT_ROW_LIGHT + ';'
      + 'color:' + DEFAULT_ROW_PRIMARY + ';'
      + '}'
      + 'th {'
      + 'font-size: 14px;'
      + 'color:' + DEFAULT_ROW_LIGHT + ';'
      + 'background:' + DEFAULT_ROW_PRIMARY + ';'
      + '}'
      + '</style>'
      + '</head>\n'
      + '<body>\n'
      + content
      + '</body>\n'
      + '</html>';
  }

  static generateCodeHtml(mdHtml: string, wrap: boolean,
    backgroundColor?: string, actionColor?: string, useBR?: boolean): string {
    const bg: string = backgroundColor !== undefined ? backgroundColor : DEFAULT_BACKGROUND;
    const action: string = actionColor !== undefined ? actionColor : DEFAULT_ACTION_COLOR;
    const br: boolean = useBR !== undefined ? useBR : true;
    return HtmlUtil.buildHtmlTemplate(mdHtml, wrap, bg, action, br);
  }

  static generateCode2Html(mdData: string | null | undefined,
    backgroundColor?: string, lang?: string, useBR?: boolean): string {
    if (mdData === null || mdData === undefined) {
      return '';
    }
    const language: string = lang !== undefined ? lang : 'java';
    const data: string = mdData as string;
    const wrapped: string = (data && data.indexOf('<code>') === -1)
      ? '<body>\n<pre class="pre">\n<code lang=\'' + language + '\'>\n' + data + '</code>\n</pre>\n</body>\n'
      : '<body>\n<pre class="pre">\n' + data + '</pre>\n</body>\n';
    return HtmlUtil.generateHtml(wrapped, backgroundColor, useBR);
  }

  static generateHtml(mdData: string | null | undefined,
    backgroundColor?: string, useBR?: boolean): string {
    if (mdData === null || mdData === undefined || (mdData as string).length === 0) {
      return '';
    }
    const broken: string = HtmlUtil.breakCodeNewLine(mdData as string);
    const linked: string = HtmlUtil.normalizeAnchorHref(broken);
    return HtmlUtil.generateCodeHtml(linked, false, backgroundColor, DEFAULT_ACTION_COLOR, useBR);
  }

  static generateImageHtml(user: string, color: string, graphicHost: string): string {
    return '<html>\n'
      + '<head>\n'
      + '<meta charset="utf-8" />\n'
      + '<title></title>\n'
      + '<meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;"/>'
      + '<style>body{background: #FFFFFF;}</style>' // TODO: HTML 内联颜色 #FFFFFF 暂保留字面量
      + '</head>\n'
      + '<body>\n'
      + '<img src="' + graphicHost + color + '/' + user + '" alt="' + user + '\'s Github Chart" />\n'
      + '</body>\n'
      + '</html>';
  }

  static generateMd2Html(mdData: string | null | undefined): string {
    if (mdData === null || mdData === undefined || (mdData as string).length === 0) {
      return '';
    }
    const dataPre: string = HtmlUtil.changeServiceResult(mdData);
    return HtmlUtil.generateCodeHtml(dataPre, false, DEFAULT_BACKGROUND, DEFAULT_ACTION_COLOR, true);
  }
}
