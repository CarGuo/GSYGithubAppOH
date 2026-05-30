# Info Compose Parity

Reference:
- Compose `feature/info/InfoScreen.kt`
- Compose `feature/info/BaseInfoViewModel.kt`
- OH `entry/src/main/ets/pages/PersonInfoPage.ets`
- OH drawer entry `entry/src/main/ets/common/DrawerMenu.ets`

## Compose Baseline

- Home drawer item `personal_info` navigates to route `info`.
- `InfoScreen` shows a top app bar titled personal info and six editable rows:
  name, email, blog, company, location, and bio.
- Each row is a `GSYCardItem`: margin 16/8, 8dp radius, outline, small
  elevation, left icon, title, and value. It does not show a trailing chevron.
- The `GSYPullRefresh` wrapper also renders the terminal footer text
  `No more data` / `后面没有数据了` when the single info item has no more
  content.
- Pull refresh calls `BaseInfoViewModel.refresh()`, which reloads the current
  authenticated user through the user repository.
- Tapping a row opens an edit dialog with a text field, cancel, and confirm.
- Confirm calls `updateUser(mapOf(field to value))`.

## OH Status

- Drawer `personal_info` now always pushes `RouteName.PersonInfo`, matching
  Compose `navigator.navigate("info")`. It no longer redirects logged-in users
  to public `UserDetailPage`.
- `PersonInfoPage` shows the six Compose fields with stable row ids:
  `person_info_row_name`, `person_info_row_email`, `person_info_row_blog`,
  `person_info_row_company`, `person_info_row_location`, and
  `person_info_row_bio`.
- Each row now also exposes stable `*_icon`, `*_label`, and `*_value` ids where
  they are needed for screenshot regression; the current scenario asserts the
  icon ids for all six rows and the label/value ids for the first row.
- `PersonInfoPage` now uses the same GSYCardItem-style row shape as Compose:
  left icon, title/value text, subtle outline, 8dp corner radius, small shadow,
  and no trailing chevron.
- Row icons now match the Compose Material icon semantics: info circle,
  envelope, link, group, location, and message.
- The page includes `person_info_no_more` with the Compose terminal footer
  copy through the shared `loadMoreEnd` resource.
- `PersonInfoPage` now uses the shared `PullLoadMoreList` refresh wrapper
  instead of a plain `Scroll`. Its refresh path calls `MyService.refreshMe()`
  (`GET /user`), updates `GlobalAuthStore` / `AppStorage`, and passes
  `UserDao` so refreshed current-user data is written to the local user-info
  table.
- The page app bar uses the same start-aligned `GSYTopAppBar` layout as
  Compose so the title is not centered or clipped by symmetric side slots.
- Tapping a row opens `PersonInfoEditDialog`, a real `TextInput` dialog with
  stable ids and submit wiring to `UserService.updateUser(field, value)`.
- Successful submit updates local page state and mirrors the updated raw user
  json back to `GlobalAuthStore` / `AppStorage`.
- `UserService.updateUser(field, value, dao)` now matches Compose
  `UserRepository.updateUserInfo`: it sends `PATCH /user` with a one-field JSON
  body and writes the GitHub response user to `UserDao` when a DAO is supplied.

## Evidence

- Compose runtime screenshot:
  `/tmp/compose-reference-20260530/personal-info.png`
- Focused OH device scenario:
  `/tmp/scenario-tour-20260530-115812/README.md`
- Result: `ok=1 fail=0 skip=34`, `asserts=27`, duplicate screenshots `NO`.
- Latest installed-HAP re-check after aligning update-user cache behavior:
  `/tmp/scenario-tour-20260530-130119/README.md`
  (`personal-info`; `SKIP_INSTALL=0`; `ok=1 fail=0 skip=36`, `asserts=27`,
  duplicate screenshots `NO`). This verifies the page still opens, refreshes,
  renders the six rows, and opens the edit dialog after sharing the same
  `UserDao` with the PATCH service path.
- Assertions prove:
  - drawer personal info reaches `person_info_root`
  - the Compose-like pull-refresh list wrapper is present through
    `person_info_pull_list`
  - all six field rows render, with stable row icon ids and first-row
    label/value ids
  - Compose terminal footer text renders through `person_info_no_more`
  - `appbar_title` stays inside `appbar_main_row`, covering the title-cropping
    regression
  - `person_info_row_name` has a non-flat screenshot crop, covering the
    low-contrast/blank-card regression path
  - row tap opens `person_info_edit_dialog_root`
  - dialog title, input, cancel, and confirm controls are present
- Screenshot evidence:
  `/tmp/scenario-tour-20260530-115812/27_personal-info.png`
- Build gate: `hvigorw assembleHap --mode module -p product=default --no-daemon`
  passed after the change.
- Logic gate: `harness/regression/reports/M5/summary.md` remains `exit=0`
  with `tests run=408`, `passed=408`, and `assertion errors=0`
  (`time=2026-05-30T05:00:37Z`). This includes
  `UserServiceTest.updateUser_uses_patch_user_json_body_and_writes_cache_like_compose`,
  which verifies URL `Address.getMyUserInfo()`, method `PATCH`,
  `Content-Type: application/json`, JSON body `{ "name": "Small Guo" }`, and
  the updated user row in `UserDao`.

## Current Gaps

- The scenario does not submit a real PATCH to avoid mutating the logged-in
  account during regression. The destructive UI submit remains intentionally
  out of unattended tours; the equivalent service contract is covered by the
  mock network logic test above.
