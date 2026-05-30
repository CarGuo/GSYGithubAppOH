# List Compose Parity

Reference:
- Compose `feature/list/ListScreen.kt`
- Compose `feature/list/ListViewModel.kt`
- OH `entry/src/main/ets/pages/CommonListPage.ets`

## Compose Baseline

- Route shape is `list_screen/{listType}/{username}/{repoName}`.
- User profile entries use `repositories`, `follower`, `following`, and `user_star`.
- Compose `ListViewModel` also supports `user_orgs`, loading
  `users/{username}/orgs` and mapping organizations into user-style rows.
- Repository detail entries use `stargazers`, `forks`, and `watchers`.
- Repository topic chips open `topics`, which searches repositories with
  `topic:<topic>`, sorted by stars descending.
- Rows are typed:
  - repository rows open `repo_detail/{owner}/{name}`
  - user rows open `person/{login}`

## OH Status

- `CommonListPage` accepts Compose aliases:
  - `repositories` maps to existing `user_repos` data loading.
  - `following` maps to existing `followed` data loading.
  - `repo_star` maps to `stargazers`.
  - `repo_watcher` maps to `watchers`.
  - `repo_fork` maps to `forks`.
  - `topics` maps to repository search `q=topic:<topic>&sort=stars&order=desc`.
  - `user_orgs` maps to `users/{username}/orgs` and renders user-style
    organization rows, matching Compose's `USER_ORGS` branch.
- `CommonListPage` now loads repository stargazers, watchers, and forks via
  `RepositoryService`.
- `CommonListPage` now loads topic result repositories via
  `RepositoryService.searchTopicRepos`.
- The id prefix keeps the incoming Compose type, so regression can assert `common_list_repositories_root`.
- Repository row navigation now passes `owner`, `name`, and `fullName` while keeping legacy `ownerName` / `reposName` compatibility.
- User rows now render through the shared `UserItem` card, matching Compose
  `core/ui/components/UserItem.kt` and `GSYCardItem`: white surface, 8dp
  radius, outline, shadow, and page-background contrast instead of a plain
  white row on a white list.
- List titles now follow Compose `ListViewModel` mapping instead of caller-provided labels:
  - user repositories: `CarGuo 的仓库` / `CarGuo repos`
  - user followers: `CarGuo 的粉丝` / `CarGuo followers`
  - user following: `CarGuo 的关注` / `CarGuo following`
  - user starred repositories: `CarGuo 的星标` / `CarGuo star`
  - repository stargazers: `GSYGithubApp 的关注者` / `GSYGithubApp stargazers`
  - repository forks: `GSYGithubApp 的复刻` / `GSYGithubApp forks`
  - repository watchers: `GSYGithubApp 的订阅者` / `GSYGithubApp watchers`
  - topic repository search: `github 的主题` / `github topics`

## Evidence

- OH scenario: `/tmp/scenario-tour-20260529-231043/README.md`
- `user_detail_repos_block` tap reached `common_list_repositories_root`.
- Latest combined OH scenario: `/tmp/scenario-tour-20260529-232223/README.md`
- `repo_header_bottom_cell_star` tap reached `common_list_stargazers_root`.
- Combined result: `ok=3 fail=0 skip=16`; duplicate screenshots `NO`.
- Fork/watch OH scenario: `/tmp/scenario-tour-20260529-232502/README.md`
- `repo_header_bottom_cell_fork` tap reached `common_list_forks_root`.
- `repo_header_bottom_cell_watch` tap reached `common_list_watchers_root`.
- Fork/watch result: `ok=2 fail=0 skip=19`; duplicate screenshots `NO`.
- Latest title-parity OH scenario: `/tmp/scenario-tour-20260530-004608/README.md`
- Title assertions passed for:
  - `17_userDetail-repos.json`: `CarGuo 的仓库`
  - `18_repoDetail-stargazers.json`: `GSYGithubApp 的关注者`
  - `20_repoDetail-forks.json`: `GSYGithubApp 的复刻`
  - `21_repoDetail-watchers.json`: `GSYGithubApp 的订阅者`
- Latest title-parity result: `ok=4 fail=0 skip=22`; duplicate screenshots `NO`.
- Latest typed-row List evidence:
  `/tmp/scenario-tour-20260530-025826/README.md`
- Typed-row result: `ok=4 fail=0 skip=22`; duplicate screenshots `NO`.
- Latest full OH scenario including typed-row List checks:
  `/tmp/scenario-tour-20260530-030024/README.md`
- Full result: `ok=26 fail=0 skip=0`, `asserts=260`; duplicate screenshots
  `NO`.
- Typed-row assertions passed for:
  - `17_userDetail-repos.json`: repository row ids
    `common_list_repositories_repo_0`, avatar, name, owner text; absence of
    `common_list_repositories_user_0`; avatar crop non-flat.
  - `18_repoDetail-stargazers.json`: user row ids
    `common_list_stargazers_user_0`, avatar, login; absence of
    `common_list_stargazers_repo_0`; avatar crop non-flat.
  - `20_repoDetail-forks.json`: repository row ids
    `common_list_forks_repo_0`, avatar, name, owner text; absence of
    `common_list_forks_user_0`; avatar crop non-flat.
  - `21_repoDetail-watchers.json`: user row ids
    `common_list_watchers_user_0`, avatar, login; absence of
    `common_list_watchers_repo_0`; avatar crop non-flat.
- Latest repository-row navigation evidence:
  `/tmp/scenario-tour-20260530-125023/README.md`
- `userDetail-list` result: `ok=1 fail=0 skip=36`, `asserts=43`, duplicate
  screenshots `NO`.
- The run taps `common_list_repositories_repo_0` and verifies the target
  RepositoryDetail page via `repo_detail_root`, `appbar_root`, `appbar_title`,
  and `repo_header_name`, matching Compose `RepositoryItem` navigation.
- Latest user-row navigation evidence:
  `/tmp/scenario-tour-20260530-125113/README.md`
- `repoDetail-stargazers-list` result: `ok=1 fail=0 skip=36`, `asserts=13`,
  duplicate screenshots `NO`.
- The run taps `common_list_stargazers_user_0` and verifies the target
  UserDetail page via `user_detail_root`, `user_detail_avatar`, and
  `user_detail_login`, matching Compose `UserItem` navigation.
- Latest Profile list branch evidence:
  `/tmp/scenario-tour-20260530-131923/README.md`
- Profile branch result: `ok=3 fail=0 skip=37`, `asserts=36`, duplicate
  screenshots `NO`.
- This run drives Compose profile list types directly through `bootCommonList`:
  - `follower`: user-style row ids, title `CarGuo 的粉丝`, no repository row,
    non-flat avatar crop, and row click reaches UserDetail.
  - `following`: user-style row ids, title `CarGuo 的关注`, no repository row,
    non-flat avatar crop, and row click reaches UserDetail.
  - `user_star`: repository-style row ids, title `CarGuo 的星标`, no user row,
    non-flat repository avatar crop, and row click reaches RepositoryDetail.
- Latest Compose-card user row evidence after the contrast/UI review:
  `/tmp/scenario-tour-20260530-132923/README.md`
- Card row result: `ok=4 fail=0 skip=36`, `asserts=46`, duplicate screenshots
  `NO`.
- This run verifies `stargazers`, `user_orgs`, `follower`, and `following`
  user lists after replacing the old plain row with shared `UserItem` card ids
  (`*_user_0`, `*_user_0_avatar`, `*_user_0_login`) and re-checks row taps to
  UserDetail.
- Latest topic List evidence:
  `/tmp/scenario-tour-20260530-050121/README.md`
- Topic result: `ok=1 fail=0 skip=31`, `asserts=14`, duplicate screenshots
  `NO`.
- Topic assertions passed for:
  - `32_repoDetail-before-topic.json`: topic group and first topic chip.
  - `32_repoDetail-topic.json`: `common_list_topics_root`, topic title,
    repository row ids, absence of a user-row template, and non-flat repo
    avatar crop.
  - `32_repoDetail-topic-repo.json`: tapping the topic repository row reaches
    `repo_detail_root` with `repo_detail_tabs`.
- Latest `user_orgs` evidence:
  `/tmp/scenario-tour-20260530-122808/README.md`
- `user_orgs` result: `ok=1 fail=0 skip=35`, `asserts=9`, duplicate
  screenshots `NO`.
- The run uses the new `bootCommonList` test entry and asserts
  `common_list_user_orgs_root`, user-style organization row ids, the Compose
  title `yyx990803 的组织`, absence of repository row ids, and a non-flat
  organization avatar crop.
- Latest logic gate:
  `harness/regression/reports/M5/summary.md` (`tests run=410`, `passed=410`,
  `failed=0`, `time=2026-05-30T05:31:44Z`). This includes
  `UserServiceTest.getUserOrgs_uses_compose_user_orgs_url`.

## Remaining Gaps

- None found in the covered user/repository/follower/following/star/topic/
  organization list flows.
