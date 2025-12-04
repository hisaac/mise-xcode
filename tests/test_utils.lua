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

	local result = utils.select_best_version(xcodes, "16.4.1")
	lu.assertNotNil(result)
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

	local result = utils.select_best_version(xcodes, "16")
	lu.assertNotNil(result)
	lu.assertEquals(tostring(result.version), "16.4.1")
end

function TestUtils:testSelectHighestMatchingVersionWithMajorMinor()
	local Xcode = require("Xcode")
	local xcodes = {
		Xcode.new("/Applications/Xcode_16_4.app", "16.4.0"),
		Xcode.new("/Applications/Xcode.app", "16.4.1"),
		Xcode.new("/Applications/Xcode_16_4_2.app", "16.4.2"),
		Xcode.new("/Applications/Xcode_16_5.app", "16.5.0"),
	}

	local result = utils.select_best_version(xcodes, "16.4")
	lu.assertNotNil(result)
	lu.assertEquals(tostring(result.version), "16.4.2")
end

function TestUtils:testReturnNilWhenNoMatchFound()
	local Xcode = require("Xcode")
	local xcodes = {
		Xcode.new("/Applications/Xcode_15.app", "15.0.0"),
		Xcode.new("/Applications/Xcode.app", "16.4.1"),
	}

	local result = utils.select_best_version(xcodes, "17.0")
	lu.assertNil(result)
end

function TestUtils:testHandleEmptyList()
	local result = utils.select_best_version({}, "16.4")
	lu.assertNil(result)
end

function TestUtils:testPreferHigherPatchVersions()
	local Xcode = require("Xcode")
	local xcodes = {
		Xcode.new("/Applications/Xcode_16_4.app", "16.4.0"),
		Xcode.new("/Applications/Xcode_16_4_1.app", "16.4.1"),
		Xcode.new("/Applications/Xcode.app", "16.4.5"),
		Xcode.new("/Applications/Xcode_16_4_2.app", "16.4.2"),
	}

	local result = utils.select_best_version(xcodes, "16.4")
	lu.assertNotNil(result)
	lu.assertEquals(tostring(result.version), "16.4.5")
end

function TestUtils:testCheckOsValidation()
	-- This test will only pass on macOS
	-- On other systems it should fail
	local function get_os()
		local handle = io.popen("uname -s")
		if not handle then
			return nil
		end
		local result = handle:read("*a")
		handle:close()
		return result:lower():gsub("%s+", "")
	end

	local os_name = get_os()
	if os_name == "darwin" then
		-- On macOS, this should not error
		local success = pcall(function()
			utils.check_os()
		end)
		lu.assertTrue(success)
	else
		-- On other systems, this should error
		lu.assertErrorMsgContains("Xcode is only available for macOS", function()
			utils.check_os()
		end)
	end
end

-- Run tests
os.exit(lu.LuaUnit.run())
