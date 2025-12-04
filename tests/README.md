# Unit Tests

This directory contains unit tests for the mise-xcode plugin using [LuaUnit](https://github.com/bluebird75/luaunit).

## Running Tests

### Without mise (standalone)

Requires Lua 5.1 or later and LuaUnit:

```bash
# Install LuaUnit
luarocks install luaunit

# Run tests
./run_tests.sh
```

On macOS:
```bash
brew install lua luarocks
luarocks install luaunit
./run_tests.sh
```

On Ubuntu/Debian:
```bash
apt-get install lua5.1 luarocks
luarocks install luaunit
./run_tests.sh
```

### With mise

```bash
mise run test
```

## Test Files

- `test_version.lua` - Tests for Version module (parsing, comparison, fuzzy matching)
- `test_xcode.lua` - Tests for Xcode module (object creation, comparison, paths)
- `test_utils.lua` - Tests for utils module (version selection logic)

## Writing Tests

Tests use [LuaUnit](https://github.com/bluebird75/luaunit), a popular Lua testing framework. Here's an example:

```lua
-- Add lib directory to package path
package.path = package.path .. ";./lib/?.lua"

local lu = require("luaunit")
local YourModule = require("YourModule")

TestYourModule = {}

function TestYourModule:testSomeFeature()
    local obj = YourModule.new("param")
    lu.assertNotNil(obj)
    lu.assertEquals(obj.field, "expected_value")
end

function TestYourModule:testAnotherFeature()
    local result = YourModule.someFunction()
    lu.assertTrue(result)
end

-- Run tests
os.exit(lu.LuaUnit.run())
```

### Available Assertions

LuaUnit provides a rich set of assertions:

- `lu.assertEquals(actual, expected)` - Assert equality
- `lu.assertTrue(value)` - Assert true
- `lu.assertFalse(value)` - Assert false
- `lu.assertNil(value)` - Assert nil
- `lu.assertNotNil(value)` - Assert not nil
- `lu.assertStrContains(str, substr)` - Assert string contains substring
- `lu.assertErrorMsgContains(expectedMsg, func)` - Assert function throws error with message

See [LuaUnit documentation](https://luaunit.readthedocs.io/) for more assertions.

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
- Tests use LuaUnit framework for consistency and better reporting
- OS-dependent functions (plist reading, xcode detection) are only testable on macOS
