#!/usr/bin/env bash
# scenario-tour.sh —— 全 App 场景测试驱动 v2（hdc + hilog + 截图 + 等待 + 断言）
#
# v1 教训（2026-05-25 真机回归发现）：
#   1. dwell 模式无人值守 = 必出 12 张同款截图（md5 重复），毫无价值
#   2. hilog -T 0x0666 抓不到 cn.gsy 业务日志（实际 domain=A00000，要用 -P PID）
#   3. App 异步加载用户数据 → 截图先于数据 → my 页全是 ---
#
# v2 改造：
#   1. 全自动推页：以"已登录"为前提，用 tap_id（坐标）+ aa start --PS（want 参数）推页
#   2. 异步等待：wait_for_id / wait_for_text 轮询 dumpLayout，直到关键 id/text 出现或超时
#   3. hilog 双源：hdc shell hilog -P <pid> 抓 cn.gsy 业务日志 + 脚本侧 echo file marker 做切片
#   4. md5 去重：跑完汇总，重复 md5 ≥3 张直接判失败，杜绝"同图蒙混"
#   5. 产物路径：默认 /tmp/scenario-tour-<ts>/，每次 run 一个独立目录，不入库
#
# 用法：
#   bash scripts/scenario-tour.sh                                # 全 16 场景
#   SCENARIOS="launch home-dynamic" bash scripts/scenario-tour.sh
#   HDC_TARGET=127.0.0.1:5555 SKIP_INSTALL=1 bash scripts/scenario-tour.sh
#
# 退出码：
#   0  全部通过
#   2  设备离线
#   3  HAP 缺失
#   4  场景执行异常或截图重复
#   5  关键断言失败

set -uo pipefail

BUNDLE="cn.gsy.githubapp"
ABILITY="EntryAbility"
TARGET="${HDC_TARGET:-127.0.0.1:5555}"
HAP_PATH="${HAP_PATH:-entry/build/default/outputs/default/entry-default-signed.hap}"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${OUT_DIR:-/tmp/scenario-tour-$TS}"
SKIP_INSTALL="${SKIP_INSTALL:-1}"
SCENARIO_DELAY="${SCENARIO_DELAY:-2}"
WAIT_MAX="${WAIT_MAX:-15}"
PYFIND="python3 scripts/uitest_find.py"
DEMO_REPO="${DEMO_REPO:-CarGuo/GSYGithubApp}"
DEMO_REPO_OWNER="${DEMO_REPO%%/*}"
DEMO_REPO_NAME="${DEMO_REPO##*/}"
DEMO_BRANCH_SELECT="${DEMO_BRANCH_SELECT:-add-license-1}"
DEMO_PUSH="${DEMO_PUSH:-CarGuo/GSYGithubApp|f55e749811b2f266979ff4e4355f253e28edd5c6}"
DEMO_ISSUE="${DEMO_ISSUE:-CarGuo/GSYGithubApp|1}"
DEMO_CODE="${DEMO_CODE:-CarGuo/GSYGithubApp|master|README.md}"
DEMO_CODE_PATH="${DEMO_CODE#*|}"
DEMO_CODE_PATH="${DEMO_CODE_PATH#*|}"
CODE_DETAIL_TITLE_ASSERT="${CODE_DETAIL_TITLE_ASSERT:-${DEMO_CODE_PATH##*/}}"
SEARCH_QUERY="${SEARCH_QUERY:-GSYGithubApp}"
SEARCH_RESULT_ASSERT="${SEARCH_RESULT_ASSERT:-CarGuo}"
SEARCH_REPO_TITLE_ASSERT="${SEARCH_REPO_TITLE_ASSERT:-CarGuo/}"
SEARCH_USER_QUERY="${SEARCH_USER_QUERY:-CarGuo}"
SEARCH_USER_ASSERT="${SEARCH_USER_ASSERT:-CarGuo}"
DEMO_USER="${DEMO_USER:-CarGuo}"
DEMO_ORG="${DEMO_ORG:-openai}"
COMMON_LIST_REPOS_TITLE_ZH="${COMMON_LIST_REPOS_TITLE_ZH:-$DEMO_USER 的仓库}"
COMMON_LIST_REPOS_TITLE_EN="${COMMON_LIST_REPOS_TITLE_EN:-$DEMO_USER repos}"
COMMON_LIST_STARGAZERS_TITLE_ZH="${COMMON_LIST_STARGAZERS_TITLE_ZH:-$DEMO_REPO_NAME 的关注者}"
COMMON_LIST_STARGAZERS_TITLE_EN="${COMMON_LIST_STARGAZERS_TITLE_EN:-$DEMO_REPO_NAME stargazers}"
COMMON_LIST_FORKS_TITLE_ZH="${COMMON_LIST_FORKS_TITLE_ZH:-$DEMO_REPO_NAME 的复刻}"
COMMON_LIST_FORKS_TITLE_EN="${COMMON_LIST_FORKS_TITLE_EN:-$DEMO_REPO_NAME forks}"
COMMON_LIST_WATCHERS_TITLE_ZH="${COMMON_LIST_WATCHERS_TITLE_ZH:-$DEMO_REPO_NAME 的订阅者}"
COMMON_LIST_WATCHERS_TITLE_EN="${COMMON_LIST_WATCHERS_TITLE_EN:-$DEMO_REPO_NAME watchers}"
DEMO_TOPIC="${DEMO_TOPIC:-github}"
COMMON_LIST_TOPICS_TITLE_ZH="${COMMON_LIST_TOPICS_TITLE_ZH:-$DEMO_TOPIC 的主题}"
COMMON_LIST_TOPICS_TITLE_EN="${COMMON_LIST_TOPICS_TITLE_EN:-$DEMO_TOPIC topics}"
DEMO_ORGS_USER="${DEMO_ORGS_USER:-yyx990803}"
COMMON_LIST_ORGS_TITLE_ZH="${COMMON_LIST_ORGS_TITLE_ZH:-$DEMO_ORGS_USER 的组织}"
COMMON_LIST_ORGS_TITLE_EN="${COMMON_LIST_ORGS_TITLE_EN:-$DEMO_ORGS_USER orgs}"
COMMON_LIST_FOLLOWERS_TITLE_ZH="${COMMON_LIST_FOLLOWERS_TITLE_ZH:-$DEMO_USER 的粉丝}"
COMMON_LIST_FOLLOWERS_TITLE_EN="${COMMON_LIST_FOLLOWERS_TITLE_EN:-$DEMO_USER followers}"
COMMON_LIST_FOLLOWING_TITLE_ZH="${COMMON_LIST_FOLLOWING_TITLE_ZH:-$DEMO_USER 的关注}"
COMMON_LIST_FOLLOWING_TITLE_EN="${COMMON_LIST_FOLLOWING_TITLE_EN:-$DEMO_USER following}"
COMMON_LIST_USER_STAR_TITLE_ZH="${COMMON_LIST_USER_STAR_TITLE_ZH:-$DEMO_USER 的星标}"
COMMON_LIST_USER_STAR_TITLE_EN="${COMMON_LIST_USER_STAR_TITLE_EN:-$DEMO_USER star}"
DEMO_WEB="${DEMO_WEB:-https://example.com}"
DEMO_WEB_ASSERT="${DEMO_WEB_ASSERT:-Example Domain}"
DEMO_PHOTO="${DEMO_PHOTO:-https://avatars.githubusercontent.com/u/10770362?v=4}"
SEARCH_HISTORY_SEED="${SEARCH_HISTORY_SEED:-}"
OH_LOCALE="${OH_LOCALE:-}"
BOOT_LOCALE_ARG=""
if [ -n "$OH_LOCALE" ]; then
  BOOT_LOCALE_ARG=" --ps bootLocale '$OH_LOCALE'"
fi
BOOT_SEARCH_HISTORY_ARG=""
if [ -n "$SEARCH_HISTORY_SEED" ]; then
  BOOT_SEARCH_HISTORY_ARG=" --ps bootSearchHistory '$SEARCH_HISTORY_SEED'"
fi

mkdir -p "$OUT_DIR"
ASSERT_LOG="$OUT_DIR/asserts.log"
SUMMARY_LOG="$OUT_DIR/summary.log"
: > "$ASSERT_LOG"
: > "$SUMMARY_LOG"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$SUMMARY_LOG"; }

# --------- 工具函数 ---------
snap() {
  local name="$1"
  hdc -t "$TARGET" shell uitest screenCap -p "/data/local/tmp/${name}.png" >/dev/null 2>&1 || true
  hdc -t "$TARGET" file recv "/data/local/tmp/${name}.png" "$OUT_DIR/${name}.png" >/dev/null 2>&1 || true
  hdc -t "$TARGET" shell uitest dumpLayout -p "/data/local/tmp/${name}.json" >/dev/null 2>&1 || true
  hdc -t "$TARGET" file recv "/data/local/tmp/${name}.json" "$OUT_DIR/${name}.json" >/dev/null 2>&1 || true
}

dumpnow() {
  local out="$1"
  hdc -t "$TARGET" shell uitest dumpLayout -p "/data/local/tmp/_now.json" >/dev/null 2>&1 || return 1
  hdc -t "$TARGET" file recv "/data/local/tmp/_now.json" "$out" >/dev/null 2>&1 || return 1
}

# wait_for_id <id> [timeout_seconds]
wait_for_id() {
  local id="$1"; local timeout="${2:-$WAIT_MAX}"
  local elapsed=0
  while [ $elapsed -lt $timeout ]; do
    dumpnow "$OUT_DIR/_wait.json" || true
    if grep -q "\"id\":\"$id\"" "$OUT_DIR/_wait.json" 2>/dev/null; then
      log "  wait_for_id($id) hit @ ${elapsed}s"
      return 0
    fi
    sleep 1; elapsed=$((elapsed + 1))
  done
  log "  wait_for_id($id) TIMEOUT @ ${timeout}s"
  return 1
}

# wait_for_text <substring> [timeout_seconds]
wait_for_text() {
  local txt="$1"; local timeout="${2:-$WAIT_MAX}"
  local elapsed=0
  while [ $elapsed -lt $timeout ]; do
    dumpnow "$OUT_DIR/_wait.json" || true
    if grep -q "\"text\":\"[^\"]*$txt" "$OUT_DIR/_wait.json" 2>/dev/null; then
      log "  wait_for_text($txt) hit @ ${elapsed}s"
      return 0
    fi
    sleep 1; elapsed=$((elapsed + 1))
  done
  log "  wait_for_text($txt) TIMEOUT @ ${timeout}s"
  return 1
}

# wait_for_text_change <id> <old_text> [timeout]
# 用于异步：原本 text=old，等到它变化（不再等于 old）
wait_for_text_change() {
  local id="$1"; local old="$2"; local timeout="${3:-$WAIT_MAX}"
  local elapsed=0
  while [ $elapsed -lt $timeout ]; do
    dumpnow "$OUT_DIR/_wait.json" || true
    # python 取该 id 的 text
    local cur
    cur=$(python3 -c "
import json,sys
try:
    t=json.load(open('$OUT_DIR/_wait.json'))
    def w(n):
        a=n.get('attributes',{}) or {}
        if a.get('id')=='$id': return a.get('text','')
        for c in n.get('children',[]) or []:
            r=w(c)
            if r is not None: return r
        return None
    print(w(t) or '')
except: print('')
" 2>/dev/null)
    if [ -n "$cur" ] && [ "$cur" != "$old" ]; then
      log "  wait_for_text_change($id) '$old' -> '$cur' @ ${elapsed}s"
      return 0
    fi
    sleep 1; elapsed=$((elapsed + 1))
  done
  log "  wait_for_text_change($id from '$old') TIMEOUT @ ${timeout}s"
  return 1
}

assert_id_in() {
  local layout="$1"; shift
  local fail=0
  for id in "$@"; do
    if grep -q "\"id\":\"$id\"" "$layout" 2>/dev/null; then
      echo "[OK]   $(basename "$layout")  id=$id" >> "$ASSERT_LOG"
    else
      echo "[FAIL] $(basename "$layout")  id=$id  MISSING" >> "$ASSERT_LOG"
      fail=$((fail + 1))
    fi
  done
  return $fail
}

assert_any_id_in() {
  local layout="$1"; shift
  local label="$1"; shift
  local id
  for id in "$@"; do
    if grep -q "\"id\":\"$id\"" "$layout" 2>/dev/null; then
      echo "[OK]   $(basename "$layout")  any=$label id=$id" >> "$ASSERT_LOG"
      return 0
    fi
  done
  echo "[FAIL] $(basename "$layout")  any=$label  MISSING ids=$*" >> "$ASSERT_LOG"
  return 1
}

assert_bounds_inside() {
  local layout="$1"; local child="$2"; local parent="$3"; local margin="${4:-0}"
  python3 - "$layout" "$child" "$parent" "$margin" "$ASSERT_LOG" <<'PY'
import json
import re
import sys

layout, child_id, parent_id, margin_s, assert_log = sys.argv[1:6]
margin = int(margin_s)

def find(node, target):
    if isinstance(node, dict):
        attrs = node.get('attributes', {}) or {}
        if attrs.get('id') == target or attrs.get('key') == target:
            return attrs
        for value in node.values():
            found = find(value, target)
            if found is not None:
                return found
    elif isinstance(node, list):
        for item in node:
            found = find(item, target)
            if found is not None:
                return found
    return None

def parse_bounds(attrs):
    raw = attrs.get('bounds', '') if attrs else ''
    match = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", raw)
    if not match:
        return None
    return tuple(int(v) for v in match.groups())

def write(status, msg):
    with open(assert_log, 'a') as out:
        out.write(f"[{status}]   {layout.split('/')[-1]}  bounds_inside={child_id}->{parent_id} {msg}\n")

try:
    root = json.load(open(layout, 'r'))
except Exception as exc:
    write("FAIL", f"LAYOUT_READ_ERROR {exc}")
    sys.exit(1)

child = parse_bounds(find(root, child_id))
parent = parse_bounds(find(root, parent_id))
if child is None:
    write("FAIL", "CHILD_NOT_FOUND_OR_BAD_BOUNDS")
    sys.exit(1)
if parent is None:
    write("FAIL", "PARENT_NOT_FOUND_OR_BAD_BOUNDS")
    sys.exit(1)

cx0, cy0, cx1, cy1 = child
px0, py0, px1, py1 = parent
ok = (
    cx0 >= px0 + margin and
    cy0 >= py0 + margin and
    cx1 <= px1 - margin and
    cy1 <= py1 - margin
)
if ok:
    write("OK", f"child=[{cx0},{cy0}][{cx1},{cy1}] parent=[{px0},{py0}][{px1},{py1}] margin={margin}")
    sys.exit(0)
write("FAIL", f"child=[{cx0},{cy0}][{cx1},{cy1}] parent=[{px0},{py0}][{px1},{py1}] margin={margin}")
sys.exit(1)
PY
}

assert_absent_id_in() {
  local layout="$1"; shift
  local fail=0
  for id in "$@"; do
    if grep -q "\"id\":\"$id\"" "$layout" 2>/dev/null; then
      echo "[FAIL] $(basename "$layout")  id=$id  UNEXPECTED" >> "$ASSERT_LOG"
      fail=$((fail + 1))
    else
      echo "[OK]   $(basename "$layout")  absent_id=$id" >> "$ASSERT_LOG"
    fi
  done
  return $fail
}

assert_absent_text_in() {
  local layout="$1"; shift
  local fail=0
  local txt
  for txt in "$@"; do
    if grep -Fq "$txt" "$layout" 2>/dev/null; then
      echo "[FAIL] $(basename "$layout")  text~=$txt  UNEXPECTED" >> "$ASSERT_LOG"
      fail=$((fail + 1))
    else
      echo "[OK]   $(basename "$layout")  absent_text~=$txt" >> "$ASSERT_LOG"
    fi
  done
  return $fail
}

assert_png_different() {
  local first="$1"; local second="$2"; local label="$3"
  local first_md5 second_md5
  first_md5=$(md5 -q "$first" 2>/dev/null || md5sum "$first" 2>/dev/null | awk '{print $1}')
  second_md5=$(md5 -q "$second" 2>/dev/null || md5sum "$second" 2>/dev/null | awk '{print $1}')
  if [ -n "$first_md5" ] && [ -n "$second_md5" ] && [ "$first_md5" != "$second_md5" ]; then
    echo "[OK]   $(basename "$first")→$(basename "$second")  png_changed=$label" >> "$ASSERT_LOG"
    return 0
  fi
  echo "[FAIL] $(basename "$first")→$(basename "$second")  png_changed=$label  SAME" >> "$ASSERT_LOG"
  return 1
}

assert_text_in() {
  local layout="$1"; shift
  local fail=0
  for txt in "$@"; do
    if grep -Fq "$txt" "$layout" 2>/dev/null; then
      echo "[OK]   $(basename "$layout")  text~=$txt" >> "$ASSERT_LOG"
    else
      echo "[FAIL] $(basename "$layout")  text~=$txt  MISSING" >> "$ASSERT_LOG"
      fail=$((fail + 1))
    fi
  done
  return $fail
}

assert_any_text_in() {
  local layout="$1"; shift
  local txt
  for txt in "$@"; do
    if grep -Fq "$txt" "$layout" 2>/dev/null; then
      echo "[OK]   $(basename "$layout")  any_text~=$txt" >> "$ASSERT_LOG"
      return 0
    fi
  done
  echo "[FAIL] $(basename "$layout")  any_text~=[$*]  MISSING" >> "$ASSERT_LOG"
  return 1
}

assert_repo_titles_not_compact() {
  local layout="$1"; local min_width="${2:-220}"
  python3 - "$layout" "$min_width" "$ASSERT_LOG" <<'PY'
import json
import re
import sys

layout, min_width_s, assert_log = sys.argv[1:4]
min_width = int(min_width_s)
patterns = [
    re.compile(r"^search_repo_\d+_name$"),
    re.compile(r"^common_list_.*_repo_\d+_name$"),
    re.compile(r"^read_history_row_\d+_name$"),
    re.compile(r"^trend_row_full_\d+$"),
]

def walk(node):
    if isinstance(node, dict):
        attrs = node.get('attributes', {}) or {}
        yield attrs
        for value in node.values():
            yield from walk(value)
    elif isinstance(node, list):
        for item in node:
            yield from walk(item)

def parse_bounds(raw):
    match = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", raw or "")
    if not match:
        return None
    return tuple(int(v) for v in match.groups())

def write(status, msg):
    with open(assert_log, 'a') as out:
        out.write(f"[{status}]   {layout.split('/')[-1]}  repo_title={msg}\n")

try:
    root = json.load(open(layout, 'r'))
except Exception as exc:
    write("FAIL", f"LAYOUT_READ_ERROR {exc}")
    sys.exit(1)

checked = 0
failures = []
for attrs in walk(root):
    cid = attrs.get('id', '')
    if not any(pattern.match(cid) for pattern in patterns):
        continue
    text = attrs.get('text', '') or ''
    bounds = parse_bounds(attrs.get('bounds', ''))
    checked += 1
    if '...' in text or '…' in text:
        failures.append(f"{cid} text={text!r}")
    if '/' in text and bounds is not None:
        width = bounds[2] - bounds[0]
        if width < min_width:
            failures.append(f"{cid} width={width}<min={min_width} text={text!r}")

if checked == 0:
    write("FAIL", "NO_REPO_TITLE_IDS")
    sys.exit(1)
if failures:
    for failure in failures:
        write("FAIL", failure)
    sys.exit(1)
write("OK", f"checked={checked} min_width={min_width}")
sys.exit(0)
PY
}

assert_id_text_any() {
  local layout="$1"; local id="$2"; shift 2
  python3 - "$layout" "$id" "$ASSERT_LOG" "$@" <<'PY'
import json
import sys

layout, target, assert_log, *needles = sys.argv[1:]

def walk(node):
    attrs = node.get("attributes", {}) or {}
    if (attrs.get("id", "") or "") == target:
        return attrs.get("text", "") or ""
    for child in node.get("children", []) or []:
        found = walk(child)
        if found:
            return found
    return ""

try:
    root = json.load(open(layout))
except Exception as exc:
    with open(assert_log, "a") as f:
        f.write(f"[FAIL] {layout.split('/')[-1]}  id={target}  READ_ERROR {exc}\n")
    sys.exit(1)

text = walk(root)
base = layout.split("/")[-1]
if not text:
    with open(assert_log, "a") as f:
        f.write(f"[FAIL] {base}  id={target}  text MISSING_NODE_OR_EMPTY\n")
    sys.exit(1)

for needle in needles:
    if needle in text:
        with open(assert_log, "a") as f:
            f.write(f"[OK]   {base}  id={target} text~={needle}\n")
        sys.exit(0)

with open(assert_log, "a") as f:
    f.write(f"[FAIL] {base}  id={target} text~= {needles}  actual={text}\n")
sys.exit(1)
PY
}

assert_id_text_positive_int() {
  local layout="$1"; local id="$2"
  python3 - "$layout" "$id" "$ASSERT_LOG" <<'PY'
import json
import re
import sys

layout, target, assert_log = sys.argv[1:4]

def walk(node):
    attrs = node.get("attributes", {}) or {}
    if (attrs.get("id", "") or "") == target:
        return attrs.get("text", "") or ""
    for child in node.get("children", []) or []:
        found = walk(child)
        if found:
            return found
    return ""

try:
    root = json.load(open(layout))
except Exception as exc:
    with open(assert_log, "a") as f:
        f.write(f"[FAIL] {layout.split('/')[-1]}  id={target}  READ_ERROR {exc}\n")
    sys.exit(1)

text = walk(root).strip().replace(",", "")
base = layout.split("/")[-1]
if re.fullmatch(r"\d+", text or "") and int(text) > 0:
    with open(assert_log, "a") as f:
        f.write(f"[OK]   {base}  id={target} positive_int={text}\n")
    sys.exit(0)

with open(assert_log, "a") as f:
    f.write(f"[FAIL] {base}  id={target} positive_int actual={text or '<empty>'}\n")
sys.exit(1)
PY
}

assert_png_crop_nonblank() {
  local png="$1"; local label="$2"; local threshold="${3:-0.003}"
  python3 - "$png" "$label" "$threshold" "$ASSERT_LOG" <<'PY'
import binascii
import struct
import sys
import zlib

png, label, threshold_s, assert_log = sys.argv[1:5]
threshold = float(threshold_s)

def fail(msg):
    with open(assert_log, 'a') as f:
        f.write(f"[FAIL] {png.split('/')[-1]}  png_crop={label}  {msg}\n")
    sys.exit(1)

try:
    data = open(png, 'rb').read()
except Exception as exc:
    fail(f"READ_ERROR {exc}")

if not data.startswith(b'\x89PNG\r\n\x1a\n'):
    fail("NOT_PNG")

pos = 8
width = height = bit_depth = color_type = None
chunks = []
while pos + 8 <= len(data):
    length = struct.unpack('>I', data[pos:pos + 4])[0]
    ctype = data[pos + 4:pos + 8]
    payload = data[pos + 8:pos + 8 + length]
    pos += 12 + length
    if ctype == b'IHDR':
        width, height, bit_depth, color_type, _comp, _filter, interlace = struct.unpack('>IIBBBBB', payload)
        if bit_depth != 8 or color_type not in (2, 6) or interlace != 0:
            fail(f"UNSUPPORTED bit={bit_depth} color={color_type} interlace={interlace}")
    elif ctype == b'IDAT':
        chunks.append(payload)
    elif ctype == b'IEND':
        break

if width is None or height is None or not chunks:
    fail("BAD_PNG")

channels = 4 if color_type == 6 else 3
stride = width * channels
try:
    raw = zlib.decompress(b''.join(chunks))
except Exception as exc:
    fail(f"ZLIB_ERROR {exc}")

def paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c

rows = []
idx = 0
prev = [0] * stride
for _y in range(height):
    ftype = raw[idx]
    idx += 1
    row = list(raw[idx:idx + stride])
    idx += stride
    for x in range(stride):
        left = row[x - channels] if x >= channels else 0
        up = prev[x]
        up_left = prev[x - channels] if x >= channels else 0
        if ftype == 1:
            row[x] = (row[x] + left) & 255
        elif ftype == 2:
            row[x] = (row[x] + up) & 255
        elif ftype == 3:
            row[x] = (row[x] + ((left + up) // 2)) & 255
        elif ftype == 4:
            row[x] = (row[x] + paeth(left, up, up_left)) & 255
        elif ftype != 0:
            fail(f"BAD_FILTER {ftype}")
    rows.append(row)
    prev = row

x0, x1 = int(width * 0.05), int(width * 0.95)
y0, y1 = int(height * 0.28), int(height * 0.82)
total = ink = 0
for y in range(y0, y1):
    row = rows[y]
    for x in range(x0, x1):
        off = x * channels
        r, g, b = row[off], row[off + 1], row[off + 2]
        total += 1
        if r < 245 or g < 245 or b < 245:
            ink += 1

ratio = ink / total if total else 0.0
status = "OK" if ratio >= threshold else "FAIL"
with open(assert_log, 'a') as f:
    f.write(f"[{status}]   {png.split('/')[-1]}  png_crop={label} ink_ratio={ratio:.5f} threshold={threshold:.5f}\n")
sys.exit(0 if ratio >= threshold else 1)
PY
}

assert_png_id_nonflat() {
  local png="$1"; local layout="$2"; local id="$3"; local threshold="${4:-12.0}"
  python3 - "$png" "$layout" "$id" "$threshold" "$ASSERT_LOG" <<'PY'
import json
import math
import re
import struct
import sys
import zlib

png, layout, target_id, threshold_s, assert_log = sys.argv[1:6]
threshold = float(threshold_s)

def log(status, msg):
    with open(assert_log, 'a') as f:
        f.write(f"[{status}]   {png.split('/')[-1]}  id_crop={target_id} {msg}\n")

def fail(msg):
    log("FAIL", msg)
    sys.exit(1)

def find_node(node):
    if isinstance(node, dict):
        attrs = node.get('attributes', {})
        if attrs.get('id') == target_id or attrs.get('key') == target_id:
            return attrs
        for value in node.values():
            found = find_node(value)
            if found is not None:
                return found
    elif isinstance(node, list):
        for item in node:
            found = find_node(item)
            if found is not None:
                return found
    return None

try:
    with open(layout, 'r') as f:
        attrs = find_node(json.load(f))
except Exception as exc:
    fail(f"LAYOUT_READ_ERROR {exc}")

if attrs is None:
    fail("ID_NOT_FOUND")

m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", attrs.get('bounds', ''))
if not m:
    fail("BAD_BOUNDS")
x0, y0, x1, y1 = [int(v) for v in m.groups()]

try:
    data = open(png, 'rb').read()
except Exception as exc:
    fail(f"PNG_READ_ERROR {exc}")

if not data.startswith(b'\x89PNG\r\n\x1a\n'):
    fail("NOT_PNG")

pos = 8
width = height = bit_depth = color_type = None
chunks = []
while pos + 8 <= len(data):
    length = struct.unpack('>I', data[pos:pos + 4])[0]
    ctype = data[pos + 4:pos + 8]
    payload = data[pos + 8:pos + 8 + length]
    pos += 12 + length
    if ctype == b'IHDR':
        width, height, bit_depth, color_type, _comp, _filter, interlace = struct.unpack('>IIBBBBB', payload)
        if bit_depth != 8 or color_type not in (2, 6) or interlace != 0:
            fail(f"UNSUPPORTED bit={bit_depth} color={color_type} interlace={interlace}")
    elif ctype == b'IDAT':
        chunks.append(payload)
    elif ctype == b'IEND':
        break

if width is None or height is None or not chunks:
    fail("BAD_PNG")

channels = 4 if color_type == 6 else 3
stride = width * channels
try:
    raw = zlib.decompress(b''.join(chunks))
except Exception as exc:
    fail(f"ZLIB_ERROR {exc}")

def paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c

rows = []
idx = 0
prev = [0] * stride
for _y in range(height):
    ftype = raw[idx]
    idx += 1
    row = list(raw[idx:idx + stride])
    idx += stride
    for x in range(stride):
        left = row[x - channels] if x >= channels else 0
        up = prev[x]
        up_left = prev[x - channels] if x >= channels else 0
        if ftype == 1:
            row[x] = (row[x] + left) & 255
        elif ftype == 2:
            row[x] = (row[x] + up) & 255
        elif ftype == 3:
            row[x] = (row[x] + ((left + up) // 2)) & 255
        elif ftype == 4:
            row[x] = (row[x] + paeth(left, up, up_left)) & 255
        elif ftype != 0:
            fail(f"BAD_FILTER {ftype}")
    rows.append(row)
    prev = row

x0, x1 = max(0, x0), min(width, x1)
y0, y1 = max(0, y0), min(height, y1)
if x1 <= x0 or y1 <= y0:
    fail("EMPTY_CROP")

values = []
for y in range(y0, y1):
    row = rows[y]
    for x in range(x0, x1):
        off = x * channels
        r, g, b = row[off], row[off + 1], row[off + 2]
        values.append((r + g + b) / 3.0)

mean = sum(values) / len(values)
variance = sum((v - mean) * (v - mean) for v in values) / len(values)
std = math.sqrt(variance)
status = "OK" if std >= threshold else "FAIL"
log(status, f"std={std:.2f} threshold={threshold:.2f}")
sys.exit(0 if std >= threshold else 1)
PY
}

tap_id() {
  local layout="$1"; local id="$2"
  local coords
  coords=$($PYFIND "$layout" "$id" 2>/dev/null) || { log "  tap_id NOT_FOUND id=$id"; return 1; }
  local cx cy
  read -r cx cy <<< "$coords"
  log "  tap_id($id) @ ($cx,$cy)"
  hdc -t "$TARGET" shell uitest uiInput click "$cx" "$cy" >/dev/null 2>&1
  return 0
}

tap_id_offset() {
  local layout="$1"; local id="$2"; local dx="${3:-0}"; local dy="${4:-0}"
  local coords
  coords=$($PYFIND "$layout" "$id" 2>/dev/null) || { log "  tap_id_offset NOT_FOUND id=$id"; return 1; }
  local cx cy
  read -r cx cy <<< "$coords"
  cx=$((cx + dx))
  cy=$((cy + dy))
  log "  tap_id_offset($id) @ ($cx,$cy) delta=($dx,$dy)"
  hdc -t "$TARGET" shell uitest uiInput click "$cx" "$cy" >/dev/null 2>&1
  return 0
}

input_text_id() {
  local layout="$1"; local id="$2"; local text="$3"
  local coords
  coords=$($PYFIND "$layout" "$id" 2>/dev/null) || { log "  input_text_id NOT_FOUND id=$id"; return 1; }
  local cx cy
  read -r cx cy <<< "$coords"
  log "  input_text_id($id) @ ($cx,$cy) text_len=${#text}"
  hdc -t "$TARGET" shell uitest uiInput inputText "$cx" "$cy" "$text" >/dev/null 2>&1
  return 0
}

hide_keyboard_if_present() {
  local layout="$1"
  dumpnow "$layout" || return 1
  if grep -q "\"id\":\"KeyHideKbd\"" "$layout" 2>/dev/null; then
    tap_id "$layout" "KeyHideKbd" || true
    sleep 1
    return 0
  fi
  return 1
}

press_back() {
  log "  keyEvent Back"
  hdc -t "$TARGET" shell uitest uiInput keyEvent Back >/dev/null 2>&1 || true
  sleep 2
}

mark_begin() {
  local key="$1"; local idx="$2"
  echo "" >> "$OUT_DIR/hilog_business.log"
  echo "=== BEGIN scenario=$key index=$idx ts=$(date '+%H:%M:%S') ===" >> "$OUT_DIR/hilog_business.log"
}
mark_end() {
  local key="$1"; local idx="$2"; local status="$3"
  echo "=== END   scenario=$key index=$idx status=$status ts=$(date '+%H:%M:%S') ===" >> "$OUT_DIR/hilog_business.log"
}

# --------- 设备探活 ---------
log "scenario-tour v2 → out=$OUT_DIR target=$TARGET"
hdc -t "$TARGET" shell param get const.product.model > "$OUT_DIR/device.txt" 2>&1 || { log "device offline"; exit 2; }
hdc -t "$TARGET" shell param get const.product.software.version >> "$OUT_DIR/device.txt" 2>&1 || true
echo "TS=$TS" >> "$OUT_DIR/device.txt"
echo "BUNDLE=$BUNDLE" >> "$OUT_DIR/device.txt"

# --------- 安装（可跳过）---------
if [ "$SKIP_INSTALL" != "1" ]; then
  if [ ! -f "$HAP_PATH" ]; then
    log "HAP not found at $HAP_PATH"; exit 3
  fi
  hdc -t "$TARGET" install -r "$HAP_PATH" 2>&1 | tee "$OUT_DIR/install.log" >/dev/null
fi

# --------- 启动 hilog 抓取（用 PID 过滤，不靠 domain 0x0666）---------
hdc -t "$TARGET" shell aa force-stop "$BUNDLE" >/dev/null 2>&1 || true
sleep 1
hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE$BOOT_LOCALE_ARG$BOOT_SEARCH_HISTORY_ARG" 2>&1 | tee "$OUT_DIR/start.log" >/dev/null
sleep 3

PID=$(hdc -t "$TARGET" shell pidof "$BUNDLE" 2>/dev/null | tr -d '\r\n ')
if [ -z "$PID" ]; then
  log "ERROR: cannot get pid for $BUNDLE"; exit 4
fi
log "pid=$PID"
echo "PID=$PID" >> "$OUT_DIR/device.txt"

# 后台抓 hilog（按 pid 过滤），使用追加避免覆盖脚本 marker
: > "$OUT_DIR/hilog_business.log"
hdc -t "$TARGET" shell hilog -P "$PID" >> "$OUT_DIR/hilog_business.log" 2>&1 &
HILOG_PID="${!:-0}"
disown "$HILOG_PID" 2>/dev/null || true
log "hilog pid=$HILOG_PID -> hilog_business.log"
cleanup() {
  if [ "$HILOG_PID" != "0" ]; then
    kill "$HILOG_PID" 2>/dev/null || true
    wait "$HILOG_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

restart_hilog_capture() {
  local label="$1"
  if [ "$HILOG_PID" != "0" ]; then
    kill "$HILOG_PID" 2>/dev/null || true
    wait "$HILOG_PID" 2>/dev/null || true
  fi
  HILOG_PID="0"
  local next_pid=""
  local elapsed=0
  while [ $elapsed -lt 8 ]; do
    next_pid=$(hdc -t "$TARGET" shell pidof "$BUNDLE" 2>/dev/null | tr -d '\r\n ')
    if [ -n "$next_pid" ]; then
      break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  if [ -z "$next_pid" ]; then
    log "  restart_hilog_capture($label) no pid"
    return 1
  fi
  PID="$next_pid"
  echo "" >> "$OUT_DIR/hilog_business.log"
  echo "=== HILOG restart label=$label pid=$PID ts=$(date '+%H:%M:%S') ===" >> "$OUT_DIR/hilog_business.log"
  hdc -t "$TARGET" shell hilog -P "$PID" >> "$OUT_DIR/hilog_business.log" 2>&1 &
  HILOG_PID="${!:-0}"
  disown "$HILOG_PID" 2>/dev/null || true
  log "  hilog restart label=$label pid=$PID hilog_pid=$HILOG_PID"
  return 0
}

# --------- 场景过滤 ---------
SCENARIO_FILTER="${SCENARIOS:-}"
should_run() {
  local key="$1"
  [ -z "$SCENARIO_FILTER" ] && return 0
  for r in $SCENARIO_FILTER; do [ "$r" = "$key" ] && return 0; done
  return 1
}

should_run_any() {
  local key
  for key in "$@"; do
    [ -n "$key" ] || continue
    should_run "$key" && return 0
  done
  return 1
}

OK_COUNT=0; FAIL_COUNT=0; SKIP_COUNT=0
declare -a RUN_KEYS

run() {
  local idx="$1"; local key="$2"; local title="$3"; shift 3
  local padded
  padded=$(printf "%02d" "$((10#$idx))")
  if ! should_run "$key"; then
    log "SKIP $padded $key  ($title)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    return 0
  fi
  log "STEP $padded $key  ($title)"
  mark_begin "$key" "$padded"
  RUN_KEYS+=("${padded}_${key}")
  # 让调用方决定流程，最后调用方 snap "${padded}_${key}"
  # 这里只做 BEGIN 标记
}

run_any() {
  local idx="$1"; local key="$2"; local title="$3"; shift 3
  local padded
  padded=$(printf "%02d" "$((10#$idx))")
  if ! should_run_any "$key" "$@"; then
    log "SKIP $padded $key  ($title)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    return 0
  fi
  log "STEP $padded $key  ($title)"
  mark_begin "$key" "$padded"
  RUN_KEYS+=("${padded}_${key}")
}

# =========================================================
#   场景 01 launch
# =========================================================
IDX=1
run $IDX "launch" "App 启动 → 落到首页"
if should_run "launch"; then
  PADDED=$(printf "%02d" $IDX)
  # 已经在 aa start 后 sleep 3，等 home_main_content 出现
  if wait_for_id "home_main_content" 12; then
    snap "${PADDED}_launch"
    if assert_id_in "$OUT_DIR/${PADDED}_launch.json" "home_main_content" "home_appbar" "appbar_action_l_menu" "appbar_action_r_search" "home_tabs" "home_tab_bar_dynamic" "home_tab_bar_trend" "home_tab_bar_my"; then
      mark_end "launch" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "launch" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    snap "${PADDED}_launch"
    mark_end "launch" "$PADDED" "wait_timeout"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 02 home-dynamic（已经在 dynamic Tab，等 dynamic_row_0_user 异步加载）
# =========================================================
IDX=2
run $IDX "home-dynamic" "首页 Dynamic Tab + 等列表加载"
if should_run "home-dynamic"; then
  PADDED=$(printf "%02d" $IDX)
  wait_for_id "dynamic_pull_list" 8 || true
  wait_for_id "dynamic_row_0_user" 12 || true
  snap "${PADDED}_home-dynamic"
  if assert_id_in "$OUT_DIR/${PADDED}_home-dynamic.json" \
    "tab_page_root_dynamic" "dynamic_pull_list" "dynamic_row_0" "dynamic_row_0_user" \
    "dynamic_row_0_target" "dynamic_row_0_time" \
    && assert_absent_id_in "$OUT_DIR/${PADDED}_home-dynamic.json" "dynamic_row_0_des" \
    && assert_png_id_nonflat "$OUT_DIR/${PADDED}_home-dynamic.png" \
      "$OUT_DIR/${PADDED}_home-dynamic.json" "dynamic_row_0" "8.0"; then
    mark_end "home-dynamic" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
  else
    mark_end "home-dynamic" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 03 home-trend
# =========================================================
IDX=3
run $IDX "home-trend" "首页 Trend Tab"
if should_run "home-trend"; then
  PADDED=$(printf "%02d" $IDX)
  dumpnow "$OUT_DIR/_pre_trend.json"
  tap_id "$OUT_DIR/_pre_trend.json" "home_tab_bar_trend" || true
  sleep 2
  wait_for_id "tab_page_root_trend" 10 || true
  snap "${PADDED}_home-trend"
  if assert_id_in "$OUT_DIR/${PADDED}_home-trend.json" "tab_page_root_trend" "trend_pull_list" "trend_row_0" \
    && assert_absent_id_in "$OUT_DIR/${PADDED}_home-trend.json" \
      "trend_filter_bar" "trend_picker_time" "trend_picker_language" "trend_filter_divider" \
    && assert_repo_titles_not_compact "$OUT_DIR/${PADDED}_home-trend.json" \
    && assert_png_id_nonflat "$OUT_DIR/${PADDED}_home-trend.png" \
      "$OUT_DIR/${PADDED}_home-trend.json" "trend_row_0" "8.0"; then
    mark_end "home-trend" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
  else
    mark_end "home-trend" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 04 home-my（异步等头像/用户名加载）
# =========================================================
IDX=4
run $IDX "home-my" "首页 My Tab + 等用户数据加载"
if should_run "home-my"; then
  PADDED=$(printf "%02d" $IDX)
  dumpnow "$OUT_DIR/_pre_my.json"
  tap_id "$OUT_DIR/_pre_my.json" "home_tab_bar_my" || true
  sleep 2
  wait_for_id "tab_page_root_my" 10 || true
  # 等用户名从 --- 变成真实
  wait_for_text_change "user_head_display_name" "---" 15 || true
  snap "${PADDED}_home-my"
  if assert_id_in "$OUT_DIR/${PADDED}_home-my.json" \
    "tab_page_root_my" "user_head_root" "user_head_profile_block" \
    "user_head_display_name" "user_head_login" "user_head_counter_row" \
    "user_head_counter_cell_repos" "user_head_counter_cell_follower" \
    "user_head_counter_cell_followed" "user_head_counter_cell_star" \
    "user_head_dynamic_title_bar" "user_head_dynamic_title" \
    && assert_absent_id_in "$OUT_DIR/${PADDED}_home-my.json" \
      "user_head_counter_cell_beStared" "user_head_link" "my_logout_btn" \
    && assert_any_text_in "$OUT_DIR/${PADDED}_home-my.json" "Repositories" "仓库" \
    && assert_any_text_in "$OUT_DIR/${PADDED}_home-my.json" "Followers" "粉丝" \
    && assert_any_text_in "$OUT_DIR/${PADDED}_home-my.json" "Following" "关注" \
    && assert_any_text_in "$OUT_DIR/${PADDED}_home-my.json" "Stars" "星标" \
    && assert_any_text_in "$OUT_DIR/${PADDED}_home-my.json" "years ago" "年前" \
    && assert_absent_text_in "$OUT_DIR/${PADDED}_home-my.json" "LoginOut" "退出登录" "Logout" "退出登陆" \
    && assert_png_id_nonflat "$OUT_DIR/${PADDED}_home-my.png" \
      "$OUT_DIR/${PADDED}_home-my.json" "user_head_profile_block" "8.0"; then
    mark_end "home-my" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
  else
    mark_end "home-my" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 05 search（从 my Tab 找搜索入口；若无则 SKIP 标注）
# =========================================================
IDX=5
run $IDX "search" "搜索页（从 dynamic 顶栏入口）"
if should_run "search"; then
  PADDED=$(printf "%02d" $IDX)
  # 回到 dynamic Tab 找 appbar 搜索
  dumpnow "$OUT_DIR/_pre_search0.json"
  tap_id "$OUT_DIR/_pre_search0.json" "home_tab_bar_dynamic" || true
  sleep 2
  dumpnow "$OUT_DIR/_pre_search.json"
  # 探测 appbar 搜索入口（多个候选 id）
  SEARCH_HIT=0
  for cand in "appbar_action_r_search" "appbar_search_btn" "home_appbar_search" "appbar_search" "search_entry"; do
    if grep -q "\"id\":\"$cand\"" "$OUT_DIR/_pre_search.json"; then
      tap_id "$OUT_DIR/_pre_search.json" "$cand" && SEARCH_HIT=1 && break
    fi
  done
  if [ $SEARCH_HIT -eq 1 ]; then
    sleep 2
    snap "${PADDED}_search-open"
    OPEN_OK=0
    if assert_id_in "$OUT_DIR/${PADDED}_search-open.json" "search_page_root" "search_input" "search_header_row" \
      && assert_id_in "$OUT_DIR/${PADDED}_search-open.json" "search_type_button_row" \
      && assert_absent_id_in "$OUT_DIR/${PADDED}_search-open.json" \
        "search_filter_drawer" "search_empty_root" "search_history_list"; then
      OPEN_OK=1
    fi
    HISTORY_FOCUS_OK=1
    if [ -n "$SEARCH_HISTORY_SEED" ]; then
      HISTORY_FOCUS_OK=0
      tap_id "$OUT_DIR/${PADDED}_search-open.json" "search_input" || true
      wait_for_id "search_history_list" 5 || true
      snap "${PADDED}_search-history"
      if assert_id_in "$OUT_DIR/${PADDED}_search-history.json" \
        "search_page_root" "search_input" "search_history_list" "search_history_row_0"; then
        HISTORY_FOCUS_OK=1
      fi
    fi
    if input_text_id "$OUT_DIR/${PADDED}_search-open.json" "search_input" "$SEARCH_QUERY"; then
      sleep 1
      dumpnow "$OUT_DIR/_search_typed.json"
      tap_id "$OUT_DIR/_search_typed.json" "search_type_repo_btn" || true
      if ! wait_for_id "search_repo_0" 30; then
        log "  search result not ready, retry repo search once"
        dumpnow "$OUT_DIR/_search_retry.json"
        tap_id "$OUT_DIR/_search_retry.json" "search_type_repo_btn" || true
        wait_for_id "search_repo_0" 30 || wait_for_text "$SEARCH_RESULT_ASSERT" 8 || true
      fi
      hide_keyboard_if_present "$OUT_DIR/_search_keyboard.json" || true
      sleep 2
      snap "${PADDED}_search"
      REPO_OK=0
      if assert_id_in "$OUT_DIR/${PADDED}_search.json" \
        "search_page_root" "search_input" "search_type_button_row" \
        "search_type_repo_btn" "search_type_user_btn" "search_pull_list_repo" "search_repo_0" "search_repo_0_name" "search_clear_icon" \
        && assert_text_in "$OUT_DIR/${PADDED}_search.json" "$SEARCH_QUERY" "$SEARCH_RESULT_ASSERT" "$SEARCH_REPO_TITLE_ASSERT" \
        && assert_repo_titles_not_compact "$OUT_DIR/${PADDED}_search.json" \
        && assert_absent_id_in "$OUT_DIR/${PADDED}_search.json" "search_filter_drawer" "search_empty_root"; then
        REPO_OK=1
      fi
      REPO_NAV_OK=0
      dumpnow "$OUT_DIR/_search_before_repo_nav.json"
      if tap_id "$OUT_DIR/_search_before_repo_nav.json" "search_repo_0"; then
        if wait_for_id "repo_detail_root" 15 || wait_for_id "repository_detail_root" 5; then
          wait_for_id "repo_detail_tabs" 8 || true
          sleep 2
          snap "${PADDED}_search-repo-detail"
          if assert_any_id_in "$OUT_DIR/${PADDED}_search-repo-detail.json" "search-repo-detail-root" \
            "repo_detail_root" "repository_detail_root" \
            && assert_any_id_in "$OUT_DIR/${PADDED}_search-repo-detail.json" "search-repo-detail-content" \
              "repo_detail_tabs" "repo_detail_bottom_bar" "repo_detail_content_stack"; then
            REPO_NAV_OK=1
          fi
        else
          snap "${PADDED}_search-repo-detail"
        fi
      else
        snap "${PADDED}_search-repo-detail"
      fi
      press_back
      wait_for_id "search_page_root" 10 || true
      USER_OK=0
      USER_NAV_OK=0
      dumpnow "$OUT_DIR/_search_before_user_clear.json"
      tap_id "$OUT_DIR/_search_before_user_clear.json" "search_submit_btn" || true
      sleep 1
      dumpnow "$OUT_DIR/_search_user_empty.json"
      if input_text_id "$OUT_DIR/_search_user_empty.json" "search_input" "$SEARCH_USER_QUERY"; then
        sleep 1
        dumpnow "$OUT_DIR/_search_user_typed.json"
        tap_id "$OUT_DIR/_search_user_typed.json" "search_type_user_btn" || true
        wait_for_id "search_user_0" 30 || wait_for_text "$SEARCH_USER_ASSERT" 8 || true
        hide_keyboard_if_present "$OUT_DIR/_search_user_keyboard.json" || true
        sleep 2
        snap "${PADDED}_search-user"
        if assert_id_in "$OUT_DIR/${PADDED}_search-user.json" \
          "search_page_root" "search_input" "search_type_button_row" \
          "search_type_repo_btn" "search_type_user_btn" "search_pull_list_user" "search_user_0" "search_clear_icon" \
          && assert_text_in "$OUT_DIR/${PADDED}_search-user.json" "$SEARCH_USER_QUERY" "$SEARCH_USER_ASSERT" \
          && assert_absent_id_in "$OUT_DIR/${PADDED}_search-user.json" "search_filter_drawer" "search_empty_root"; then
          USER_OK=1
        fi
        dumpnow "$OUT_DIR/_search_before_user_nav.json"
        if tap_id "$OUT_DIR/_search_before_user_nav.json" "search_user_0"; then
          if wait_for_id "user_detail_root" 15; then
            wait_for_id "user_detail_counts_row" 8 || true
            sleep 2
            snap "${PADDED}_search-user-detail"
            if assert_id_in "$OUT_DIR/${PADDED}_search-user-detail.json" \
              "user_detail_root" "user_detail_counts_row"; then
              USER_NAV_OK=1
            fi
          else
            snap "${PADDED}_search-user-detail"
          fi
        else
          snap "${PADDED}_search-user-detail"
        fi
      else
        snap "${PADDED}_search-user"
      fi
      if [ $OPEN_OK -eq 1 ] && [ $HISTORY_FOCUS_OK -eq 1 ] && [ $REPO_OK -eq 1 ] && [ $REPO_NAV_OK -eq 1 ] && [ $USER_OK -eq 1 ] && [ $USER_NAV_OK -eq 1 ]; then
        mark_end "search" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
      else
        mark_end "search" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      mark_end "search" "$PADDED" "input_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    snap "${PADDED}_search"
    log "  search entry not found in appbar — recorded snapshot only"
    echo "[SKIP] $PADDED search: no entry id in appbar (need probe)" >> "$ASSERT_LOG"
    mark_end "search" "$PADDED" "no_entry"; SKIP_COUNT=$((SKIP_COUNT + 1))
  fi
fi

# =========================================================
#   场景 06 repoDetail-info（用 bootRepo want 通道）
# =========================================================
IDX=6
run_any $IDX "repoDetail-info" "RepoDetail Info Tab（aa start --PS bootRepo）" "repoDetail-activity"
if should_run_any "repoDetail-info" "repoDetail-activity"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootRepo '$DEMO_REPO'" >/dev/null 2>&1
  sleep 5
  wait_for_id "repo_detail_root" 10 || wait_for_id "repository_detail_root" 5 || true
  wait_for_id "repo_detail_bottom_bar" 15 || true
  wait_for_id "repo_detail_create_issue_fab" 8 || true
  snap "${PADDED}_repoDetail-info"
  # repoDetail root id 不确定，留多候选
  PASS=0
  for cand in "repo_detail_root" "repository_detail_root" "repository_detail_host_root" "repo_detail_host_root"; do
    if grep -q "\"id\":\"$cand\"" "$OUT_DIR/${PADDED}_repoDetail-info.json"; then PASS=1; break; fi
  done
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_repoDetail-info.json" \
      "repo_detail_content_stack" \
      "repo_detail_tabs" \
      "repo_detail_tab_content_info" \
      "repo_event_root" \
      "repo_event_list" \
      "repo_header_root" \
      "repo_header_content" \
      "repo_header_bottom_row" \
      "repo_header_bottom_cell_star" \
      "repo_header_bottom_cell_fork" \
      "repo_header_bottom_cell_watch" \
      "repo_header_bottom_cell_issue" \
      "repo_header_bottom_text_star" \
      "repo_header_bottom_text_fork" \
      "repo_header_bottom_text_watch" \
      "repo_header_bottom_text_issue" \
      "repo_detail_tab_bar_info" \
      "repo_detail_tab_bar_readme" \
      "repo_detail_tab_bar_issue" \
      "repo_detail_tab_bar_file" \
      "repo_detail_create_issue_fab" \
      "repo_detail_bottom_bar" \
      "common_bottom_bar_item_star" \
      "common_bottom_bar_item_watch" \
      "common_bottom_bar_item_fork" \
      "common_bottom_bar_item_branch" \
      && assert_id_in "$OUT_DIR/${PADDED}_repoDetail-info.json" "appbar_action_r_more" \
      && assert_bounds_inside "$OUT_DIR/${PADDED}_repoDetail-info.json" "appbar_title" "appbar_main_row" 4 \
      && assert_bounds_inside "$OUT_DIR/${PADDED}_repoDetail-info.json" "repo_header_bottom_row" "repo_header_root" 4 \
      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_repoDetail-info.png" "$OUT_DIR/${PADDED}_repoDetail-info.json" "repo_header_root" "8.0"; then
      if tap_id "$OUT_DIR/${PADDED}_repoDetail-info.json" "repo_detail_create_issue_fab"; then
        wait_for_id "create_issue_dialog_root" 5 || true
        snap "${PADDED}_repoDetail-info-createIssue"
        if assert_id_in "$OUT_DIR/${PADDED}_repoDetail-info-createIssue.json" \
          "create_issue_dialog_root" \
          "create_issue_dialog_title" \
          "create_issue_dialog_title_input" \
          "create_issue_dialog_body_input" \
          "create_issue_markdown_toolbar" \
          "create_issue_markdown_toolbar_h1" \
          "create_issue_markdown_toolbar_h2" \
          "create_issue_markdown_toolbar_h3" \
          "create_issue_markdown_toolbar_bold" \
          "create_issue_dialog_cancel" \
          "create_issue_dialog_confirm"; then
          tap_id "$OUT_DIR/${PADDED}_repoDetail-info-createIssue.json" "create_issue_dialog_cancel" || true
          mark_end "repoDetail-info" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
        else
          mark_end "repoDetail-info" "$PADDED" "create_issue_assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
      else
        mark_end "repoDetail-info" "$PADDED" "create_issue_tap_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      mark_end "repoDetail-info" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "repoDetail-info" "$PADDED" "id_unknown"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 35 repoDetail-branch-selector（底部分支下拉 → 切换 branch）
# =========================================================
IDX=35
run $IDX "repoDetail-branch-selector" "RepoDetail bottom branch selector"
if should_run "repoDetail-branch-selector"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootRepo '$DEMO_REPO'" >/dev/null 2>&1
  sleep 5
  wait_for_id "repo_detail_root" 10 || wait_for_id "repository_detail_root" 5 || true
  wait_for_id "repo_detail_bottom_bar" 15 || true
  wait_for_id "common_bottom_bar_item_branch" 8 || true
  wait_for_id "repo_event_row_0" 20 || true
  snap "${PADDED}_repoDetail-branch-before"
  PASS=0
  SELECT_PASS=0
  if tap_id "$OUT_DIR/${PADDED}_repoDetail-branch-before.json" "common_bottom_bar_item_branch"; then
    if ! wait_for_id "repo_branch_menu_root" 30; then
      dumpnow "$OUT_DIR/${PADDED}_repoDetail-branch-retry.json" || true
      tap_id "$OUT_DIR/${PADDED}_repoDetail-branch-retry.json" "common_bottom_bar_item_branch" || true
      wait_for_id "repo_branch_menu_root" 30 || true
    fi
    if wait_for_id "repo_branch_menu_root" 1; then
      PASS=1
      sleep 1
      snap "${PADDED}_repoDetail-branch-menu"
      if tap_id "$OUT_DIR/${PADDED}_repoDetail-branch-menu.json" "repo_branch_menu_item_0"; then
        wait_for_text "$DEMO_BRANCH_SELECT" 12 || true
        sleep 3
        snap "${PADDED}_repoDetail-branch-selected"
        if assert_any_text_in "$OUT_DIR/${PADDED}_repoDetail-branch-selected.json" "$DEMO_BRANCH_SELECT"; then
          SELECT_PASS=1
        fi
      fi
    fi
  fi
  if [ $PASS -eq 1 ] && [ $SELECT_PASS -eq 1 ] \
    && assert_id_in "$OUT_DIR/${PADDED}_repoDetail-branch-menu.json" \
      "repo_branch_menu_overlay" \
      "repo_branch_menu_scrim" \
      "repo_branch_menu_root" \
      "repo_branch_menu_item_0" \
      "repo_branch_menu_item_text_0" \
    && assert_any_text_in "$OUT_DIR/${PADDED}_repoDetail-branch-menu.json" "$DEMO_BRANCH_SELECT" \
    && assert_id_in "$OUT_DIR/${PADDED}_repoDetail-branch-selected.json" \
      "repo_detail_bottom_bar" \
      "common_bottom_bar_item_branch" \
      "common_bottom_bar_text_branch" \
    && assert_absent_id_in "$OUT_DIR/${PADDED}_repoDetail-branch-selected.json" \
      "repo_branch_menu_root"; then
    mark_end "repoDetail-branch-selector" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
  else
    mark_end "repoDetail-branch-selector" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 33 repoDetail-commit-route（Info 内切 Commits 并进入 PushDetail）
# =========================================================
IDX=33
run $IDX "repoDetail-commit-route" "RepoDetail Info Commits → PushDetail"
if should_run "repoDetail-commit-route"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootRepo '$DEMO_REPO'" >/dev/null 2>&1
  sleep 5
  wait_for_id "repo_detail_root" 10 || wait_for_id "repository_detail_root" 5 || true
  wait_for_id "common_bottom_bar_item_push" 15 || true
  wait_for_id "repo_event_row_0" 20 || true
  snap "${PADDED}_repoDetail-commit-before"
  PASS=0
  PUSH_PASS=0
  if tap_id "$OUT_DIR/${PADDED}_repoDetail-commit-before.json" "common_bottom_bar_item_push"; then
    if wait_for_id "repo_commit_row_0" 45; then
      PASS=1
      sleep 2
      snap "${PADDED}_repoDetail-commit"
      if tap_id "$OUT_DIR/${PADDED}_repoDetail-commit.json" "repo_commit_row_0"; then
        if wait_for_id "push_detail_root" 15; then
          sleep 3
          snap "${PADDED}_repoDetail-commit-pushDetail"
          PUSH_PASS=1
        fi
      fi
    fi
  fi
  if [ $PASS -eq 1 ] && [ $PUSH_PASS -eq 1 ] \
    && assert_absent_id_in "$OUT_DIR/${PADDED}_repoDetail-commit-before.json" \
      "common_bottom_bar_item_pulse" \
    && assert_id_in "$OUT_DIR/${PADDED}_repoDetail-commit.json" \
      "repo_commit_row_0" \
      "repo_commit_row_0_avatar" \
      "repo_commit_row_0_message" \
      "repo_commit_row_0_author" \
      "repo_commit_row_0_time" \
	    && assert_id_in "$OUT_DIR/${PADDED}_repoDetail-commit-pushDetail.json" \
	      "push_detail_root" \
	      "appbar_action_r_more" \
	      "push_detail_header_list_item" \
	      "push_detail_commit_card" \
	      "push_detail_stats_row" \
	      "push_detail_message_text" \
	      "push_detail_file_card_0" \
	    && assert_bounds_inside "$OUT_DIR/${PADDED}_repoDetail-commit.json" "appbar_title" "appbar_main_row" 4 \
	    && assert_bounds_inside "$OUT_DIR/${PADDED}_repoDetail-commit-pushDetail.json" "appbar_title" "appbar_main_row" 4 \
	    && assert_png_id_nonflat "$OUT_DIR/${PADDED}_repoDetail-commit-pushDetail.png" \
	      "$OUT_DIR/${PADDED}_repoDetail-commit-pushDetail.json" "push_detail_commit_card" "8.0"; then
    mark_end "repoDetail-commit-route" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
  else
    mark_end "repoDetail-commit-route" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 07 repoDetail-readme  08 issue  09 file（在同一 repo 内切 tab）
# =========================================================
for spec in "07 repoDetail-readme readme" "08 repoDetail-issue issue repoDetail-issues" "09 repoDetail-file file repoDetail-files"; do
  read -r IDX KEY TAB ALIAS <<< "$spec"
  run_any $IDX "$KEY" "RepoDetail $TAB Tab" "$ALIAS"
  if should_run_any "$KEY" "$ALIAS"; then
    PADDED="$IDX"
    dumpnow "$OUT_DIR/_pre_${KEY}.json"
    if ! grep -q "\"id\":\"repo_detail_tabs\"" "$OUT_DIR/_pre_${KEY}.json" 2>/dev/null; then
      hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
      sleep 1
      hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootRepo '$DEMO_REPO'" >/dev/null 2>&1
      sleep 5
      wait_for_id "repo_detail_root" 10 || wait_for_id "repository_detail_root" 5 || true
      wait_for_id "repo_detail_tabs" 10 || true
      dumpnow "$OUT_DIR/_pre_${KEY}.json"
    fi
    HIT=0
    for cand in "repo_detail_tab_bar_$TAB" "repo_tab_$TAB" "repo_detail_tab_$TAB" "tab_$TAB" "repo_$TAB"; do
      if grep -q "\"id\":\"$cand\"" "$OUT_DIR/_pre_${KEY}.json"; then
        tap_id "$OUT_DIR/_pre_${KEY}.json" "$cand" && HIT=1 && break
      fi
    done
    if [ $HIT -eq 0 ]; then
      # 备选：按 text 找 "Activity"/"Readme"/"Issues"/"Files"
      case "$TAB" in
        info) PYTXT="Info";;
        readme) PYTXT="Readme";;
        issue|issues) PYTXT="Issue";;
        file|files)  PYTXT="File";;
      esac
      COORDS=$(python3 scripts/uitest_find.py "$OUT_DIR/_pre_${KEY}.json" "text:$PYTXT" 2>/dev/null) || true
      if [ -n "$COORDS" ]; then
        read -r CX CY <<< "$COORDS"
        log "  tap text:$PYTXT @ ($CX,$CY)"
        hdc -t "$TARGET" shell uitest uiInput click "$CX" "$CY" >/dev/null 2>&1
        HIT=1
      fi
    fi
    sleep 3
    if [ "$KEY" = "repoDetail-readme" ]; then
      for _ in $(seq 1 20); do
        dumpnow "$OUT_DIR/_pre_${KEY}.json" || true
        if grep -Fq "English Readme" "$OUT_DIR/_pre_${KEY}.json" 2>/dev/null \
          || grep -Fq "Github客户端App" "$OUT_DIR/_pre_${KEY}.json" 2>/dev/null \
          || grep -Fq "HarmonyOS" "$OUT_DIR/_pre_${KEY}.json" 2>/dev/null; then
          break
        fi
        sleep 0.5
      done
    fi
    wait_for_id "repo_detail_bottom_bar" 8 || true
    wait_for_id "repo_detail_create_issue_fab" 8 || true
    snap "${PADDED}_${KEY}"
    if [ $HIT -eq 1 ]; then
      case "$KEY" in
        repoDetail-readme)
          ASSERT_IDS=(
            "repo_detail_tab_content_readme"
            "readme_tab_root"
            "readme_tab_web"
            "repo_detail_create_issue_fab"
            "repo_detail_bottom_bar"
            "common_bottom_bar_item_star"
            "common_bottom_bar_item_watch"
            "common_bottom_bar_item_fork"
            "common_bottom_bar_item_branch"
          )
          ;;
        repoDetail-issue)
          ASSERT_IDS=(
            "repo_detail_tab_content_issue"
            "repo_issue_root"
            "repo_issue_search_row"
            "repo_issue_search_input"
            "repo_issue_search_submit_btn"
            "repo_issue_chip_bar"
            "repo_issue_list"
            "repo_detail_create_issue_fab"
            "repo_detail_bottom_bar"
            "common_bottom_bar_item_star"
            "common_bottom_bar_item_watch"
            "common_bottom_bar_item_fork"
            "common_bottom_bar_item_branch"
          )
          ;;
        repoDetail-file)
          ASSERT_IDS=(
            "repo_detail_tab_content_file"
            "repo_file_root"
            "repo_file_breadcrumb"
            "repo_file_breadcrumb_seg_0"
            "repo_file_breadcrumb_sep_0"
            "repo_file_list"
            "repo_detail_create_issue_fab"
            "repo_detail_bottom_bar"
            "common_bottom_bar_item_star"
            "common_bottom_bar_item_watch"
            "common_bottom_bar_item_fork"
            "common_bottom_bar_item_branch"
          )
          ;;
        *)
          ASSERT_IDS=()
          ;;
      esac
      if [ ${#ASSERT_IDS[@]} -eq 0 ] || assert_id_in "$OUT_DIR/${PADDED}_${KEY}.json" "${ASSERT_IDS[@]}"; then
        if [ "$KEY" = "repoDetail-readme" ]; then
          assert_absent_id_in "$OUT_DIR/${PADDED}_${KEY}.json" "readme_tab_native_fallback" || {
            mark_end "$KEY" "$PADDED" "native_fallback_visible"; FAIL_COUNT=$((FAIL_COUNT + 1)); continue;
          }
          assert_png_id_nonflat "$OUT_DIR/${PADDED}_${KEY}.png" "$OUT_DIR/${PADDED}_${KEY}.json" "readme_tab_web" "4.0" || {
            mark_end "$KEY" "$PADDED" "blank_content"; FAIL_COUNT=$((FAIL_COUNT + 1)); continue;
          }
          assert_any_text_in "$OUT_DIR/${PADDED}_${KEY}.json" "English Readme" "Github客户端App" "HarmonyOS" || {
            mark_end "$KEY" "$PADDED" "no_readme_web_text"; FAIL_COUNT=$((FAIL_COUNT + 1)); continue;
          }
        fi
        if [ "$KEY" = "repoDetail-file" ]; then
          assert_absent_id_in "$OUT_DIR/${PADDED}_${KEY}.json" "repo_file_breadcrumb_back" || {
            mark_end "$KEY" "$PADDED" "breadcrumb_back_present"; FAIL_COUNT=$((FAIL_COUNT + 1)); continue;
          }
        fi
        mark_end "$KEY" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
      else
        mark_end "$KEY" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      mark_end "$KEY" "$PADDED" "no_tab"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi
done

# =========================================================
#   场景 13 pushDetail（aa start --PS bootPush "fullName|sha"）
# =========================================================
IDX=13
run $IDX "pushDetail" "PushDetail（aa start --PS bootPush）"
if should_run "pushDetail"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootPush '$DEMO_PUSH'" >/dev/null 2>&1
  sleep 5
  PASS=0
  if wait_for_id "push_detail_root" 12; then
    PASS=1
  fi
  sleep 3
  snap "${PADDED}_pushDetail"
  if [ $PASS -eq 1 ]; then
    CODE_PASS=0
    if grep -q "\"id\":\"push_detail_file_row_0\"" "$OUT_DIR/${PADDED}_pushDetail.json"; then
      if tap_id "$OUT_DIR/${PADDED}_pushDetail.json" "push_detail_file_row_0"; then
        if wait_for_id "code_detail_web" 15 || wait_for_id "code_detail_appbar" 3; then
          sleep 5
          snap "${PADDED}_pushDetail-codeDetail"
          CODE_PASS=1
        fi
      fi
    fi
	    if assert_id_in "$OUT_DIR/${PADDED}_pushDetail.json" \
	      "appbar_action_r_more" \
	      "push_detail_file_list" \
	      "push_detail_header_list_item" \
	      "push_detail_author_avatar" \
      "push_detail_stats_row" \
      "push_detail_message_text" \
      "push_detail_file_row_0" \
      "push_detail_file_filename_0" \
	      && assert_text_in "$OUT_DIR/${PADDED}_pushDetail.json" \
	        "docs(readme): list 5 sibling repos in same-stack section" \
	      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_pushDetail.png" \
	        "$OUT_DIR/${PADDED}_pushDetail.json" "push_detail_author_avatar" "12.0" \
	      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_pushDetail.png" \
	        "$OUT_DIR/${PADDED}_pushDetail.json" "push_detail_commit_card" "8.0" \
	      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_pushDetail.png" \
	        "$OUT_DIR/${PADDED}_pushDetail.json" "push_detail_file_card_0" "8.0" \
	      && [ $CODE_PASS -eq 1 ] \
	      && assert_id_in "$OUT_DIR/${PADDED}_pushDetail-codeDetail.json" \
	        "code_detail_appbar" "appbar_action_r_more" "code_detail_web" \
      && assert_text_in "$OUT_DIR/${PADDED}_pushDetail-codeDetail.json" "@@" \
      && assert_absent_text_in "$OUT_DIR/${PADDED}_pushDetail-codeDetail.json" "English Readme" \
      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_pushDetail-codeDetail.png" \
        "$OUT_DIR/${PADDED}_pushDetail-codeDetail.json" "code_detail_web" "4.0"; then
      mark_end "pushDetail" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "pushDetail" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "pushDetail" "$PADDED" "no_push_root"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 14 issueDetail（aa start --PS bootIssue "fullName|number"）
# =========================================================
IDX=14
run $IDX "issueDetail" "IssueDetail（aa start --PS bootIssue）"
if should_run "issueDetail"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootIssue '$DEMO_ISSUE'" >/dev/null 2>&1
  sleep 6
  PASS=0
  # NavDestination 内的 root Column id 被 ArkUI uitest 吞掉，改用 appbar 作锚点
  if wait_for_id "issue_detail_appbar" 12; then
    PASS=1
  fi
  # 等底栏渲染（与 Header 一同出现）
  wait_for_id "issue_detail_bottom_bar" 8 || true
  sleep 3
  snap "${PADDED}_issueDetail"
  if [ $PASS -eq 1 ]; then
    COMMENT_SOURCE_LAYOUT="$OUT_DIR/${PADDED}_issueDetail.json"
    EDIT_CHECK=1
    if grep -q "\"id\":\"common_bottom_bar_item_edit\"" "$OUT_DIR/${PADDED}_issueDetail.json"; then
      if tap_id "$OUT_DIR/${PADDED}_issueDetail.json" "common_bottom_bar_item_edit"; then
        sleep 1
        dumpnow "$OUT_DIR/_issue_edit_probe.json" || true
        if ! grep -q "\"id\":\"issue_edit_dialog_root\"" "$OUT_DIR/_issue_edit_probe.json" 2>/dev/null; then
          tap_id_offset "$OUT_DIR/${PADDED}_issueDetail.json" "common_bottom_bar_item_edit" 0 -24 || true
        fi
        wait_for_id "issue_edit_dialog_root" 5 || true
        sleep 1
        snap "${PADDED}_issueDetail-edit"
        if assert_id_in "$OUT_DIR/${PADDED}_issueDetail-edit.json" \
          "issue_edit_dialog_root" "issue_edit_dialog_title_input" "issue_edit_dialog_body_input" \
          "issue_markdown_toolbar" "issue_markdown_toolbar_h1" "issue_markdown_toolbar_bold" \
          "issue_markdown_toolbar_image" "issue_edit_dialog_ok_btn" "issue_edit_dialog_cancel_btn"; then
          EDIT_CHECK=1
        else
          EDIT_CHECK=0
        fi
        tap_id "$OUT_DIR/${PADDED}_issueDetail-edit.json" "issue_edit_dialog_cancel_btn" || true
        sleep 3
        dumpnow "$OUT_DIR/_issue_after_edit.json" || true
        if [ -s "$OUT_DIR/_issue_after_edit.json" ]; then
          COMMENT_SOURCE_LAYOUT="$OUT_DIR/_issue_after_edit.json"
        fi
      else
        EDIT_CHECK=0
      fi
    fi
    COMMENT_OPTIONS_CHECK=1
    if grep -q "\"id\":\"issue_comment_row_0\"" "$COMMENT_SOURCE_LAYOUT"; then
      if tap_id "$COMMENT_SOURCE_LAYOUT" "issue_comment_row_0"; then
        sleep 2
        snap "${PADDED}_issueDetail-commentOptions"
        if assert_id_in "$OUT_DIR/${PADDED}_issueDetail-commentOptions.json" \
          "issue_comment_options_dialog" "issue_comment_option_edit" "issue_comment_option_delete" \
          "issue_comment_option_cancel"; then
          if tap_id "$OUT_DIR/${PADDED}_issueDetail-commentOptions.json" "issue_comment_option_edit"; then
            wait_for_id "issue_comment_edit_dialog_root" 5 || true
            sleep 1
            snap "${PADDED}_issueDetail-commentEdit"
            if ! assert_id_in "$OUT_DIR/${PADDED}_issueDetail-commentEdit.json" \
              "issue_comment_edit_dialog_root" "issue_comment_edit_dialog_body_input" \
              "issue_comment_edit_markdown_toolbar" "issue_comment_edit_markdown_toolbar_h1" \
              "issue_comment_edit_markdown_toolbar_image" "issue_comment_edit_dialog_ok_btn" \
              "issue_comment_edit_dialog_cancel_btn"; then
              COMMENT_OPTIONS_CHECK=0
            fi
            tap_id "$OUT_DIR/${PADDED}_issueDetail-commentEdit.json" "issue_comment_edit_dialog_cancel_btn" || true
            sleep 2
            dumpnow "$OUT_DIR/_issue_after_comment_edit.json" || true
            if [ -s "$OUT_DIR/_issue_after_comment_edit.json" ]; then
              COMMENT_SOURCE_LAYOUT="$OUT_DIR/_issue_after_comment_edit.json"
            fi
          else
            COMMENT_OPTIONS_CHECK=0
          fi
        else
          COMMENT_OPTIONS_CHECK=0
        fi
      else
        COMMENT_OPTIONS_CHECK=0
      fi
    else
      COMMENT_OPTIONS_CHECK=0
    fi
    COMMENT_REPLY_CHECK=1
    if grep -q "\"id\":\"common_bottom_bar_item_comment\"" "$COMMENT_SOURCE_LAYOUT"; then
      if tap_id "$COMMENT_SOURCE_LAYOUT" "common_bottom_bar_item_comment"; then
        wait_for_id "issue_reply_dialog_root" 5 || true
        sleep 1
        snap "${PADDED}_issueDetail-reply"
        if assert_id_in "$OUT_DIR/${PADDED}_issueDetail-reply.json" \
          "issue_reply_dialog_root" "issue_reply_dialog_body_input" \
          "issue_reply_markdown_toolbar" "issue_reply_markdown_toolbar_h1" \
          "issue_reply_markdown_toolbar_image" "issue_reply_dialog_ok_btn" \
          "issue_reply_dialog_cancel_btn"; then
          tap_id "$OUT_DIR/${PADDED}_issueDetail-reply.json" "issue_reply_dialog_cancel_btn" || true
          sleep 1
        else
          COMMENT_REPLY_CHECK=0
        fi
      else
        COMMENT_REPLY_CHECK=0
      fi
    else
      COMMENT_REPLY_CHECK=0
    fi
	    if assert_id_in "$OUT_DIR/${PADDED}_issueDetail.json" \
	      "issue_detail_root" "issue_detail_appbar" "appbar_action_r_more" "issue_detail_body_html" "issue_detail_bottom_bar" "issue_comment_row_0" \
      && [ $COMMENT_OPTIONS_CHECK -eq 1 ] \
      && [ $COMMENT_REPLY_CHECK -eq 1 ] \
      && [ $EDIT_CHECK -eq 1 ]; then
      mark_end "issueDetail" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "issueDetail" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "issueDetail" "$PADDED" "no_issue_appbar"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 15 codeDetail（aa start --PS bootCode "fullName|branch|path"）
# =========================================================
IDX=15
run $IDX "codeDetail" "CodeDetail（aa start --PS bootCode）"
if should_run "codeDetail"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootCode '$DEMO_CODE'" >/dev/null 2>&1
  sleep 6
  PASS=0
  # NavDestination 内的 root Column id 被 ArkUI uitest 吞掉，改用 appbar 作锚点（与 14 issueDetail 同款）
  if wait_for_id "code_detail_appbar" 12; then
    PASS=1
  fi
  # Compose 文件详情统一走 WebView：Markdown 文件由 GitHub HTML 内容 + WebView 渲染。
  wait_for_id "code_detail_web" 12 || true
  sleep 3
  snap "${PADDED}_codeDetail"
  if [ $PASS -eq 1 ]; then
	    if assert_id_in "$OUT_DIR/${PADDED}_codeDetail.json" "code_detail_appbar" "appbar_action_r_more" "code_detail_title_text" \
      && assert_id_in "$OUT_DIR/${PADDED}_codeDetail.json" "code_detail_web" \
      && { [ -z "$CODE_DETAIL_TITLE_ASSERT" ] || assert_text_in "$OUT_DIR/${PADDED}_codeDetail.json" "$CODE_DETAIL_TITLE_ASSERT"; } \
      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_codeDetail.png" "$OUT_DIR/${PADDED}_codeDetail.json" "code_detail_web" "8.0"; then
      mark_end "codeDetail" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "codeDetail" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "codeDetail" "$PADDED" "no_code_appbar"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 10 my-avatar-static / notify / readHistory
# =========================================================
# 先回 home/my 找入口
for spec in "10 my-setting avatar-static" "11 my-notify notify" "12 my-readHistory readHistory"; do
  read -r IDX KEY ENTRY_HINT <<< "$spec"
  run $IDX "$KEY" "My → $ENTRY_HINT"
  if should_run "$KEY"; then
    PADDED="$IDX"
    if [ "$KEY" = "my-readHistory" ]; then
      log "  seed read history via bootRepo($DEMO_REPO)"
      hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
      sleep 1
      hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootRepo '$DEMO_REPO'" >/dev/null 2>&1
      if wait_for_id "repo_detail_root" 20 || wait_for_id "repository_detail_root" 5; then
        wait_for_id "repo_header_name" 20 || true
        wait_for_id "repo_event_row_0" 12 || true
        sleep 4
      else
        log "  seed read history did not reach repo detail root"
      fi
    fi
    # 回 home + 切 my（先 force-stop 保证从干净状态进 home）
    hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
    sleep 1
    hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE$BOOT_LOCALE_ARG" >/dev/null 2>&1
    sleep 4
    wait_for_id "home_main_content" 10 || true
    HIT=0
    if [ "$KEY" = "my-readHistory" ]; then
      dumpnow "$OUT_DIR/_pre_$KEY.json"
      if tap_id "$OUT_DIR/_pre_$KEY.json" "appbar_action_l_menu"; then
        sleep 1
        dumpnow "$OUT_DIR/_pre_${KEY}_drawer.json"
        tap_id "$OUT_DIR/_pre_${KEY}_drawer.json" "drawer_menu_item_history" && HIT=1
      fi
    else
      dumpnow "$OUT_DIR/_pre_my_for_$KEY.json"
      tap_id "$OUT_DIR/_pre_my_for_$KEY.json" "home_tab_bar_my" || true
      wait_for_id "tab_page_root_my" 10 || true
      sleep 1
      dumpnow "$OUT_DIR/_pre_$KEY.json"
      if [ "$KEY" = "my-setting" ]; then
        for cand in "user_head_avatar" "user_head_avatar_placeholder"; do
          if grep -q "\"id\":\"$cand\"" "$OUT_DIR/_pre_$KEY.json"; then
            tap_id "$OUT_DIR/_pre_$KEY.json" "$cand" && HIT=1 && break
          fi
        done
      elif [ "$KEY" = "my-notify" ]; then
        for cand in "user_head_bell" "my_notify_entry" "my_entry_notify" "notify_entry"; do
          if grep -q "\"id\":\"$cand\"" "$OUT_DIR/_pre_$KEY.json"; then
            tap_id "$OUT_DIR/_pre_$KEY.json" "$cand" && HIT=1 && break
          fi
        done
      else
        for cand in "my_${ENTRY_HINT}_entry" "my_entry_${ENTRY_HINT}" "user_${ENTRY_HINT}" "${ENTRY_HINT}_entry"; do
          if grep -q "\"id\":\"$cand\"" "$OUT_DIR/_pre_$KEY.json"; then
            tap_id "$OUT_DIR/_pre_$KEY.json" "$cand" && HIT=1 && break
          fi
        done
      fi
    fi
    sleep 3
    snap "${PADDED}_${KEY}"
    if [ $HIT -eq 1 ]; then
      if [ "$KEY" = "my-notify" ]; then
        NOTIFY_ISSUE_ROUTE_CHECK=1
        NOTIFY_ISSUE_ROW_ID=$(python3 - "$OUT_DIR/${PADDED}_${KEY}.json" <<'PY'
import json
import re
import sys

try:
    root = json.load(open(sys.argv[1]))
except Exception:
    print("")
    sys.exit(0)

found = []
def walk(node):
    attrs = node.get("attributes", {}) or {}
    ident = attrs.get("id", "") or ""
    text = attrs.get("text", "") or ""
    m = re.match(r"notify_row_status_(\d+)$", ident)
    if m and "Issue" in text:
        found.append("notify_row_" + m.group(1))
    for child in node.get("children", []) or []:
        walk(child)

walk(root)
print(found[0] if found else "")
PY
)
        if [ -n "$NOTIFY_ISSUE_ROW_ID" ]; then
          if tap_id "$OUT_DIR/${PADDED}_${KEY}.json" "$NOTIFY_ISSUE_ROW_ID"; then
            if wait_for_id "issue_detail_appbar" 12; then
              sleep 4
              snap "${PADDED}_${KEY}-issueDetail"
              if ! assert_id_in "$OUT_DIR/${PADDED}_${KEY}-issueDetail.json" \
                "issue_detail_appbar" "issue_detail_body_html"; then
                NOTIFY_ISSUE_ROUTE_CHECK=0
              fi
            else
              NOTIFY_ISSUE_ROUTE_CHECK=0
            fi
          else
            NOTIFY_ISSUE_ROUTE_CHECK=0
          fi
        else
          log "  my-notify visible page has no Issue row; fallback to bootNotifyIssue($DEMO_ISSUE)"
          hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
          sleep 1
          hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE$BOOT_LOCALE_ARG --ps bootNotifyIssue '$DEMO_ISSUE'" >/dev/null 2>&1
          restart_hilog_capture "my-notify-bootIssue" || true
          if wait_for_id "notify_root" 12; then
            sleep 2
            snap "${PADDED}_${KEY}-bootIssue"
            if assert_id_in "$OUT_DIR/${PADDED}_${KEY}-bootIssue.json" \
              "notify_root" "notify_row_0" "notify_row_status_0" \
              && assert_text_in "$OUT_DIR/${PADDED}_${KEY}-bootIssue.json" "Issue" \
              && tap_id "$OUT_DIR/${PADDED}_${KEY}-bootIssue.json" "notify_row_0"; then
              if wait_for_id "issue_detail_appbar" 12; then
                sleep 4
                snap "${PADDED}_${KEY}-bootIssue-issueDetail"
                if ! assert_id_in "$OUT_DIR/${PADDED}_${KEY}-bootIssue-issueDetail.json" \
                  "issue_detail_appbar" "issue_detail_body_html"; then
                  NOTIFY_ISSUE_ROUTE_CHECK=0
                fi
              else
                NOTIFY_ISSUE_ROUTE_CHECK=0
              fi
            else
              NOTIFY_ISSUE_ROUTE_CHECK=0
            fi
          else
            NOTIFY_ISSUE_ROUTE_CHECK=0
          fi
        fi
        if assert_id_in "$OUT_DIR/${PADDED}_${KEY}.json" "notify_root" "notify_tab_bar" "notify_pull_list" \
          && assert_absent_id_in "$OUT_DIR/${PADDED}_${KEY}.json" "notify_initial_loading" "notify_initial_error" \
          && { [ "$OH_LOCALE" != "en" ] || {
            assert_text_in "$OUT_DIR/${PADDED}_${KEY}.json" "Notification" \
              && assert_text_in "$OUT_DIR/${PADDED}_${KEY}.json" "Unread" \
              && assert_text_in "$OUT_DIR/${PADDED}_${KEY}.json" "Participating" \
              && assert_text_in "$OUT_DIR/${PADDED}_${KEY}.json" "All" \
              && assert_text_in "$OUT_DIR/${PADDED}_${KEY}.json" "Type" \
              && assert_text_in "$OUT_DIR/${PADDED}_${KEY}.json" "Status" \
              && assert_any_text_in "$OUT_DIR/${PADDED}_${KEY}.json" "days ago" "hours ago" "minutes ago" "just now";
          }; } \
          && [ $NOTIFY_ISSUE_ROUTE_CHECK -eq 1 ]; then
          mark_end "$KEY" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
        else
          mark_end "$KEY" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
      elif [ "$KEY" = "my-readHistory" ]; then
        READ_HISTORY_ROUTE_CHECK=1
        if tap_id "$OUT_DIR/${PADDED}_${KEY}.json" "read_history_row_0"; then
          if wait_for_id "repo_detail_root" 25 || wait_for_id "repository_detail_root" 5; then
            wait_for_id "repo_header_name" 20 || true
            sleep 3
            snap "${PADDED}_${KEY}-repoDetail"
            if ! assert_id_in "$OUT_DIR/${PADDED}_${KEY}-repoDetail.json" \
              "repo_detail_root" "appbar_root" "appbar_title" "repo_header_name"; then
              READ_HISTORY_ROUTE_CHECK=0
            fi
          else
            READ_HISTORY_ROUTE_CHECK=0
          fi
        else
          READ_HISTORY_ROUTE_CHECK=0
        fi
        if assert_id_in "$OUT_DIR/${PADDED}_${KEY}.json" "read_history_root" "read_history_appbar" "read_history_pull_list" "read_history_row_0" "read_history_row_0_name" "read_history_row_0_type" "read_history_row_0_star_text" "read_history_row_0_fork_text" \
          && assert_text_in "$OUT_DIR/${PADDED}_${KEY}.json" "$DEMO_REPO_OWNER" \
          && [ $READ_HISTORY_ROUTE_CHECK -eq 1 ]; then
          mark_end "$KEY" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
        else
          mark_end "$KEY" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
      elif [ "$KEY" = "my-setting" ]; then
        if assert_id_in "$OUT_DIR/${PADDED}_${KEY}.json" \
          "tab_page_root_my" "user_head_root" "user_head_display_name" \
          && assert_absent_id_in "$OUT_DIR/${PADDED}_${KEY}.json" \
          "setting_root" "setting_scroll" "setting_person_info_btn" "my_logout_btn"; then
          mark_end "$KEY" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
        else
          mark_end "$KEY" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
      else
        mark_end "$KEY" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
      fi
    else
      log "  $KEY entry not found in my-tab — snapshot only"
      mark_end "$KEY" "$PADDED" "no_entry"; SKIP_COUNT=$((SKIP_COUNT + 1))
    fi
  fi
done

# =========================================================
#   场景 17 userDetail-list（aa start --PS bootUser，并从统计区进入 CommonList）
# =========================================================
IDX=17
run $IDX "userDetail-list" "UserDetail → Repositories List（aa start --PS bootUser）"
if should_run "userDetail-list"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootUser '$DEMO_USER'" >/dev/null 2>&1
  sleep 5
  PASS=0
  if wait_for_id "user_detail_root" 12 && wait_for_id "user_detail_counts_row" 8; then
    PASS=1
  fi
  sleep 2
  snap "${PADDED}_userDetail"
  LIST_PASS=0
  if [ $PASS -eq 1 ]; then
    dumpnow "$OUT_DIR/_pre_userDetail_list.json"
    if tap_id "$OUT_DIR/_pre_userDetail_list.json" "user_detail_repos_block"; then
      sleep 4
      if wait_for_id "common_list_repositories_root" 12 || wait_for_id "common_list_user_repos_root" 4; then
        LIST_PASS=1
      fi
      snap "${PADDED}_userDetail-repos"
    else
      snap "${PADDED}_userDetail-repos"
    fi
	  fi
	  NAV_PASS=0
	  if [ $LIST_PASS -eq 1 ]; then
	    dumpnow "$OUT_DIR/_pre_userDetail_repos_nav.json"
	    if tap_id "$OUT_DIR/_pre_userDetail_repos_nav.json" "common_list_repositories_repo_0"; then
	      sleep 4
	      if wait_for_id "repo_detail_root" 12 || wait_for_id "repository_detail_root" 4; then
	        wait_for_id "repo_header_name" 12 || true
	        NAV_PASS=1
	      fi
	      snap "${PADDED}_userDetail-repos-repoDetail"
	    else
	      snap "${PADDED}_userDetail-repos-repoDetail"
	    fi
	  fi
	  if [ $PASS -eq 1 ] && [ $LIST_PASS -eq 1 ] && [ $NAV_PASS -eq 1 ]; then
	    if assert_id_in "$OUT_DIR/${PADDED}_userDetail.json" \
	      "user_detail_root" "user_detail_header_stack" "user_detail_head_row" "user_detail_avatar" \
	      "user_detail_name" "user_detail_login" "user_detail_joined" "user_detail_counts_row" \
      "user_detail_repos_block" "user_detail_repos_label" \
      "user_detail_followers_block" "user_detail_followers_label" \
      "user_detail_following_block" "user_detail_following_label" \
      "user_detail_stared_block" "user_detail_stared_count" "user_detail_stared_label" \
      "user_detail_dynamic_title_bar" "user_detail_dynamic_title" "user_detail_follow_fab" \
      && assert_id_text_positive_int "$OUT_DIR/${PADDED}_userDetail.json" "user_detail_stared_count" \
      && assert_any_id_in "$OUT_DIR/${PADDED}_userDetail.json" "user-detail-follow-icon" "user_detail_follow_fab_icon_following" "user_detail_follow_fab_icon_add" \
      && assert_absent_id_in "$OUT_DIR/${PADDED}_userDetail.json" \
        "user_detail_follow_btn" "user_detail_be_stared_block" "user_detail_contribution" \
        "user_detail_blog" "user_detail_orgs" \
      && assert_absent_text_in "$OUT_DIR/${PADDED}_userDetail.json" "nothing" "Ta什么都没留下" \
      && assert_text_in "$OUT_DIR/${PADDED}_userDetail.json" "$DEMO_USER" \
      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_userDetail.png" "$OUT_DIR/${PADDED}_userDetail.json" "user_detail_avatar" "8.0" \
      && assert_any_id_in "$OUT_DIR/${PADDED}_userDetail-repos.json" "common-list-repositories" "common_list_repositories_root" "common_list_user_repos_root" \
      && assert_any_text_in "$OUT_DIR/${PADDED}_userDetail-repos.json" "$COMMON_LIST_REPOS_TITLE_ZH" "$COMMON_LIST_REPOS_TITLE_EN" \
	      && assert_id_in "$OUT_DIR/${PADDED}_userDetail-repos.json" \
	        "common_list_repositories_header" "common_list_repositories_title" \
	        "common_list_repositories_repo_0" "common_list_repositories_repo_0_avatar" \
	        "common_list_repositories_repo_0_name" "common_list_repositories_repo_0_owner_text" \
	      && assert_absent_id_in "$OUT_DIR/${PADDED}_userDetail-repos.json" "common_list_repositories_user_0" \
	      && assert_repo_titles_not_compact "$OUT_DIR/${PADDED}_userDetail-repos.json" \
	      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_userDetail-repos.png" "$OUT_DIR/${PADDED}_userDetail-repos.json" "common_list_repositories_repo_0_avatar" "8.0" \
	      && assert_id_in "$OUT_DIR/${PADDED}_userDetail-repos-repoDetail.json" \
	        "repo_detail_root" "appbar_root" "appbar_title" "repo_header_name"; then
	      mark_end "userDetail-list" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
	    else
	      mark_end "userDetail-list" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
	    fi
	  elif [ $PASS -eq 1 ] && [ $LIST_PASS -eq 1 ]; then
	    mark_end "userDetail-list" "$PADDED" "repo_nav_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
	  elif [ $PASS -eq 1 ]; then
	    mark_end "userDetail-list" "$PADDED" "no_list"; FAIL_COUNT=$((FAIL_COUNT + 1))
	  else
    mark_end "userDetail-list" "$PADDED" "no_user_root"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 18 repoDetail-stargazers-list（Compose: repo header stat → CommonList）
# =========================================================
IDX=18
run $IDX "repoDetail-stargazers-list" "RepoDetail header Stars → Stargazers List"
if should_run "repoDetail-stargazers-list"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootRepo '$DEMO_REPO'" >/dev/null 2>&1
  sleep 5
  PASS=0
  if wait_for_id "repo_detail_root" 10 || wait_for_id "repository_detail_root" 5; then
    wait_for_id "repo_header_bottom_cell_star" 12 || true
    PASS=1
  fi
  snap "${PADDED}_repoDetail-before-stargazers"
  LIST_PASS=0
	  if [ $PASS -eq 1 ]; then
	    dumpnow "$OUT_DIR/_pre_repoDetail_stargazers.json"
	    if tap_id_offset "$OUT_DIR/_pre_repoDetail_stargazers.json" "repo_header_bottom_cell_star" 0 -50; then
	      sleep 4
      if wait_for_id "common_list_stargazers_root" 12 || wait_for_id "common_list_repo_star_root" 4; then
        LIST_PASS=1
      else
        dumpnow "$OUT_DIR/_pre_repoDetail_stargazers_retry.json"
        if tap_id_offset "$OUT_DIR/_pre_repoDetail_stargazers_retry.json" "repo_header_bottom_cell_star" 0 -50; then
          sleep 4
          if wait_for_id "common_list_stargazers_root" 12 || wait_for_id "common_list_repo_star_root" 4; then
            LIST_PASS=1
          fi
        fi
      fi
      snap "${PADDED}_repoDetail-stargazers"
    else
	      snap "${PADDED}_repoDetail-stargazers"
	    fi
	  fi
	  NAV_PASS=0
	  if [ $LIST_PASS -eq 1 ]; then
	    dumpnow "$OUT_DIR/_pre_repoDetail_stargazers_user_nav.json"
	    if tap_id "$OUT_DIR/_pre_repoDetail_stargazers_user_nav.json" "common_list_stargazers_user_0"; then
	      sleep 4
	      if wait_for_id "user_detail_root" 12; then
	        wait_for_id "user_detail_login" 12 || true
	        NAV_PASS=1
	      fi
	      snap "${PADDED}_repoDetail-stargazers-userDetail"
	    else
	      snap "${PADDED}_repoDetail-stargazers-userDetail"
	    fi
	  fi
	  if [ $PASS -eq 1 ] && [ $LIST_PASS -eq 1 ] && [ $NAV_PASS -eq 1 ]; then
	    if assert_id_in "$OUT_DIR/${PADDED}_repoDetail-before-stargazers.json" "repo_header_bottom_cell_star" \
	      && assert_any_id_in "$OUT_DIR/${PADDED}_repoDetail-stargazers.json" "common-list-stargazers" "common_list_stargazers_root" "common_list_repo_star_root" \
	      && assert_any_text_in "$OUT_DIR/${PADDED}_repoDetail-stargazers.json" "$COMMON_LIST_STARGAZERS_TITLE_ZH" "$COMMON_LIST_STARGAZERS_TITLE_EN" \
	      && assert_id_in "$OUT_DIR/${PADDED}_repoDetail-stargazers.json" \
	        "common_list_stargazers_header" "common_list_stargazers_title" \
	        "common_list_stargazers_user_0" "common_list_stargazers_user_0_avatar" \
	        "common_list_stargazers_user_0_login" \
	      && assert_absent_id_in "$OUT_DIR/${PADDED}_repoDetail-stargazers.json" "common_list_stargazers_repo_0" \
	      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_repoDetail-stargazers.png" "$OUT_DIR/${PADDED}_repoDetail-stargazers.json" "common_list_stargazers_user_0_avatar" "8.0" \
	      && assert_id_in "$OUT_DIR/${PADDED}_repoDetail-stargazers-userDetail.json" \
	        "user_detail_root" "user_detail_avatar" "user_detail_login"; then
	      mark_end "repoDetail-stargazers-list" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
	    else
	      mark_end "repoDetail-stargazers-list" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
	    fi
	  elif [ $PASS -eq 1 ] && [ $LIST_PASS -eq 1 ]; then
	    mark_end "repoDetail-stargazers-list" "$PADDED" "user_nav_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
	  elif [ $PASS -eq 1 ]; then
	    mark_end "repoDetail-stargazers-list" "$PADDED" "no_list"; FAIL_COUNT=$((FAIL_COUNT + 1))
	  else
    mark_end "repoDetail-stargazers-list" "$PADDED" "no_repo_root"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 20/21 repoDetail forks/watchers list（Compose header stats → CommonList）
# =========================================================
for spec in "20 repoDetail-forks-list fork forks repo_header_bottom_cell_fork common_list_forks_root common_list_repo_fork_root repository RepoDetail header Forks → Forks List" \
            "21 repoDetail-watchers-list watch watchers repo_header_bottom_cell_watch common_list_watchers_root common_list_repo_watcher_root user RepoDetail header Watchers → Watchers List"; do
  read -r IDX KEY STAT_NAME LIST_TYPE CELL_ID ROOT_ID LEGACY_ROOT SHOW_TYPE DESC <<< "$spec"
  run $IDX "$KEY" "$DESC"
  if should_run "$KEY"; then
    PADDED=$(printf "%02d" $IDX)
    hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
    sleep 1
    hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootRepo '$DEMO_REPO'" >/dev/null 2>&1
    sleep 5
    PASS=0
    if wait_for_id "repo_detail_root" 10 || wait_for_id "repository_detail_root" 5; then
      wait_for_id "$CELL_ID" 12 || true
      PASS=1
    fi
    snap "${PADDED}_repoDetail-before-${LIST_TYPE}"
    LIST_PASS=0
    if [ $PASS -eq 1 ]; then
      dumpnow "$OUT_DIR/_pre_repoDetail_${LIST_TYPE}.json"
      if tap_id_offset "$OUT_DIR/_pre_repoDetail_${LIST_TYPE}.json" "$CELL_ID" 0 -50; then
        sleep 4
        if wait_for_id "$ROOT_ID" 12 || wait_for_id "$LEGACY_ROOT" 4; then
          LIST_PASS=1
        else
          dumpnow "$OUT_DIR/_pre_repoDetail_${LIST_TYPE}_retry.json"
          if tap_id_offset "$OUT_DIR/_pre_repoDetail_${LIST_TYPE}_retry.json" "$CELL_ID" 0 -50; then
            sleep 4
            if wait_for_id "$ROOT_ID" 12 || wait_for_id "$LEGACY_ROOT" 4; then
              LIST_PASS=1
            fi
          fi
        fi
        snap "${PADDED}_repoDetail-${LIST_TYPE}"
      else
        snap "${PADDED}_repoDetail-${LIST_TYPE}"
      fi
    fi
    if [ $PASS -eq 1 ] && [ $LIST_PASS -eq 1 ]; then
      if assert_id_in "$OUT_DIR/${PADDED}_repoDetail-before-${LIST_TYPE}.json" "$CELL_ID" \
        && assert_any_id_in "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.json" "common-list-${LIST_TYPE}" "$ROOT_ID" "$LEGACY_ROOT" \
        && { if [ "$LIST_TYPE" = "forks" ]; then assert_any_text_in "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.json" "$COMMON_LIST_FORKS_TITLE_ZH" "$COMMON_LIST_FORKS_TITLE_EN"; else assert_any_text_in "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.json" "$COMMON_LIST_WATCHERS_TITLE_ZH" "$COMMON_LIST_WATCHERS_TITLE_EN"; fi; } \
        && { if [ "$LIST_TYPE" = "forks" ]; then
          assert_id_in "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.json" \
            "common_list_forks_header" "common_list_forks_title" \
            "common_list_forks_repo_0" "common_list_forks_repo_0_avatar" \
            "common_list_forks_repo_0_name" "common_list_forks_repo_0_owner_text" \
          && assert_absent_id_in "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.json" "common_list_forks_user_0" \
          && assert_repo_titles_not_compact "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.json" \
          && assert_png_id_nonflat "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.png" "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.json" "common_list_forks_repo_0_avatar" "8.0";
        else
          assert_id_in "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.json" \
            "common_list_watchers_header" "common_list_watchers_title" \
            "common_list_watchers_user_0" "common_list_watchers_user_0_avatar" \
            "common_list_watchers_user_0_login" \
          && assert_absent_id_in "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.json" "common_list_watchers_repo_0" \
          && assert_png_id_nonflat "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.png" "$OUT_DIR/${PADDED}_repoDetail-${LIST_TYPE}.json" "common_list_watchers_user_0_avatar" "8.0";
        fi; }; then
        mark_end "$KEY" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
      else
        mark_end "$KEY" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    elif [ $PASS -eq 1 ]; then
      mark_end "$KEY" "$PADDED" "no_list"; FAIL_COUNT=$((FAIL_COUNT + 1))
    else
      mark_end "$KEY" "$PADDED" "no_repo_root"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi
done

# =========================================================
#   场景 32 repoDetail-topic-list（Compose: repo topic chip → topics CommonList）
# =========================================================
IDX=32
run $IDX "repoDetail-topic-list" "RepoDetail topic chip → Topics List"
if should_run "repoDetail-topic-list"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootRepo '$DEMO_REPO'" >/dev/null 2>&1
  sleep 5
  PASS=0
  if wait_for_id "repo_detail_root" 10 || wait_for_id "repository_detail_root" 5; then
    wait_for_id "repo_header_topic_0" 12 || true
    PASS=1
  fi
  snap "${PADDED}_repoDetail-before-topic"
  LIST_PASS=0
  if [ $PASS -eq 1 ]; then
    dumpnow "$OUT_DIR/_pre_repoDetail_topic.json"
    if tap_id "$OUT_DIR/_pre_repoDetail_topic.json" "repo_header_topic_0"; then
      sleep 5
      if wait_for_id "common_list_topics_root" 15; then
        LIST_PASS=1
      fi
      snap "${PADDED}_repoDetail-topic"
    else
      snap "${PADDED}_repoDetail-topic"
    fi
  fi
  NAV_PASS=0
  if [ $LIST_PASS -eq 1 ]; then
    dumpnow "$OUT_DIR/_pre_topic_repo.json"
    if tap_id "$OUT_DIR/_pre_topic_repo.json" "common_list_topics_repo_0"; then
      sleep 4
      if wait_for_id "repo_detail_root" 12 || wait_for_id "repository_detail_root" 4; then
        NAV_PASS=1
      fi
      snap "${PADDED}_repoDetail-topic-repo"
    else
      snap "${PADDED}_repoDetail-topic-repo"
    fi
  fi
  if [ $PASS -eq 1 ] && [ $LIST_PASS -eq 1 ] && [ $NAV_PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_repoDetail-before-topic.json" "repo_header_topics" "repo_header_topic_0" \
      && assert_any_text_in "$OUT_DIR/${PADDED}_repoDetail-topic.json" "$COMMON_LIST_TOPICS_TITLE_ZH" "$COMMON_LIST_TOPICS_TITLE_EN" \
      && assert_id_in "$OUT_DIR/${PADDED}_repoDetail-topic.json" \
        "common_list_topics_root" "common_list_topics_header" "common_list_topics_title" \
        "common_list_topics_repo_0" "common_list_topics_repo_0_avatar" \
        "common_list_topics_repo_0_name" "common_list_topics_repo_0_owner_text" \
      && assert_absent_id_in "$OUT_DIR/${PADDED}_repoDetail-topic.json" "common_list_topics_user_0" \
      && assert_repo_titles_not_compact "$OUT_DIR/${PADDED}_repoDetail-topic.json" \
      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_repoDetail-topic.png" "$OUT_DIR/${PADDED}_repoDetail-topic.json" "common_list_topics_repo_0_avatar" "8.0" \
      && assert_id_in "$OUT_DIR/${PADDED}_repoDetail-topic-repo.json" "repo_detail_root" "repo_detail_tabs"; then
      mark_end "repoDetail-topic-list" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "repoDetail-topic-list" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  elif [ $PASS -eq 1 ] && [ $LIST_PASS -eq 1 ]; then
    mark_end "repoDetail-topic-list" "$PADDED" "repo_nav_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
  elif [ $PASS -eq 1 ]; then
    mark_end "repoDetail-topic-list" "$PADDED" "no_list"; FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    mark_end "repoDetail-topic-list" "$PADDED" "no_repo_topic"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 36 user-orgs-list（Compose: list_screen/user_orgs/{login}/_）
# =========================================================
IDX=36
run $IDX "user-orgs-list" "CommonList user_orgs（aa start --PS bootCommonList）"
if should_run "user-orgs-list"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE$BOOT_LOCALE_ARG --ps bootCommonList 'user_orgs|user|$DEMO_ORGS_USER|_'" >/dev/null 2>&1
  sleep 6
  PASS=0
  if wait_for_id "common_list_user_orgs_root" 15; then
    PASS=1
  fi
  snap "${PADDED}_user-orgs-list"
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_user-orgs-list.json" \
        "common_list_user_orgs_root" "common_list_user_orgs_header" "common_list_user_orgs_title" \
        "common_list_user_orgs_user_0" "common_list_user_orgs_user_0_avatar" \
        "common_list_user_orgs_user_0_login" \
      && assert_any_text_in "$OUT_DIR/${PADDED}_user-orgs-list.json" "$COMMON_LIST_ORGS_TITLE_ZH" "$COMMON_LIST_ORGS_TITLE_EN" \
      && assert_absent_id_in "$OUT_DIR/${PADDED}_user-orgs-list.json" "common_list_user_orgs_repo_0" \
      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_user-orgs-list.png" "$OUT_DIR/${PADDED}_user-orgs-list.json" "common_list_user_orgs_user_0_avatar" "8.0"; then
      mark_end "user-orgs-list" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "user-orgs-list" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "user-orgs-list" "$PADDED" "no_list"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 38/39/40 Compose Profile CommonList branches
# =========================================================
for spec in \
  "38|user-followers-list|follower|user|common_list_follower|$COMMON_LIST_FOLLOWERS_TITLE_ZH|$COMMON_LIST_FOLLOWERS_TITLE_EN|user" \
  "39|user-following-list|following|user|common_list_following|$COMMON_LIST_FOLLOWING_TITLE_ZH|$COMMON_LIST_FOLLOWING_TITLE_EN|user" \
  "40|user-star-list|user_star|repository|common_list_user_star|$COMMON_LIST_USER_STAR_TITLE_ZH|$COMMON_LIST_USER_STAR_TITLE_EN|repo"; do
  IFS='|' read -r IDX KEY DATA_TYPE SHOW_TYPE ID_PREFIX TITLE_ZH TITLE_EN ROW_KIND <<< "$spec"
  run $IDX "$KEY" "CommonList ${DATA_TYPE}（aa start --PS bootCommonList）"
  if should_run "$KEY"; then
    PADDED=$(printf "%02d" "$IDX")
    hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
    sleep 1
    hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE$BOOT_LOCALE_ARG --ps bootCommonList '$DATA_TYPE|$SHOW_TYPE|$DEMO_USER|_'" >/dev/null 2>&1
    PASS=0
    NAV_PASS=0
    if wait_for_id "${ID_PREFIX}_root" 15; then
      if [ "$ROW_KIND" = "user" ]; then
        wait_for_id "${ID_PREFIX}_user_0" 10 && PASS=1
      else
        wait_for_id "${ID_PREFIX}_repo_0" 10 && PASS=1
      fi
    fi
    snap "${PADDED}_${KEY}"
    if [ $PASS -eq 1 ]; then
      if [ "$ROW_KIND" = "user" ]; then
        if tap_id "$OUT_DIR/${PADDED}_${KEY}.json" "${ID_PREFIX}_user_0"; then
          wait_for_id "user_detail_root" 12 && NAV_PASS=1
          snap "${PADDED}_${KEY}-userDetail"
        fi
        if assert_id_in "$OUT_DIR/${PADDED}_${KEY}.json" \
            "${ID_PREFIX}_root" "${ID_PREFIX}_header" "${ID_PREFIX}_title" \
            "${ID_PREFIX}_user_0" "${ID_PREFIX}_user_0_avatar" "${ID_PREFIX}_user_0_login" \
          && assert_any_text_in "$OUT_DIR/${PADDED}_${KEY}.json" "$TITLE_ZH" "$TITLE_EN" \
          && assert_absent_id_in "$OUT_DIR/${PADDED}_${KEY}.json" "${ID_PREFIX}_repo_0" \
          && assert_png_id_nonflat "$OUT_DIR/${PADDED}_${KEY}.png" "$OUT_DIR/${PADDED}_${KEY}.json" "${ID_PREFIX}_user_0_avatar" "8.0" \
          && [ $NAV_PASS -eq 1 ] \
          && assert_id_in "$OUT_DIR/${PADDED}_${KEY}-userDetail.json" "user_detail_root" "user_detail_avatar" "user_detail_login"; then
          mark_end "$KEY" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
        else
          mark_end "$KEY" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
      else
        if tap_id "$OUT_DIR/${PADDED}_${KEY}.json" "${ID_PREFIX}_repo_0"; then
          wait_for_id "repo_detail_root" 12 && NAV_PASS=1
          snap "${PADDED}_${KEY}-repoDetail"
        fi
        if assert_id_in "$OUT_DIR/${PADDED}_${KEY}.json" \
            "${ID_PREFIX}_root" "${ID_PREFIX}_header" "${ID_PREFIX}_title" \
            "${ID_PREFIX}_repo_0" "${ID_PREFIX}_repo_0_avatar" "${ID_PREFIX}_repo_0_name" "${ID_PREFIX}_repo_0_owner_text" \
          && assert_any_text_in "$OUT_DIR/${PADDED}_${KEY}.json" "$TITLE_ZH" "$TITLE_EN" \
          && assert_absent_id_in "$OUT_DIR/${PADDED}_${KEY}.json" "${ID_PREFIX}_user_0" \
          && assert_repo_titles_not_compact "$OUT_DIR/${PADDED}_${KEY}.json" \
          && assert_png_id_nonflat "$OUT_DIR/${PADDED}_${KEY}.png" "$OUT_DIR/${PADDED}_${KEY}.json" "${ID_PREFIX}_repo_0_avatar" "8.0" \
          && [ $NAV_PASS -eq 1 ] \
          && assert_id_in "$OUT_DIR/${PADDED}_${KEY}-repoDetail.json" "repo_detail_root" "repo_detail_tabs"; then
          mark_end "$KEY" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
        else
          mark_end "$KEY" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
      fi
    else
      mark_end "$KEY" "$PADDED" "no_list"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi
done

# =========================================================
#   场景 19 organization-profile（Compose: Organization profile → members）
# =========================================================
IDX=19
run $IDX "organization-profile" "Organization Profile → Members（aa start --PS bootUser）"
if should_run "organization-profile"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootUser '$DEMO_ORG'" >/dev/null 2>&1
  sleep 6
  PASS=0
  if wait_for_id "user_detail_root" 12 && wait_for_id "user_detail_counts_row" 8; then
    PASS=1
  fi
  wait_for_id "user_detail_org_member_row_0" 12 || true
  sleep 2
  snap "${PADDED}_organization-profile"
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_organization-profile.json" \
      "user_detail_root" "user_detail_header_stack" "user_detail_head_row" "user_detail_avatar" \
      "user_detail_name" "user_detail_login" "user_detail_joined" \
      "user_detail_counts_row" "user_detail_dynamic_title_bar" \
      "user_detail_dynamic_title" "user_detail_org_member_row_0" \
      "user_detail_org_member_avatar_0" "user_detail_org_member_login_0" \
      && assert_text_in "$OUT_DIR/${PADDED}_organization-profile.json" "$DEMO_ORG" \
      && assert_absent_id_in "$OUT_DIR/${PADDED}_organization-profile.json" \
        "user_detail_follow_btn" "user_detail_follow_fab" "user_detail_event_row_0" \
        "user_detail_blog" "user_detail_orgs" \
      && assert_absent_text_in "$OUT_DIR/${PADDED}_organization-profile.json" "nothing" "Ta什么都没留下" \
      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_organization-profile.png" "$OUT_DIR/${PADDED}_organization-profile.json" "user_detail_avatar" "8.0" \
      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_organization-profile.png" "$OUT_DIR/${PADDED}_organization-profile.json" "user_detail_org_member_avatar_0" "8.0"; then
      mark_end "organization-profile" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "organization-profile" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "organization-profile" "$PADDED" "no_org_root"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 37 notifyMarkAll（Compose: DoneAll → mark_all_as_read）
# =========================================================
IDX=37
run $IDX "notifyMarkAll" "Notification DoneAll marks injected row read"
if should_run "notifyMarkAll"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE$BOOT_LOCALE_ARG --ps bootNotifyIssue '$DEMO_ISSUE'" >/dev/null 2>&1
  restart_hilog_capture "notifyMarkAll" || true
  PASS=0
  if wait_for_id "notify_root" 12 && wait_for_id "notify_row_status_0" 8; then
    PASS=1
  fi
  sleep 1
  snap "${PADDED}_notifyMarkAll"
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_notifyMarkAll.json" \
        "notify_root" "notify_app_bar" "appbar_action_r_done_all" \
        "notify_row_0" "notify_row_status_0" \
      && assert_id_text_any "$OUT_DIR/${PADDED}_notifyMarkAll.json" "notify_row_status_0" "Unread" "未读" \
      && tap_id "$OUT_DIR/${PADDED}_notifyMarkAll.json" "appbar_action_r_done_all"; then
      sleep 2
      snap "${PADDED}_notifyMarkAll-after"
      if assert_id_in "$OUT_DIR/${PADDED}_notifyMarkAll-after.json" \
          "notify_root" "notify_row_0" "notify_row_status_0" \
        && assert_id_text_any "$OUT_DIR/${PADDED}_notifyMarkAll-after.json" "notify_row_status_0" "Read" "已读" \
        && assert_absent_id_in "$OUT_DIR/${PADDED}_notifyMarkAll-after.json" "notify_initial_loading" "notify_initial_error"; then
        mark_end "notifyMarkAll" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
      else
        mark_end "notifyMarkAll" "$PADDED" "after_assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      mark_end "notifyMarkAll" "$PADDED" "assert_or_tap_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "notifyMarkAll" "$PADDED" "no_notify_root"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 22 webPage（aa start --PS bootWeb）
# =========================================================
IDX=22
run $IDX "webPage" "WebPage（aa start --PS bootWeb）"
if should_run "webPage"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootWeb '$DEMO_WEB'" >/dev/null 2>&1
  sleep 5
  PASS=0
  if wait_for_id "web_page_root" 12 && wait_for_id "web_page_view" 8; then
    PASS=1
  fi
  sleep 3
  snap "${PADDED}_webPage"
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_webPage.json" "web_page_root" "web_page_appbar" "web_page_view" \
      && { [ -z "$DEMO_WEB_ASSERT" ] || assert_text_in "$OUT_DIR/${PADDED}_webPage.json" "$DEMO_WEB_ASSERT"; } \
      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_webPage.png" "$OUT_DIR/${PADDED}_webPage.json" "web_page_view" "8.0"; then
      mark_end "webPage" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "webPage" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "webPage" "$PADDED" "no_web_root"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 23 photoPage（aa start --PS bootPhoto）
# =========================================================
IDX=23
run $IDX "photoPage" "PhotoPage（aa start --PS bootPhoto）"
if should_run "photoPage"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE --ps bootPhoto '$DEMO_PHOTO'" >/dev/null 2>&1
  sleep 5
  PASS=0
  if wait_for_id "photo_page_root" 12 && wait_for_id "photo_image" 8; then
    PASS=1
  fi
  sleep 3
  snap "${PADDED}_photoPage"
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_photoPage.json" "photo_page_root" "photo_image" \
      && assert_absent_id_in "$OUT_DIR/${PADDED}_photoPage.json" "photo_loading" "photo_failed" \
      && assert_png_id_nonflat "$OUT_DIR/${PADDED}_photoPage.png" "$OUT_DIR/${PADDED}_photoPage.json" "photo_image" "8.0"; then
      mark_end "photoPage" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "photoPage" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "photoPage" "$PADDED" "no_photo_root"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 24 welcome（冷启动欢迎页，登录态不清除）
# =========================================================
IDX=24
run $IDX "welcome" "Welcome（冷启动欢迎页截图）"
if should_run "welcome"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE" >/dev/null 2>&1
  PASS=0
  if wait_for_id "welcome_root" 4; then
    PASS=1
  fi
  snap "${PADDED}_welcome"
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_welcome.json" "welcome_root" "welcome_image" "welcome_subtitle"; then
      mark_end "welcome" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "welcome" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "welcome" "$PADDED" "no_welcome_root"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 25 loginPage（aa start --PS bootLogin，不清除 token）
# =========================================================
IDX=25
run $IDX "loginPage" "LoginPage（aa start --PS bootLogin）"
if should_run "loginPage"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE$BOOT_LOCALE_ARG --ps bootLogin true" >/dev/null 2>&1
  PASS=0
  if wait_for_id "login_root" 8 && wait_for_id "login_token_input" 4; then
    PASS=1
  fi
  snap "${PADDED}_loginPage"
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_loginPage.json" \
      "login_stack_root" "login_root" "login_form" "login_logo" "login_title" "login_subtitle" \
      "login_token_field" "login_token_leading_icon" "login_token_input" \
      "login_submit_btn" "login_oauth_btn" "login_language_btn" \
      && assert_absent_id_in "$OUT_DIR/${PADDED}_loginPage.json" \
      "login_legacy_probe" "login_username_input" "login_password_input" \
      "login_register_link" "login_pat_btn"; then
      mark_end "loginPage" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "loginPage" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "loginPage" "$PADDED" "no_login_root"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 31 welcomeAnimation（Compose welcome bottom animation）
# =========================================================
IDX=31
run $IDX "welcomeAnimation" "Welcome animated bottom mark"
if should_run "welcomeAnimation"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE$BOOT_LOCALE_ARG --ps bootWelcomeHold true" >/dev/null 2>&1
  PASS=0
  if wait_for_id "welcome_root" 2 && wait_for_id "welcome_harmony_mark" 1; then
    snap "${PADDED}_welcomeAnimation-a"
    sleep 0.2
    snap "${PADDED}_welcomeAnimation-b"
    PASS=1
  fi
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_welcomeAnimation-a.json" \
      "welcome_root" "welcome_image" "welcome_harmony_mark" "welcome_harmony_letter" "welcome_harmony_label" "welcome_subtitle" \
      "welcome_harmony_mark_orbit_dot_0" "welcome_harmony_mark_orbit_dot_1" "welcome_harmony_mark_orbit_dot_2" \
      && assert_id_in "$OUT_DIR/${PADDED}_welcomeAnimation-b.json" \
      "welcome_root" "welcome_harmony_mark" "welcome_harmony_letter" "welcome_harmony_label" \
      "welcome_harmony_mark_orbit_dot_0" "welcome_harmony_mark_orbit_dot_1" "welcome_harmony_mark_orbit_dot_2" \
      && assert_text_in "$OUT_DIR/${PADDED}_welcomeAnimation-b.json" "HarmonyOS" \
      && assert_png_different "$OUT_DIR/${PADDED}_welcomeAnimation-a.png" "$OUT_DIR/${PADDED}_welcomeAnimation-b.png" "welcome-animation"; then
      mark_end "welcomeAnimation" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "welcomeAnimation" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
      mark_end "welcomeAnimation" "$PADDED" "no_welcome_animation"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 26 loginOAuth（LoginPage → OAuth WebView）
# =========================================================
IDX=26
run $IDX "loginOAuth" "LoginPage → OAuth WebView"
if should_run "loginOAuth"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE$BOOT_LOCALE_ARG --ps bootLogin true" >/dev/null 2>&1
  PASS=0
  if wait_for_id "login_root" 8; then
    snap "${PADDED}_loginOAuth-before"
    if tap_id "$OUT_DIR/${PADDED}_loginOAuth-before.json" "login_oauth_btn"; then
      sleep 3
      if wait_for_id "login_web_root" 8 && wait_for_id "login_web_view" 4; then
        PASS=1
      fi
    fi
  fi
  snap "${PADDED}_loginOAuth"
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_loginOAuth.json" "login_web_root" "login_web_appbar" "login_web_view" \
      && assert_text_in "$OUT_DIR/${PADDED}_loginOAuth.json" "redirect_uri=gsygithubapp" \
      && assert_text_in "$OUT_DIR/${PADDED}_loginOAuth.json" "scope=user%2Crepo%2Cgist%2Cnotifications%2Cread%3Aorg%2Cworkflow"; then
      mark_end "loginOAuth" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "loginOAuth" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "loginOAuth" "$PADDED" "no_login_web"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 29 loginLanguage（LoginPage → LanguageSelectDialog）
# =========================================================
IDX=29
run $IDX "loginLanguage" "LoginPage → Language dialog"
if should_run "loginLanguage"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE$BOOT_LOCALE_ARG --ps bootLogin true" >/dev/null 2>&1
  PASS=0
  if wait_for_id "login_root" 8; then
    dumpnow "$OUT_DIR/_pre_login_language.json"
    if tap_id "$OUT_DIR/_pre_login_language.json" "login_language_btn"; then
      sleep 1
      if wait_for_id "login_language_dialog" 6; then
        PASS=1
      fi
    fi
  fi
  snap "${PADDED}_loginLanguage"
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_loginLanguage.json" \
      "login_language_overlay" \
      "login_language_dialog" \
      "login_language_title" \
      "login_language_option_local" \
      "login_language_option_zh-CN" \
      "login_language_option_en" \
      "login_language_label_local" \
      "login_language_label_zh-CN" \
      "login_language_label_en" \
      "login_language_radio_local" \
      "login_language_radio_zh-CN" \
      "login_language_radio_en" \
      && assert_absent_id_in "$OUT_DIR/${PADDED}_loginLanguage.json" "login_language_cancel_btn"; then
      mark_end "loginLanguage" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "loginLanguage" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "loginLanguage" "$PADDED" "no_language_dialog"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 30 loginAnimation（Compose AnimatedLogoSwitcher）
# =========================================================
IDX=30
run $IDX "loginAnimation" "LoginPage animated logo"
if should_run "loginAnimation"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell "aa start -a $ABILITY -b $BUNDLE$BOOT_LOCALE_ARG --ps bootLogin true" >/dev/null 2>&1
  PASS=0
  if wait_for_id "login_root" 8 && wait_for_id "login_logo" 4; then
    sleep 1
    snap "${PADDED}_loginAnimation-a"
    sleep 3
    snap "${PADDED}_loginAnimation-b"
    PASS=1
  fi
  if [ $PASS -eq 1 ]; then
    if assert_id_in "$OUT_DIR/${PADDED}_loginAnimation-a.json" "login_logo" \
      && assert_id_in "$OUT_DIR/${PADDED}_loginAnimation-b.json" "login_logo" \
      && assert_id_in "$OUT_DIR/${PADDED}_loginAnimation-b.json" \
      "login_logo_harmony_letter" "login_logo_orbit_dot_0" "login_logo_orbit_dot_1" "login_logo_orbit_dot_2" \
      && assert_any_text_in "$OUT_DIR/${PADDED}_loginAnimation-b.json" "HarmonyOS Edition" "HarmonyOS 版本" \
      && assert_png_different "$OUT_DIR/${PADDED}_loginAnimation-a.png" "$OUT_DIR/${PADDED}_loginAnimation-b.png" "login-logo-animation"; then
      mark_end "loginAnimation" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
    else
      mark_end "loginAnimation" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "loginAnimation" "$PADDED" "no_login_logo"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 16 home-drawer
# =========================================================
IDX=16
run $IDX "home-drawer" "首页 Drawer（Compose 菜单顺序）"
if should_run "home-drawer"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell aa start -a "$ABILITY" -b "$BUNDLE" >/dev/null 2>&1
  sleep 4
  wait_for_id "home_main_content" 10 || true
  dumpnow "$OUT_DIR/_pre_home_drawer.json"
  tap_id "$OUT_DIR/_pre_home_drawer.json" "appbar_action_l_menu" || true
  sleep 1
  snap "${PADDED}_home-drawer"
  if assert_id_in "$OUT_DIR/${PADDED}_home-drawer.json" "home_drawer_content" "drawer_header" "drawer_name" "drawer_login" "drawer_menu_item_history" "drawer_menu_item_feedback" "drawer_menu_item_personal_info" "drawer_menu_item_language" "drawer_menu_item_check_update" "drawer_menu_item_about" "drawer_menu_item_logout"; then
    if tap_id "$OUT_DIR/${PADDED}_home-drawer.json" "drawer_menu_item_feedback"; then
      sleep 1
      wait_for_id "create_issue_dialog_root" 5 || true
      snap "${PADDED}_home-drawer-feedback"
      if assert_id_in "$OUT_DIR/${PADDED}_home-drawer-feedback.json" "create_issue_dialog_root" "create_issue_dialog_title" "create_issue_dialog_title_input" "create_issue_dialog_body_input" "create_issue_markdown_toolbar" "create_issue_markdown_toolbar_h1" "create_issue_markdown_toolbar_h2" "create_issue_markdown_toolbar_h3" "create_issue_markdown_toolbar_bold" "create_issue_dialog_cancel" "create_issue_dialog_confirm" \
        && assert_absent_id_in "$OUT_DIR/${PADDED}_home-drawer-feedback.json" "home_drawer_content" "drawer_menu_item_logout"; then
        mark_end "home-drawer" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
      else
        mark_end "home-drawer" "$PADDED" "feedback_assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      mark_end "home-drawer" "$PADDED" "feedback_tap_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "home-drawer" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 27 personal-info（Compose drawer personal_info → InfoScreen）
# =========================================================
IDX=27
run $IDX "personal-info" "Drawer → Personal Info → edit dialog"
if should_run "personal-info"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell aa start -a "$ABILITY" -b "$BUNDLE" >/dev/null 2>&1
  sleep 4
  wait_for_id "home_main_content" 10 || true
  dumpnow "$OUT_DIR/_pre_personal_info_home.json"
  if tap_id "$OUT_DIR/_pre_personal_info_home.json" "appbar_action_l_menu"; then
    sleep 1
    dumpnow "$OUT_DIR/_pre_personal_info_drawer.json"
    if tap_id "$OUT_DIR/_pre_personal_info_drawer.json" "drawer_menu_item_personal_info"; then
      wait_for_id "person_info_root" 10 || true
      snap "${PADDED}_personal-info"
      if assert_id_in "$OUT_DIR/${PADDED}_personal-info.json" \
        "person_info_root" \
        "person_info_pull_list" \
        "person_info_content" \
        "person_info_row_name" \
        "person_info_row_name_icon" \
        "person_info_row_name_label" \
        "person_info_row_name_value" \
        "person_info_row_email" \
        "person_info_row_email_icon" \
        "person_info_row_blog" \
        "person_info_row_blog_icon" \
        "person_info_row_company" \
        "person_info_row_company_icon" \
        "person_info_row_location" \
        "person_info_row_location_icon" \
        "person_info_row_bio" \
        "person_info_row_bio_icon" \
        "person_info_no_more" \
        && assert_any_text_in "$OUT_DIR/${PADDED}_personal-info.json" "No more data" "后面没有数据了" \
        && assert_bounds_inside "$OUT_DIR/${PADDED}_personal-info.json" "appbar_title" "appbar_main_row" 4 \
        && assert_png_id_nonflat "$OUT_DIR/${PADDED}_personal-info.png" \
          "$OUT_DIR/${PADDED}_personal-info.json" "person_info_row_name" "8.0"; then
        dumpnow "$OUT_DIR/_pre_personal_info_edit.json"
        if tap_id "$OUT_DIR/_pre_personal_info_edit.json" "person_info_row_name"; then
          wait_for_id "person_info_edit_dialog_root" 5 || true
          snap "${PADDED}_personal-info-edit"
          if assert_id_in "$OUT_DIR/${PADDED}_personal-info-edit.json" \
            "person_info_root" \
            "person_info_edit_dialog_root" \
            "person_info_edit_dialog_title" \
            "person_info_edit_dialog_input" \
            "person_info_edit_dialog_cancel" \
            "person_info_edit_dialog_confirm"; then
            mark_end "personal-info" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
          else
            mark_end "personal-info" "$PADDED" "dialog_assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
          fi
        else
          mark_end "personal-info" "$PADDED" "row_tap_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
      else
        mark_end "personal-info" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      mark_end "personal-info" "$PADDED" "drawer_tap_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "personal-info" "$PADDED" "drawer_open_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 28 drawer-language（Compose drawer language → LanguageSelectDialog）
# =========================================================
IDX=28
run $IDX "drawer-language" "Drawer → Language dialog"
if should_run "drawer-language"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell aa start -a "$ABILITY" -b "$BUNDLE" >/dev/null 2>&1
  sleep 4
  wait_for_id "home_main_content" 10 || true
  dumpnow "$OUT_DIR/_pre_drawer_language_home.json"
  if tap_id "$OUT_DIR/_pre_drawer_language_home.json" "appbar_action_l_menu"; then
    sleep 1
    dumpnow "$OUT_DIR/_pre_drawer_language_drawer.json"
    if tap_id "$OUT_DIR/_pre_drawer_language_drawer.json" "drawer_menu_item_language"; then
      wait_for_id "drawer_language_dialog_root" 6 || true
      snap "${PADDED}_drawer-language"
      if assert_id_in "$OUT_DIR/${PADDED}_drawer-language.json" \
        "drawer_language_dialog_root" \
        "drawer_language_dialog_title" \
        "drawer_language_option_local" \
        "drawer_language_option_zh-CN" \
        "drawer_language_option_en" \
        "drawer_language_label_local" \
        "drawer_language_label_zh-CN" \
        "drawer_language_label_en"; then
        mark_end "drawer-language" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
      else
        mark_end "drawer-language" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      mark_end "drawer-language" "$PADDED" "drawer_tap_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "drawer-language" "$PADDED" "drawer_open_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# =========================================================
#   场景 34 drawer-about（Compose drawer about → AlertDialog）
# =========================================================
IDX=34
run $IDX "drawer-about" "Drawer → About dialog"
if should_run "drawer-about"; then
  PADDED=$(printf "%02d" $IDX)
  hdc -t "$TARGET" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  hdc -t "$TARGET" shell aa start -a "$ABILITY" -b "$BUNDLE" >/dev/null 2>&1
  sleep 4
  wait_for_id "home_main_content" 10 || true
  dumpnow "$OUT_DIR/_pre_drawer_about_home.json"
  if tap_id "$OUT_DIR/_pre_drawer_about_home.json" "appbar_action_l_menu"; then
    sleep 1
    dumpnow "$OUT_DIR/_pre_drawer_about_drawer.json"
    if tap_id "$OUT_DIR/_pre_drawer_about_drawer.json" "drawer_menu_item_about"; then
      wait_for_id "drawer_about_dialog_root" 6 || true
      snap "${PADDED}_drawer-about"
      if assert_id_in "$OUT_DIR/${PADDED}_drawer-about.json" \
        "drawer_about_dialog_root" \
        "drawer_about_dialog_title" \
        "drawer_about_dialog_text" \
        "drawer_about_dialog_confirm" \
        && assert_any_text_in "$OUT_DIR/${PADDED}_drawer-about.json" "Version:" "版本：" \
        && assert_any_text_in "$OUT_DIR/${PADDED}_drawer-about.json" "Update" "更新" \
        && assert_absent_id_in "$OUT_DIR/${PADDED}_drawer-about.json" \
        "home_drawer_content" \
        "about_root" \
        "about_honor_btn" \
        "about_custom_btn"; then
        mark_end "drawer-about" "$PADDED" "ok"; OK_COUNT=$((OK_COUNT + 1))
      else
        mark_end "drawer-about" "$PADDED" "assert_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      mark_end "drawer-about" "$PADDED" "drawer_tap_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    mark_end "drawer-about" "$PADDED" "drawer_open_fail"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# --------- 收尾：md5 去重校验 ---------
sleep 1
[ "$HILOG_PID" != "0" ] && kill "$HILOG_PID" 2>/dev/null || true

log ""
log "===== md5 去重校验 ====="
TMP_MD5="$OUT_DIR/_md5_count.tmp"
: > "$TMP_MD5"
for f in "$OUT_DIR"/*.png; do
  [ -f "$f" ] || continue
  m=$(md5 -q "$f" 2>/dev/null || md5sum "$f" 2>/dev/null | awk '{print $1}')
  bn=$(basename "$f")
  echo "$m  $bn" >> "$OUT_DIR/md5sums.txt"
  echo "$m" >> "$TMP_MD5"
done
DUP_FOUND=0
while read -r m c; do
  if [ "$c" -ge 3 ]; then
    log "  DUPLICATE md5=$m count=$c"; DUP_FOUND=1
  fi
done < <(sort "$TMP_MD5" | uniq -c | awk '{print $2" "$1}')
rm -f "$TMP_MD5"

# --------- 生成 README.md ---------
{
  echo "# scenario-tour $TS"
  echo
  echo "- target: \`$TARGET\`  pid: \`$PID\`  bundle: \`$BUNDLE\`"
  echo "- 产物目录: \`$OUT_DIR\`"
  echo "- 结果: ok=\`$OK_COUNT\` fail=\`$FAIL_COUNT\` skip=\`$SKIP_COUNT\`"
  echo "- md5 重复 (≥3 张同图): \`$([ $DUP_FOUND -eq 1 ] && echo YES || echo NO)\`"
  echo
  echo "## 场景产物"
  echo
  echo "| # | key | screenshot | layout | md5 | assert |"
  echo "|---|-----|------------|--------|-----|--------|"
  for f in "$OUT_DIR"/*.png; do
    [ -f "$f" ] || continue
    bn=$(basename "$f" .png)
    m=$(grep " $bn.png\$" "$OUT_DIR/md5sums.txt" | awk '{print $1}' | head -c 8)
    a_ok=$(grep -c "^\[OK\].*$bn" "$ASSERT_LOG" 2>/dev/null || true)
    a_fail=$(grep -c "^\[FAIL\].*$bn" "$ASSERT_LOG" 2>/dev/null || true)
    a_ok=${a_ok:-0}
    a_fail=${a_fail:-0}
    echo "| ${bn%%_*} | ${bn#*_} | [${bn}.png](${bn}.png) | [${bn}.json](${bn}.json) | \`${m}\` | ok:$a_ok fail:$a_fail |"
  done
  echo
  echo "## hilog 切片协议"
  echo
  echo "在 \`hilog_business.log\` 中按 marker 切片："
  echo
  echo '```bash'
  echo "awk '/=== BEGIN scenario=launch /,/=== END   scenario=launch /' $OUT_DIR/hilog_business.log"
  echo '```'
  echo
  echo "## 断言全文"
  echo
  echo '```'
  cat "$ASSERT_LOG"
  echo '```'
} > "$OUT_DIR/README.md"

log ""
log "===== DONE ====="
log "OUT_DIR  : $OUT_DIR"
log "screenshots: $(ls "$OUT_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')"
log "asserts   : $(wc -l < "$ASSERT_LOG" | tr -d ' ')"
log "hilog     : $(wc -l < "$OUT_DIR/hilog_business.log" | tr -d ' ') lines"
log "README    : $OUT_DIR/README.md"
log ""
log "Result    : ok=$OK_COUNT fail=$FAIL_COUNT skip=$SKIP_COUNT  dup=$([ $DUP_FOUND -eq 1 ] && echo YES || echo NO)"

if [ $DUP_FOUND -eq 1 ]; then exit 4; fi
if [ $FAIL_COUNT -gt 0 ]; then exit 5; fi
exit 0
