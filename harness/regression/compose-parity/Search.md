# Search Compose Parity

## Compose Reference

Source files:

- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/search/src/main/java/com/shuyu/gsygithubappcompose/feature/search/SearchScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/search/src/main/java/com/shuyu/gsygithubappcompose/feature/search/SearchViewModel.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/ui/src/main/java/com/shuyu/gsygithubappcompose/core/ui/components/GSYSearchInput.kt`

Runtime evidence:

- Compose emulator screenshot:
  `/tmp/gsy-compose-screens/search-after-tap.png`
- Compose UI dump:
  `/tmp/gsy-compose-screens/search-after-tap.xml`

Structure:

- Top app bar title is `Search`, with back button.
- Search field placeholder is `Search GitHub`, with a search icon.
- After input is non-empty, the trailing icon becomes Clear. The keyboard
  search action submits the query, while Repository/User buttons also submit
  the current text after changing the selected type.
- Empty query shows Repository/User buttons disabled. If search history is
  available and the field is active, Compose shows a `Search History` list.
- Search types are only Repository and User.
- Repository rows navigate to `repo_detail/{owner}/{name}`.
- User rows navigate to `person/{login}`.

## OH Changes

- `SearchPage.ets` no longer uses the old RN-style filter drawer in its main
  UI path.
- The page now renders a Compose-style input, search history list, and
  Repository/User type buttons with stable ids:
  `search_input`, `search_history_list`, `search_type_repo_btn`,
  `search_type_user_btn`.
- Successful first-page searches are saved through the existing
  `SearchHistoryManager`.
- The search field now mirrors Compose clear/search behavior: empty input shows
  `search_submit_icon`, non-empty input shows `search_clear_icon`, and tapping
  the trailing button clears input/results.
- Search history visibility now follows Compose focus rules: when the field is
  empty, Repository/User buttons remain on the first-open page; the history
  list appears only after the empty input gains focus and history exists.
- Repository/User buttons now submit the typed text even when the selected tab
  is clicked again, matching Compose's `performSearch()` behavior.
- Repository result rows now use `full_name` as the main
  `RepositoryItem` title, matching Compose's `toRepositoryDisplayData()`
  instead of the old OH/RN-style repo-name-only title.
- `EntryAbility.ets` adds the test-only `bootSearchHistory` parameter so
  focused device runs can seed history without touching token or login state.
- Existing search service methods are preserved so current service tests and
  compatibility callers keep working.

## Automated Checks

- `SearchHostPage` injects a memory `SearchHistoryManager` so UI tests can
  verify the history list without touching persistent user data.
- `SearchUiTest` now checks the Compose-style ids, focus-gated history, and row
  ids, including the `full_name` repository row title.
- Device scenario now performs typed Repository and User searches:
  `/tmp/scenario-tour-20260530-003439/README.md`
  - Result: ok=1, fail=0, skip=25, duplicate screenshots=NO.
  - Open-state screenshot:
    `/tmp/scenario-tour-20260530-003439/05_search-open.png`
  - Repository result screenshot:
    `/tmp/scenario-tour-20260530-003439/05_search.png`
  - User result screenshot:
    `/tmp/scenario-tour-20260530-003439/05_search-user.png`
  - Repository navigation screenshot:
    `/tmp/scenario-tour-20260530-003439/05_search-repo-detail.png`
  - User navigation screenshot:
    `/tmp/scenario-tour-20260530-003439/05_search-user-detail.png`
  - Assertions include `search_repo_0`, `search_user_0`,
    `search_clear_icon`, query/result texts, RepositoryDetail root/tabs,
    UserDetail root/counts, and absence of the old `search_filter_drawer`.
- Latest focus-gated history device run:
  `/tmp/scenario-tour-20260530-053938/README.md`
  - Result: ok=1, fail=0, skip=32, assertions=39, duplicate screenshots=NO.
  - Open-state screenshot:
    `/tmp/scenario-tour-20260530-053938/05_search-open.png`
  - Focused empty-input history screenshot:
    `/tmp/scenario-tour-20260530-053938/05_search-history.png`
  - Assertions include `search_type_button_row` plus absent
    `search_history_list` on first open, then `search_history_list` and
  `search_history_row_0` after focusing the empty input.
- Latest full-name repository row device run:
  `/tmp/scenario-tour-20260530-060928/README.md`
  - Result: ok=1, fail=0, skip=32, assertions=37, duplicate screenshots=NO.
  - Assertions include `search_repo_0_name` and text `CarGuo/`, proving the
    repository row title is the Compose-style full name rather than only the
    repository short name.

## Current Gaps

- No blocking Search gap in the first pass. Open state, focus-gated history,
  Repository/User typed search, and result navigation into
  RepositoryDetail/UserDetail are covered by the device tour.
