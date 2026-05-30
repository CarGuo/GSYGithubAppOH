# User / Person Compose Parity

Reference:
- Compose `feature/profile/ProfileShared.kt`
- Compose `feature/profile/PersonScreen.kt`
- OH `entry/src/main/ets/pages/tabs/MyTabPage.ets`
- OH `entry/src/main/ets/widget/UserHeadItem.ets`
- OH `entry/src/main/ets/pages/UserDetailPage.ets`

## Compose Baseline

- `PersonScreen` uses a top app bar titled with the username and a follow FAB.
- `ProfileContent` renders `ProfileHeader` followed by either org members or user events.
- `ProfileHeader` contains avatar, display name, login, bio, location, company, joined date, four stats, and a dynamic section title.
- Stat routes are:
  - `list_screen/repositories/{login}/_`
  - `list_screen/follower/{login}/_`
  - `list_screen/following/{login}/_`
  - `list_screen/user_star/{login}/_`
- `ProfileScreen` uses the same `ProfileHeader` structure for the My tab:
  display name, login, optional bio/location/company, joined date, four stats,
  and the Activity Feed title in the primary header area.
- Joined time uses Compose `getRelativeTimeSpanString` behavior: just now,
  minutes, hours, days, months, then years, instead of falling back to an
  absolute date for older accounts.
- `ProfileScreen` renders a `Logout` button below `ProfileContent`.
- `ProfileHeader` does not make the avatar a settings entry; only the
  notification icon is actionable in the header.

## OH Status

- `MyTabPage` now maps the header like Compose: display name from `name`
  with login fallback, login from `login`, bio only when present, and joined
  date as a separate line.
- `TimeUtil.resolveTime(...)` now keeps older joined dates in Compose relative
  form (`8 years ago` / `8 年前`) instead of rendering `yyyy-MM-dd`.
- `UserHeadItem` now renders the My header with four Compose stats only:
  repositories, followers, following, stars, with labels matching Compose
  resources (`Repositories / Followers / Following / Stars` in English).
- The old RN-only My header pieces are removed from the visible surface:
  "honour"/be-stared stat, link placeholder, organization strip, and
  contribution heatmap.
- My header keeps the Activity Feed title inside the primary header block.
- My tab now keeps the Compose `Logout` button below the profile/event
  content, invokes the shared login use case logout flow, and navigates back to
  Login. English/Chinese logout text now matches Compose (`Logout` /
  `退出登录`) instead of the old `LoginOut` / `退出登陆` strings.
- The old OH/RN avatar-to-Setting shortcut has been removed from My tab. The
  avatar remains visible but does not route to `SettingPage`, matching Compose
  `ProfileHeader`.
- `UserDetailPage` now uses the plain login as the app bar title, matching Compose `PersonScreen`.
- `UserDetailPage` now matches Compose's optional profile fields: company,
  location, bio, and joined date render only when data exists; joined date is a
  separate line; the old RN blog row, organization strip, placeholder text, and
  avatar-to-Photo preview action are removed from this profile header.
- Stat row has the four Compose entries: repositories, followers, following, stars.
- Repositories and stars now navigate to `CommonList` instead of only logging.
- The old RN-only "honour" stat and contribution heatmap are removed from this page.
- A dynamic title row is rendered above the event/member list.
- Organization profiles now load `orgs/{org}/members` and render member rows
  instead of normal user events.
- Follow/unfollow is now a Compose-style floating action button at bottom right
  for normal users. Organization profiles hide this action.
- `UserService.getUser(login)` now mirrors Compose `UserRepository.getUser`:
  apply cached user detail from local DB first, then refresh from network and
  replace the store with the fresh response.
- `MyService.refreshMe()` now applies cached current-user info first when the
  logged-in login is known, then refreshes `GET /user` and updates the shared
  auth/profile store. Network fallback keeps the cached user for non-401
  failures.
- Organization member loading now mirrors Compose `getOrgMembers`: page 1
  reads `OrgMember` cache first and renders cached rows through the page
  callback before issuing the network request, then saves and displays the
  refreshed member list.

## Evidence

- OH scenario: `/tmp/scenario-tour-20260529-231043/README.md`
- Screenshots:
  - `/tmp/scenario-tour-20260529-231043/17_userDetail.png`
  - `/tmp/scenario-tour-20260529-231043/17_userDetail-repos.png`
- Result: `ok=1 fail=0 skip=16`, duplicate screenshots `NO`.
- Assertions include `user_detail_dynamic_title`, all four stat blocks, and absence of `user_detail_be_stared_block` and `user_detail_contribution`.
- Latest OH evidence: `/tmp/scenario-tour-20260530-030024/README.md`
- Result: `ok=26 fail=0 skip=0`, duplicate screenshots `NO`.
- Screenshots:
- `/tmp/scenario-tour-20260530-030024/17_userDetail.png`
- `/tmp/scenario-tour-20260530-030024/17_userDetail-repos.png`
- `/tmp/scenario-tour-20260530-030024/19_organization-profile.png`
- Latest focused User/Profile evidence:
  `/tmp/scenario-tour-20260530-024800/README.md`
- Assertions now cover the full Compose-style header surface:
  `user_detail_avatar`, `user_detail_name`, `user_detail_login`,
  optional `user_detail_company` / `user_detail_location` / `user_detail_bio`,
  all four stat blocks and labels, dynamic title bar, and follow FAB/icon for
  normal users.
- The normal user avatar, organization avatar, and first organization member
  avatar are covered by non-flat screenshot crop checks.
- Organization evidence asserts `user_detail_org_member_row_0`,
  `user_detail_org_member_avatar_0`, `user_detail_org_member_login_0`, and
  absence of follow actions and normal event rows.
- Latest UserDetail optional-field cleanup evidence:
  `/tmp/scenario-tour-20260530-062042/README.md`
- Latest UserDetail optional-field result: `ok=2 fail=0 skip=31`,
  `asserts=62`, duplicate screenshots `NO`. This run covers normal user and
  organization profile headers, `user_detail_joined`, absent
  `user_detail_blog` / `user_detail_orgs`, absent empty-field placeholder text,
  repository-list navigation, and organization member rows.
- Prior focused My/Profile evidence:
  `/tmp/scenario-tour-20260530-043923/README.md`
- Result: `ok=2 fail=0 skip=29`, `asserts=22`, duplicate screenshots `NO`.
- Screenshot:
  `/tmp/scenario-tour-20260530-043923/04_home-my.png`
- Latest full-run My/Profile evidence:
  `/tmp/scenario-tour-20260530-044058/README.md`
- Full result: `ok=31 fail=0 skip=0`, `asserts=346`, duplicate screenshots
  `NO`.
- Full-run screenshot:
  `/tmp/scenario-tour-20260530-044058/04_home-my.png`
- Layout evidence confirms `user_head_display_name = Small Guo`,
  `user_head_login = CarSmallGuo`, four stat cells only, absence of
  `user_head_counter_cell_beStared` and `user_head_link`, and joined date
  left-aligned with bounds `[35,740][1285,797]`.
- Latest My/Profile logout parity evidence:
  `/tmp/scenario-tour-20260530-062858/README.md`
- Result: `ok=1 fail=0 skip=32`, `asserts=18`, duplicate screenshots `NO`.
  This run covers `my_logout_btn`, visible `Logout` text, and absence of the
  old `LoginOut` / `退出登陆` text.
- Latest My/Profile avatar-static evidence:
  `/tmp/scenario-tour-20260530-063215/README.md`
- Result: `ok=2 fail=0 skip=31`, `asserts=25`, duplicate screenshots `NO`.
  This run taps the My avatar and verifies the app remains on `tab_page_root_my`
  with no `setting_root`, `setting_scroll`, or `setting_person_info_btn`.
- Latest My/Profile stat-label evidence:
  `/tmp/scenario-tour-20260530-064301/README.md`
- Result: `ok=2 fail=0 skip=32`, `asserts=29`, duplicate screenshots `NO`.
  This run verifies the Compose stat labels `Repositories`, `Followers`,
  `Following`, and `Stars` in the My header while retaining the avatar-static
  route check.
- Latest My/Profile relative-joined evidence:
  `/tmp/scenario-tour-20260530-064657/README.md`
- Result: `ok=2 fail=0 skip=32`, `asserts=30`, duplicate screenshots `NO`.
  Screenshot `/tmp/scenario-tour-20260530-064657/04_home-my.png` and the UI
  dump confirm `Joined: 8 years ago`, matching Compose relative year behavior,
  while retaining the stat-label and avatar-static route checks.
- Latest User/Profile cache-first evidence:
  `harness/regression/reports/M5/summary.md` (`tests run=403`, `passed=403`,
  `failed=0`, `time=2026-05-30T04:16:54Z`). Added assertions prove
  `UserService.getUser` and `MyService.refreshMe` apply local DB cached user
  data before issuing the HTTP request, then replace it with network data.
- Latest rebuilt-HAP User/Profile scenario:
  `/tmp/scenario-tour-20260530-121801/README.md`
- Result: `ok=3 fail=0 skip=32`, `asserts=86`, duplicate screenshots `NO`.
  This run covers `home-my`, `userDetail-list`, and `organization-profile`
  after the cache-first change, including My profile stat labels/logout,
  UserDetail optional fields, repository-list navigation, and organization
  member rows.
- Latest organization-member cache-first evidence:
  `harness/regression/reports/M5/summary.md` (`tests run=404`, `passed=404`,
  `failed=0`, `time=2026-05-30T04:22:34Z`). The new service assertion proves
  the organization member cache callback fires before the HTTP request and the
  refreshed network members are written back to `OrgMember`.
- Latest rebuilt-HAP organization profile scenario:
  `/tmp/scenario-tour-20260530-122252/README.md`
- Result: `ok=1 fail=0 skip=34`, `asserts=23`, duplicate screenshots `NO`.
  This confirms the organization profile still renders member rows, hides
  follow actions, and keeps the old normal event/blog/org strips absent after
  the cache-first change.

## Remaining Gaps

- Header spacing and typography are Compose-style and covered by screenshot
  evidence; pixel-perfect typography remains a polish item, not a functional
  or route gap.
- The org/member section is now structurally and visually smoke-tested with
  member row/avatar evidence. Pixel-level typography matching remains a visual
  refinement rather than an uncovered functional gap.
- No open old-RN header row gap remains for `UserDetailPage`.
