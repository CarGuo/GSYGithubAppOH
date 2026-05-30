#!/usr/bin/env bash
set -euo pipefail

# harness/regression/run-tests.sh
#
# 用法：
#   ./run-tests.sh                # 仅跑逻辑套件，set LOGIC_ONLY=1，
#                                 # ohosTest 内 List.test.ets 检测后跳过 *UiTest()
#   ./run-tests.sh --full-ui-host # 诊断性全量 hvigor test（含 *UiTest）
#   ./run-tests.sh --help         # 查看帮助
#
# 说明：
#   - 默认/--logic-only 实际仍然调用 hvigorw test，仅通过环境变量 LOGIC_ONLY=1
#     在 entry/src/ohosTest/ets/test/List.test.ets 的 testsuite() 起始处被检测，
#     为 true 时跳过所有 *UiTest 调用。grep 仅用于在 stdout 中过滤 *UiTest 行，
#     便于人工查阅，真正的"跳过"逻辑在 testsuite() 内完成。
#   - --full-ui-host 会恢复 *UiTest，当前只作为 ArkUI/Hypium 宿主诊断入口；
#     真机 UI 回归以 scripts/scenario-tour.sh 的截图、dump、hilog 为准。
#   - GitHub Actions Linux runner 不可用（OH SDK 当前未官方支持 Linux），
#     详见 harness/playbooks/ci.md。

print_help() {
  cat <<'HLP'
用法: run-tests.sh [选项]

选项:
  --logic-only   默认值。仅跑逻辑套件（跳过 *UiTest）。会 export LOGIC_ONLY=1，
                 List.test.ets 内 testsuite() 检测后跳过 *UiTest 调用，
                 同时 grep 过滤 stdout 中的 *UiTest 行。
  --full-ui-host 诊断性全量 hvigor test（包含 *UiTest）。该入口用于排查
                 ArkUI/Hypium 宿主行为，不作为 Compose UI parity 的权威 gate；
                 UI 回归请使用 scripts/scenario-tour.sh。
  --help, -h     显示本帮助。

环境变量:
  LOGIC_ONLY=1   等价于 --logic-only。
  LOGIC_ONLY=0   等价于 --full-ui-host。

输出:
  harness/regression/reports/M5/hvigorw-test.log
  harness/regression/reports/M5/summary.md
HLP
}

LOGIC_ONLY="${LOGIC_ONLY:-1}"

while [ $# -gt 0 ]; do
  case "$1" in
    --logic-only)
      LOGIC_ONLY=1
      shift
      ;;
    --full-ui-host|--full)
      LOGIC_ONLY=0
      shift
      ;;
    --help|-h)
      print_help
      exit 0
      ;;
    *)
      echo "[run-tests] 未知参数: $1" >&2
      print_help
      exit 64
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_DIR="${ROOT_DIR}/harness/regression/reports/M5"
LOG_FILE="${REPORT_DIR}/hvigorw-test.log"
SUMMARY_FILE="${REPORT_DIR}/summary.md"
LOGIC_ONLY_CONFIG="${ROOT_DIR}/entry/src/ohosTest/ets/test/LogicOnlyConfig.ets"
TEST_RESULT_FILE="${ROOT_DIR}/entry/.test/default/intermediates/test/coverage_data/test_result.txt"

HVIGORW="$(command -v hvigorw || true)"
if [ -z "${HVIGORW}" ] && [ -x "./hvigorw" ]; then
  HVIGORW="./hvigorw"
fi
if [ -z "${HVIGORW}" ]; then
  echo "[run-tests] hvigorw not found. Set DEVECO_HOME and source scripts/env.sh first." >&2
  exit 1
fi

mkdir -p "${REPORT_DIR}"

pushd "${ROOT_DIR}" > /dev/null

echo "[run-tests] cwd=${ROOT_DIR}"
echo "[run-tests] log -> ${LOG_FILE}"
echo "[run-tests] LOGIC_ONLY=${LOGIC_ONLY}"
if [ "${LOGIC_ONLY}" != "1" ]; then
  echo "[run-tests] full UI-host mode is diagnostic; scenario-tour.sh is the authoritative UI parity gate."
fi
echo "[run-tests] hvigorw=${HVIGORW}"

if [ ! -x "${HVIGORW}" ]; then
  echo "hvigorw not found at ${ROOT_DIR}/hvigorw or DevEco default path" >&2
  exit 2
fi

write_logic_only_config() {
  local enabled="$1"
  printf 'export const LOGIC_ONLY: boolean = %s;\n' "${enabled}" > "${LOGIC_ONLY_CONFIG}"
}

write_logic_only_config "$( [ "${LOGIC_ONLY}" = "1" ] && echo true || echo false )"
trap 'write_logic_only_config false' EXIT

START_TS=$(date +%s)
set +e
if [ "${LOGIC_ONLY}" = "1" ]; then
  # 通过环境变量传给 ohosTest 进程；List.test.ets 内会检测后跳过 *UiTest 调用。
  # 同时 grep -v 过滤 stdout 中的 *UiTest 行，便于人工核对。
  LOGIC_ONLY=1 "${HVIGORW}" test --mode module -p product=default --no-daemon 2>&1 \
    | grep -v -E 'UiTest' \
    | tee "${LOG_FILE}"
  EXIT_CODE=${PIPESTATUS[0]}
else
  "${HVIGORW}" test --mode module -p product=default --no-daemon 2>&1 | tee "${LOG_FILE}"
  EXIT_CODE=${PIPESTATUS[0]}
fi
set -e
END_TS=$(date +%s)
DURATION=$(( END_TS - START_TS ))

PASS_COUNT=$(grep -Eo "passed[: ]+[0-9]+" "${LOG_FILE}" | tail -n1 | grep -Eo "[0-9]+" || true)
FAIL_COUNT=$(grep -Eo "failed[: ]+[0-9]+" "${LOG_FILE}" | tail -n1 | grep -Eo "[0-9]+" || true)
ERROR_COUNT=$(grep -Eo "error[: ]+[0-9]+" "${LOG_FILE}" | tail -n1 | grep -Eo "[0-9]+" || true)
IGNORE_COUNT=0
TEST_RUNS=0
SUITES=$(grep -cE "^describe " "${LOG_FILE}" || true)
if [ -f "${TEST_RESULT_FILE}" ]; then
  RESULT_LINE=$(grep -E "^Tests run:" "${TEST_RESULT_FILE}" | tail -n1 || true)
  if [ -n "${RESULT_LINE}" ]; then
    TEST_RUNS=$(printf '%s\n' "${RESULT_LINE}" | sed -E 's/^Tests run: ([0-9]+), Failure: ([0-9]+), Error: ([0-9]+), Pass: ([0-9]+), Ignore: ([0-9]+).*/\1/')
    FAIL_COUNT=$(printf '%s\n' "${RESULT_LINE}" | sed -E 's/^Tests run: ([0-9]+), Failure: ([0-9]+), Error: ([0-9]+), Pass: ([0-9]+), Ignore: ([0-9]+).*/\2/')
    ERROR_COUNT=$(printf '%s\n' "${RESULT_LINE}" | sed -E 's/^Tests run: ([0-9]+), Failure: ([0-9]+), Error: ([0-9]+), Pass: ([0-9]+), Ignore: ([0-9]+).*/\3/')
    PASS_COUNT=$(printf '%s\n' "${RESULT_LINE}" | sed -E 's/^Tests run: ([0-9]+), Failure: ([0-9]+), Error: ([0-9]+), Pass: ([0-9]+), Ignore: ([0-9]+).*/\4/')
    IGNORE_COUNT=$(printf '%s\n' "${RESULT_LINE}" | sed -E 's/^Tests run: ([0-9]+), Failure: ([0-9]+), Error: ([0-9]+), Pass: ([0-9]+), Ignore: ([0-9]+).*/\5/')
  fi
  SUITES=$(grep -cE "^class=" "${TEST_RESULT_FILE}" || true)
fi
PASS_COUNT="${PASS_COUNT:-0}"
FAIL_COUNT="${FAIL_COUNT:-0}"
ERROR_COUNT="${ERROR_COUNT:-0}"
TEST_RUNS="${TEST_RUNS:-0}"
IGNORE_COUNT="${IGNORE_COUNT:-0}"
ASSERT_ERRORS=$(grep -c "ERROR: Error in" "${LOG_FILE}" || true)
if [ "${ASSERT_ERRORS}" != "0" ] && [ "${EXIT_CODE}" = "0" ]; then
  EXIT_CODE=1
fi

cat > "${SUMMARY_FILE}" <<EOF
# M5 Hvigor 测试报告

- 时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- 模式: $( [ "${LOGIC_ONLY}" = "1" ] && echo "logic-only (跳过 *UiTest)" || echo "full-ui-host diagnostic (包含 *UiTest，UI parity 以 scenario-tour.sh 为准)" )
- 命令: \`./hvigorw test --mode module -p product=default --no-daemon\`
- 退出码: ${EXIT_CODE}
- 耗时: ${DURATION}s
- 套件估算: ${SUITES}
- tests run: ${TEST_RUNS}
- passed: ${PASS_COUNT}
- failed: ${FAIL_COUNT}
- error: ${ERROR_COUNT}
- ignored: ${IGNORE_COUNT}
- assertion errors: ${ASSERT_ERRORS}
- 原始日志: [hvigorw-test.log](./hvigorw-test.log)
- Hypium 结果: [test_result.txt](../../../entry/.test/default/intermediates/test/coverage_data/test_result.txt)

## 套件清单
$(if [ -f "${TEST_RESULT_FILE}" ]; then grep -E "^class=" "${TEST_RESULT_FILE}" | sed 's/^class=/- /' || true; else grep -E "^describe " "${LOG_FILE}" | sed 's/^/- /' || true; fi)
EOF

echo "[run-tests] summary -> ${SUMMARY_FILE}"

popd > /dev/null

exit ${EXIT_CODE}
