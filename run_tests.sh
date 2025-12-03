#!/usr/bin/env bash
# run_tests.sh
# Runs all unit tests without requiring mise

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Running unit tests for mise-xcode..."
echo "======================================"

# Check if lua is available
if ! command -v lua &> /dev/null; then
    echo -e "${RED}Error: lua command not found${NC}"
    echo "Please install Lua 5.1 or later to run tests"
    echo "You can install it via:"
    echo "  - macOS: brew install lua"
    echo "  - Ubuntu/Debian: apt-get install lua5.1"
    echo "  - Or use mise: mise install lua && mise use lua"
    exit 1
fi

echo -e "${YELLOW}Using Lua:${NC} $(lua -v 2>&1 | head -n1)"
echo ""

# Track test results
FAILED_TESTS=()
PASSED_TESTS=()

# Run each test file
for test_file in "$PROJECT_ROOT/tests"/test_*.lua; do
    if [ -f "$test_file" ]; then
        test_name=$(basename "$test_file")
        echo "Running $test_name..."
        
        # Run the test from the project root directory
        if (cd "$PROJECT_ROOT" && lua "$test_file"); then
            PASSED_TESTS+=("$test_name")
        else
            FAILED_TESTS+=("$test_name")
        fi
        echo ""
    fi
done

# Print summary
echo "======================================"
echo "Test Summary"
echo "======================================"
echo -e "${GREEN}Passed:${NC} ${#PASSED_TESTS[@]}"
if [ ${#PASSED_TESTS[@]} -gt 0 ]; then
    for test in "${PASSED_TESTS[@]}"; do
        echo -e "  ${GREEN}✓${NC} $test"
    done
fi

echo -e "${RED}Failed:${NC} ${#FAILED_TESTS[@]}"
if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $test"
    done
fi

echo "======================================"

# Exit with error if any tests failed
if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    exit 1
fi

echo -e "${GREEN}All tests passed!${NC}"
exit 0
