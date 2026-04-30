#!/usr/bin/env bash
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

RESULTS_DIR="tests/results"
mkdir -p "$RESULTS_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$RESULTS_DIR/godot-$TS.log"
SUMMARY_FILE="$RESULTS_DIR/godot-summary-$TS.txt"

GODOT_BIN="${GODOT_EXE:-}"
if [[ -z "$GODOT_BIN" ]]; then
  if command -v godot4 >/dev/null 2>&1; then
    GODOT_BIN="godot4"
  elif command -v godot >/dev/null 2>&1; then
    GODOT_BIN="godot"
  else
    echo "[ERROR] Could not find Godot binary. Set GODOT_EXE, or install godot4/godot on PATH." >&2
    exit 1
  fi
fi

TESTS=(
  "res://tests/godot/input_validator_test.gd"
  "res://tests/godot/answer_modal_headless_test.gd"
  "res://tests/godot/vote_multiplayer_headless_scaffold.gd"
)

fail_count=0
: > "$LOG_FILE"
: > "$SUMMARY_FILE"

echo "[INFO] Godot binary: $GODOT_BIN" | tee -a "$LOG_FILE"
echo "[INFO] Writing log: $LOG_FILE" | tee -a "$LOG_FILE"

for test_script in "${TESTS[@]}"; do
  echo "" | tee -a "$LOG_FILE"
  echo "=== RUN $test_script ===" | tee -a "$LOG_FILE"
  "$GODOT_BIN" --headless --path . -s "$test_script" >> "$LOG_FILE" 2>&1
  code=$?
  if [[ $code -ne 0 ]]; then
    fail_count=$((fail_count + 1))
    echo "[FAIL] $test_script (exit $code)" | tee -a "$SUMMARY_FILE"
  fi
done

if [[ $fail_count -eq 0 ]]; then
  echo "[PASS] Godot tests passed (${#TESTS[@]}/${#TESTS[@]})" | tee -a "$SUMMARY_FILE"
else
  echo "[FAIL] Godot tests failed: $fail_count" | tee -a "$SUMMARY_FILE"
fi

echo "[INFO] Summary: $SUMMARY_FILE"

# Print only issues/errors to terminal for fast review.
if [[ $fail_count -gt 0 ]]; then
  echo ""
  echo "=== Error Snippets ==="
  grep -E "(ERROR|Error|error|FAIL|Failed|failed|assert|Assertion)" "$LOG_FILE" | tail -n 80 || true
fi

[[ $fail_count -eq 0 ]]
