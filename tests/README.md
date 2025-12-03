# Unit Tests

This directory contains unit tests for the mise-xcode plugin.

## Running Tests

### Without mise (standalone)

Requires Lua 5.1 or later:

```bash
./run_tests.sh
```

On macOS:
```bash
brew install lua
./run_tests.sh
```

On Ubuntu/Debian:
```bash
apt-get install lua5.1
./run_tests.sh
```

### With mise

```bash
mise run test
```

## Test Files

- `framework.lua` - Simple test framework (no external dependencies)
- `test_version.lua` - Tests for Version module (parsing, comparison, fuzzy matching)
- `test_xcode.lua` - Tests for Xcode module (object creation, comparison, paths)
- `test_utils.lua` - Tests for utils module (version selection logic)

## Writing Tests

Tests use a simple built-in framework. Here's an example:

```lua
-- Add lib directory to package path
package.path = package.path .. ";./lib/?.lua;./tests/?.lua"

local TestFramework = require("framework")
local YourModule = require("YourModule")

local test = TestFramework.new()

test:describe("YourModule.new()", function()
    test:it("should create an object", function()
        local obj = YourModule.new("param")
        test:assert_not_nil(obj)
        test:assert_equal(obj.field, "expected_value")
    end)
end)

-- Run tests and exit with appropriate code
local success = test:summary()
os.exit(success and 0 or 1)
```

### Available Assertions

- `test:assert_equal(actual, expected, message)` - Assert equality
- `test:assert_true(value, message)` - Assert true
- `test:assert_false(value, message)` - Assert false
- `test:assert_nil(value, message)` - Assert nil
- `test:assert_not_nil(value, message)` - Assert not nil
- `test:assert_error(func, message)` - Assert function throws error

## Test Coverage

Current test coverage includes:

### Version.lua (100%)
- ✅ Constructor with different precision levels
- ✅ Comparison operators (`<`, `==`)
- ✅ String conversion
- ✅ Fuzzy matching logic

### Xcode.lua (100%)
- ✅ Constructor
- ✅ Comparison operators
- ✅ Developer directory path generation
- ✅ String representation

### utils.lua (Partial)
- ✅ `select_best_version()` with various scenarios
- ✅ `check_os()` validation
- ⚠️ OS-dependent functions not tested (require macOS)
  - `get_installed_xcodes()` - requires macOS filesystem
  - `read_plist_key()` - requires PlistBuddy tool
  - `find_xcode_versions_in()` - requires macOS filesystem

## Notes

- Tests are designed to run independently without mise
- OS-dependent functions (plist reading, xcode detection) are only testable on macOS
- The test framework is intentionally minimal to avoid external dependencies
