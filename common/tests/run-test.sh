#!/usr/bin/env bash
# run-test.sh - Run a single Jock test via jockc and check its output.
#
# Usage: run-test.sh <test-name>
#
# Environment overrides:
#   JOCKC        path to jockc binary       (default: <repo>/target/release/jockc)
#   IMPORT_DIR   path to hoon lib directory (default: <repo>/common/hoon/lib)
#   TEST_DIR     directory of .jock files   (default: <repo>/crates/jockt/hoon/lib/tests)
#   EXPECTED_DIR directory of .expected     (default: <script-dir>/expected)
#   TEST_TIMEOUT seconds before giving up   (default: 60)
#
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

JOCKC="${JOCKC:-$REPO_ROOT/target/release/jockc}"
IMPORT_DIR="${IMPORT_DIR:-$REPO_ROOT/common/hoon/lib}"
TEST_DIR="${TEST_DIR:-$REPO_ROOT/crates/jockt/hoon/lib/tests}"
EXPECTED_DIR="${EXPECTED_DIR:-$SCRIPT_DIR/expected}"
TIMEOUT="${TEST_TIMEOUT:-60}"

test_name="${1:-}"
if [ -z "$test_name" ]; then
  echo "Usage: $0 <test-name>" >&2
  exit 1
fi

test_path="$TEST_DIR/$test_name"
expected_path="$EXPECTED_DIR/$test_name.expected"

# Run jockc in background, streaming output to a temp file.
# jockc never exits cleanly (NockApp hang), so we poll for %nock and kill early.
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

"$JOCKC" "$test_path" --import-dir "$IMPORT_DIR" >"$tmpfile" 2>&1 &
JOCK_PID=$!

# Poll every 0.5s until %nock appears or timeout.
max_checks=$((TIMEOUT * 2))
checks=0
while [ $checks -lt $max_checks ]; do
  if grep -aq '%nock' "$tmpfile" 2>/dev/null; then
    sleep 1  # let the full %nock line flush before killing
    break
  fi
  sleep 0.5
  checks=$((checks + 1))
done

# Kill jockc (it's either hung after output, or we timed out).
kill "$JOCK_PID" 2>/dev/null || true
wait "$JOCK_PID" 2>/dev/null || true

# Read and clean output (strip null bytes first — jockc emits binary log data on Linux).
output=$(tr -d '\0' < "$tmpfile" | sed 's/\x1b\[[0-9;]*m//g')

# Extract %nock result line.
nock_line=$(printf '%s' "$output" | grep '%nock' | head -1 || true)

if [ -z "$nock_line" ]; then
  echo "FAIL [$test_name]: did not reach %nock"
  printf '%s\n' "$output" | tail -5 | sed 's/^/  /'
  exit 1
fi

# Normalize: strip tag, collapse whitespace, trim.
nock_value=$(printf '%s' "$nock_line" \
  | sed 's/.*%nock//' \
  | tr -s ' \t' ' ' \
  | sed 's/^ //;s/ $//')

# Tier 1: %nock reached — if no expected file, that's enough.
if [ ! -f "$expected_path" ]; then
  echo "PASS [$test_name] (no expected file; %nock reached)"
  exit 0
fi

# Tier 2: compare against expected output.
expected=$(cat "$expected_path")

if [ "$nock_value" = "$expected" ]; then
  echo "PASS [$test_name]"
  exit 0
else
  echo "FAIL [$test_name]: output mismatch"
  echo "  expected: $expected"
  echo "  got:      $nock_value"
  exit 1
fi
