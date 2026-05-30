# Notification Compose Parity

## Compose Reference

Source files:

- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/notification/src/main/java/com/shuyu/gsygithubappcompose/feature/notification/NotificationScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/common/src/main/res/values/strings.xml`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/common/src/main/res/values-zh-rCN/strings.xml`

Runtime evidence:

- Compose emulator screenshot:
  `/tmp/gsy-compose-screens/notification-page.png`
- Compose UI dump:
  `/tmp/gsy-compose-screens/notification-page.xml`
- Compose emulator locale was checked as `en-US`; the captured reference text is
  English.

Structure:

- Top app bar title is `Notification`, with back button.
- Right action is the `DoneAll` icon for `mark_all_as_read`.
- During the first empty load, Compose shows only a centered
  `CircularProgressIndicator` under the app bar. The segmented filters and
  notification list are not rendered until the initial request finishes.
- If the first load fails while the list is empty, Compose shows the error text
  centered under the app bar instead of the segmented/list content.
- Segmented filter order is `Unread / Participating / All`.
- Rows are cards with repository full name, relative update time, subject title,
  and `Type: X, Status: Unread/Read`.
- Tapping a row marks it as read. Compose only navigates to Issue detail when
  `subject.type == "Issue"`.
- Compose `NotificationRepository` is network-only for notification list,
  mark-one-read, mark-all-read, and notification-count requests; unlike
  repository/readme/file/history data, this feature does not define a local
  Room/DAO cache path.

## OH Changes

- `NotifyPage.ets` now uses the Compose filter order and card row structure.
- `NotifyPage.ets` now tracks the Compose initial-load state: an empty first
  request renders `notify_initial_loading` with a centered progress indicator,
  an empty first failure renders `notify_initial_error`, and the segmented tabs
  plus pull-refresh list render only after the first load/boot fixture is done.
- Notification cards now more closely match Compose `GSYCardItem`/`NotificationItem`:
  8px radius, 1px outline, 10px content padding, and repository full name
  rendered as the primary-color small title instead of the older bold main-text
  row title.
- `AppBar.ets` exposes the stable `appbar_action_r_done_all` icon action.
- Notification row ids now cover the same inspectable parts:
  `notify_row_repo_N`, `notify_row_time_N`, `notify_row_title_N`,
  `notify_row_status_N`.
- Empty or failed refreshes no longer leave a load-more footer active.
- Row click routing now follows Compose: only Issue notifications open
  `IssueDetail`; PullRequest, Discussion, and Commit rows are only marked read.
- `bootNotifyIssue=fullName|number` is a test-only want parameter used when the
  real notification list has no visible Issue row. It opens NotifyPage and
  injects one Issue notification so the Issue click route remains deterministic.
- `TimeUtil.resolveTime` now reads the existing i18n strings instead of
  hard-coded Chinese text. The strings match Compose-style patterns such as
  `%d days ago` and `%d 天前`.
- `EntryAbility` accepts the test-only `bootLocale` want parameter so OH
  screenshots can be captured in the same language as Compose without changing
  production routing or login state.

## Automated Checks

- `NotifyUiTest` checks the segmented tabs, card row fields, status text, and
  done-all action id.
- `scenario-tour.sh` drives the real My page notification entry through
  `my-notify`.
- `scenario-tour.sh` also includes `notifyMarkAll`, which starts NotifyPage
  with a `bootNotifyIssue` fixture, taps the Compose DoneAll app-bar action,
  and verifies the row status changes from unread to read without depending on
  the user's real notification inbox.
- Same-locale English OH evidence:
  `/tmp/scenario-tour-20260530-021352/README.md`
- Same-locale English OH screenshot:
  `/tmp/scenario-tour-20260530-021352/11_my-notify.png`
- Latest full OH scenario run:
  `/tmp/scenario-tour-20260530-042308/README.md`
- Latest focused Issue route run:
  `/tmp/scenario-tour-20260530-041214/README.md`
  (`my-notify`; `ok=1`, `fail=0`, `asserts=9`, `dup=NO`).
- Latest focused notification style/route run after card-row polish:
  `/tmp/scenario-tour-20260530-112636/README.md`
  (`my-notify`; `ok=1`, `fail=0`, `asserts=18`, `dup=NO`).
  It captures the English Notification page, confirms
  `notify_initial_loading` / `notify_initial_error` are absent from the loaded
  content state, verifies the boot issue fallback row, and checks IssueDetail
  route.
- Route log evidence in
  `/tmp/scenario-tour-20260530-112636/hilog_business.log`:
  `bootNotifyIssue injected`, `push name=Notify`, `notify/boot`,
  `notify/click open issue`, `push name=IssueDetail`, and `issue/route`.
- Latest focused DoneAll / mark-all-read evidence:
  `/tmp/scenario-tour-20260530-123541/README.md`
  (`notifyMarkAll`; `ok=1`, `fail=0`, `asserts=12`, `dup=NO`). It verifies
  `appbar_action_r_done_all`, `notify_row_status_0` changing from `未读` to
  `已读`, and absence of the initial loading/error states after the action.
- Route log evidence in
  `/tmp/scenario-tour-20260530-123541/hilog_business.log`:
  `notify/boot` and `notify/markAll`.

## Current Gaps

- No blocking Notification gap remains in this pass. Same-locale evidence checks
  the English title, segmented tabs, row `Type/Status` text, and relative time
  (`days ago`/`hours ago`/`minutes ago`/`just now`); the focused route evidence
  verifies Issue notification click-through into IssueDetail with screenshot,
  layout, and hilog markers. The focused mark-all evidence now covers the
  Compose DoneAll action path.
