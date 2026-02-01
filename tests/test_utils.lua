-- tests/test_utils.lua
-- Unit tests for the utils module

-- Add lib directory to package path so we can require modules
package.path = package.path .. ";./lib/?.lua"

local lu = require("luaunit")
local utils = require("utils")

TestUtils = {}

function TestUtils:testSelectExactMatchWhenAvailable()
	-- Create mock Xcode objects
	local Xcode = require("Xcode")
	local xcodes = {
		Xcode.new("/Applications/Xcode_15.app", "15.0.0"),
		Xcode.new("/Applications/Xcode.app", "16.4.1"),
		Xcode.new("/Applications/Xcode_17.app", "17.0.0"),
	}

	local result = assert(utils.select_best_version(xcodes, "16.4.1"), "Expected exact match")
	lu.assertEquals(tostring(result.version), "16.4.1")
end

function TestUtils:testSelectHighestMatchingVersionWithMajorOnly()
	local Xcode = require("Xcode")
	local xcodes = {
		Xcode.new("/Applications/Xcode_16.app", "16.0.0"),
		Xcode.new("/Applications/Xcode_16_2.app", "16.2.0"),
		Xcode.new("/Applications/Xcode.app", "16.4.1"),
		Xcode.new("/Applications/Xcode_17.app", "17.0.0"),
	}

	local result = assert(utils.select_best_version(xcodes, "16"), "Expected major-only match")
	lu.assertEquals(tostring(result.version), "16.4.1", "Should select highest 16.x version")
end

function TestUtils:testSelectHighestMatchingVersionWithMajorMinor()
	local Xcode = require("Xcode")
	local xcodes = {
		Xcode.new("/Applications/Xcode_16_4.app", "16.4.0"),
		Xcode.new("/Applications/Xcode.app", "16.4.1"),
		Xcode.new("/Applications/Xcode_16_4_2.app", "16.4.2"),
		Xcode.new("/Applications/Xcode_16_5.app", "16.5.0"),
	}

	local result = assert(utils.select_best_version(xcodes, "16.4"), "Expected major/minor match")
	lu.assertEquals(tostring(result.version), "16.4.2", "Should select highest 16.4.x version")
end

function TestUtils:testReturnNilWhenNoMatchFound()
	local Xcode = require("Xcode")
	local xcodes = {
		Xcode.new("/Applications/Xcode_15.app", "15.0.0"),
		Xcode.new("/Applications/Xcode.app", "16.4.1"),
	}

	local result = utils.select_best_version(xcodes, "17.0")
	lu.assertNil(result, "Should return nil when no matching version found")
end

function TestUtils:testHandleEmptyList()
	local result = utils.select_best_version({}, "16.4")
	lu.assertNil(result, "Should return nil for empty list")
end

function TestUtils:testHandleEmptyDesiredVersion()
	local Xcode = require("Xcode")
	local xcodes = {
		Xcode.new("/Applications/Xcode.app", "16.4.1"),
	}

	local result = utils.select_best_version(xcodes, "")
	lu.assertNil(result, "Should return nil for empty desired version")
end

function TestUtils:testPreferHigherPatchVersions()
	local Xcode = require("Xcode")
	local xcodes = {
		Xcode.new("/Applications/Xcode_16_4.app", "16.4.0"),
		Xcode.new("/Applications/Xcode_16_4_1.app", "16.4.1"),
		Xcode.new("/Applications/Xcode.app", "16.4.5"),
		Xcode.new("/Applications/Xcode_16_4_2.app", "16.4.2"),
	}

	local result = assert(utils.select_best_version(xcodes, "16.4"), "Expected patch match")
	lu.assertEquals(tostring(result.version), "16.4.5")
end
