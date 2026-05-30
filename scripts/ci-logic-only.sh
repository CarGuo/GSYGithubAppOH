#!/usr/bin/env bash
# CI logic-only checks（OH SDK Linux 限制下使用）
# 校验逻辑：
#   1) 从 entry/src/ohosTest/ets/test 列出所有逻辑套件文件
#      （*ServiceTest.ets / *Test.ets，排除 *UiTest.ets 与 List.test.ets 自身）。
#   2) 以 List.test.ets 中的 import 行为依据，挑出"已注册"的逻辑套件。
#   3) 对每个已注册逻辑套件：
#        a. 文件存在
#        b. List.test.ets 中存在 `import <id> from './<name>'`
#        c. List.test.ets 的 testsuite() 中调用了 <id>()
#        d. 套件文件内出现 describe('xxx', ...)
#   4) 输出 pass/total 到 stdout，pass != total 退出非 0。
#
# 注：
#   - List.test.ets 中未 import 的"孤立"逻辑套件文件会被 WARN 但不计入 fail，
#     避免破坏现有未注册的本地套件。
#   - 真机 hvigor test 仍需 macOS / Win，参见 harness/playbooks/ci.md。

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="${ROOT_DIR}/entry/src/ohosTest/ets/test"
LIST_FILE="${TEST_DIR}/List.test.ets"

if [ ! -d "${TEST_DIR}" ]; then
  echo "[ci-logic-only] FAIL: 测试目录不存在: ${TEST_DIR}" >&2
  exit 2
fi

if [ ! -f "${LIST_FILE}" ]; then
  echo "[ci-logic-only] FAIL: List.test.ets 不存在: ${LIST_FILE}" >&2
  exit 2
fi

# 1) 收集磁盘上所有逻辑套件文件名（不含路径与扩展名）
DISK_SUITES=()
while IFS= read -r line; do
  [ -n "${line}" ] && DISK_SUITES+=("${line}")
done < <(
  find "${TEST_DIR}" -maxdepth 1 -type f \
    \( -name '*ServiceTest.ets' -o -name '*Test.ets' \) \
    ! -name '*UiTest.ets' \
    ! -name 'List.test.ets' \
    -exec basename {} .ets \; \
    | sort
)

# 2) 从 List.test.ets 提取已注册的逻辑套件：默认导出 id 与来源 base
#    匹配形如：import I18nTest from './I18nTest';
REGISTERED=()
while IFS= read -r line; do
  [ -n "${line}" ] && REGISTERED+=("${line}")
done < <(
  grep -E "^[[:space:]]*import[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+from[[:space:]]+['\"]\./[^'\"]+['\"]" "${LIST_FILE}" \
    | sed -E "s/^[[:space:]]*import[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]+from[[:space:]]+['\"]\.\/([^'\"]+)['\"].*/\1|\2/"
)

# 过滤掉 UiTest（按 base 名 *UiTest 结尾判定）
LOGIC_REGISTERED=()
for entry in "${REGISTERED[@]}"; do
  id="${entry%%|*}"
  base="${entry##*|}"
  case "${base}" in
    *UiTest) continue ;;
  esac
  LOGIC_REGISTERED+=("${entry}")
done

TOTAL=${#LOGIC_REGISTERED[@]}
PASS=0
FAIL_DETAIL=()

if [ "${TOTAL}" -eq 0 ]; then
  echo "[ci-logic-only] FAIL: List.test.ets 中未发现已注册的逻辑套件" >&2
  exit 3
fi

echo "[ci-logic-only] List.test.ets 已注册逻辑套件: ${TOTAL}"
echo "[ci-logic-only] 磁盘逻辑套件文件: ${#DISK_SUITES[@]}"

# 检测磁盘上存在但未注册的孤立套件，仅 WARN
for d in "${DISK_SUITES[@]}"; do
  hit=0
  for entry in "${LOGIC_REGISTERED[@]}"; do
    base="${entry##*|}"
    if [ "${base}" = "${d}" ]; then
      hit=1
      break
    fi
  done
  if [ "${hit}" -eq 0 ]; then
    echo "[ci-logic-only] WARN: 套件文件 ${d}.ets 未在 List.test.ets 中 import"
  fi
done

# 3) 逐个核对每个已注册逻辑套件
for entry in "${LOGIC_REGISTERED[@]}"; do
  id="${entry%%|*}"
  base="${entry##*|}"
  file="${TEST_DIR}/${base}.ets"
  ok=1

  # a. 文件存在
  if [ ! -f "${file}" ]; then
    FAIL_DETAIL+=("${base}: 套件文件不存在 (${file})")
    ok=0
  fi

  # b. import 行（已通过 grep 匹配进入循环，二次确认）
  if ! grep -E "^[[:space:]]*import[[:space:]]+${id}[[:space:]]+from[[:space:]]+['\"]\./${base}['\"]" "${LIST_FILE}" > /dev/null; then
    FAIL_DETAIL+=("${base}: List.test.ets 未 import ${id}")
    ok=0
  fi

  # c. testsuite() 中调用 id()
  if ! grep -E "^[[:space:]]*${id}\(\s*\)\s*;" "${LIST_FILE}" > /dev/null; then
    FAIL_DETAIL+=("${base}: List.test.ets 未调用 ${id}()")
    ok=0
  fi

  # d. describe('xxx', ...) 存在
  if [ -f "${file}" ]; then
    if ! grep -E "describe\(\s*['\"][^'\"]+['\"]" "${file}" > /dev/null; then
      FAIL_DETAIL+=("${base}: 缺少 describe('xxx', ...)")
      ok=0
    fi
  fi

  if [ "${ok}" -eq 1 ]; then
    PASS=$((PASS + 1))
  fi
done

echo "[ci-logic-only] pass/total = ${PASS}/${TOTAL}"

if [ "${PASS}" -ne "${TOTAL}" ]; then
  echo "[ci-logic-only] 失败明细:" >&2
  for d in "${FAIL_DETAIL[@]}"; do
    echo "  - ${d}" >&2
  done
  exit 1
fi

echo "[ci-logic-only] OK"
exit 0
