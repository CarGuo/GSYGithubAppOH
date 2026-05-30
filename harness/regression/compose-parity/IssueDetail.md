# IssueDetail Compose Parity

## Compose Reference

Source files:

- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/issue/src/main/java/com/shuyu/gsygithubappcompose/feature/issue/IssueScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/issue/src/main/java/com/shuyu/gsygithubappcompose/feature/issue/IssueViewModel.kt`

Structure:

- Top app bar title is `#number title`, with back button.
- Header is a white card with avatar, user, state, number, comment count, time,
  title, and Markdown body.
- Comments are white cards with avatar, user, relative time, and Markdown body.
- Bottom bar is conditional. Compose shows only actions allowed by:
  reply = repo owner or issue creator or not locked; edit = repo owner or
  issue creator while unlocked; open/close = repo owner or issue creator;
  lock/unlock = repo owner.

## OH Changes

- `IssueDetailPage.ets` now uses the Compose app bar title format.
- Issue and comment bodies no longer render generated HTML templates as text.
- Header and comments use white card styling instead of the old RN gray header.
- Bottom actions are filtered using the same permission rules as Compose.
- Issue permission logic is shared through `IssuePermissionUtil`, matching the
  Compose ViewModel rules: repo owner can edit even when they are not the issue
  creator, issue creator can edit while unlocked, and only repo owner can
  lock/unlock.
- The edit action handler now uses the same `canEditIssue()` rule as the
  visible bottom action. This fixes the previous mismatch where the edit button
  could be visible for repo owner but clicking it was still blocked by an
  issue-creator-only check.
- Comment interaction now follows Compose: tapping a manageable comment opens
  an Edit / Delete option dialog, while long press copies the comment text.
  The previous OH behavior only exposed edit/delete through long press.
- Issue and comment bodies now render through `MarkdownText`, matching
  Compose's `GSYMarkdownText` direction for headings, lists, quotes, code
  blocks, links, and common inline Markdown cleanup while keeping the old
  stable ids such as `issue_detail_body_html`.
- `MarkdownText` now also handles GitHub-style pipe tables and indented nested
  ordered/bullet list levels, covering the larger Markdown shapes seen in
  dependency/update issue bodies.
- `MarkdownText` now renders GitHub-style task-list rows with checked/unchecked
  markers, so issue bodies with checklist content no longer degrade to plain
  bullet text.
- `MarkdownUtil.normalize()` now converts common GitHub HTML block wrappers
  (`h1`-`h6`, `blockquote`, `ul`/`ol`/`li`, checkbox inputs, and
  `pre`/`code`) into Markdown-like lines before parsing. This closes the
  previous mixed-HTML degradation for the block shapes most commonly produced
  by GitHub issue bodies while still keeping the renderer ArkUI-native.
- Issue edit, comment edit, and reply now use the same Compose-style Markdown
  input dialog shape: optional title field, 200px body input, markdown action
  row (`H1/H2/H3/B/I/UL/Quote/Code/IMG/Link`), and trailing cancel/confirm
  buttons. The old single-line prompt is no longer used for these flows.
- Issue detail data loading now matches Compose `IssueRepository`: issue
  detail and first-page comments read local DB cache into the store before the
  network request, then network data refreshes the store and writes cache back.

## Automated Checks

- Existing `issueDetail` scenario drives the boot route:
  `aa start --ps bootIssue "fullName|number"`.
- Latest OH evidence:
  `/tmp/gsy-oh-compose-detail-20260529-225822/README.md`
- Latest OH screenshot:
  `/tmp/gsy-oh-compose-detail-20260529-225822/14_issueDetail.png`
- Latest Markdown OH evidence:
  `/tmp/scenario-tour-20260530-005451/README.md`
- Latest Markdown OH screenshot:
  `/tmp/scenario-tour-20260530-005451/14_issueDetail.png`
- Latest Markdown run result: `ok=1 fail=0 skip=25`; duplicate screenshots
  `NO`. Assertions include `issue_detail_body_html`.
- Rich Markdown smoke evidence with `CarGuo/GSYGithubAPP#155`:
  `/tmp/scenario-tour-20260530-005546/README.md`
- Rich Markdown smoke screenshot:
  `/tmp/scenario-tour-20260530-005546/14_issueDetail.png`
- Latest rich Markdown smoke after table/nested-list support:
  `/tmp/scenario-tour-20260530-005810/README.md`
- Latest rich Markdown screenshot:
  `/tmp/scenario-tour-20260530-005810/14_issueDetail.png`
- Latest task-list Markdown smoke after parser/renderer support:
  `/tmp/scenario-tour-20260530-010039/README.md`
- Latest task-list Markdown screenshot:
  `/tmp/scenario-tour-20260530-010039/14_issueDetail.png`
- Latest Issue permission/edit/comment-entry evidence:
  `/tmp/scenario-tour-20260530-035744/README.md`
- Latest Issue edit-entry screenshot:
  `/tmp/scenario-tour-20260530-035744/14_issueDetail-edit.png`
- Latest Issue comment-option screenshot:
  `/tmp/scenario-tour-20260530-035744/14_issueDetail-commentOptions.png`
- Latest Issue result: `ok=1 fail=0 skip=30`, `asserts=14`, duplicate
  screenshots `NO`. Assertions include `common_bottom_bar_item_edit` being
  tapped and the edit dialog ids `issue_edit_dialog_root`,
  `issue_edit_dialog_title_input`, `issue_edit_dialog_body_input`,
  `issue_edit_dialog_ok_btn`, and `issue_edit_dialog_cancel_btn`; it also taps
  `issue_comment_row_0` and verifies `issue_comment_options_dialog`,
  `issue_comment_option_edit`, `issue_comment_option_delete`, and
  `issue_comment_option_cancel`.
- Latest Issue Markdown input dialog evidence:
  `/tmp/scenario-tour-20260530-061628/README.md`
- Latest Issue Markdown input result: `ok=1 fail=0 skip=32`, `asserts=32`,
  duplicate screenshots `NO`. This run covers issue edit, comment options,
  comment edit, and reply dialog, including stable ids for the Markdown toolbar
  and visible action buttons in each dialog.
- Latest mixed HTML Markdown logic evidence:
  `harness/regression/reports/M5/summary.md` passed with `exit=0`,
  `tests run=392`, `passed=392`, `assertion errors=0`, and
  `time=2026-05-30T02:59:06Z`. This includes
  `MarkdownUtil_parseLines_githubHtmlBlocks`, covering heading, quote,
  GitHub checkbox task, plain list item, and pre/code HTML blocks.
- Latest post-build IssueDetail device evidence:
  `/tmp/scenario-tour-20260530-105926/README.md` (`issueDetail`; `ok=1`,
  `fail=0`, `skip=34`, `asserts=32`, duplicate screenshots `NO`) after
  rebuilding and installing the latest HAP.
- Latest logic-only evidence includes `IssuePermissionUtil_matchesComposeRules`
  in `harness/regression/reports/M5/summary.md` with `exit=0` and
  `assertion errors=0`.
- Latest IssueDetail cache-first logic evidence:
  `harness/regression/reports/M5/summary.md` passed with `exit=0`,
  `tests run=401`, `passed=401`, `assertion errors=0`, and
  `time=2026-05-30T04:11:48Z`. This includes
  `IssueServiceTest.getIssue_applies_cache_before_network_refresh` and
  `IssueServiceTest.getComments_first_page_applies_cache_before_network_refresh`.
- Latest installed-HAP IssueDetail evidence after the cache-first change:
  `/tmp/scenario-tour-20260530-121218/README.md` (`issueDetail`; `ok=1`,
  `fail=0`, `skip=34`, `asserts=32`, duplicate screenshots `NO`). This run
  covers the page, edit dialog, comment option dialog, comment edit dialog,
  and reply dialog on the rebuilt package.

## Current Gaps

- The renderer now covers common Markdown blocks, tables, nested lists,
  task-list checkboxes, common GitHub HTML block wrappers, and inline cleanup.
  It is still not a full CommonMark implementation like Compose's Markdown
  library, so rare deeply mixed inline HTML/CSS remains a follow-up item.
- No open permission/action-entry gap remains for the covered repo-owner
  edit flow, manageable-comment option/edit flow, or reply Markdown input flow.
- No open cache-first gap remains for issue detail or first-page comments.
