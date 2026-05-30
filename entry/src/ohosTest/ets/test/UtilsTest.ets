import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { TimeUtil } from '../../../main/ets/utils/TimeUtil';
import { StringUtil } from '../../../main/ets/utils/StringUtil';
import { HtmlUtil } from '../../../main/ets/utils/HtmlUtil';
import { IssuePermissionUtil } from '../../../main/ets/utils/IssuePermissionUtil';
import { EventActionUtil } from '../../../main/ets/utils/EventActionUtil';
import { DynamicActor, DynamicEvent, DynamicRepo } from '../../../main/ets/store/DynamicStore';
import { isImageOrArchiveFile } from '../../../main/ets/pages/repo/FilesTab';
import { changeLocale } from '../../../main/ets/i18n/I18n';
import {
  MarkdownUtil,
  MARKDOWN_LINE_BULLET,
  MARKDOWN_LINE_CODE,
  MARKDOWN_LINE_HEADING,
  MARKDOWN_LINE_QUOTE,
  MARKDOWN_LINE_TABLE,
  MARKDOWN_LINE_TASK
} from '../../../main/ets/utils/MarkdownUtil';

function buildEventForComposeAction(type: string, repoName: string): DynamicEvent {
  const actor: DynamicActor = {
    id: 1,
    login: 'CarGuoUI',
    display_login: 'CarGuoUI',
    avatar_url: '',
  } as DynamicActor;
  const repo: DynamicRepo = {
    id: 2,
    name: repoName,
    url: '',
  } as DynamicRepo;
  return {
    id: type + '-1',
    type: type,
    actor: actor,
    repo: repo,
    created_at: '2024-01-01T00:00:00Z',
    payload: {} as Record<string, Object>,
  } as DynamicEvent;
}

export default function utilsTest(): void {
  describe('UtilsTest', () => {
    beforeAll(() => {
      changeLocale('zh-CN');
    });

    afterAll(() => {
      changeLocale('zh-CN');
    });

    it('TimeUtil_parseISO_returnsTimestamp', 0, () => {
      const ts: number = TimeUtil.parseISO('2024-01-01T00:00:00Z');
      expect(ts > 0).assertTrue();
    });

    it('TimeUtil_parseISO_emptyReturnsZero', 0, () => {
      expect(TimeUtil.parseISO('')).assertEqual(0);
      expect(TimeUtil.parseISO(null)).assertEqual(0);
      expect(TimeUtil.parseISO(undefined)).assertEqual(0);
    });

    it('TimeUtil_resolveTime_recent', 0, () => {
      const recent: number = Date.now() - 30 * 1000;
      expect(TimeUtil.resolveTime(recent)).assertEqual('刚刚');
    });

    it('TimeUtil_resolveTime_minutesAgo', 0, () => {
      const ts: number = Date.now() - 5 * 60 * 1000;
      const text: string = TimeUtil.resolveTime(ts);
      expect(text.indexOf('分钟前') >= 0).assertTrue();
    });

    it('TimeUtil_resolveTime_englishLocale', 0, () => {
      changeLocale('en');
      const ts: number = Date.now() - 3 * 60 * 60 * 1000;
      const text: string = TimeUtil.resolveTime(ts);
      expect(text.indexOf('hours ago') >= 0).assertTrue();
      changeLocale('zh-CN');
    });

    it('TimeUtil_resolveTime_uses_compose_months_and_years', 0, () => {
      changeLocale('en');
      const yearOld: number = Date.now() - 400 * 24 * 60 * 60 * 1000;
      const yearText: string = TimeUtil.resolveTime(yearOld);
      expect(yearText.indexOf('years ago') >= 0).assertTrue();

      const monthOld: number = Date.now() - 60 * 24 * 60 * 60 * 1000;
      const monthText: string = TimeUtil.resolveTime(monthOld);
      expect(monthText.indexOf('months ago') >= 0).assertTrue();
      changeLocale('zh-CN');
    });

    it('TimeUtil_resolveTimeWithLocale', 0, () => {
      const ts: number = Date.now() - 3 * 60 * 60 * 1000;
      const text: string = TimeUtil.resolveTimeWithLocale(ts, 'now', 'mAgo', 'hAgo', 'dAgo');
      expect(text.indexOf('hAgo') >= 0).assertTrue();
    });

    it('StringUtil_trim', 0, () => {
      expect(StringUtil.trim('   hello   ')).assertEqual('hello');
      expect(StringUtil.trim(null)).assertEqual('');
    });

    it('StringUtil_isEmpty_isBlank', 0, () => {
      expect(StringUtil.isEmpty('')).assertTrue();
      expect(StringUtil.isEmpty(null)).assertTrue();
      expect(StringUtil.isBlank('   ')).assertTrue();
      expect(StringUtil.isBlank('a')).assertFalse();
    });

    it('StringUtil_getFullName', 0, () => {
      const name: string = StringUtil.getFullName('https://github.com/CarGuo/GSYGithubApp/');
      expect(name).assertEqual('CarGuo/GSYGithubApp');
    });

    it('StringUtil_formName', 0, () => {
      expect(StringUtil.formName('js')).assertEqual('javascript');
      expect(StringUtil.formName('kt')).assertEqual('kotlin');
      expect(StringUtil.formName('md')).assertEqual('markdown');
      expect(StringUtil.formName('html')).assertEqual('xml');
      expect(StringUtil.formName('cpp')).assertEqual('cpp');
    });

    it('StringUtil_isImageEnd', 0, () => {
      expect(StringUtil.isImageEnd('a/b/icon.png')).assertTrue();
      expect(StringUtil.isImageEnd('a/b/file.txt')).assertFalse();
    });

    it('HtmlUtil_changeServiceResult_blobToRaw', 0, () => {
      const html: string = '<img src="https://github.com/x/y/blob/main/a.png">';
      const out: string = HtmlUtil.changeServiceResult(html);
      expect(out.indexOf('/raw/') >= 0).assertTrue();
      expect(out.indexOf('/blob/') < 0).assertTrue();
    });

    it('HtmlUtil_normalizeAnchorHref_addScheme', 0, () => {
      const html: string = '<a href="/CarGuo">user</a>';
      const out: string = HtmlUtil.normalizeAnchorHref(html);
      expect(out.indexOf('gsygithub://') >= 0).assertTrue();
    });

    it('HtmlUtil_generateCodeHtml_includesDraculaAndHljs', 0, () => {
      const out: string = HtmlUtil.generateCodeHtml('<p>x</p>', false);
      expect(out.indexOf('dracula.min.css') >= 0).assertTrue();
      expect(out.indexOf('highlight.min.js') >= 0).assertTrue();
      expect(out.indexOf('hljs.configure') >= 0).assertTrue();
    });

    it('HtmlUtil_generateHtml_emptyReturnsEmpty', 0, () => {
      expect(HtmlUtil.generateHtml('')).assertEqual('');
      expect(HtmlUtil.generateHtml(null)).assertEqual('');
    });

    it('HtmlUtil_generateImageHtml_containsImg', 0, () => {
      const html: string = HtmlUtil.generateImageHtml('CarGuo', 'blue', 'https://example.com/');
      expect(html.indexOf('<img') >= 0).assertTrue();
      expect(html.indexOf('CarGuo') >= 0).assertTrue();
    });

    it('MarkdownUtil_parseLines_commonBlocks', 0, () => {
      const lines = MarkdownUtil.parseLines('# Title\n> quote\n- **bold** item\n```ts\nconst a = 1\n```');
      expect(lines.length).assertEqual(4);
      expect(lines[0].kind).assertEqual(MARKDOWN_LINE_HEADING);
      expect(lines[0].text).assertEqual('Title');
      expect(lines[1].kind).assertEqual(MARKDOWN_LINE_QUOTE);
      expect(lines[2].kind).assertEqual(MARKDOWN_LINE_BULLET);
      expect(lines[2].text).assertEqual('bold item');
      expect(lines[3].kind).assertEqual(MARKDOWN_LINE_CODE);
      expect(lines[3].text).assertEqual('const a = 1');
    });

    it('MarkdownUtil_stripInline_linksAndHtml', 0, () => {
      const value: string = MarkdownUtil.stripInline('<p>[GitHub](https://github.com) &amp; `code`</p>');
      expect(value).assertEqual('GitHub & code');
    });

    it('MarkdownUtil_parseLines_tablesAndNestedLists', 0, () => {
      const markdown: string = '| Name | Value |\n| --- | --- |\n| A | **B** |\n- parent\n  - child';
      const lines = MarkdownUtil.parseLines(markdown);
      expect(lines.length).assertEqual(4);
      expect(lines[0].kind).assertEqual(MARKDOWN_LINE_TABLE);
      expect(lines[0].level).assertEqual(1);
      expect(lines[0].cells[0]).assertEqual('Name');
      expect(lines[1].kind).assertEqual(MARKDOWN_LINE_TABLE);
      expect(lines[1].cells[1]).assertEqual('B');
      expect(lines[2].kind).assertEqual(MARKDOWN_LINE_BULLET);
      expect(lines[2].level).assertEqual(0);
      expect(lines[3].kind).assertEqual(MARKDOWN_LINE_BULLET);
      expect(lines[3].level).assertEqual(1);
    });

    it('MarkdownUtil_parseLines_taskList', 0, () => {
      const lines = MarkdownUtil.parseLines('- [ ] todo\n  - [x] done');
      expect(lines.length).assertEqual(2);
      expect(lines[0].kind).assertEqual(MARKDOWN_LINE_TASK);
      expect(lines[0].checked).assertFalse();
      expect(lines[0].marker).assertEqual('☐');
      expect(lines[0].text).assertEqual('todo');
      expect(lines[1].kind).assertEqual(MARKDOWN_LINE_TASK);
      expect(lines[1].checked).assertTrue();
      expect(lines[1].level).assertEqual(1);
      expect(lines[1].marker).assertEqual('☑');
      expect(lines[1].text).assertEqual('done');
    });

    it('MarkdownUtil_parseLines_githubHtmlBlocks', 0, () => {
      const html: string =
        '<h2>Title</h2><blockquote><p>quoted &amp; linked</p></blockquote>' +
          '<ul><li><input type="checkbox" checked> done</li><li>plain</li></ul>' +
          '<pre><code>const a = 1</code></pre>';
      const lines = MarkdownUtil.parseLines(html);
      expect(lines.length).assertEqual(5);
      expect(lines[0].kind).assertEqual(MARKDOWN_LINE_HEADING);
      expect(lines[0].level).assertEqual(2);
      expect(lines[0].text).assertEqual('Title');
      expect(lines[1].kind).assertEqual(MARKDOWN_LINE_QUOTE);
      expect(lines[1].text).assertEqual('quoted & linked');
      expect(lines[2].kind).assertEqual(MARKDOWN_LINE_TASK);
      expect(lines[2].checked).assertTrue();
      expect(lines[2].text).assertEqual('done');
      expect(lines[3].kind).assertEqual(MARKDOWN_LINE_BULLET);
      expect(lines[3].text).assertEqual('plain');
      expect(lines[4].kind).assertEqual(MARKDOWN_LINE_CODE);
      expect(lines[4].text).assertEqual('const a = 1');
    });

    it('IssuePermissionUtil_matchesComposeRules', 0, () => {
      expect(IssuePermissionUtil.repoOwner('CarGuo/GSYGithubApp')).assertEqual('CarGuo');
      expect(IssuePermissionUtil.isRepoOwner('CarGuo/GSYGithubApp', 'CarGuo')).assertTrue();
      expect(IssuePermissionUtil.isRepoOwner('CarGuo/GSYGithubApp', 'CarSmallGuo')).assertFalse();

      expect(IssuePermissionUtil.canReply(false, false, false)).assertTrue();
      expect(IssuePermissionUtil.canReply(false, false, true)).assertFalse();
      expect(IssuePermissionUtil.canReply(true, false, true)).assertTrue();

      expect(IssuePermissionUtil.canEdit(true, false, true)).assertTrue();
      expect(IssuePermissionUtil.canEdit(false, true, false)).assertTrue();
      expect(IssuePermissionUtil.canEdit(false, true, true)).assertFalse();
      expect(IssuePermissionUtil.canEdit(false, false, false)).assertFalse();

      expect(IssuePermissionUtil.canOpenClose(true, false)).assertTrue();
      expect(IssuePermissionUtil.canOpenClose(false, true)).assertTrue();
      expect(IssuePermissionUtil.canOpenClose(false, false)).assertFalse();
      expect(IssuePermissionUtil.canLockUnlock(true)).assertTrue();
      expect(IssuePermissionUtil.canLockUnlock(false)).assertFalse();
    });

    it('EventActionUtil_getComposeActionText_matchesComposeEventItem', 0, () => {
      expect(EventActionUtil.getComposeActionText(
        buildEventForComposeAction('PushEvent', 'CarGuoUI/RepoZero')))
        .assertEqual('pushed to CarGuoUI/RepoZero');
      expect(EventActionUtil.getComposeActionText(
        buildEventForComposeAction('WatchEvent', 'CarGuoUI/RepoOne')))
        .assertEqual('started watching CarGuoUI/RepoOne');
      expect(EventActionUtil.getComposeActionText(
        buildEventForComposeAction('IssuesEvent', 'CarGuoUI/RepoTwo')))
        .assertEqual('created issue in CarGuoUI/RepoTwo');
    });

    it('FilesTab_isImageOrArchiveFile_matchesComposeClickRules', 0, () => {
      expect(isImageOrArchiveFile('logo.png')).assertTrue();
      expect(isImageOrArchiveFile('archive.tar.gz')).assertTrue();
      expect(isImageOrArchiveFile('README.md')).assertFalse();
      expect(isImageOrArchiveFile('src/main.ts')).assertFalse();
    });
  });
}
