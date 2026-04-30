#!/usr/bin/env bash
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

RESULTS_DIR="tests/results"
mkdir -p "$RESULTS_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
MASTER_SUMMARY="$RESULTS_DIR/all-tests-summary-$TS.txt"
E2E_LOG="$RESULTS_DIR/e2e-$TS.log"

: > "$MASTER_SUMMARY"

fail_count=0

echo "=== Godot Tests ===" | tee -a "$MASTER_SUMMARY"
bash tools/run-godot-tests.sh
code=$?
if [[ $code -ne 0 ]]; then
  fail_count=$((fail_count + 1))
  echo "[FAIL] Godot suite" | tee -a "$MASTER_SUMMARY"
else
  echo "[PASS] Godot suite" | tee -a "$MASTER_SUMMARY"
fi

echo "" | tee -a "$MASTER_SUMMARY"
echo "=== Playwright E2E ===" | tee -a "$MASTER_SUMMARY"
if [[ ! -d node_modules ]]; then
  echo "[INFO] node_modules missing; run npm install first." | tee -a "$MASTER_SUMMARY"
fi

npm run test:e2e >> "$E2E_LOG" 2>&1
code=$?
if [[ $code -ne 0 ]]; then
  fail_count=$((fail_count + 1))
  echo "[FAIL] Playwright suite" | tee -a "$MASTER_SUMMARY"
  echo ""
  echo "=== Playwright Error Snippets ==="
  grep -E "(ERROR|Error|error|FAIL|Failed|failed|Assertion|Expected|Timeout)" "$E2E_LOG" | tail -n 120 || true
else
  echo "[PASS] Playwright suite" | tee -a "$MASTER_SUMMARY"
fi

echo ""
echo "Summary file: $MASTER_SUMMARY"
echo "E2E log file: $E2E_LOG"

if [[ $fail_count -gt 0 ]]; then
  echo "[FAIL] One or more suites failed"
  exit 1
fi

echo "[PASS] All test suites passed"
exit 0
