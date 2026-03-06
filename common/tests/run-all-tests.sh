#!/usr/bin/env bash
# run-all-tests.sh - Run all Jock tests and report results.
#
# Usage: run-all-tests.sh [test-name ...]
#   With no arguments, runs all tests in TEST_DIR.
#
# Environment:
#   PARALLEL   number of concurrent tests (default: 1 = sequential)
#   TEST_DIR   directory of .jock files
#
# Exit 0 if all tests pass, 1 if any fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TEST_DIR="${TEST_DIR:-$REPO_ROOT/crates/jockt/hoon/lib/tests}"
PARALLEL="${PARALLEL:-1}"

# Temp dir to record failures (safe across parallel subshells).
FAIL_DIR=$(mktemp -d)
trap 'rm -rf "$FAIL_DIR"' EXIT

run_one() {
  local test_name="$1"
  if bash "$SCRIPT_DIR/run-test.sh" "$test_name"; then
    :
  else
    touch "$FAIL_DIR/$test_name.fail"
  fi
}
export -f run_one
export SCRIPT_DIR

# Build test list.
if [ $# -gt 0 ]; then
  tests=("$@")
else
  tests=()
  for jock_file in "$TEST_DIR"/*.jock; do
    tests+=("$(basename "$jock_file" .jock)")
  done
fi

if [ "$PARALLEL" -le 1 ]; then
  # Sequential.
  for test_name in "${tests[@]}"; do
    run_one "$test_name"
  done
else
  # Parallel: cap at $PARALLEL concurrent jobs.
  running=0
  for test_name in "${tests[@]}"; do
    run_one "$test_name" &
    running=$((running + 1))
    if [ $running -ge "$PARALLEL" ]; then
      wait -n 2>/dev/null || wait  # wait for any one job to finish
      running=$((running - 1))
    fi
  done
  wait  # wait for remaining
fi

# Report.
fail_count=$(find "$FAIL_DIR" -name "*.fail" 2>/dev/null | wc -l | tr -d ' ')
pass_count=$(( ${#tests[@]} - fail_count ))

echo ""
echo "Results: $pass_count passed, $fail_count failed"

if [ "$fail_count" -gt 0 ]; then
  echo "Failed tests:"
  find "$FAIL_DIR" -name "*.fail" | sort | while read -r f; do
    echo "  - $(basename "$f" .fail)"
  done
  exit 1
fi
