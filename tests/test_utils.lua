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

	local result = utils.select_best_version(xcodes, "16.4")
	lu.assertNotNil(result)
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

function TestUtils:testHandleNilList()
	local result = utils.select_best_version(nil, "16.4")
	lu.assertNil(result, "Should return nil for nil list")
end

function TestUtils:testHandleNilDesiredVersion()
	local Xcode = require("Xcode")
	local xcodes = {
		Xcode.new("/Applications/Xcode.app", "16.4.1"),
	}

	local result = utils.select_best_version(xcodes, nil)
	lu.assertNil(result, "Should return nil for nil desired version")
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
		lu.assertTrue(success, "check_os should not error on macOS")
	else
		-- On other systems, this should error
		local success, err = pcall(function()
			utils.check_os()
		end)
		lu.assertFalse(success)
		lu.assertTrue(tostring(err):find("Xcode is only available for macOS") ~= nil)
	end
end

function TestUtils:testReadFileAndTrim()
	local temp_path = os.tmpname()
	local file = assert(io.open(temp_path, "w"))
	file:write("  hello  ")
	file:close()

	local raw = utils.read_file(temp_path, false)
	local trimmed = utils.read_file(temp_path, true)

	lu.assertEquals(raw, "  hello  ")
	lu.assertEquals(trimmed, "hello")

	os.remove(temp_path)
end

function TestUtils:testReadFileErrorsOnEmptyPath()
	local success, err = pcall(function()
		utils.read_file("")
	end)
	lu.assertFalse(success)
	lu.assertTrue(tostring(err):find("File path cannot be nil or empty") ~= nil)
end
