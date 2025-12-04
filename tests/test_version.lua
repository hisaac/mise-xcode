-- tests/test_version.lua
-- Unit tests for the Version module

-- Add lib directory to package path so we can require modules
package.path = package.path .. ";./lib/?.lua"

local lu = require("luaunit")
local Version = require("Version")

TestVersion = {}

function TestVersion:testCreateVersionFromSimpleString()
	local v = Version.new("16")
	lu.assertEquals(v.raw, "16")
	lu.assertEquals(v.parts[1], 16)
	lu.assertEquals(v.parts[2], 0)
	lu.assertEquals(v.parts[3], 0)
	lu.assertEquals(v.precision, 1)
end

function TestVersion:testCreateVersionFromTwoPartString()
	local v = Version.new("16.4")
	lu.assertEquals(v.raw, "16.4")
	lu.assertEquals(v.parts[1], 16)
	lu.assertEquals(v.parts[2], 4)
	lu.assertEquals(v.parts[3], 0)
	lu.assertEquals(v.precision, 2)
end

function TestVersion:testCreateVersionFromThreePartString()
	local v = Version.new("16.4.1")
	lu.assertEquals(v.raw, "16.4.1")
	lu.assertEquals(v.parts[1], 16)
	lu.assertEquals(v.parts[2], 4)
	lu.assertEquals(v.parts[3], 1)
	lu.assertEquals(v.precision, 3)
end

function TestVersion:testHandleVersionStringsWithMoreThanThreeParts()
	local v = Version.new("16.4.1.2")
	lu.assertEquals(v.precision, 4)
	-- Parts are padded to 3, so only first 3 parts are stored in parts array
	lu.assertEquals(v.parts[1], 16)
	lu.assertEquals(v.parts[2], 4)
	lu.assertEquals(v.parts[3], 1)
end

function TestVersion:testCompareMajorVersionsCorrectly()
	local v1 = Version.new("15.0.0")
	local v2 = Version.new("16.0.0")
	lu.assertTrue(v1 < v2)
	lu.assertFalse(v2 < v1)
end

function TestVersion:testCompareMinorVersionsCorrectly()
	local v1 = Version.new("16.3.0")
	local v2 = Version.new("16.4.0")
	lu.assertTrue(v1 < v2)
	lu.assertFalse(v2 < v1)
end

function TestVersion:testComparePatchVersionsCorrectly()
	local v1 = Version.new("16.4.0")
	local v2 = Version.new("16.4.1")
	lu.assertTrue(v1 < v2)
	lu.assertFalse(v2 < v1)
end

function TestVersion:testReturnFalseForEqualVersions()
	local v1 = Version.new("16.4.1")
	local v2 = Version.new("16.4.1")
	lu.assertFalse(v1 < v2)
	lu.assertFalse(v2 < v1)
end

function TestVersion:testReturnTrueForEqualVersionsUsingEquality()
	local v1 = Version.new("16.4.1")
	local v2 = Version.new("16.4.1")
	lu.assertTrue(v1 == v2)
end

function TestVersion:testReturnFalseForDifferentVersions()
	local v1 = Version.new("16.4.0")
	local v2 = Version.new("16.4.1")
	lu.assertFalse(v1 == v2)
end

function TestVersion:testHandleVersionsWithDifferentPrecision()
	local v1 = Version.new("16")
	local v2 = Version.new("16.0.0")
	lu.assertTrue(v1 == v2)
end

function TestVersion:testConvertVersionToString()
	local v = Version.new("16.4.1")
	lu.assertEquals(tostring(v), "16.4.1")
end

function TestVersion:testShowPaddedZeros()
	local v = Version.new("16")
	lu.assertEquals(tostring(v), "16.0.0")
end

function TestVersion:testMatchWhenQueryHasPrecision1()
	local v = Version.new("16.4.1")
	local query = Version.new("16")
	lu.assertTrue(v:matches_fuzzy(query))
end

function TestVersion:testNotMatchWhenMajorDiffers()
	local v = Version.new("15.4.1")
	local query = Version.new("16")
	lu.assertFalse(v:matches_fuzzy(query))
end

function TestVersion:testMatchWhenQueryHasPrecision2()
	local v = Version.new("16.4.1")
	local query = Version.new("16.4")
	lu.assertTrue(v:matches_fuzzy(query))
end

function TestVersion:testNotMatchWhenMinorDiffers()
	local v = Version.new("16.3.1")
	local query = Version.new("16.4")
	lu.assertFalse(v:matches_fuzzy(query))
end

function TestVersion:testMatchWhenQueryHasPrecision3()
	local v = Version.new("16.4.1")
	local query = Version.new("16.4.1")
	lu.assertTrue(v:matches_fuzzy(query))
end

function TestVersion:testNotMatchWhenPatchDiffers()
	local v = Version.new("16.4.0")
	local query = Version.new("16.4.1")
	lu.assertFalse(v:matches_fuzzy(query))
end

function TestVersion:testAllowDifferentPatchWhenQueryPrecisionIs2()
	local v1 = Version.new("16.4.0")
	local v2 = Version.new("16.4.1")
	local query = Version.new("16.4")
	lu.assertTrue(v1:matches_fuzzy(query))
	lu.assertTrue(v2:matches_fuzzy(query))
end

-- Run tests
os.exit(lu.LuaUnit.run())
