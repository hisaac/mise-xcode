#!/usr/bin/env bash

set -o errexit  # Exit on error
set -o nounset  # Exit on unset variable
set -o pipefail # Exit on pipe failure

# Output extra debug logging if `DEBUG` or `TRACE` are set to `true` or `RUNNER_DEBUG` is set to `1`
# (https://docs.github.com/en/actions/reference/workflows-and-actions/variables)
if [[ "${DEBUG:-}" == "true" || "${TRACE:-}" == "true" || "${RUNNER_DEBUG:-}" == "1" ]]; then
	set -o xtrace # Trace the execution of the script (debug)
fi

function main() {
	local -r os="$(uname -s | tr '[:upper:]' '[:lower:]')"
	case "${os}" in
	darwin*) test-macos ;;
	linux*) test-linux ;;
	*) echo "Unsupported OS: $os" ;;
	esac
}

function test-macos() {
	mise plugin link --force xcode-version .
}

function test-linux() {
	set +e # Don't exit on error

	local -r temp_file=$(mktemp)
	mise plugin link --force xcode-version . 2>&1 | tee "${temp_file}"

	# Check if it failed with the expected error message
	if grep -q "Xcode is only available for macOS" "${temp_file}"; then
		echo "✓ Plugin correctly failed on Ubuntu with expected error"
		exit 0
	else
		echo "✗ Plugin did not fail as expected on Ubuntu"
		cat "${temp_file}"
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
