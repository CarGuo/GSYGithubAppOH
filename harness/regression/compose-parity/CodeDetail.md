# CodeDetail Compose Parity

## Compose Reference

Source file:

- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/code/src/main/java/com/shuyu/gsygithubappcompose/feature/code/FileCodeViewScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/code/src/main/java/com/shuyu/gsygithubappcompose/feature/code/FileCodeViewViewModel.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/network/src/main/java/com/shuyu/gsygithubappcompose/core/network/api/GitHubApiService.kt`

Structure:

- Top app bar title is the file name, with back button.
- Content is displayed in a WebView.
- File content comes from GitHub contents API with
  `Accept: application/vnd.github.html`; README.md therefore receives
  GitHub-rendered HTML, not a local/native Markdown parse.
- Markdown HTML is wrapped in a mobile-friendly document style; code files use
  highlight.js styling.
- Push detail opens files by SHA.

## OH Changes

- `CodeDetailPage.ets` keeps `code_detail_appbar`, `code_detail_title_text`,
  and `code_detail_web` stable ids for scenario checks.
- The app bar title now matches Compose's `path.substringAfterLast('/')`
  behavior: nested paths show only the file name, not the whole path.
- The previously blank content area now renders fetched content through an
  ArkUI `Web` component, matching Compose's WebView-centered structure.
- `CodeService.getRawContent` first reads the local code-content cache, then
  refreshes from GitHub contents API with `Accept: application/vnd.github.html`
  and stores the new body back to the local database.
- For `.md/.markdown` files, OH now matches Compose's strict WebView path:
  only GitHub-rendered HTML or an existing HTML cache is displayed. If the
  GitHub HTML request fails, OH does not fall back to raw Markdown/source text.
- `CodeDetailPage.ets` uses `WebviewController.loadData(..., 'text/html',
  'UTF-8', baseUrl, baseUrl)` like Compose's `loadDataWithBaseURL`. A
  generated `file://` document remains only as a device fallback if controller
  loading throws.
- Loading now matches Compose `GSYGeneralLoadState`: while `content/htmlContent`
  is still empty and the request is pending, `CodeDetailPage` shows the
  explicit `loading...` / `加载中...` indicator instead of the unsupported-file
  error state. The unsupported/failed preview text is only shown after the
  service sets an error.
- A mobile CSS layer is injected so long README and code lines wrap instead of
  shrinking the whole document.
- Link interception remains inside the Web component: repository/user links
  route back into OH pages and other external links open through the system
  browser path.
- CodeDetail now accepts the PushDetail `sha` route parameter. In that path it
  fetches the commit detail and renders the matching file's `patch`, matching
  Compose's `loadFileWithSha` branch instead of treating the commit SHA as a
  branch name.

## Automated Checks

- Existing `codeDetail` scenario drives the boot route:
  `aa start --ps bootCode "fullName|branch|path"`.
- The scenario now asserts the stable ids, the app bar basename title, and a
  non-flat `code_detail_web` screenshot crop so a blank Web node cannot pass.
- Latest focused WebView loading/final-render gate:
  `/tmp/scenario-tour-20260530-145742/README.md` (`repoDetail-readme`,
  `codeDetail`; `SKIP_INSTALL=0`; `ok=2`, `fail=0`, `asserts=17`, `dup=NO`),
  plus
  `harness/regression/reports/M5/summary.md` (`tests run=412`,
  `passed=412`) for the README loading-state service assertion. This run also
  verifies that RepositoryDetail README exposes real WebView text, not just a
  non-flat screenshot crop.
- Latest OH evidence:
  `/tmp/scenario-tour-20260530-030024/README.md`
- Latest OH screenshot:
  `/tmp/scenario-tour-20260530-030024/15_codeDetail.png`
- Latest focused CodeDetail evidence:
  `/tmp/scenario-tour-20260530-023856/README.md`
- Post-Hypium focused CodeDetail evidence after rebuilding/installing the HAP:
  `/tmp/scenario-tour-20260530-032054/README.md`
  (`ok=3 fail=0 skip=23`, `asserts=33`, duplicate screenshots `NO`).
- Latest nested-path title evidence:
  `/tmp/scenario-tour-20260530-054637/README.md`
  (`codeDetail`; `ok=1 fail=0 skip=32`, `asserts=6`, duplicate screenshots
  `NO`). This uses `app/config/index.js` and verifies the title text
  `index.js`, plus rendered content marker `Created%20by%20guoshuyu`.
- Latest README WebView evidence after switching README.md away from native
  Markdown rendering:
  `/tmp/scenario-tour-20260530-104117/README.md`
  (full run; `ok=35 fail=0 skip=0`, `asserts=467`, duplicate screenshots
  `NO`). The installed-HAP focused evidence remains
  `/tmp/scenario-tour-20260530-101303/README.md`, whose
  `/tmp/scenario-tour-20260530-101303/15_codeDetail.png` shows
  GitHub-rendered README HTML and whose layout dump exposes Web accessibility
  nodes such as `article`, `heading`, `link`, and `English Readme` inside
  `code_detail_web`.
- Latest rebuilt-HAP README.md / CodeDetail evidence:
  `/tmp/scenario-tour-20260530-115340/README.md`
  (`repoDetail-readme`, `repoDetail-file`, `codeDetail`, `welcomeAnimation`,
  `loginAnimation`; `ok=5 fail=0 skip=30`, `asserts=55`, duplicate
  screenshots `NO`). The run was executed with `SKIP_INSTALL=0` and verifies
  README.md opens as a non-flat `code_detail_web` Web surface, while
  RepositoryDetail README still has no `readme_tab_native_fallback`.
- Latest focused re-check after the README.md Compose logic audit:
  `/tmp/scenario-tour-20260530-123143/README.md`
  (`repoDetail-readme`, `codeDetail`; `ok=2 fail=0 skip=34`, `asserts=16`,
  duplicate screenshots `NO`). It verifies README.md is rendered in
  `code_detail_web`, the crop is non-flat (`std=96.75`), and the repository
  Readme tab has no native fallback.
- Latest installed-HAP re-check after the user README.md screenshot review:
  `/tmp/scenario-tour-20260530-125642/README.md`
  (`repoDetail-readme`, `codeDetail`; `SKIP_INSTALL=0`; `ok=2 fail=0 skip=35`,
  `asserts=16`, duplicate screenshots `NO`). The CodeDetail screenshot
  `/tmp/scenario-tour-20260530-125642/15_codeDetail.png` shows GitHub-rendered
  README HTML in ArkUI Web (link/title/list styling and Web scrollbar), not raw
  markdown source.
- `CommitServiceTest.CodeService_getRawContent_succeeds_via_github_html_contents_api`
  now asserts the request header is exactly
  `Accept: application/vnd.github.html`; the markdown failure test also
  verifies OH does not issue raw/source fallback requests for README.md after a
  GitHub HTML failure.
- `CommitServiceTest.CodeService_getCommitFile_loads_patch_from_commit_sha_like_compose`
  verifies the PushDetail SHA path requests commit detail and stores the file
  patch in `CodeDetailStore`.
- Latest PushDetail commit-patch evidence:
  `/tmp/scenario-tour-20260530-124046/README.md`
  (`pushDetail`; `ok=1 fail=0 skip=36`, `asserts=14`, duplicate screenshots
  `NO`). The CodeDetail snapshot contains `@@` and does not contain the old
  full README text `English Readme`.

## Current Gaps

- The CodeDetail Web dump can expose inner text for this README case; the
  automated screenshot crop plus Web accessibility tree now prove the Web area
  is GitHub HTML, not native Markdown/source text.
- Syntax highlighting depends on the generated Web document loading its
  highlight.js assets, same as the Compose reference path.
- No open CodeDetail title gap remains for nested paths.
