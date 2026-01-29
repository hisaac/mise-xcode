-- tests/run.lua
-- Test runner for all unit tests

-- Ensure local lib and tests are on the path
package.path = package.path .. ";./lib/?.lua;./tests/?.lua"

local lu = require("luaunit")

require("test_version")
require("test_xcode")
require("test_utils")

os.exit(lu.LuaUnit.run())
