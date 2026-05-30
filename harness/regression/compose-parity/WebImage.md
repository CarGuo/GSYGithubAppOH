# Web / Image Compose Parity

## Compose Reference

Source files:

- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/login/src/main/java/com/shuyu/gsygithubappcompose/feature/login/OAuthWebView.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/home/src/main/java/com/shuyu/gsygithubappcompose/feature/home/HomeScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/code/src/main/java/com/shuyu/gsygithubappcompose/feature/code/FileCodeViewScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/detail/src/main/java/com/shuyu/gsygithubappcompose/feature/detail/readme/RepoDetailReadmeScreen.kt`

Observed behavior:

- Compose has an in-app OAuth WebView for login redirect handling.
- Compose uses WebView surfaces for README and code rendering in the relevant
  feature pages, not as a separate generic route.
- Update links and ReleaseEvent tarball links are opened through
  `Intent.ACTION_VIEW`.
- There is no Compose-only full-screen image preview route found in the current
  feature tree; image use is mostly avatar/content rendering through Coil.

## OH Status

- `LoginWebPage.ets` matches the OAuth concept: loads the authorization URL,
  enables JavaScript/dom storage, and intercepts the callback/deep link.
- `WebPage.ets` is retained as an OH generic web fallback route with AppBar,
  reload action, JavaScript/dom storage/mixed mode, stable ids, and `bootWeb`.
- `ExternalUrlUtil.ets` now provides the Compose-style external browser opener
  for update/release URLs. Dynamic, My/Profile, Repository activity, and
  UserDetail event rows pass this opener into `EventActionDispatcher`, so
  ReleaseEvent tarball links no longer default to the generic OH WebPage.
- `PhotoPage.ets` is retained as an OH generic image preview route with
  full-screen contain mode, click-to-dismiss, failure state, stable ids, and
  `bootPhoto`.
- Generic Web/Image routes are therefore compatibility routes rather than
  Compose-first feature pages, but they are now covered by automated UI
  evidence so existing callers stay usable.

## Automated Checks

- `scenario-tour.sh` adds `webPage`:
  `aa start --ps bootWeb "$DEMO_WEB"`.
- Default `DEMO_WEB` is `https://example.com` to avoid GitHub WebView
  throttling/slow-load false negatives; callers can override it when a real
  GitHub URL is required.
- `webPage` asserts `web_page_root`, `web_page_appbar`, `web_page_view`, the
  WebView content text `Example Domain`, and a non-flat `web_page_view`
  screenshot crop so a flat background cannot pass.
- `scenario-tour.sh` adds `photoPage`:
  `aa start --ps bootPhoto "$DEMO_PHOTO"`.
- `photoPage` asserts `photo_page_root`, `photo_image`, absence of
  `photo_loading`/`photo_failed`, and a non-flat `photo_image` screenshot crop
  so an empty Image node cannot pass.
- Latest OH evidence:
  `/tmp/scenario-tour-20260530-130803/README.md`
- Latest OH screenshots:
  `/tmp/scenario-tour-20260530-130803/22_webPage.png`
  `/tmp/scenario-tour-20260530-130803/23_photoPage.png`
- Latest focused Web/Image evidence:
  `/tmp/scenario-tour-20260530-130803/README.md`
  (`webPage`, `photoPage`; `SKIP_INSTALL=0`; `ok=2`, `fail=0`,
  `asserts=10`, duplicate screenshots `NO`). The WebView crop contains
  `Example Domain` and the image route crop is non-flat with no loading/error
  state left visible.

## Current Gaps

- Compose does not expose a matching generic WebPage/PhotoPage, so UI parity is
  judged by behavior and route coverage rather than one-to-one screen matching.
- A real GitHub repository URL was also tested through `bootWeb`; it reached
  the WebView and set the title to `github.com`, but the screenshot stayed
  blank in the short scenario window. The stable default now uses a lightweight
  page plus a screenshot non-flat check to verify rendering deterministically.
