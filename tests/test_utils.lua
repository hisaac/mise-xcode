-- tests/test_utils.lua
-- Unit tests for the utils module

-- Add lib directory to package path so we can require modules
package.path = package.path .. ";./lib/?.lua;./tests/?.lua"

local TestFramework = require("framework")
local utils = require("utils")

local test = TestFramework.new()

test:describe("select_best_version()", function()
	test:it("should select exact match when available", function()
		-- Create mock Xcode objects
		local Xcode = require("Xcode")
		local xcodes = {
			Xcode.new("/Applications/Xcode_15.app", "15.0.0"),
			Xcode.new("/Applications/Xcode.app", "16.4.1"),
			Xcode.new("/Applications/Xcode_17.app", "17.0.0"),
		}
		
		local result = utils.select_best_version(xcodes, "16.4.1")
		test:assert_not_nil(result)
		test:assert_equal(tostring(result.version), "16.4.1")
	end)
	
	test:it("should select highest matching version with major only", function()
		local Xcode = require("Xcode")
		local xcodes = {
			Xcode.new("/Applications/Xcode_16.app", "16.0.0"),
			Xcode.new("/Applications/Xcode_16_2.app", "16.2.0"),
			Xcode.new("/Applications/Xcode.app", "16.4.1"),
			Xcode.new("/Applications/Xcode_17.app", "17.0.0"),
		}
		
		local result = utils.select_best_version(xcodes, "16")
		test:assert_not_nil(result)
		test:assert_equal(tostring(result.version), "16.4.1", "Should select highest 16.x version")
	end)
	
	test:it("should select highest matching version with major.minor", function()
		local Xcode = require("Xcode")
		local xcodes = {
			Xcode.new("/Applications/Xcode_16_4.app", "16.4.0"),
			Xcode.new("/Applications/Xcode.app", "16.4.1"),
			Xcode.new("/Applications/Xcode_16_4_2.app", "16.4.2"),
			Xcode.new("/Applications/Xcode_16_5.app", "16.5.0"),
		}
		
		local result = utils.select_best_version(xcodes, "16.4")
		test:assert_not_nil(result)
		test:assert_equal(tostring(result.version), "16.4.2", "Should select highest 16.4.x version")
	end)
	
	test:it("should return nil when no match found", function()
		local Xcode = require("Xcode")
		local xcodes = {
			Xcode.new("/Applications/Xcode_15.app", "15.0.0"),
			Xcode.new("/Applications/Xcode.app", "16.4.1"),
		}
		
		local result = utils.select_best_version(xcodes, "17.0")
		test:assert_nil(result, "Should return nil when no matching version found")
	end)
	
	test:it("should handle empty list", function()
		local result = utils.select_best_version({}, "16.4")
		test:assert_nil(result, "Should return nil for empty list")
	end)
	
	test:it("should prefer higher patch versions", function()
		local Xcode = require("Xcode")
		local xcodes = {
			Xcode.new("/Applications/Xcode_16_4.app", "16.4.0"),
			Xcode.new("/Applications/Xcode_16_4_1.app", "16.4.1"),
			Xcode.new("/Applications/Xcode.app", "16.4.5"),
			Xcode.new("/Applications/Xcode_16_4_2.app", "16.4.2"),
		}
		
		local result = utils.select_best_version(xcodes, "16.4")
		test:assert_not_nil(result)
		test:assert_equal(tostring(result.version), "16.4.5")
	end)
end)

test:describe("check_os()", function()
	test:it("should not throw error on macOS", function()
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
			local success, err = pcall(function()
				utils.check_os()
			end)
			test:assert_true(success, "check_os should not error on macOS")
		else
			-- On other systems, this should error
			test:assert_error(function()
				utils.check_os()
			end, "check_os should error on non-macOS systems")
		end
	end)
end)

-- Run tests and exit with appropriate code
local success = test:summary()
os.exit(success and 0 or 1)
