#!/bin/bash
# tests/integration_tests.sh
# Integration tests for the mise-xcode plugin using shell-based e2e approach.
# Run with: bash tests/integration_tests.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
SKIP=0

# --- Helpers ---

red() { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }

pass() {
	green "  PASS: $1"
	PASS=$((PASS + 1))
}

fail() {
	red "  FAIL: $1 — $2"
	FAIL=$((FAIL + 1))
}

skip() {
	yellow "  SKIP: $1 — $2"
	SKIP=$((SKIP + 1))
}

is_macos() {
	[[ "$(uname -s)" == "Darwin" ]]
}

get_env_var() {
	# Usage: get_env_var <mise_env_name> <var_name> [workdir]
	local env_name="$1"
	local var_name="$2"
	local workdir="${3:-$PROJECT_ROOT}"

	local json
	json=$(cd "$workdir" && mise env --env "$env_name" --json 2>/dev/null) || return 1
	echo "$json" | jq -r ".[\"$var_name\"] // empty"
}

# --- Setup ---

echo "Setting up: linking plugin..."
mise plugin link --force xcode "$PROJECT_ROOT"
echo ""

# --- Tests ---

echo "Running integration tests..."
echo ""

# Test: version option sets DEVELOPER_DIR on macOS
if is_macos; then
	dev_dir=$(get_env_var "integration-tests_version" "DEVELOPER_DIR")
	if [[ -n "$dev_dir" ]]; then
		pass "version option sets DEVELOPER_DIR on macOS"
	else
		fail "version option sets DEVELOPER_DIR on macOS" "DEVELOPER_DIR was empty"
	fi
else
	dev_dir=$(get_env_var "integration-tests_version" "DEVELOPER_DIR")
	if [[ -z "$dev_dir" ]]; then
		pass "version option returns empty on non-macOS"
	else
		fail "version option returns empty on non-macOS" "DEVELOPER_DIR was unexpectedly set"
	fi
fi

# Test: version_file from project root
if is_macos; then
	dev_dir=$(get_env_var "integration-tests_version_file" "DEVELOPER_DIR")
	if [[ -n "$dev_dir" ]]; then
		pass "version_file sets DEVELOPER_DIR from project root"
	else
		fail "version_file sets DEVELOPER_DIR from project root" "DEVELOPER_DIR was empty"
	fi
else
	skip "version_file sets DEVELOPER_DIR from project root" "not macOS"
fi

# Test: version_file from subdirectory (the key regression test)
if is_macos; then
	dev_dir=$(get_env_var "integration-tests_version_file" "DEVELOPER_DIR" "$PROJECT_ROOT/tests/test-data")
	if [[ -n "$dev_dir" ]]; then
		pass "version_file resolves correctly from subdirectory"
	else
		fail "version_file resolves correctly from subdirectory" "DEVELOPER_DIR was empty (config_root resolution failed)"
	fi
else
	skip "version_file resolves correctly from subdirectory" "not macOS"
fi

# --- Summary ---

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"

if [[ $FAIL -gt 0 ]]; then
	exit 1
fi
