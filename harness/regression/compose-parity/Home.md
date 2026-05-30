# Home Compose Parity

## Compose Reference

Source files:

- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/home/src/main/java/com/shuyu/gsygithubappcompose/feature/home/HomeScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/trending/src/main/java/com/shuyu/gsygithubappcompose/feature/trending/TrendingScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/trending/src/main/java/com/shuyu/gsygithubappcompose/feature/trending/TrendingViewModel.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/ui/src/main/java/com/shuyu/gsygithubappcompose/core/ui/components/EventItem.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/ui/src/main/java/com/shuyu/gsygithubappcompose/core/ui/components/RepositoryItem.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/ui/src/main/java/com/shuyu/gsygithubappcompose/core/ui/components/LanguageSelectDialog.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/common/src/main/res/values/strings.xml`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/common/src/main/res/values-zh-rCN/strings.xml`

Runtime evidence:

- Compose emulator screenshot:
  `/tmp/gsy-compose-screens/home-feed.png`
- Compose drawer screenshot:
  `/tmp/gsy-compose-screens/home-drawer.png`
- Compose drawer About runtime screenshot:
  `/tmp/gsy-compose-screens/home-drawer-about-runtime.png`
- Compose UI dump:
  `/tmp/gsy-compose-screens/home-feed.xml`

Structure:

- Top app bar title is fixed to `app_name`.
- Left navigation icon opens the home drawer.
- Right action opens search.
- Bottom navigation contains Dynamic / Trending / Profile with labels
  `Feed / Trending / My` in English and `动态 / 趋势 / 我的` in Chinese.
- Trending content is a pull-refresh list only. Compose `TrendingViewModel`
  always loads `since = "daily"` and `languageType = null`; `TrendingScreen`
  explicitly disables load-more and does not render the old RN time/language
  filter bar.
- Global list refresh uses Compose `GSYPullRefresh`, backed by Material3
  `PullToRefreshBox`. The refresh surface is the default circular indicator
  only; it does not render a `refreshing...` text row or a grey/white banner.
- Trending repository rows use the shared Compose `RepositoryItem` shape:
  avatar, full name, optional language, optional description, then star/fork
  metadata. There is no third watch/current-period column.
- Compose card rows sit on a white surface with the shared `GSYCardItem`
  outline border (`#E1E4E8`) and 2dp-level elevation, so the cards remain
  readable against the white page background.
- Drawer menu order is `history`, `feedback`, `personal_info`, `language`,
  `check_update`, `about`, then logout.
- Drawer `language` opens `LanguageSelectDialog`. The dialog is an
  `AlertDialog` with the menu language title, one radio row for each
  `AppLanguage` value, and no confirm button; tapping a row applies the
  language and dismisses the dialog.
- Drawer `about` opens an in-place `AlertDialog`, not an About page. The title
  is `app_name`, body is `app_version`, and the confirm button uses
  Compose's `app_ok` resource (`Update` / `更新`).
- Dynamic/Profile/Repository event rows share Compose `EventItem` click
  routing: Issue events open issue detail, Push events open push detail when a
  commit SHA is available, Release events open `release.tarballUrl` through an
  external browser intent, Member events open the actor's person page, and
  other repo events including ForkEvent open `event.repo.name`.
- Dynamic/Profile/Repository event rows also share the Compose `EventItem`
  card shape: 40dp avatar, username, concise action text, then relative time.
  The old RN expanded description line is not rendered in list rows.

## OH Changes

- `HomePage.ets` uses a controlled Stack overlay for the drawer and exposes
  stable ids for the root, main content, drawer content, app bar actions, and
  existing tab bars. Menu actions can now close the drawer before opening modal
  UI.
- The home app bar title is fixed to `I18n('appName')`, with
  `appbar_action_l_menu` and `appbar_action_r_search`.
- Bottom tab labels now match Compose resources.
- `TrendTabPage.ets` now matches Compose Trending: it removes the RN
  daily/weekly/monthly + language filter bar, always refreshes
  `TREND_SINCE_DAILY` with no language parameter, renders a two-metric
  star/fork row, and passes `owner`, `name`, and `fullName` when opening
  RepositoryDetail.
- `TrendService.ets` accepts the Compose trending response fields
  `fullName`, `name`, `reposName`, `starCount`, `forkCount`, and
  `contributors` while retaining compatibility with the existing cached
  `TrendRepo` shape.
- `DrawerHeader.ets` / `DrawerMenu.ets` now use the Compose-style drawer:
  light background, centered avatar/name/login header, text-only menu rows,
  and a red logout button. It emits the Compose drawer order and ids:
  `drawer_menu_item_history`, `drawer_menu_item_feedback`,
  `drawer_menu_item_personal_info`, `drawer_menu_item_language`,
  `drawer_menu_item_check_update`, `drawer_menu_item_about`,
  `drawer_menu_item_logout`.
- Drawer feedback now opens the same Compose-style Markdown input dialog as
  `GSYMarkdownInputDialog`: title field, 200dp-level body field, horizontal
  Markdown actions (`H1 / H2 / H3 / B / ...`), and submission through
  `POST /repos/CarGuo/GSYGithubAppCompose/issues`.
- Drawer check-update now queries `CarGuo/GSYGithubAppCompose` releases,
  compares the latest tag with the installed bundle version, and shows the
  Compose-style update dialog before opening the release URL.
- Drawer feedback/check-update actions wait for the drawer to close before
  opening modal UI, matching Compose's drawer-close behavior.
- Drawer language now opens an in-place language dialog instead of navigating
  to Settings. The dialog exposes stable ids for the root/title and the three
  options (`local`, `zh-CN`, `en`), and selection is wired through
  `SettingPageHelper.applyLanguage(...)` so the same locale persistence/event
  path is used as Settings.
- Drawer about now opens an in-place dialog instead of pushing the legacy
  `AboutPage`. It exposes `drawer_about_dialog_*` ids, uses the installed
  bundle version, formats the version label like Compose resources, and uses
  the Compose `Update` / `更新` confirm text.
- `HomePageHost` mirrors the production structure so Hypium can exercise the
  drawer without depending on login/network observers.
- `EventActionDispatcher` no longer keeps the RN-only ForkEvent route override.
  ForkEvent now falls through to the Compose default repository route, and
  ReleaseEvent now uses `ExternalUrlUtil` to open `tarball_url`/`tarballUrl`
  with an external browser intent before falling back to the OH `WebPage` route
  only when no external opener is available.
- `EventActionDispatcher` now handles Compose's `MemberEvent` branch by opening
  `UserDetail` for `event.actor.login` instead of falling through to
  RepositoryDetail.
- `EventItem.ets` now uses the Compose card structure and `EventActionUtil`
  exposes `getComposeActionText(...)` for the shared action labels
  (`pushed to`, `created`, `forked`, `started watching`, `created issue in`,
  and so on). Dynamic, My, UserDetail, and RepositoryDetail event rows now pass
  the Compose label instead of the RN `actionStr/des` pair.
- `PullLoadMoreList.ets` refresh indicator now matches Compose's
  `PullToRefreshBox` behavior more closely: the old `refreshing...` text and
  visible grey/blue banner were removed. ArkUI `Refresh` stays responsible for
  pull gesture detection, but its native `refreshingContent` is transparent and
  zero-height. Programmatic active refresh is rendered by a centered primary
  circular indicator (`pull_refresh_indicator`) with a transparent hit-test
  overlay, matching Compose's no-prompt visual behavior and avoiding the
  previous translucent strip / diagonal-artifact regression.
- `PullLoadMoreList.ets` load-more footer now separates Compose's `hasMore`
  and `isLoadMore` states. When more data is available but no request is in
  flight, the footer shows only the text (`pull_load_more_text`), like Compose's
  `loading_more` branch; the spinner (`pull_load_more_indicator`) appears only
  after the list reaches the end and `beginLoadMore()` marks an active load.
- `RepositoryItem.ets` and `TrendTabPage.ets` now use the Compose
  `GSYCardItem` outline (`GSYColor.borderSubtle == #E1E4E8`) plus the softer
  shared alpha shadow, fixing the low-contrast white-card-on-white-background
  regression seen in list screenshots.
- Shared terminal footer copy now matches Compose resources through
  `loadMoreEnd`: `No more data` / `后面没有数据了`, replacing the older RN-style
  `no more` / `加载完了哟` copy.

## Automated Checks

- `HomeUiTest` now checks the app bar menu/search actions and drawer menu ids.
- `UtilsTest.EventActionUtil_getComposeActionText_matchesComposeEventItem`
  locks the shared Compose action text mapping.
- `DynamicUiTest` now expects the Compose `EventItem` ids
  `dynamic_row_N_user`, `dynamic_row_N_target`, and `dynamic_row_N_time`.
- `scenario-tour.sh` `home-dynamic` now asserts the shared Compose event row
  ids and verifies the old RN `dynamic_row_0_des` block is absent.
- `TrendServiceTest.maps_compose_trending_model_full_name_and_counts` checks
  Compose trending model parsing for full name, counts, and avatar.
- `TrendUiTest` now expects the Compose Trending root/list and row ids instead
  of the old filter-switching controls.
- `scenario-tour.sh` `home-trend` now asserts `trend_pull_list` and verifies
  the old `trend_filter_bar`, `trend_picker_time`, `trend_picker_language`,
  and `trend_filter_divider` ids are absent.
- `scenario-tour.sh` has a `home-drawer` scenario that opens the home drawer,
  snapshots it, asserts the Compose drawer menu ids, taps feedback, and asserts
  the feedback Markdown dialog controls plus the first visible Markdown action
  ids. It also asserts the drawer ids are absent from the feedback-dialog
  layout snapshot so the old "dialog over drawer" visual regression cannot
  pass.
- `scenario-tour.sh` has a `drawer-language` scenario that opens the home
  drawer, taps Language, snapshots the dialog, and asserts the language dialog
  root/title plus all three option/label ids.
- `DrawerMenuUiTest.about_click_opens_compose_style_dialog_without_about_page_route`
  verifies the About item opens the Compose-style dialog and does not push
  `pages/AboutPage`.
- `scenario-tour.sh` has a `drawer-about` scenario that opens the home drawer,
  taps About, snapshots the dialog, asserts version/update text, and verifies
  the legacy `about_root` page ids are absent.
- Latest OH tab evidence:
  `/tmp/gsy-oh-compose-home-tabs-20260529-222502/README.md`
- Latest OH drawer evidence:
  `/tmp/scenario-tour-20260530-001206/README.md`
- Latest OH check-update evidence:
  `/tmp/gsy-oh-check-update-20260530-001434/check_update.png`
- Latest drawer-close feedback evidence:
  `/tmp/scenario-tour-20260530-013547/README.md`
  with result `ok=1 fail=0 skip=25`, duplicate screenshots `NO`.
- Latest feedback Markdown dialog evidence:
  `/tmp/scenario-tour-20260530-062507/README.md` (`home-drawer`;
  `ok=1` within the focused run, `asserts=50`, duplicate screenshots `NO`).
  This covers the Compose-style Markdown action row in the feedback dialog and
  verifies the drawer is closed behind the modal.
- Latest full scenario evidence:
  `/tmp/scenario-tour-20260530-104117/README.md`
  with result `ok=35 fail=0 skip=0`, `asserts=467`, screenshots `62`, and
  duplicate screenshots `NO`. This covers Home tabs, drawer, feedback,
  language, About, personal info, notifications, history, Web/Image, and the
  repository/list routes reached from Home.
- Latest drawer language evidence:
  `/tmp/scenario-tour-20260530-032833/README.md`
  with result `ok=1 fail=0 skip=27`, `asserts=8`, duplicate screenshots `NO`.
- Latest Compose drawer About runtime evidence:
  `/tmp/gsy-compose-screens/home-drawer-about-runtime.png` and
  `/tmp/gsy-compose-screens/home-drawer-about-runtime.xml`. This verifies the
  Compose runtime surface is an in-place About dialog with `GSY GitHub App`,
  `Version: 1.3.0`, and `Update`.
- Latest OH drawer About evidence:
  `/tmp/scenario-tour-20260530-063913/README.md` (`home-drawer`,
  `drawer-about`; `ok=2`, `fail=0`, `asserts=34`, duplicate screenshots
  `NO`). This verifies the About action opens an in-place dialog, the
  version/update text matches Compose resources, and legacy AboutPage ids are
  absent.
- Latest Hypium logic-only evidence:
  `harness/regression/reports/M5/summary.md`
  with `exit=0`, `tests run=396`, `passed=396`, `assertion errors=0`,
  `time=2026-05-30T03:13:57Z`.
- Latest EventItem route parity evidence:
  `LoggerAndRoutesTest.event_dispatcher_fork_event_uses_compose_repo_route`,
  `LoggerAndRoutesTest.event_dispatcher_release_event_opens_external_compose_tarball_url`,
  and
  `LoggerAndRoutesTest.event_dispatcher_release_event_falls_back_to_web_without_external_handler`,
  plus `LoggerAndRoutesTest.event_dispatcher_member_event_uses_compose_person_route`
  in `harness/regression/reports/M5/summary.md` (`exit=0`,
  `assertion errors=0`).
- Latest post-MemberEvent device route evidence:
  `/tmp/scenario-tour-20260530-111417/README.md` (`home-dynamic`,
  `home-my`, `repoDetail-commit-route`, `userDetail-list`; `ok=4`,
  `fail=0`, `asserts=78`, duplicate screenshots `NO`). This run verifies the
  shared event-list surfaces and UserDetail route still work after adding the
  Compose MemberEvent branch.
- Latest post-ReleaseEvent device route evidence:
  `/tmp/scenario-tour-20260530-110522/README.md` (`home-dynamic`,
  `home-my`, `repoDetail-commit-route`, `userDetail-list`; `ok=4`,
  `fail=0`, `asserts=78`, duplicate screenshots `NO`). This run confirms the
  shared event-list call sites still render and route after injecting the
  external URL opener.
- Latest EventItem UI parity evidence:
  `/tmp/scenario-tour-20260530-120050/README.md` (`home-dynamic`,
  `home-trend`, `home-my`; `ok=3`, `fail=0`, `asserts=40`, duplicate
  screenshots `NO`). This run covers the shared Compose event-row
  user/action/time layout, absence of the old expanded description block, and
  a non-flat `dynamic_row_0` screenshot crop.
- Latest Trending focused evidence:
  `/tmp/scenario-tour-20260530-120050/README.md` (`home-trend`; included in
  the focused Home run above). This run covers the Compose-style list-only
  Trending screen, absence of RN filter controls, and a non-flat `trend_row_0`
  screenshot crop.
- Latest refresh-indicator code/build evidence:
  `hvigorw assembleHap --mode module -p product=default --no-daemon` passed
  after changing `PullLoadMoreList.ets`. `./harness/regression/run-tests.sh`
  passed with `tests run=410`, `passed=410`, `time=2026-05-30T05:38:34Z`;
  `CommonComponentsTest` now covers the custom `pull_refresh_indicator`,
  asserts that programmatic refresh does not enter ArkUI's native refreshing
  state, and verifies the load-more spinner is active only between
  `beginLoadMore()` and `loadMoreComplete()`.
- Latest installed-HAP Home list evidence after the refresh/load-more footer
  change:
  `/tmp/scenario-tour-20260530-133926/README.md` (`home-dynamic`,
  `home-trend`, `personal-info`; `SKIP_INSTALL=0`; `ok=3`, `fail=0`,
  `asserts=43`, `dup=NO`). This covers the first-screen list surfaces and the
  drawer-to-personal-info path after the global `PullLoadMoreList` change.
- Latest card-contrast code/build evidence:
  `hvigorw assembleHap --mode module -p product=default --no-daemon` passed
  after adding the Compose outline border to the shared repository cards and
  Trending cards, and the latest logic-only run above stayed green. The latest
  focused Home run also asserts non-flat crops for `dynamic_row_0`,
  `trend_row_0`, and `user_head_profile_block`, covering the previous
  low-contrast card regression from the device UI side.

## Current Gaps

- No blocking Home gap remains from this pass. The drawer menu order, feedback
  dialog, language dialog, about dialog, update flow, Trending list-only
  surface, shared EventItem surface, card contrast, and global
  refresh/load-more indicator shapes are covered by code/build evidence plus
  the existing automated layout/screenshot checks.
