-- tests/run_integration_tests.lua
-- Test runner for integration tests only

-- Ensure local lib and tests are on the path
package.path = package.path .. ";./lib/?.lua;./tests/?.lua"

local lu = require("luaunit")

require("test_integration")

os.exit(lu.LuaUnit.run())
