#!/usr/bin/env bash
set -euo pipefail

BUNDLE="cn.gsy.githubapp"
ABILITY="EntryAbility"
TARGET="${HDC_TARGET:-127.0.0.1:5555}"
HAP_PATH="${HAP_PATH:-entry/build/default/outputs/default/entry-default-signed.hap}"
OUT_DIR="${OUT_DIR:-harness/regression/reports/M6/device-smoke-$(date +%Y%m%d-%H%M%S)}"

echo "[device-smoke] target=$TARGET out=$OUT_DIR"
mkdir -p "$OUT_DIR"

# 1. device alive
hdc -t "$TARGET" shell param get const.product.model > "$OUT_DIR/device.txt" || { echo "device offline"; exit 2; }
hdc -t "$TARGET" shell param get const.product.software.version >> "$OUT_DIR/device.txt" || true
hdc -t "$TARGET" shell hidumper -s RenderService -a screen 2>&1 | head -10 >> "$OUT_DIR/device.txt" || true

# 2. install
if [ ! -f "$HAP_PATH" ]; then
  echo "[device-smoke] HAP not found at $HAP_PATH, please Build > Build Hap in DevEco first."
  exit 3
fi
hdc -t "$TARGET" install -r "$HAP_PATH" | tee "$OUT_DIR/install.log"

# 3. start ability
hdc -t "$TARGET" shell aa start -a "$ABILITY" -b "$BUNDLE" | tee "$OUT_DIR/start.log"
sleep 3

# 4. screenshot welcome
hdc -t "$TARGET" shell uitest screenCap -p /data/local/tmp/welcome.png || true
hdc -t "$TARGET" file recv /data/local/tmp/welcome.png "$OUT_DIR/01_welcome.png" || true

# 5. dump layout（welcome）
hdc -t "$TARGET" shell uitest dumpLayout -p /data/local/tmp/welcome.json || true
hdc -t "$TARGET" file recv /data/local/tmp/welcome.json "$OUT_DIR/01_welcome_layout.json" || true

# 6. hilog 30s（domain 0x0666 业务 + system）
hdc -t "$TARGET" hilog -T 0x0666 > "$OUT_DIR/hilog_business.log" &
HILOG_PID="${!:-0}"
sleep 30
[ "$HILOG_PID" != "0" ] && kill "$HILOG_PID" 2>/dev/null || true

# 7. screenshot login（30s 后通常已到 LoginPage）
hdc -t "$TARGET" shell uitest screenCap -p /data/local/tmp/after.png || true
hdc -t "$TARGET" file recv /data/local/tmp/after.png "$OUT_DIR/02_after.png" || true
hdc -t "$TARGET" shell uitest dumpLayout -p /data/local/tmp/after.json || true
hdc -t "$TARGET" file recv /data/local/tmp/after.json "$OUT_DIR/02_after_layout.json" || true

# 8. summary
{
  echo "# device-smoke $(date)"
  echo "- target: $TARGET"
  echo "- bundle: $BUNDLE"
  echo "- hap: $HAP_PATH"
  echo "- artifacts:"
  ls -1 "$OUT_DIR" | sed 's/^/  - /'
} > "$OUT_DIR/README.md"

echo "[device-smoke] DONE → $OUT_DIR"
