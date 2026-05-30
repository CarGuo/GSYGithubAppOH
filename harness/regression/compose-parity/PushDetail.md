# PushDetail Compose Parity

## Compose Reference

Source file:

- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/push/src/main/java/com/shuyu/gsygithubappcompose/feature/push/PushDetailScreen.kt`

Structure:

- Top app bar title is `owner/repo`, with back button.
- Header card shows avatar, changed/added/deleted stats, relative commit time,
  and commit message.
- Each changed file renders optional parent path text and a card containing a
  file icon plus the file name.
- Tapping a file opens `file_code/{owner}/{repo}/{path}?sha={sha}`.

## OH Changes

- `PushDetailPage.ets` now titles the page with `fullName` instead of the short
  SHA.
- Header card was reshaped toward Compose: avatar slot, stats row, relative
  date, and bold message.
- Header card is now the first item inside the file list, matching Compose's
  `GSYPullRefresh` content where the commit header scrolls with changed files.
- The previous file-list divider was removed because Compose uses spaced card
  rows rather than a divided fixed list.
- File rows now split path and file name, use card styling, and keep
  `push_detail_file_row_N` / `push_detail_file_filename_N` ids.
- File row click now has regression coverage for the Compose flow into
  CodeDetail using the commit SHA as the file revision.
- PushDetail now passes `sha` to CodeDetail instead of treating the commit SHA
  as a branch/ref. `CodeService.getCommitFile` matches Compose's
  `getCommitFile`: fetch commit detail, find the changed file by filename, and
  render `file.patch` in CodeDetail.

## Automated Checks

- Existing `pushDetail` scenario drives the boot route:
  `aa start --ps bootPush "fullName|sha"`.
- The default boot sample now uses a stable commit with a GitHub author avatar:
  `CarGuo/GSYGithubApp|f55e749811b2f266979ff4e4355f253e28edd5c6`.
- The scenario asserts `push_detail_file_list`,
  `push_detail_header_list_item`, `push_detail_author_avatar`,
  `push_detail_stats_row`, `push_detail_message_text`,
  `push_detail_file_row_0`, and `push_detail_file_filename_0`, then checks the
  avatar bounds in the screenshot are non-flat so an empty avatar slot cannot
  pass as parity.
- The scenario also taps `push_detail_file_row_0`, waits for CodeDetail, and
  asserts `code_detail_appbar`, `code_detail_web`, a patch marker (`@@`), the
  absence of full README content (`English Readme`), and a non-flat Web crop so
  the PushDetail -> CodeDetail route cannot pass by rendering only the file
  list or by showing the complete file instead of the commit patch.
- Latest OH evidence:
  `/tmp/scenario-tour-20260530-014737/README.md`
- Latest OH screenshot:
  `/tmp/scenario-tour-20260530-014737/13_pushDetail.png`
- Latest full OH evidence:
  `/tmp/scenario-tour-20260530-030024/README.md`
  with result `ok=26 fail=0 skip=0`, duplicate screenshots `NO`.
- Latest PushDetail -> CodeDetail route evidence:
  `/tmp/scenario-tour-20260530-040030/README.md`
  with result `ok=1 fail=0 skip=30`, `asserts=10`, duplicate screenshots
  `NO`.
- Latest route screenshots:
  `/tmp/scenario-tour-20260530-040030/13_pushDetail.png`
  `/tmp/scenario-tour-20260530-040030/13_pushDetail-codeDetail.png`
- Latest header-in-list evidence:
  `/tmp/scenario-tour-20260530-054307/README.md`
  with result `ok=1 fail=0 skip=32`, `asserts=12`, duplicate screenshots
  `NO`. This covers the Compose-style header list item plus the existing
  PushDetail -> CodeDetail click-through.
- Latest header-in-list screenshots:
  `/tmp/scenario-tour-20260530-054307/13_pushDetail.png`
  `/tmp/scenario-tour-20260530-054307/13_pushDetail-codeDetail.png`
- Latest commit-patch CodeDetail evidence:
  `/tmp/scenario-tour-20260530-124046/README.md`
  with result `ok=1 fail=0 skip=36`, `asserts=14`, duplicate screenshots
  `NO`. This run verifies the CodeDetail snapshot reached from PushDetail
  contains `@@` and no longer contains the full README text `English Readme`.
- Logic evidence:
  `harness/regression/reports/M5/summary.md` now reports `tests run: 407`,
  `passed: 407`, and includes
  `CodeService_getCommitFile_loads_patch_from_commit_sha_like_compose`.

## Current Gaps

- No blocking PushDetail gap remains in this pass. The previous empty-avatar
  evidence was caused by the default sample commit having `author=null` in the
  GitHub commit API response, not by missing OH rendering behavior.
- PushDetail file-to-CodeDetail navigation is now covered by click-through
  evidence that verifies commit patch semantics, and the commit header now
  shares the file list's scroll surface.
