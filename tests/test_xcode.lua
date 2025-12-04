-- tests/test_xcode.lua
-- Unit tests for the Xcode module

-- Add lib directory to package path so we can require modules
package.path = package.path .. ";./lib/?.lua"

local lu = require("luaunit")
local Xcode = require("Xcode")

TestXcode = {}

function TestXcode:testCreateXcodeObjectWithPathAndVersion()
	local xcode = Xcode.new("/Applications/Xcode.app", "16.4.1")
	lu.assertNotNil(xcode)
	lu.assertEquals(xcode.path, "/Applications/Xcode.app")
	lu.assertNotNil(xcode.version)
end

function TestXcode:testCreateVersionObjectFromVersionString()
	local xcode = Xcode.new("/Applications/Xcode.app", "16.4.1")
	lu.assertEquals(xcode.version.parts[1], 16)
	lu.assertEquals(xcode.version.parts[2], 4)
	lu.assertEquals(xcode.version.parts[3], 1)
end

function TestXcode:testCompareXcodeObjectsByVersion()
	local xcode1 = Xcode.new("/Applications/Xcode_15.app", "15.0.0")
	local xcode2 = Xcode.new("/Applications/Xcode.app", "16.0.0")
	lu.assertTrue(xcode1 < xcode2)
	lu.assertFalse(xcode2 < xcode1)
end

function TestXcode:testHandleDifferentPathsWithSameVersion()
	local xcode1 = Xcode.new("/Applications/Xcode.app", "16.0.0")
	local xcode2 = Xcode.new("/Users/test/Applications/Xcode.app", "16.0.0")
	lu.assertFalse(xcode1 < xcode2)
	lu.assertFalse(xcode2 < xcode1)
end

function TestXcode:testConvertXcodeToStringWithVersionAndPath()
	local xcode = Xcode.new("/Applications/Xcode.app", "16.4.1")
	local str = tostring(xcode)
	lu.assertStrContains(str, "Xcode")
	lu.assertStrContains(str, "16.4.1")
	lu.assertStrContains(str, "/Applications/Xcode.app")
end

function TestXcode:testReturnCorrectDeveloperDirectoryPath()
	local xcode = Xcode.new("/Applications/Xcode.app", "16.4.1")
	local dev_dir = xcode:developer_dir()
	lu.assertEquals(dev_dir, "/Applications/Xcode.app/Contents/Developer")
end

function TestXcode:testWorkWithDifferentBasePaths()
	local xcode = Xcode.new("/Users/test/Applications/Xcode_16.app", "16.0.0")
	local dev_dir = xcode:developer_dir()
	lu.assertEquals(dev_dir, "/Users/test/Applications/Xcode_16.app/Contents/Developer")
end

-- Run tests
os.exit(lu.LuaUnit.run())
