#!/usr/bin/env bash
# 沉淀：DevEco 自带工具链入口。source 一次后即可在终端跑 hvigorw / ohpm / node / hdc。
# 用法：export DEVECO_HOME="<DevEco Studio Contents path>" && source scripts/env.sh
if [ -z "${DEVECO_HOME:-}" ]; then
  echo "[env] Please set DEVECO_HOME to your DevEco Studio Contents path first." >&2
  return 1 2>/dev/null || exit 1
fi
export NODE_HOME="$DEVECO_HOME/tools/node"
export HVIGOR_USER_HOME="${HVIGOR_USER_HOME:-$HOME/.hvigor}"
export OHPM_HOME="$DEVECO_HOME/tools/ohpm"
export HARMONYOS_SDK_HOME="$DEVECO_HOME/sdk"
export PATH="$NODE_HOME:$OHPM_HOME/bin:$DEVECO_HOME/tools/hvigor/bin:$DEVECO_HOME/sdk/default/openharmony/toolchains:$PATH"
echo "[env] node=$(node -v 2>/dev/null) ohpm=$(ohpm -v 2>/dev/null | tail -1) hvigorw=$(hvigorw --version 2>/dev/null | tail -1) hdc=$(hdc -v 2>/dev/null | head -1)"
