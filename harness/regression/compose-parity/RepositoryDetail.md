# RepositoryDetail Compose Parity

## Compose Reference

Source files:

- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/detail/src/main/java/com/shuyu/gsygithubappcompose/feature/detail/RepoDetailScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/detail/src/main/java/com/shuyu/gsygithubappcompose/feature/detail/info/RepoDetailInfoScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/detail/src/main/java/com/shuyu/gsygithubappcompose/feature/detail/info/RepositoryDetailInfoHeader.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/ui/src/main/java/com/shuyu/gsygithubappcompose/core/ui/components/IssueItem.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/push/src/main/java/com/shuyu/gsygithubappcompose/feature/push/PushDetailScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/ui/src/main/java/com/shuyu/gsygithubappcompose/core/ui/components/GSYCardItem.kt`

Structure:

- Top app bar title is `owner/repo`, with back button.
- `GSYTopAppBar` lays long titles out start-aligned after the back button,
  instead of center-aligning them between fixed side slots.
- Compose does not expose a repository detail top-right overflow/more menu.
- Tab row order is `Info / Readme / Issue / File`.
- Info tab contains the repository header, an `Events / Commits` segmented
  switch, and a list.
- The Commits segment renders `CommitItem`: 40dp circular author image, bold
  two-line commit message, author/committer login fallback to `Unknown`,
  relative commit time, and click navigation to
  `push_detail/{owner}/{repo}/{sha}`.
- Push detail uses top-bar title `owner/repo`, wraps the header and file rows
  in Compose `GSYCardItem` surfaces, uses 40dp author avatar, a stats row for
  edited/added/deleted counts, 24dp file icon, and opens file rows into
  CodeDetail for the commit SHA.
- Bottom app bar contains Star, Watch, Fork, and branch selector.
- Bottom Fork action directly calls `RepoDetailInfoViewModel.forkRepo`; Compose
  shows the loading dialog around the request and refreshes repository info on
  success. There is no old RN-style confirm dialog and no success toast.
- The branch selector opens an in-page bottom/right menu and selecting a branch
  refreshes README and file content against that ref.
- Create Issue is a floating action button at bottom right.
- Tapping Create Issue opens `GSYMarkdownInputDialog` with title field, body
  field, Markdown action row, and cancel/confirm actions.
- Issue rows use Compose `IssueItem`: bug icon, `#number title` as a bold
  single-line title, body text capped to two lines, and a footer with
  `Opened by user` plus the `yyyy-MM-dd` created date.

Runtime evidence captured from the Android Compose emulator:

- `/tmp/gsy-compose-screens/repo-detail-info-live.png`
- `/tmp/gsy-compose-screens/repo-detail-readme-live.png`
- `/tmp/gsy-compose-screens/repo-detail-readme-refresh.png`
- `/tmp/gsy-compose-screens/repo-detail-issue-live.png`
- `/tmp/gsy-compose-screens/repo-detail-file-live.png`

Matching UI dumps:

- `/tmp/gsy-compose-screens/repo-detail-info-live.xml`
- `/tmp/gsy-compose-screens/repo-detail-readme-live.xml`
- `/tmp/gsy-compose-screens/repo-detail-readme-refresh.xml`
- `/tmp/gsy-compose-screens/repo-detail-issue-live.xml`
- `/tmp/gsy-compose-screens/repo-detail-file-live.xml`

Observed live Compose repo detail (`CarGuo/GSYGithubAPP`) exposes:

- app bar title `CarGuo/GSYGithubAPP`;
- tabs `Info / Readme / Issue / File`;
- bottom actions `Star / Unwatch / Fork / master`;
- right-bottom `Add` FAB;
- Info header stats for stars, forks, watchers, and open issues;
- Issue tab search field, segmented `All / Open / Closed`, and issue cards;
- File tab file/folder rows.
- refreshed Readme tab renders the README logo image and `English Readme`
  body content.
- Readme tab uses Android `WebView.loadDataWithBaseURL` with README HTML from
  `GET /repos/{owner}/{repo}/readme` and `Accept: application/vnd.github.html`;
  this is not native Markdown rendering.
- File Code detail also uses `WebView.loadDataWithBaseURL`. For `.md` files it
  embeds the GitHub HTML response into the same mobile HTML wrapper; for other
  code paths it uses the highlight.js wrapper.
- `FileContentRepository` only reads/writes the local file-list cache for the
  repository root path on the selected default branch. Subdirectories and
  non-default branches skip the DB cache and use network data for that ref.

## OH Changes

- `RepositoryDetailPage.ets` uses Compose tab order and stable ids:
  `repo_detail_tab_bar_info`, `repo_detail_tab_bar_readme`,
  `repo_detail_tab_bar_issue`, `repo_detail_tab_bar_file`.
- The old RN-style repository top-right overflow menu was removed from
  `RepositoryDetailPage`; the page top bar now matches Compose's back + title
  surface.
- `AppBar.ets` now defaults to the same start-aligned title layout as Compose's
  `TopAppBar`, with a 64vp bar, 48vp back hit target, and stable
  title/subtitle line heights so long titles are not prematurely clipped into
  `owner/...` or vertically cropped.
- The existing Activity tab component remains the Info tab body because it
  already owns the repository header plus event/commit content.
- The Info segmented bar now exposes only Compose's `Events / Commits` entries;
  the old RN `Pulse` entry and row renderer are not part of this UI path.
- The Issue tab no longer owns the page-level create button when hosted by
  `RepositoryDetailPage`; the parent page renders `repo_detail_create_issue_fab`.
- Issue tab now matches Compose's `GSYSearchInput` position above
  `All / Open / Closed`; non-empty searches use GitHub `search/issues` with
  `query + repo:owner/name` and optional `state:*`, while empty searches keep
  the normal repository issues API/cache path.
- Issue tab now avoids taking initial focus when opened, matching Compose's
  non-keyboard initial state. The invisible `repo_issue_initial_focus_sink`
  keeps the search input usable while preventing the soft keyboard from
  covering the page-level bottom bar/FAB on first tab entry.
- Issue rows now match Compose `IssueItem` and no longer use the old RN avatar
  row or `fullName - title` body string. Stable ids cover the icon, title,
  body, opened-by footer, and created date.
- Bottom bar remains page-level and keeps Star, Watch, Fork, Branch behavior.
- Branch selection now uses a page-level Compose-style menu instead of the
  system `ActionSheet`, with stable ids for the overlay, scrim, root, and rows.
  Selecting a branch updates the bottom bar label and refreshes README plus File
  tab data using the selected ref.
- The page-level create issue FAB now opens the shared Compose-style Markdown
  input dialog used by feedback and issue edit surfaces. Existing dialog ids
  are preserved, with added `create_issue_markdown_toolbar*` ids for automated
  parity checks.
- Header stat clicks now match Compose list navigation:
  - stars -> `CommonList` data type `stargazers`
  - forks -> `CommonList` data type `forks`
  - watchers -> `CommonList` data type `watchers`
  Bottom bar Star / Watch / Fork still performs the repository actions.
- Header topic chips now match Compose list navigation:
  - topic -> `CommonList` data type `topics`
  - topic result repository rows navigate back to `RepositoryDetail`.
- Info tab commit rows now use a dedicated Compose-style card instead of the
  old shared event row: `repo_commit_row_N`, avatar, message, author, and time
  ids are stable, and row tap opens `PushDetail`.
- Info tab activity/events now match Compose `EventRepository.getRepositoryEvents`:
  page 1 reads the repository event DB cache into `activity` before the network
  request, then network data refreshes the store and writes the cache back.
- File tab breadcrumb now matches Compose `PathNavigator`: root is `.`,
  separators render as `>`, and the old `..` back item is not part of the UI.
- File tab row taps now match Compose `FileItem`: directories still enter the
  next path, code/text files open `CodeDetail`, and image/archive files do not
  navigate.
- Readme tab now matches Compose's WebView path: README HTML is loaded through
  ArkUI `Web` with UTF-8 and a GitHub raw `baseUrl`. The old native
  Markdown/Text fallback overlay is removed from the visible tree.
- README cache behavior now matches Compose `ReadmeRepository`: default branch
  loads database cache first, then refreshes from network and writes back;
  non-default branches skip the default-branch cache to avoid stale content.
- README loading behavior now matches Compose `GSYGeneralLoadState`: when
  neither cache nor network content is available yet, `ReadmeTab` shows an
  explicit loading state; error/empty copy appears only after the request ends
  without cached content. Cached README remains visible while the network
  refresh happens.
- Commits cache behavior now matches Compose `RepositoryRepository`: the
  default branch first page reads the local commits table before network, passes
  the active branch through GitHub's `sha` query, and writes refreshed results
  back to DB.
- File-list cache behavior now matches Compose `FileContentRepository`: only
  the root path of the active default branch reads from DB before network and
  writes refreshed data back. Subdirectory and non-default-branch file lists no
  longer read/write the default cache, preventing stale rows after path/branch
  changes.
- Issue-list cache behavior now matches Compose `IssueRepository`: the default
  Issue tab path (`query` empty, `state == all`, page 1) reads the local issue
  cache into both `issues` and `issueList` before the HTTP request starts, then
  replaces it with network rows and writes refreshed data back.
- Push/Commit detail now matches Compose `PushRepository`: it reads cached
  commit detail before network, writes refreshed commit detail back, and falls
  back to cache if the network request fails.
- Cache-first coverage reviewed against Compose source:
  Repository detail, README default branch, repository activity/time line,
  default-branch first-page commits, default-root file list, default Issue
  list, issue detail/comments, user detail, user events, organization members,
  dynamic events, trending, code cache fallback, and push commit detail are
  cache-first or cache-before-network where Compose does so. Compose does not
  emit DB cache first for followers/following, repo stargazers/watchers/forks,
  user repos, user-star repos, branches, or search result lists; OH may retain
  failure fallback caches there, but those are not counted as Compose
  cache-first parity.
- PushDetail UI now matches Compose's card surface: header and file rows use
  16vp horizontal / 8vp vertical outer spacing, 8vp radius, the Compose outline
  color `#E1E4E8`, the `#FAFBFC` primary-container header background, a 40vp
  author avatar, 24vp file icon, and the `owner/repo` app-bar title.
- Code detail README/open-file behavior now follows the same Compose route:
  OH requests GitHub HTML first with `Accept: application/vnd.github.html`,
  loads it through ArkUI `Web.loadData`, and for `.md/.markdown` files will
  only display GitHub HTML or cached HTML. Non-Markdown code files may still use
  raw/API decoded content as a code-rendering fallback.
- Bottom Fork action now calls `doFork()` directly. The old
  `CommonModal.confirm(reposFork/reposForkedTip)` and `forkSuccess` toast path
  were removed; success refreshes repository info, failure shows the generic
  network error toast, matching Compose's direct action flow.

## Automated Checks

- `scripts/scenario-tour.sh` now drives `repoDetail-info`,
  `repoDetail-readme`, `repoDetail-issue`, and `repoDetail-file`.
- `repoDetail-info` now taps `repo_detail_create_issue_fab`, snapshots the
  create issue modal, and asserts the Compose-style Markdown dialog controls
  and first visible Markdown actions.
- `repoDetail-info` now also asserts `appbar_action_r_more` is absent, covering
  Compose top-bar parity and catching the old RN overflow menu if it returns.
- `repoDetail-readme` now waits for real WebView accessibility text such as
  `English Readme` / `Github客户端App` / `HarmonyOS` before snapshotting, and
  fails if the Web area has no README text. This closes the old false-positive
  path where `readme_tab_web` existed but still pointed at `about:blank`.
- The script still accepts the old `repoDetail-activity`,
  `repoDetail-issues`, and `repoDetail-files` names for older command lines.
- `repoDetail-stargazers-list` verifies that tapping the header star stat
  reaches `common_list_stargazers_root`.
- `repoDetail-forks-list` verifies that tapping the header fork stat reaches
  `common_list_forks_root`.
- `repoDetail-watchers-list` verifies that tapping the header watcher stat
  reaches `common_list_watchers_root`.
- `repoDetail-topic-list` verifies that tapping the first header topic chip
  reaches `common_list_topics_root`, renders repository rows, and opens a topic
  result repository detail.
- `repoDetail-commit-route` verifies that Info -> Commits renders a Compose
  commit card, verifies the old `Pulse` item is absent, confirms tapping the
  card reaches `push_detail_root`, and asserts the PushDetail stats row, first
  file card, non-flat commit-card crop, and full app-bar title bounds.
- `RepositoryServiceTest.getRepositoryEvents_first_page_applies_cache_before_network_refresh`
  verifies the actual RepositoryDetailPage activity service path, asserting the
  cached row is already in `store.activity` when the HTTP request starts and
  that network rows replace it afterward.
- `RepositoryServiceTest.getIssues_all_first_page_applies_cache_before_network_refresh`
  verifies the Compose default Issue tab cache path: cache is visible in
  `store.issues` before the HTTP request starts, then network rows replace it.
- Latest rebuilt-HAP README WebView evidence:
  `/tmp/scenario-tour-20260530-145742/README.md` (`repoDetail-readme`,
  `codeDetail`; `SKIP_INSTALL=0`; `ok=2`, `fail=0`, `asserts=17`,
  duplicate screenshots `NO`). The screenshot
  `/tmp/scenario-tour-20260530-145742/07_repoDetail-readme.png` shows the
  README logo image and `English Readme` content inside `readme_tab_web`, and
  the layout dump shows
  `file://<device-cache>/readme/CarGuo_GSYGithubApp_readme.html`
  plus inner Web text nodes instead of a plain `about:blank` Web node.
- `repoDetail-issue` asserts the Compose issue search row/input/button ids in
  addition to the segmented state bar, issue list, page-level bottom bar, and
  create issue FAB, catching keyboard-over-bottom-bar regressions.
- `RepoTabsUiTest` verifies the mocked Compose issue row shape:
  `#101 [all] tab issue 1`, body text, opened-by text, and `2024-01-01` date.
- `repoDetail-file` verifies the Compose breadcrumb root/separator ids and
  confirms the old `repo_file_breadcrumb_back` control is absent.
- `RepoTabsServiceTest` now locks Compose file-list cache behavior: default
  branch root writes cache and can fall back to cache on network failure,
  subdirectories do not write cache, and non-default branches do not read the
  default branch cache.
- `repoDetail-readme` now asserts the Web root, proves
  `readme_tab_native_fallback` is absent, and checks a non-flat `readme_tab_web`
  crop so a blank content area cannot pass by id-only assertions.
- `repoDetail-branch-selector` verifies the bottom branch item, in-page branch
  menu ids, selected branch text, menu dismissal, and updated bottom-bar branch
  label.
- `RepositoryDetailUiTest.should_fork_directly_without_old_confirm_dialog`
  covers the direct Fork POST path against the mocked host provider. The
  `run-tests.sh --full-ui-host` command compiles and runs, but the UI-host
  runner has a broader isolation problem where many unrelated host pages read
  empty text or clicks do not update state, so this result is tracked as a
  diagnostic runner gap rather than a RepositoryDetail parity gate.

Evidence:
- `/tmp/scenario-tour-20260529-232502/README.md`
- Fork/watch run result: `ok=2 fail=0 skip=19`, duplicate screenshots `NO`.
- Screenshots:
  - `/tmp/scenario-tour-20260529-232502/20_repoDetail-forks.png`
  - `/tmp/scenario-tour-20260529-232502/21_repoDetail-watchers.png`
- Prior combined evidence remains `/tmp/scenario-tour-20260529-232223/README.md`
  with result `ok=3 fail=0 skip=16`.
- Latest List title evidence also covers repository header stat navigation:
  `/tmp/scenario-tour-20260530-004608/README.md`
  with result `ok=4 fail=0 skip=22`, duplicate screenshots `NO`.
- Readme content evidence:
  `/tmp/scenario-tour-20260530-012148/README.md`
  with result `ok=2 fail=0 skip=24`, duplicate screenshots `NO`.
  The Readme screenshot is
  `/tmp/scenario-tour-20260530-012148/07_repoDetail-readme.png`.
- Latest Readme WebView-only evidence:
  `/tmp/scenario-tour-20260530-085237/README.md`
  with `repoDetail-readme` passing (`ok=1 fail=0 skip=34`, `asserts=11`,
  duplicate screenshots `NO`). This run asserts
  `absent_id=readme_tab_native_fallback` and a non-flat Web crop
  (`std=21.89`).
- Build gate after removing the README native fallback:
  `hvigorw assembleHap --mode module -p product=default --no-daemon`
  passed.
- Build gate after direct-Fork alignment:
  `hvigorw assembleHap --mode module -p product=default --no-daemon`
  passed on 2026-05-30 after updating `RepositoryDetailPage.ets`,
  `RepositoryService.ets`, and the RepositoryDetail UI test host.
- Logic gate after updating cache-first tests and direct-Fork host typing:
  `harness/regression/reports/M5/summary.md` passed with `exit=0`,
  `tests run=391`, `passed=391`, `assertion errors=0`, and
  `time=2026-05-30T02:56:34Z`.
- Latest file-list cache parity logic gate:
  `harness/regression/reports/M5/summary.md` passed with `exit=0`,
  `tests run=395`, `passed=395`, `assertion errors=0`, and
  `time=2026-05-30T03:10:27Z`. This includes
  `RepoTabsServiceTest.getFiles_default_root_falls_back_to_cache_when_network_fails`
  and
  `RepoTabsServiceTest.getFiles_non_default_root_does_not_read_or_write_default_branch_cache`.
- Build gate after file-list cache parity:
  `hvigorw assembleHap --mode module -p product=default --no-daemon` passed.
- Latest full tour including RepositoryDetail tabs:
  `/tmp/scenario-tour-20260530-030024/README.md`
  with result `ok=26 fail=0 skip=0`, `asserts=260`, duplicate screenshots
  `NO`.
- Post-Hypium focused Readme regression after rebuilding/installing the HAP:
  `/tmp/scenario-tour-20260530-032054/README.md`
  with `repoDetail-info`, `repoDetail-readme`, and `codeDetail` all passing
  (`ok=3 fail=0 skip=23`, `asserts=33`, duplicate screenshots `NO`).
- Latest topic-chip focused evidence:
  `/tmp/scenario-tour-20260530-050121/README.md`
  with `repoDetail-topic-list` passing (`ok=1 fail=0 skip=31`,
  `asserts=14`, duplicate screenshots `NO`).
- Latest commit-card / PushDetail layout evidence:
  `/tmp/scenario-tour-20260530-134925/README.md`
  with `repoDetail-commit-route` and `pushDetail` passing
  (`ok=2 fail=0 skip=38`, `asserts=31`, duplicate screenshots `NO`). This
  covers Info -> Commits -> PushDetail, PushDetail stats/file-card presence,
  non-flat card crops, and PushDetail -> CodeDetail.
- Latest File Tab focused evidence:
  `/tmp/scenario-tour-20260530-053259/README.md`
  with `repoDetail-file` passing (`ok=1 fail=0 skip=32`, `asserts=13`,
  duplicate screenshots `NO`). This covers Compose breadcrumb parity and the
  absence of the legacy `..` back item.
- Latest Issue Tab focused evidence after matching Compose `IssueItem`:
  `/tmp/scenario-tour-20260530-055638/README.md`
  with `repoDetail-issue` passing (`ok=1 fail=0 skip=32`, `asserts=13`,
  duplicate screenshots `NO`). The layout dump contains
  `repo_issue_row_icon_0`, `repo_issue_row_title_0`,
  `repo_issue_row_body_0`, `repo_issue_row_opened_by_0`, and
  `repo_issue_row_date_0`.
- Latest Issue Tab initial-focus regression evidence:
  `/tmp/scenario-tour-20260530-070044/README.md`
  with `repoDetail-readme`, `repoDetail-issue`, and `repoDetail-file` passing
  (`ok=3 fail=0 skip=31`, `asserts=40`, duplicate screenshots `NO`). This
  verifies the Issue tab no longer auto-opens the soft keyboard after tab
  switching, and `repo_detail_bottom_bar` plus `repo_detail_create_issue_fab`
  remain visible.
- Latest Branch selector focused evidence:
  `/tmp/scenario-tour-20260530-071749/README.md`
  with `repoDetail-branch-selector` passing (`ok=1 fail=0 skip=34`,
  `asserts=11`, duplicate screenshots `NO`). This verifies the in-page branch
  menu, selection of `add-license-1`, menu dismissal, and bottom bar label
  update. Screenshots:
  - `/tmp/scenario-tour-20260530-071749/35_repoDetail-branch-menu.png`
  - `/tmp/scenario-tour-20260530-071749/35_repoDetail-branch-selected.png`
- Latest top-bar overflow cleanup focused evidence:
  `/tmp/scenario-tour-20260530-073303/README.md`
  with `repoDetail-info` passing (`ok=1 fail=0 skip=34`, `asserts=27`,
  duplicate screenshots `NO`). The layout dump asserts
  `absent_id=appbar_action_r_more` while the Info tab, bottom bar, FAB, and
  create issue dialog still pass.
- Latest title/commit focused evidence:
  `/tmp/scenario-tour-20260530-083752/README.md`
  with `repoDetail-commit-route`, `repoDetail-file`, `codeDetail`,
  `personal-info`, `welcomeAnimation`, and `loginAnimation` passing
  (`ok=6 fail=0 skip=29`, `asserts=59`, duplicate screenshots `NO`). This
  run covers the commit card route to PushDetail plus the left-start title
  layout on RepositoryDetail, PushDetail, CodeDetail, and PersonInfo.
- Latest AppBar crop + commit route focused evidence:
  `/tmp/scenario-tour-20260530-114213/README.md` with `repoDetail-info` and
  `repoDetail-commit-route` passing (`ok=2 fail=0 skip=33`, `asserts=40`,
  duplicate screenshots `NO`). The scenario now asserts
  `bounds_inside=appbar_title->appbar_main_row` for both RepositoryDetail and
  the PushDetail reached from a commit card:
  `child=[168,200][869,298] parent=[0,137][1320,361] margin=4`.
- Latest PushDetail card bounds after Compose card alignment:
  `/tmp/scenario-tour-20260530-134925/README.md` confirms the installed HAP
  renders `appbar_title=CarGuo/GSYGithubApp`, `push_detail_commit_card` at
  `[56,389][1264,754]`, and `push_detail_file_card_0` at
  `[56,810][1264,970]`, so file cards no longer stick to the screen edge or
  collapse to text width.
- Latest create issue Markdown dialog focused evidence:
  `/tmp/scenario-tour-20260530-062507/README.md` (`repoDetail-info`;
  `ok=1` within the focused run, `asserts=50`, duplicate screenshots `NO`).
  This covers the Info tab, bottom bar, FAB, and the Compose-style Markdown
  input dialog opened from the FAB.
- Latest full scenario evidence:
  `/tmp/scenario-tour-20260530-104117/README.md`
  with result `ok=35 fail=0 skip=0`, `asserts=467`, screenshots `62`, and
  duplicate screenshots `NO`. This run covers Info/Create Issue, branch
  selection, commit-card to PushDetail, README WebView, Issue/File tabs,
  PushDetail-to-CodeDetail, star/fork/watch list routes, topic list routing,
  and the CodeDetail README WebView path.
- Latest focused Forks-list retry evidence:
  `/tmp/scenario-tour-20260530-104021/README.md` (`repoDetail-forks-list`,
  `repoDetail-watchers-list`; `ok=2 fail=0 skip=33`, `asserts=21`, duplicate
  screenshots `NO`). This confirms the visible header Fork/Watch stats open
  the matching `CommonList` roots after the stat hit point was moved to the
  upper half of the row to avoid topic-chip overlap.
- Latest installed-HAP README/CodeDetail verification:
  `/tmp/scenario-tour-20260530-101303/README.md` (`repoDetail-readme`,
  `codeDetail`; `ok=2 fail=0 skip=33`, `asserts=16`, duplicate screenshots
  `NO`). This run verifies the rebuilt OH package on device: RepositoryDetail
  README still has no `readme_tab_native_fallback`, and CodeDetail README.md
  renders GitHub HTML (`article`/`heading`/`link` Web nodes) instead of raw
  Markdown text.
- Latest focused Stargazers hit-area verification:
  `/tmp/scenario-tour-20260530-102858/README.md` (`repoDetail-stargazers-list`;
  `ok=1 fail=0 skip=34`, `asserts=10`, duplicate screenshots `NO`). This
  covers the same upper-half header stat tap used by Fork/Watch and verifies
  `common_list_stargazers_root`.
- Latest file-list cache device verification:
  `/tmp/scenario-tour-20260530-111111/README.md`
  (`repoDetail-branch-selector`, `repoDetail-file`, `codeDetail`; `ok=3`,
  `fail=0`, `asserts=29`, duplicate screenshots `NO`). This verifies the File
  tab and CodeDetail route still work after restricting DB cache usage to the
  Compose default-branch root-path rule.
- Latest rebuilt-HAP Readme/File/CodeDetail verification:
  `/tmp/scenario-tour-20260530-115340/README.md`
  (`repoDetail-readme`, `repoDetail-file`, `codeDetail`, `welcomeAnimation`,
  `loginAnimation`; `ok=5`, `fail=0`, `asserts=55`, duplicate screenshots
  `NO`). This run verifies the installed package uses GitHub HTML + Web for
  README and file CodeDetail, not native Markdown/source rendering.
- Latest installed-HAP README.md re-check after the user screenshot review:
  `/tmp/scenario-tour-20260530-125642/README.md`
  (`repoDetail-readme`, `codeDetail`; `SKIP_INSTALL=0`; `ok=2`, `fail=0`,
  `asserts=16`, duplicate screenshots `NO`). The CodeDetail screenshot
  `/tmp/scenario-tour-20260530-125642/15_codeDetail.png` shows rendered
  GitHub HTML, while the RepositoryDetail README assertion still verifies
  `readme_tab_native_fallback` is absent.
- Latest RepositoryDetail activity cache-first verification:
  `harness/regression/reports/M5/summary.md` passed with `exit=0`,
  `tests run=399`, `passed=399`, `assertion errors=0`, and
  `time=2026-05-30T04:07:01Z`; this includes the cache-before-request
  assertion for `getRepositoryEvents`. Focused installed-HAP UI evidence:
  `/tmp/scenario-tour-20260530-120725/README.md`
  (`repoDetail-info`, `repoDetail-commit-route`; `ok=2`, `fail=0`,
  `asserts=40`, duplicate screenshots `NO`).

## Current Gaps

- README rendering has no open RepositoryDetail gap in this pass: Compose and
  OH both use WebView/ArkUI Web with GitHub HTML, not native Markdown, and the
  OH screenshot path asserts the old native fallback is absent.
- README.md opened from the File tab now has the same CodeDetail restriction:
  markdown files do not fall back to raw source text after GitHub HTML fails.
- File-list local DB behavior is now covered for Compose's root/default-branch
  cache-only rule.
- Repository activity local DB behavior is now covered for Compose's
  cache-first page-1 rule.
- `run-tests.sh --full-ui-host` now compiles, but UI runtime still reports many
  unrelated empty-text/click-state failures across
  Dynamic/Login/Trend/My/Repository/User/etc. That lane is diagnostic only; the
  current automated UI parity gate is the green `scenario-tour.sh` full run.
