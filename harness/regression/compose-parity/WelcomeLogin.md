# Welcome / Login Compose Parity

## Compose Reference

Source files:

- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/welcome/src/main/java/com/shuyu/gsygithubappcompose/feature/welcome/WelcomeScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/welcome/src/main/java/com/shuyu/gsygithubappcompose/feature/welcome/WelcomeViewModel.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/login/src/main/java/com/shuyu/gsygithubappcompose/feature/login/LoginScreen.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/login/src/main/java/com/shuyu/gsygithubappcompose/feature/login/OAuthWebView.kt`
- `https://github.com/CarGuo/GSYGithubAppCompose/blob/master/core/ui/src/main/java/com/shuyu/gsygithubappcompose/core/ui/components/LanguageSelectDialog.kt`

Observed behavior:

- Welcome keeps a minimum 2 second splash before routing to Home or Login.
- Login is a centered card on a dark primary background.
- Login card contains logo, title/subtitle, token password field, helper text,
  Login and OAuth buttons, and a language switch entry.
- Login language switch opens `LanguageSelectDialog`: an alert with System /
  Chinese / English radio rows, no confirm button, and row tap applies the
  language then closes.
- OAuth opens an in-app WebView with a top app bar titled GitHub Authorization.
- OAuth authorization URL uses Compose's redirect/scope:
  `gsygithubapp://authed` and
  `user,repo,gist,notifications,read:org,workflow`.

## OH Changes

- `WelcomePage.ets` delay is now 2 seconds and exposes
  `welcome_root`, `welcome_image`, and `welcome_subtitle`.
- `WelcomePage.ets` now renders a shared ArkUI HarmonyOS mark animation through
  `HarmonyLogoMark.ets`: `welcome_harmony_mark`, `welcome_harmony_letter`,
  `welcome_harmony_label`, and the orbit-dot ids. `bootWelcomeHold` keeps
  Welcome visible only for regression screenshots.
- The Welcome subtitle is `HarmonyOS`, not Compose's Android-only
  `Jetpack Compose` label.
- `EntryAbility.ets` adds `bootLogin`, which forces the Login page for
  regression without clearing an existing token.
- `LoginPage.ets` now uses the Compose card layout and direct PAT field:
  `login_token_input`, `login_submit_btn`, `login_oauth_btn`,
  `login_language_btn`.
- `LoginPage.ets` now exposes the same shared ArkUI Harmony logo animation
  through `login_logo`, `login_logo_harmony_letter`, and the orbit-dot ids.
- The PAT field now mirrors Compose's leading `Key` icon through
  `login_token_field` and `login_token_leading_icon`.
- Token login no longer requires the old prompt. The submit button calls the
  same PAT login use case with the field value.
- Login language selection now uses the same row/radio shape as Compose and
  persists through `SettingPageHelper.applyLanguage(...)`; the previous Cancel
  button is removed.
- `LoginWebPage.ets` title now uses the Compose GitHub Authorization copy.
- OAuth callback handling now matches Compose's single `onCodeReceived ->
  handleOAuthCode` flow: `LoginWebPage` publishes the callback and returns,
  `LoginPage` consumes it, and `EntryAbility` only forwards external scheme
  wants into the same pending callback bus.
- OAuth redirect/scope now match Compose exactly:
  `gsygithubapp://authed` plus
  `user,repo,gist,notifications,read:org,workflow`; the Ability `viewData`
  skill is registered for the same `gsygithubapp` scheme.
- The old username/password/register/PAT probe nodes are removed from the UI
  tree; login exposes only the Compose token/OAuth/language surface.

## Automated Checks

- `scenario-tour.sh` adds `welcome`, `welcomeAnimation`, `loginPage`,
  `loginOAuth`, `loginLanguage`, and `loginAnimation`.
- `welcome` cold-starts the app and screenshots the splash before routing.
- `welcomeAnimation` starts Welcome with `bootWelcomeHold`, captures two
  screenshots, and asserts the Harmony mark, label, letter, orbit-dot ids
  remain present and the PNGs differ.
- `loginPage` starts with `aa start --ps bootLogin true` and checks the visible
  Compose login card ids, including the token field's leading key icon.
  It also asserts the old hidden legacy probes are absent:
  `login_legacy_probe`, `login_username_input`, `login_password_input`,
  `login_register_link`, and `login_pat_btn`.
- `loginOAuth` taps `login_oauth_btn` and verifies `login_web_root`,
  `login_web_appbar`, and `login_web_view`.
- `OauthServiceTest` covers the pending callback path and asserts one callback
  produces exactly one `login/oauth/access_token` request.
- `OauthServiceTest` now also asserts the default authorization URL constants
  and legacy `Address.getAuthorizationWeb(...)` helper match the Compose
  redirect/scope.
- `loginLanguage` taps `login_language_btn`, verifies the three option/label
  and radio ids, and asserts the old `login_language_cancel_btn` is absent.
- `loginAnimation` starts Login with `bootLogin`, captures two screenshots, and
  asserts `login_logo`, `login_logo_harmony_letter`, the orbit-dot ids, and the
  localized HarmonyOS subtitle are present while the PNGs differ.
- Latest OH evidence:
  `/tmp/scenario-tour-20260530-061244/README.md`
  with result `ok=1 fail=0 skip=32`, `asserts=17`, duplicate screenshots
  `NO`. This run covers the Compose login card and absence of old RN
  username/password/register/PAT probe ids.
- Latest full OH tour:
  `/tmp/scenario-tour-20260530-030024/README.md`
- Token login evidence, with token read from Compose `local.properties` and not
  written to logs/reports:
  `/tmp/gsy-oh-token-login-20260529-2354/after.png`
- Latest OH screenshots:
  `/tmp/scenario-tour-20260530-030024/24_welcome.png`
  `/tmp/scenario-tour-20260530-030024/25_loginPage.png`
  `/tmp/scenario-tour-20260530-030024/26_loginOAuth.png`
- Latest OAuth entry evidence:
  `/tmp/scenario-tour-20260530-131605/README.md`
  with result `ok=1 fail=0 skip=36`, `asserts=5`, duplicate screenshots
  `NO`. This run asserts the OAuth WebView URL contains
  `redirect_uri=gsygithubapp` and the encoded Compose scope
  `user,repo,gist,notifications,read:org,workflow`.
- Latest Login language evidence:
  `/tmp/scenario-tour-20260530-033141/README.md`
  with result `ok=1 fail=0 skip=28`, `asserts=13`, duplicate screenshots `NO`.
- Latest Welcome/Login animation evidence:
  `/tmp/scenario-tour-20260530-082802/README.md`
  with `welcomeAnimation` and `loginAnimation` passing, duplicate screenshots
  `NO`.
- Latest localized Login animation evidence:
  `/tmp/scenario-tour-20260530-093126/README.md`
  with `loginAnimation` passing in the current Chinese runtime locale
  (`HarmonyOS 版本`), `ok=1 fail=0 skip=34`, duplicate screenshots `NO`.
- Latest rebuilt-HAP Welcome/Login animation evidence:
  `/tmp/scenario-tour-20260530-115340/README.md`
  with `welcomeAnimation` and `loginAnimation` passing, `ok=5 fail=0 skip=30`,
  `asserts=55`, duplicate screenshots `NO`. This run also covers
  `repoDetail-readme`, `repoDetail-file`, and `codeDetail` after installing the
  rebuilt package.
- Latest Hypium logic-only evidence:
  `harness/regression/reports/M5/summary.md`
  with `exit=0`, `tests run=410`, `passed=410`, `assertion errors=0`,
  `time=2026-05-30T05:14:51Z`. The new OAuth test asserts the Compose
  redirect/scope constants and the legacy authorization URL helper.

## Current Gaps

- Welcome/Login animation intentionally no longer reuses the Compose Kotlin
  Lottie JSON assets. Per OH branding feedback it uses lightweight ArkUI
  HarmonyOS mark animations, with no rawfile Lottie bundle left in the app.
- OAuth authorization can open the GitHub WebView, and callback exchange is
  covered with a mocked access-token response so no credential or secret is
  written to logs. A real GitHub authorization submission still depends on
  external account interaction and remains outside automated submission.
