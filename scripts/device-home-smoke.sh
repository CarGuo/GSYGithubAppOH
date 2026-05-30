#!/usr/bin/env bash
# device-home-smoke.sh —— R5 真机回归：通过 want bootToken 注入 PAT，跳过登录直达 HomePage
# 用法：
#   GH_TOKEN=ghp_xxxx bash scripts/device-home-smoke.sh
# 产出：
#   harness/regression/reports/M6/home-smoke-<ts>/
#     - 01_welcome.png/.json
#     - 02_home_dynamic.png/.json
#     - 03_home_trend.png/.json
#     - 04_home_my.png/.json
#     - device.txt / install.log / start.log / hilog_business.log / asserts.log

set -uo pipefail

BUNDLE="cn.gsy.githubapp"
ABILITY="EntryAbility"
TARGET="${HDC_TARGET:-127.0.0.1:5555}"
HAP_PATH="${HAP_PATH:-entry/build/default/outputs/default/entry-default-signed.hap}"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${OUT_DIR:-harness/regression/reports/M6/home-smoke-${TS}}"
TOKEN="${GH_TOKEN:-}"
PYFIND="python3 scripts/uitest_find.py"

if [ -z "$TOKEN" ]; then
  echo "[home-smoke] ERROR: GH_TOKEN env not set"
  exit 1
fi

mkdir -p "$OUT_DIR"
ASSERT_LOG="$OUT_DIR/asserts.log"
: > "$ASSERT_LOG"
echo "[home-smoke] target=$TARGET out=$OUT_DIR"

snap () {
  local name="$1"
  hdc -t "$TARGET" shell uitest screenCap -p "/data/local/tmp/${name}.png" >/dev/null 2>&1 || true
  hdc -t "$TARGET" file recv "/data/local/tmp/${name}.png" "$OUT_DIR/${name}.png" >/dev/null 2>&1 || true
  hdc -t "$TARGET" shell uitest dumpLayout -p "/data/local/tmp/${name}.json" >/dev/null 2>&1 || true
  hdc -t "$TARGET" file recv "/data/local/tmp/${name}.json" "$OUT_DIR/${name}.json" >/dev/null 2>&1 || true
  echo "[home-smoke] snap → ${name}"
}

assert_id_in () {
  local layout="$1"; shift
  for id in "$@"; do
    if ! $PYFIND "$layout" "$id" >/dev/null 2>&1; then
      echo "[FAIL] id '$id' missing in $(basename "$layout")" | tee -a "$ASSERT_LOG"
    else
      echo "[OK]   id '$id' present in $(basename "$layout")" | tee -a "$ASSERT_LOG"
    fi
  done
}

assert_id_absent () {
  local layout="$1"; shift
  for id in "$@"; do
    if $PYFIND "$layout" "$id" >/dev/null 2>&1; then
      echo "[FAIL] id '$id' SHOULD NOT exist in $(basename "$layout")" | tee -a "$ASSERT_LOG"
    else
      echo "[OK]   id '$id' absent in $(basename "$layout")" | tee -a "$ASSERT_LOG"
    fi
  done
}

tap_id () {
  local layout="$1" id="$2"
  COORDS=$($PYFIND "$layout" "$id" 2>/dev/null) || { echo "[home-smoke] tap_id NOT_FOUND: $id"; return 1; }
  read CX CY <<<"$COORDS"
  echo "[home-smoke] tap id=$id at ($CX,$CY)"
  hdc -t "$TARGET" shell uitest uiInput click "$CX" "$CY" >/dev/null 2>&1
}

# 1. device alive
hdc -t "$TARGET" shell param get const.product.model > "$OUT_DIR/device.txt" 2>&1
hdc -t "$TARGET" shell param get const.product.software.version >> "$OUT_DIR/device.txt" 2>&1 || true

# 2. (re)install + force-stop
hdc -t "$TARGET" install -r "$HAP_PATH" 2>&1 | tee "$OUT_DIR/install.log" >/dev/null
hdc -t "$TARGET" shell aa force-stop "$BUNDLE" >/dev/null 2>&1 || true
sleep 1

# 3. start ability with bootToken want param + hilog tail
hdc -t "$TARGET" shell aa start -a "$ABILITY" -b "$BUNDLE" --ps bootToken "$TOKEN" 2>&1 | tee "$OUT_DIR/start.log" >/dev/null
hdc -t "$TARGET" hilog -T 0x0666 > "$OUT_DIR/hilog_business.log" &
HILOG_PID="${!:-0}"
sleep 2

# 4. welcome
snap "01_welcome"
assert_id_in "$OUT_DIR/01_welcome.json" "welcome_root"

# WelcomePage 3000ms 后路由到 Home（注入了 bootToken），再加 fetchUser 网络耗时
sleep 8

# 5. Home Dynamic
snap "02_home_dynamic"
assert_id_in "$OUT_DIR/02_home_dynamic.json" \
  "home_main_content" "home_appbar" "home_tabs" \
  "home_tab_bar_dynamic" "home_tab_bar_trend" "home_tab_bar_my" \
  "tab_page_root_dynamic"
assert_id_absent "$OUT_DIR/02_home_dynamic.json" \
  "home_tab_bar_recommend" "home_drawer_title" "home_drawer_close_btn" \
  "home_double_tap_count"

# 6. tap trend tab
tap_id "$OUT_DIR/02_home_dynamic.json" "home_tab_bar_trend"
sleep 3
snap "03_home_trend"
assert_id_in "$OUT_DIR/03_home_trend.json" "tab_page_root_trend"

# 7. tap my tab
tap_id "$OUT_DIR/03_home_trend.json" "home_tab_bar_my"
sleep 3
snap "04_home_my"
assert_id_in "$OUT_DIR/04_home_my.json" "tab_page_root_my"

# tail hilog
[ "$HILOG_PID" != "0" ] && kill "$HILOG_PID" 2>/dev/null || true

# 8. summary
{
  echo "# home-smoke ${TS}"
  echo "- target: $TARGET"
  echo "- bundle: $BUNDLE"
  echo "- hap: $HAP_PATH"
  echo
  echo "## artifacts"
  ls -1 "$OUT_DIR" | sed 's/^/  - /'
  echo
  echo "## asserts"
  cat "$ASSERT_LOG" | sed 's/^/  /'
} > "$OUT_DIR/README.md"

if grep -q "\[FAIL\]" "$ASSERT_LOG"; then
  echo "[home-smoke] FAIL → $OUT_DIR"
  exit 4
fi
echo "[home-smoke] PASS → $OUT_DIR"
