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

function main() {
	local -a failures=()
	set +e
	for test_file in "${MISE_PROJECT_ROOT}"/tests/test_*.lua; do
		echo "==> Running test file: $test_file"
		if ! lua "$test_file" --verbose; then
			failures+=("$test_file")
		fi
		echo
	done
	set -e
	if [[ ${#failures[@]} -gt 0 ]]; then
		echo "==> Failed test suites:"
		for failure in "${failures[@]}"; do
			echo "  - $failure"
		done
		exit 1
	fi
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
