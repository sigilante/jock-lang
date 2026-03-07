#!/usr/bin/env bash
# update-expected.sh - Regenerate all .expected files from current jockc output.
#
# Run this after compiler changes to update the expected baseline.
# Tests that don't reach %nock are skipped (no file written).
#
# Usage: update-expected.sh [test-name ...]
#   With no arguments, updates all tests in TEST_DIR.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

JOCKC="${JOCKC:-$REPO_ROOT/target/release/jockc}"
IMPORT_DIR="${IMPORT_DIR:-$REPO_ROOT/common/hoon/lib}"
TEST_DIR="${TEST_DIR:-$REPO_ROOT/crates/jockt/hoon/lib/tests}"
EXPECTED_DIR="${EXPECTED_DIR:-$SCRIPT_DIR/expected}"
TIMEOUT="${TEST_TIMEOUT:-60}"

mkdir -p "$EXPECTED_DIR"

pass=0
skip=0

run_one() {
  local test_name="$1"
  local test_path="$TEST_DIR/$test_name"

  local tmpfile
  tmpfile=$(mktemp)

  "$JOCKC" "$test_path" --import-dir "$IMPORT_DIR" >"$tmpfile" 2>&1 &
  local JOCK_PID=$!

  # Poll every 0.5s until %nock appears or timeout.
  local max_checks=$((TIMEOUT * 2))
  local checks=0
  while [ $checks -lt $max_checks ]; do
    if grep -aq '%nock' "$tmpfile" 2>/dev/null; then
      sleep 1  # let the full %nock line flush before killing
      break
    fi
    sleep 0.5
    checks=$((checks + 1))
  done

  kill "$JOCK_PID" 2>/dev/null || true
  wait "$JOCK_PID" 2>/dev/null || true

  local output
  output=$(tr -d '\0' < "$tmpfile" | sed 's/\x1b\[[0-9;]*m//g')
  rm -f "$tmpfile"

  local nock_line
  nock_line=$(printf '%s' "$output" | grep '%nock' | head -1 || true)

  if [ -z "$nock_line" ]; then
    echo "SKIP [$test_name]: did not reach %nock"
    skip=$((skip + 1))
    return
  fi

  local nock_value
  nock_value=$(printf '%s' "$nock_line" \
    | sed 's/.*%nock//' \
    | tr -s ' \t' ' ' \
    | sed 's/^ //;s/ $//')

  printf '%s' "$nock_value" > "$EXPECTED_DIR/$test_name.expected"
  local preview
  preview=$(printf '%s' "$nock_value" | head -c 80)
  echo "WROTE [$test_name]: $preview"
  pass=$((pass + 1))
}

if [ $# -gt 0 ]; then
  for name in "$@"; do
    run_one "$name"
  done
else
  for jock_file in "$TEST_DIR"/*.jock; do
    test_name="$(basename "$jock_file" .jock)"
    run_one "$test_name"
  done
fi

echo ""
echo "Done: $pass expected files written, $skip tests skipped (no %nock output)"
