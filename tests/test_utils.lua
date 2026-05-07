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

-- Tests for resolve_path

function TestUtils:testResolvePathAbsolute()
	local result = utils.resolve_path("/absolute/path/to/file")
	lu.assertEquals(result, "/absolute/path/to/file", "Absolute paths should pass through unchanged")
end

function TestUtils:testResolvePathExpandsTilde()
	local home = os.getenv("HOME")
	lu.assertNotNil(home, "HOME must be set for this test")
	local result = utils.resolve_path("~/some/file")
	lu.assertEquals(result, home .. "/some/file", "~ should be expanded to $HOME")
end

function TestUtils:testResolvePathExpandsTildeOnly()
	local home = os.getenv("HOME")
	lu.assertNotNil(home, "HOME must be set for this test")
	local result = utils.resolve_path("~")
	lu.assertEquals(result, home, "~ alone should expand to $HOME")
end

function TestUtils:testResolvePathErrorOnTildeUsername()
	lu.assertErrorMsgContains("Unsupported home expansion", utils.resolve_path, "~user/file")
end

function TestUtils:testResolvePathRelativeWithConfigRoot()
	local result = utils.resolve_path("relative/file", "/my/project")
	lu.assertEquals(result, "/my/project/relative/file", "Relative paths should resolve against config_root")
end

function TestUtils:testResolvePathRelativeFallsToPwd()
	local pwd = os.getenv("PWD")
	lu.assertNotNil(pwd, "PWD must be set for this test")
	local result = utils.resolve_path("relative/file")
	lu.assertEquals(result, pwd .. "/relative/file", "Relative paths should fall back to $PWD when no config_root")
end

function TestUtils:testResolvePathRelativeDotSlash()
	local result = utils.resolve_path("./file", "/my/project")
	lu.assertEquals(result, "/my/project/./file", "Paths starting with ./ should resolve against config_root")
end

function TestUtils:testResolvePathErrorOnEmpty()
	lu.assertErrorMsgContains("nil or empty", utils.resolve_path, "")
end

function TestUtils:testResolvePathErrorOnNil()
	lu.assertErrorMsgContains("nil or empty", utils.resolve_path, nil)
end
