# History Compose Parity

## Compose Reference

Source files:

- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/history/src/main/java/com/shuyu/gsygithubappcompose/feature/history/HistoryScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/data/src/main/java/com/shuyu/gsygithubappcompose/data/repository/HistoryRepository.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/data/src/main/java/com/shuyu/gsygithubappcompose/data/repository/mapper/DataMappers.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/ui/src/main/java/com/shuyu/gsygithubappcompose/core/ui/components/RepositoryItem.kt`

Runtime evidence:

- Compose emulator screenshot:
  `/tmp/gsy-compose-screens/history-page.png`
- Compose UI dump:
  `/tmp/gsy-compose-screens/history-page.xml`

Structure:

- Top app bar title is `History`, with back button.
- Content is a repository list using `RepositoryItem`.
- The list maps `HistoryEntity.data` back to `Repository`, then uses
  `toRepositoryDisplayData()` so rows show full name, language, description,
  stars, forks, and avatar from the saved repository detail payload.
- Rows navigate to `repo_detail/{owner}/{name}`.
- There are no type tabs, no clear button, and no visible empty-state message
  in the current empty-list Compose run.

## OH Changes

- `ReadHistoryPage.ets` no longer renders the old All/Repository/User tabs.
- The page no longer exposes the old clear action or bottom clear button.
- The list is filtered to repository history and renders via `RepositoryItem`.
- Empty history now matches the current Compose empty page: blank content under
  the app bar, without the old OH empty text or load-more footer.
- Row ids remain stable as `read_history_row_N` for scenario and Hypium tests.
- History rows now parse `ReadHistoryItem.payloadJson` to restore Compose-like
  repository display data: full name, owner avatar/login, language,
  description, stars, forks, and watchers. The old `---` stat placeholders are
  gone for saved repository detail records.
- `RepositoryItem` exposes stable stat text ids:
  `read_history_row_N_star_text`, `read_history_row_N_fork_text`, and
  `read_history_row_N_watch_text`.
- `EntryAbility.ets` initializes `RdbStore` at app startup, so repository/user
  detail pages can persist real read-history records instead of silently
  failing before the database is ready.

## Automated Checks

- `ReadHistoryUiTest` checks the app bar, repository-only list behavior,
  payload-backed language/star/fork/watch values, and row navigation into
  repository detail.
- `scenario-tour.sh` opens History from the Compose-style home drawer through
  `my-readHistory`.
- `my-readHistory` now first opens `DEMO_REPO` through `bootRepo`, waits for
  real repository content, then enters History and asserts `read_history_row_0`,
  owner text, language id, and stat ids. The text assert deliberately uses the
  owner because GitHub may return a canonical `full_name` with different case
  from the scripted input.
- The same scenario taps `read_history_row_0` and asserts it routes back to
  RepositoryDetail with `repo_detail_root`, `appbar_root`, `appbar_title`, and
  `repo_header_name`, matching Compose row navigation to `repo_detail/{owner}/{name}`.
- Latest OH evidence:
  `/tmp/gsy-oh-compose-notify-history-20260529-224140/README.md`
- Latest OH screenshot:
  `/tmp/gsy-oh-compose-notify-history-20260529-224140/12_my-readHistory.png`
- Latest seeded non-empty OH evidence:
  `/tmp/scenario-tour-20260530-124642/README.md`
- Latest seeded non-empty OH screenshot:
  `/tmp/scenario-tour-20260530-124642/12_my-readHistory.png`
- Latest History row route screenshot:
  `/tmp/scenario-tour-20260530-124642/12_my-readHistory-repoDetail.png`

## Current Gaps

- No covered History gaps remain in this pass. The current automated evidence
  includes both the Compose-style empty-page shape and a seeded non-empty OH
  repository row, including row-to-RepositoryDetail navigation.
