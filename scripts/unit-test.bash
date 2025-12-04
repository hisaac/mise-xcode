#!/usr/bin/env bash

# Runs all unit tests using LuaUnit

set -o errexit  # Exit on error
set -o nounset  # Exit on unset variable
set -o pipefail # Exit on pipe failure

# Output extra debug logging if `DEBUG` or `TRACE` are set to `true` or `RUNNER_DEBUG` is set to `1`
# (https://docs.github.com/en/actions/reference/workflows-and-actions/variables)
if [[ "${DEBUG:-}" == "true" || "${TRACE:-}" == "true" || "${RUNNER_DEBUG:-}" == "1" ]]; then
	set -o xtrace # Trace the execution of the script (debug)
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function main() {
	echo "Running unit tests for mise-xcode..."
	echo "======================================"

	echo -e "${YELLOW}Using LuaUnit${NC}"
	echo ""

	# Track test results
	local failed_tests=()
	local passed_tests=()

	# Run each test file
	for test_file in "$MISE_PROJECT_ROOT/tests"/test_*.lua; do
		if [ -f "$test_file" ]; then
			test_name=$(basename "$test_file")
			echo -e "${YELLOW}Running $test_name...${NC}"

			# Run the test from the project root directory
			if (cd "$MISE_PROJECT_ROOT" && lua "$test_file"); then
				passed_tests+=("$test_name")
			else
				failed_tests+=("$test_name")
			fi
			echo ""
		fi
	done

	# Print summary
	echo "======================================"
	echo "Test Summary"
	echo "======================================"
	echo -e "${GREEN}Passed:${NC} ${#passed_tests[@]}"
	if [ ${#passed_tests[@]} -gt 0 ]; then
		for test in "${passed_tests[@]}"; do
			echo -e "  ${GREEN}✓${NC} $test"
		done
	fi

	echo -e "${RED}Failed:${NC} ${#failed_tests[@]}"
	if [ ${#failed_tests[@]} -gt 0 ]; then
		for test in "${failed_tests[@]}"; do
			echo -e "  ${RED}✗${NC} $test"
		done
	fi

	echo "======================================"

	# Exit with error if any tests failed
	if [ ${#failed_tests[@]} -gt 0 ]; then
		exit 1
	fi

	echo -e "${GREEN}All tests passed!${NC}"
	exit 0
}

trap handle_exit EXIT
# shellcheck disable=SC2329
function handle_exit() {
	declare -ri exit_code="$?"
	if [[ "${exit_code}" -ne 0 ]]; then
		declare -r script_name="${0##*/}"
		echo -e "\n==> ${script_name} exited with code ${exit_code}"
	fi
}

main "$@"
