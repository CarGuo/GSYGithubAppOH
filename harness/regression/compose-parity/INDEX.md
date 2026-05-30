# Compose Parity Index

This directory tracks the new reference source for GSYGithubAppOH: the Android
Compose app at `https://github.com/CarGuo/GSYGithubAppCompose`.

| Area | Compose source | OH source | Status |
|---|---|---|---|
| Welcome / Login | `feature/welcome`, `feature/login` | `WelcomePage.ets`, `LoginPage.ets`, `LoginWebPage.ets` | First pass aligned |
| Home | `feature/home`, `feature/dynamic`, `feature/trending`, `feature/profile` | `HomePage.ets`, `tabs/*`, `DrawerMenu.ets` | First pass aligned |
| Search | `feature/search` | `SearchPage.ets` | First pass aligned |
| Repository detail | `feature/detail` | `RepositoryDetailPage.ets`, `pages/repo/*` | First pass aligned |
| User / Person | `feature/profile` | `UserDetailPage.ets`, `PersonInfoPage.ets` | First pass aligned |
| List | `feature/list` | `CommonListPage.ets`, follower/star/fork pages | First pass aligned |
| Notification | `feature/notification` | `NotifyPage.ets` | First pass aligned |
| Info | `feature/info` | `PersonInfoPage.ets`, drawer `personal_info` | First pass aligned |
| History | `feature/history` | `ReadHistoryPage.ets` | First pass aligned |
| Issue detail | `feature/issue` | `IssueDetailPage.ets` | First pass aligned |
| Push detail | `feature/push` | `PushDetailPage.ets` | First pass aligned |
| Code detail | `feature/code` | `CodeDetailPage.ets` | First pass aligned |
| Web / Image | `OAuthWebView.kt`, URL callers | `WebPage.ets`, `PhotoPage.ets` | First pass verified |

## Rules

- Compose wins when Compose and RN disagree.
- Tokens, secrets, and client secrets must not be copied into reports.
- Evidence comes from code, layout dumps, screenshots, logs, and automated
  scripts. No manual acceptance step is required.
- Latest full OH scenario run:
  `/tmp/scenario-tour-20260530-104117/README.md` (`ok=35`, `fail=0`,
  `skip=0`, `asserts=467`, `screenshots=62`, `dup=NO`). This run uses the
  latest README/CodeDetail WebView, cache-first commit/detail, Harmony
  welcome/login, personal-info, and stable Stars/Forks/Watchers header-stat
  list assertions.
- Latest Hypium logic-only run:
  `harness/regression/reports/M5/summary.md` (`exit=0`,
  `tests run=410`, `passed=410`, `assertion errors=0`,
  `time=2026-05-30T05:48:19Z`). `run-tests.sh` now defaults to this logic
  gate, falls back to the DevEco bundled `hvigorw`, captures stderr, reads
  Hypium `test_result.txt`, and fails when Hypium reports `ERROR: Error in ...`.
- Latest full Hypium compile/runtime check:
  `/tmp/gsy-full-hypium-20260530-105356.log` and
  `entry/.test/default/intermediates/test/coverage_data/test_result.txt`.
  `hvigorw test --mode module -p product=default --no-daemon` compiles and
  exits `0`, but Hypium reports `Tests run: 523, Failure: 56, Error: 0,
  Pass: 467, Ignore: 0`. Failures are cross-suite UI-host assertions where
  root ids exist but text reads empty or clicks do not update state. Treat
  `run-tests.sh --full-ui-host` as a diagnostic lane only; UI parity is gated by
  `scenario-tour.sh` screenshots, layout dumps, and hilog.
- Latest global refresh-indicator fix:
  Compose `GSYPullRefresh` / `PullToRefreshBox` shows only a circular
  indicator. `PullLoadMoreList.ets` now keeps ArkUI `Refresh` as the gesture
  trigger but makes its native `refreshingContent` transparent and zero-height;
  the only visible active refresh UI is the small primary
  `pull_refresh_indicator` overlay, with no grey/white banner, black diagonal
  artifacts, or `refreshing...` text. `assembleHap`, `git diff --check`, and
  the latest logic-only gate passed after this change. Installed-HAP evidence:
  `/tmp/scenario-tour-20260530-142230/README.md` (`home-dynamic`,
  `personal-info`, `repoDetail-info`; `ok=3`, `fail=0`, `asserts=63`,
  `dup=NO`). Direct pull screenshots:
  `/tmp/pull-refresh-check-20260530-142423/after.png` for RepositoryDetail and
  `/tmp/pull-refresh-user-check-20260530-142735/after.png` for UserDetail;
  both dumps show `pull_refresh_overlay` background `#00000000`.
- Latest global load-more footer fix:
  `PullLoadMoreList.ets` now separates `hasMore` from active `isLoadMore`, so
  the idle footer shows text only and the spinner appears only during an active
  end-reached load. Logic gate: `harness/regression/reports/M5/summary.md`
  (`tests run=409`, `passed=409`). Installed-HAP UI evidence:
  `/tmp/scenario-tour-20260530-130645/README.md` (`home-dynamic`,
  `home-trend`; `ok=2`, `fail=0`, `asserts=16`, `dup=NO`).
- Latest card-contrast fix:
  `RepositoryItem.ets` and `TrendTabPage.ets` now use the Compose
  `GSYCardItem` outline border (`#E1E4E8`) with the softer shared card shadow,
  so white cards stay distinguishable from the page background.
- Latest PushDetail commit/file card alignment:
  `PushDetailPage.ets` now uses Compose `GSYCardItem` spacing and outline for
  the commit header and file rows, the Compose `#FAFBFC` header background,
  40vp author avatar, 24vp file icon, and the `owner/repo` app-bar title.
  Installed-HAP evidence:
  `/tmp/scenario-tour-20260530-134925/README.md` (`repoDetail-commit-route`,
  `pushDetail`; `ok=2`, `fail=0`, `asserts=31`, `dup=NO`). Layout dumps show
  `push_detail_commit_card=[56,389][1264,754]`,
  `push_detail_file_card_0=[56,810][1264,970]`, and
  `appbar_title=CarGuo/GSYGithubApp`.
- Latest AppBar/cache-first fix:
  `AppBar.ets` now defaults to Compose-style start-aligned titles with a 64vp
  bar and stable title/subtitle line heights, and repository commits plus push
  commit details now read local DB cache before network refresh. `assembleHap`,
  `git diff --check`, and the latest logic-only gate passed after these
  changes. Focused device evidence:
  `/tmp/scenario-tour-20260530-114213/README.md` (`repoDetail-info`,
  `repoDetail-commit-route`; `ok=2`, `fail=0`, `asserts=40`, `dup=NO`),
  including `bounds_inside=appbar_title->appbar_main_row` on RepositoryDetail
  and PushDetail.
- Latest file-list cache parity fix:
  `RepositoryService.getFiles` now matches Compose `FileContentRepository`:
  only the root path on the selected default branch uses local DB cache before
  network and writes refreshed data back. Subdirectories and non-default
  branches skip the default cache. `assembleHap` passed, and the latest
  logic-only gate includes the new default-root fallback and non-default cache
  exclusion assertions.
- Latest RepositoryDetail activity cache-first fix:
  `RepositoryDetailPage` uses `RepositoryService.getRepositoryEvents`; this
  path now matches Compose `EventRepository.getRepositoryEvents` by applying
  page-1 DB cache to `activity` before the HTTP request, then replacing it with
  network data and writing refreshed cache. Logic gate:
  `harness/regression/reports/M5/summary.md` (`tests run=399`, `passed=399`,
  `time=2026-05-30T04:07:01Z`). Focused installed-HAP UI gate:
  `/tmp/scenario-tour-20260530-120725/README.md` (`repoDetail-info`,
  `repoDetail-commit-route`; `ok=2`, `fail=0`, `asserts=40`, `dup=NO`).
- Latest RepositoryDetail Issue-list cache-first fix:
  Compose `IssueRepository.getRepositoryIssues()` emits `IssueDao` cache first
  when `query` is empty and `state == "all"`, then refreshes from network.
  `RepositoryService.getIssues()` now matches that page-1 default Issue tab
  path: cached rows are applied to `store.issues` and `store.issueList` before
  the HTTP request starts, then network rows replace them and are written back.
  Logic gate: `harness/regression/reports/M5/summary.md`
  (`tests run=411`, `passed=411`, `time=2026-05-30T06:30:20Z`).
- Latest WebView loading-state fix:
  `CodeDetailPage` and `ReadmeTab` now match Compose `GSYGeneralLoadState` by
  showing explicit `loading...` / `加载中...` UI while Web content is empty and
  the request is pending. Unsupported/failed preview text is shown only after
  the service reports an error. README has a dedicated `readmeLoading` /
  `readmeError` state so cached README remains visible during network refresh.
  RepositoryDetail README now writes the rendered HTML to a local
  `file://` document and drives ArkUI `Web.src`, because the controller
  `loadData` path inside `Tabs` could leave the visible Web node on
  `about:blank`. The scenario assertion now requires actual WebView README
  text, closing the earlier false positive.
  Logic gate: `harness/regression/reports/M5/summary.md`
  (`tests run=412`, `passed=412`, `time=2026-05-30T06:56:57Z`).
  Device gate:
  `/tmp/scenario-tour-20260530-145742/README.md` (`repoDetail-readme`,
  `codeDetail`; `SKIP_INSTALL=0`; `ok=2`, `fail=0`, `asserts=17`, `dup=NO`).
  Screenshot:
  `/tmp/scenario-tour-20260530-145742/07_repoDetail-readme.png`.
- Latest cache-first coverage review:
  Verified against Compose source on 2026-05-30. Compose cache-first paths are:
  repository detail, default-branch README, repository activity/time line,
  default-branch first-page commits, default-root file list, default Issue
  list, issue detail/comments, user detail, user events, organization members,
  dynamic events, trending, code cached fallback, and push commit detail.
  Compose network-only list paths include followers/following, repo
  stargazers/watchers/forks, user repos, user-star repos, branches, and search
  result lists; OH fallback caches on those paths are retained but are not
  treated as Compose cache-first parity.
- Latest IssueDetail cache-first fix:
  `IssueService.getIssue` and first-page `getComments` now match Compose
  `IssueRepository` by applying DB cache before the HTTP request, then
  refreshing from network and writing cache. Logic gate:
  `harness/regression/reports/M5/summary.md` (`tests run=401`, `passed=401`,
  `time=2026-05-30T04:11:48Z`). Focused installed-HAP UI gate:
  `/tmp/scenario-tour-20260530-121218/README.md` (`issueDetail`; `ok=1`,
  `fail=0`, `asserts=32`, `dup=NO`).
- Latest User/Profile cache-first fix:
  `UserService.getUser` and `MyService.refreshMe` now match Compose
  `UserRepository.getUser` by applying local DB user data before network
  refresh, then replacing the store with fresh API data. Logic gate:
  `harness/regression/reports/M5/summary.md` (`tests run=403`, `passed=403`,
  `time=2026-05-30T04:16:54Z`). Rebuilt-HAP UI gate:
  `/tmp/scenario-tour-20260530-121801/README.md` (`home-my`,
  `userDetail-list`, `organization-profile`; `ok=3`, `fail=0`, `asserts=86`,
  `dup=NO`).
- Latest organization-member cache-first fix:
  `UserService.getOrgMembers` now matches Compose's paginated
  cache-and-network path for organization profiles: page 1 emits local
  `OrgMember` cache through the page callback before the HTTP request, then
  writes refreshed network members. Logic gate:
  `harness/regression/reports/M5/summary.md` (`tests run=404`, `passed=404`,
  `time=2026-05-30T04:22:34Z`). Rebuilt-HAP UI gate:
  `/tmp/scenario-tour-20260530-122252/README.md` (`organization-profile`;
  `ok=1`, `fail=0`, `asserts=23`, `dup=NO`).
- Latest List `user_orgs` parity fix:
  `CommonListPage` now supports Compose's `CommonListDataType.USER_ORGS`
  branch, using `UserService.getUserOrgs` and rendering user-style
  organization rows. The new `bootCommonList` startup parameter provides a
  stable device-test entry for list types without a nearby primary-flow tap.
  Logic gate: `harness/regression/reports/M5/summary.md` (`tests run=405`,
  `passed=405`, `time=2026-05-30T04:27:49Z`). Rebuilt-HAP UI gate:
  `/tmp/scenario-tour-20260530-122808/README.md` (`user-orgs-list`; `ok=1`,
  `fail=0`, `asserts=9`, `dup=NO`).
- Latest List row-navigation focused runs:
  `/tmp/scenario-tour-20260530-125023/README.md` (`userDetail-list`; `ok=1`,
  `fail=0`, `asserts=43`, `dup=NO`) verifies repository rows route to
  RepositoryDetail. `/tmp/scenario-tour-20260530-125113/README.md`
  (`repoDetail-stargazers-list`; `ok=1`, `fail=0`, `asserts=13`, `dup=NO`)
  verifies user rows route to UserDetail.
- Latest Profile list branch coverage:
  `/tmp/scenario-tour-20260530-131923/README.md` (`user-followers-list`,
  `user-following-list`, `user-star-list`; `ok=3`, `fail=0`, `asserts=36`,
  `dup=NO`). This run covers Compose's profile list types `follower`,
  `following`, and `user_star`, including row shape, title, non-flat avatar
  crops, and row navigation to UserDetail/RepositoryDetail.
- Latest CommonList user-card contrast pass:
  `/tmp/scenario-tour-20260530-132923/README.md`
  (`repoDetail-stargazers-list`, `user-orgs-list`, `user-followers-list`,
  `user-following-list`; `ok=4`, `fail=0`, `asserts=46`, `dup=NO`). This run
  verifies the shared `UserItem` card ids and navigation after replacing the
  old plain user rows with Compose-style outlined cards on page background.
- Latest focused post-build device run:
  `/tmp/scenario-tour-20260530-032054/README.md` (`repoDetail-info`,
  `repoDetail-readme`, `codeDetail`; `ok=3`, `fail=0`, `asserts=33`,
  `dup=NO`).
- Latest focused feedback-fix run:
  `/tmp/scenario-tour-20260530-083752/README.md` (`repoDetail-commit-route`,
  `repoDetail-file`, `codeDetail`, `personal-info`, `welcomeAnimation`,
  `loginAnimation`; `ok=6`, `fail=0`, `asserts=59`, `dup=NO`). This run covers
  commit route coverage, README/code WebView presence, Harmony welcome/login
  animation ids, and the left-start app bar layout on the touched detail pages.
- Latest RepositoryDetail Readme WebView-only run:
  `/tmp/scenario-tour-20260530-085237/README.md` (`repoDetail-readme`;
  `ok=1`, `fail=0`, `asserts=11`, `dup=NO`). This run covers removal of the
  native README fallback overlay and a non-flat `readme_tab_web` crop.
- Latest Login animation focused run:
  `/tmp/scenario-tour-20260530-093126/README.md` (`loginAnimation`;
  `ok=1`, `fail=0`, `asserts=5`, `dup=NO`). This run verifies the HarmonyOS
  login subtitle in either English or Chinese locale and the animated Harmony
  logo state change.
- Latest CodeDetail nested-title focused run:
  `/tmp/scenario-tour-20260530-054637/README.md` (`codeDetail`; `ok=1`,
  `fail=0`, `asserts=6`, `dup=NO`). This run covers Compose's filename-only
  app bar title for nested paths and a non-flat Web render.
- Latest CodeDetail README WebView focused run:
  `/tmp/scenario-tour-20260530-101303/README.md` (`repoDetail-readme`,
  `codeDetail`; `ok=2`, `fail=0`, `asserts=16`, `dup=NO`). This run was after
  rebuilding/installing the latest HAP and covers README.md rendering via
  Web/GitHub HTML instead of native Markdown/raw source fallback.
- Latest rebuilt-HAP README/File/CodeDetail/animation run:
  `/tmp/scenario-tour-20260530-115340/README.md` (`repoDetail-readme`,
  `repoDetail-file`, `codeDetail`, `welcomeAnimation`, `loginAnimation`;
  `ok=5`, `fail=0`, `asserts=55`, `dup=NO`). This run was executed with
  `SKIP_INSTALL=0` and verifies README.md opens as GitHub HTML in ArkUI Web,
  `readme_tab_native_fallback` stays absent, and the HarmonyOS welcome/login
  animation ids plus screenshot deltas are present.
- Latest installed-HAP README.md re-check after screenshot review:
  `/tmp/scenario-tour-20260530-125642/README.md` (`repoDetail-readme`,
  `codeDetail`; `SKIP_INSTALL=0`; `ok=2`, `fail=0`, `asserts=16`, `dup=NO`).
  The CodeDetail screenshot shows rendered GitHub HTML in ArkUI Web rather than
  raw markdown source, and RepositoryDetail README still has no native fallback.
- Latest Web/Image compatibility route run:
  `/tmp/scenario-tour-20260530-130803/README.md` (`webPage`, `photoPage`;
  `SKIP_INSTALL=0`; `ok=2`, `fail=0`, `asserts=10`, `dup=NO`). This run keeps
  the Compose rule that README/code rendering belongs to the feature WebViews
  while proving OH's retained generic Web/Image routes still render non-blank
  content for existing callers.
- Latest Info route focused run:
  `/tmp/scenario-tour-20260530-115812/README.md` (`personal-info`;
  `ok=1`, `fail=0`, `asserts=27`, `dup=NO`). This run covers the Compose-like
  pull-refresh wrapper, info row icon/label/value ids, no-chevron rows, edit
  dialog, `No more data` / `后面没有数据了` terminal footer, `appbar_title`
  bounds inside `appbar_main_row`, and a non-flat `person_info_row_name`
  screenshot crop. `PersonInfoPage` refresh now calls `GET /user` via
  `MyService.refreshMe()` and writes refreshed user info through `UserDao`,
  matching Compose's current-user reload path.
- Latest Info update-user cache alignment:
  `/tmp/scenario-tour-20260530-130119/README.md` (`personal-info`;
  `SKIP_INSTALL=0`; `ok=1`, `fail=0`, `asserts=27`, `dup=NO`) plus
  `harness/regression/reports/M5/summary.md` (`tests run=408`,
  `passed=408`). The added `UserServiceTest` verifies Compose-like
  `PATCH /user` JSON body and writes the returned user to `UserDao` without
  mutating the real account in UI tours.
- Latest History focused run:
  `/tmp/scenario-tour-20260530-124642/README.md` (`my-readHistory`; `ok=1`,
  `fail=0`, `asserts=13`, `dup=NO`). This run seeds repository history from
  `bootRepo`, opens History from the drawer, verifies the repository row/stat
  ids, then taps `read_history_row_0` and verifies it routes back to
  RepositoryDetail.
- Latest drawer language focused run:
  `/tmp/scenario-tour-20260530-032833/README.md` (`drawer-language`;
  `ok=1`, `fail=0`, `asserts=9`, `dup=NO`).
- Latest Compose drawer About runtime evidence:
  `/tmp/gsy-compose-screens/home-drawer-about-runtime.png` and
  `/tmp/gsy-compose-screens/home-drawer-about-runtime.xml`. This run confirms
  Compose opens an in-place About dialog with `Version: 1.3.0` and the
  `Update` confirm resource.
- Latest OH drawer About focused run:
  `/tmp/scenario-tour-20260530-063913/README.md` (`home-drawer`,
  `drawer-about`; `ok=2`, `fail=0`, `asserts=34`, `dup=NO`). This run covers
  drawer About as an in-place dialog, Compose-format version/update text, and
  absence of legacy AboutPage ids.
- Latest Login language focused run:
  `/tmp/scenario-tour-20260530-033141/README.md` (`loginLanguage`;
  `ok=1`, `fail=0`, `asserts=13`, `dup=NO`).
- Latest Login/OAuth entry focused run:
  `/tmp/scenario-tour-20260530-131605/README.md` (`loginOAuth`; `ok=1`,
  `fail=0`, `asserts=5`, `dup=NO`). This run asserts the Compose OAuth
  redirect/scope inside the WebView URL:
  `gsygithubapp://authed` and
  `user,repo,gist,notifications,read:org,workflow`.
- Latest Login legacy-probe cleanup focused run:
  `/tmp/scenario-tour-20260530-061244/README.md` (`loginPage`; `ok=1`,
  `fail=0`, `asserts=17`, `dup=NO`). This run covers the Compose login card
  and absence of old RN username/password/register/PAT probe ids.
- Latest Search focus/history focused run:
  `/tmp/scenario-tour-20260530-053938/README.md` (`search`; `ok=1`,
  `fail=0`, `asserts=39`, `dup=NO`). This run covers Compose's
  focus-gated Search History behavior, Repository/User typed search, and
  result navigation.
- Latest Search full-name repository row focused run:
  `/tmp/scenario-tour-20260530-060928/README.md` (`search`; `ok=1`,
  `fail=0`, `asserts=37`, `dup=NO`). This run covers Compose-style
  repository result titles using `full_name`.
- Latest Welcome/Login animation focused run:
  `/tmp/scenario-tour-20260530-083752/README.md` (`welcomeAnimation`,
  `loginAnimation` inside the focused run; `ok=6`, `fail=0`, `asserts=59`,
  `dup=NO`).
- Latest Issue edit-entry focused run:
  `/tmp/scenario-tour-20260530-035744/README.md` (`issueDetail`;
  `ok=1`, `fail=0`, `asserts=14`, `dup=NO`).
- Latest Issue Markdown input dialog focused run:
  `/tmp/scenario-tour-20260530-061628/README.md` (`issueDetail`; `ok=1`,
  `fail=0`, `asserts=32`, `dup=NO`). This run covers Compose-style Markdown
  input dialogs for issue edit, comment edit, and reply.
- Latest Issue Markdown mixed-HTML focused evidence:
  `harness/regression/reports/M5/summary.md` now includes
  `MarkdownUtil_parseLines_githubHtmlBlocks`, and
  `/tmp/scenario-tour-20260530-105926/README.md` (`issueDetail`; `ok=1`,
  `fail=0`, `asserts=32`, `dup=NO`) passed after rebuilding/installing the
  latest HAP.
- Latest PushDetail route focused run:
  `/tmp/scenario-tour-20260530-134925/README.md` (`repoDetail-commit-route`,
  `pushDetail`; `ok=2`, `fail=0`, `asserts=31`, `dup=NO`). This run covers the
  Compose header-as-list-item structure, stats row, file card surface,
  PushDetail -> CodeDetail route, and commit SHA patch semantics (`@@`
  present, full README text absent).
- Latest Notification route/style focused run:
  `/tmp/scenario-tour-20260530-112636/README.md` (`my-notify`;
  `ok=1`, `fail=0`, `asserts=18`, `dup=NO`). This run covers the Compose
  Notification page in English locale, confirms the loaded content state does
  not retain `notify_initial_loading` / `notify_initial_error`, verifies boot
  issue fallback, and checks IssueDetail route from an Issue notification.
- Latest Notification DoneAll focused run:
  `/tmp/scenario-tour-20260530-123541/README.md` (`notifyMarkAll`;
  `ok=1`, `fail=0`, `asserts=12`, `dup=NO`). This run covers the Compose
  mark-all-read app-bar action by verifying the injected row status changes
  from unread to read and by checking the `notify/markAll` hilog marker.
- Latest Setting entry focused run:
  `/tmp/scenario-tour-20260530-042236/README.md` (`my-setting`;
  `ok=1`, `fail=0`, `asserts=9`, `dup=NO`).
- Latest My/Profile header focused run:
  `/tmp/scenario-tour-20260530-043923/README.md` (`home-my`, `my-setting`;
  `ok=2`, `fail=0`, `asserts=22`, `dup=NO`). This run covers the
  Compose-style My header, the four-stat surface, and the Setting avatar
  entry route.
- Latest My/Profile logout focused run:
  `/tmp/scenario-tour-20260530-062858/README.md` (`home-my`; `ok=1`,
  `fail=0`, `asserts=18`, `dup=NO`). This run covers the Compose
  `ProfileScreen` logout button and corrected `Logout` / `退出登录` text.
- Latest My/Profile avatar-static focused run:
  `/tmp/scenario-tour-20260530-063215/README.md` (`home-my`, `my-setting`;
  `ok=2`, `fail=0`, `asserts=25`, `dup=NO`). This run covers Compose's
  non-clickable Profile avatar behavior by proving avatar taps do not open
  Setting.
- Latest My/Profile stat-label focused run:
  `/tmp/scenario-tour-20260530-064301/README.md` (`home-my`, `my-setting`;
  `ok=2`, `fail=0`, `asserts=29`, `dup=NO`). This run covers Compose profile
  stat labels `Repositories`, `Followers`, `Following`, and `Stars`.
- Latest My/Profile relative-joined focused run:
  `/tmp/scenario-tour-20260530-064657/README.md` (`home-my`, `my-setting`;
  `ok=2`, `fail=0`, `asserts=30`, `dup=NO`). This run covers Compose-style
  joined time for older accounts (`Joined: 8 years ago`) plus the stat-label
  and avatar-static checks.
- Latest UserDetail optional-field focused run:
  `/tmp/scenario-tour-20260530-062042/README.md` (`userDetail-list`,
  `organization-profile`; `ok=2`, `fail=0`, `asserts=62`, `dup=NO`). This run
  covers Compose optional profile fields, removal of old RN blog/org strip and
  placeholder text, repository list navigation, and organization member rows.
- Latest Home feedback / Repository create issue Markdown dialog focused run:
  `/tmp/scenario-tour-20260530-062507/README.md` (`repoDetail-info`,
  `home-drawer`; `ok=2`, `fail=0`, `asserts=50`, `dup=NO`). This run covers
  Compose-style `GSYMarkdownInputDialog` parity for drawer feedback and
  repository FAB create issue, including the first visible Markdown action ids.
- Latest RepositoryDetail topic-list focused run:
  `/tmp/scenario-tour-20260530-050121/README.md`
  (`repoDetail-topic-list`; `ok=1`, `fail=0`, `asserts=14`, `dup=NO`).
  This run covers the Compose topic chip -> `topics` list -> repository detail
  route.
- Latest RepositoryDetail commit-card focused run:
  `/tmp/scenario-tour-20260530-134925/README.md`
  (`repoDetail-commit-route`, `pushDetail`; `ok=2`, `fail=0`,
  `asserts=31`, `dup=NO`).
  This run covers the Compose Info -> Commits card UI, tap-through to
  PushDetail, PushDetail card styling, and file tap-through to CodeDetail.
- Latest RepositoryDetail File Tab focused run:
  `/tmp/scenario-tour-20260530-053259/README.md`
  (`repoDetail-file`; `ok=1`, `fail=0`, `asserts=13`, `dup=NO`). This run
  covers the Compose PathNavigator root `.`, separator `>`, and absence of the
  legacy `..` back item.
- Latest RepositoryDetail file-cache focused run:
  `/tmp/scenario-tour-20260530-111111/README.md`
  (`repoDetail-branch-selector`, `repoDetail-file`, `codeDetail`; `ok=3`,
  `fail=0`, `asserts=29`, `dup=NO`). This run verifies the File tab,
  branch selector, and CodeDetail route after restricting file-list cache
  behavior to Compose's default-branch root-path rule.
- Latest RepositoryDetail tab focus focused run:
  `/tmp/scenario-tour-20260530-070044/README.md`
  (`repoDetail-readme`, `repoDetail-issue`, `repoDetail-file`; `ok=3`,
  `fail=0`, `asserts=40`, `dup=NO`). This run covers Readme -> Issue -> File
  tab switching with the Issue search field not auto-opening the keyboard, so
  the page-level bottom bar and create issue FAB remain visible.
- Latest RepositoryDetail branch-selector focused run:
  `/tmp/scenario-tour-20260530-071749/README.md`
  (`repoDetail-branch-selector`; `ok=1`, `fail=0`, `asserts=11`,
  `dup=NO`). This run covers the Compose-style in-page branch menu, selecting
  `add-license-1`, menu dismissal, and bottom bar branch-label update.
- Latest RepositoryDetail top-bar focused run:
  `/tmp/scenario-tour-20260530-073303/README.md`
  (`repoDetail-info`; `ok=1`, `fail=0`, `asserts=27`, `dup=NO`). This run
  covers removal of the old RN-style `appbar_action_r_more` overflow menu while
  keeping the Info tab, bottom bar, FAB, and create issue dialog functional.
- Latest shared EventItem route parity check:
  `harness/regression/reports/M5/summary.md` (`exit=0`,
  `assertion errors=0`) covers the Compose default ForkEvent repository route,
  ReleaseEvent external-browser opening for `tarball_url`/`tarballUrl`, and the
  OH `WebPage` fallback only when no external opener is supplied. It now also
  covers Compose's `MemberEvent -> person/{actor.login}` branch through
  `LoggerAndRoutesTest.event_dispatcher_member_event_uses_compose_person_route`.
- Latest post-MemberEvent device route focused run:
  `/tmp/scenario-tour-20260530-111417/README.md` (`home-dynamic`, `home-my`,
  `repoDetail-commit-route`, `userDetail-list`; `ok=4`, `fail=0`,
  `asserts=78`, `dup=NO`). This verifies the shared event-list screens and
  UserDetail route after adding the MemberEvent person-route branch.
- Latest post-ReleaseEvent device route focused run:
  `/tmp/scenario-tour-20260530-110522/README.md` (`home-dynamic`, `home-my`,
  `repoDetail-commit-route`, `userDetail-list`; `ok=4`, `fail=0`,
  `asserts=78`, `dup=NO`). This run verifies the touched Dynamic, Profile,
  Repository activity, and UserDetail event/list call sites after the external
  URL opener injection.
- Latest shared EventItem / Home card-contrast parity run:
  `/tmp/scenario-tour-20260530-120050/README.md` (`home-dynamic`,
  `home-trend`, `home-my`; `ok=3`, `fail=0`, `asserts=40`, `dup=NO`). This run
  covers the Compose user/action/time event-row layout, absence of the old RN
  expanded description block, absence of Trending filter controls, My/Profile
  labels, and non-flat screenshot crops for `dynamic_row_0`, `trend_row_0`,
  and `user_head_profile_block`.
