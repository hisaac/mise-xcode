-- tests/test_xcode.lua
-- Unit tests for the Xcode module

-- Add lib directory to package path so we can require modules
package.path = package.path .. ";./lib/?.lua;./tests/?.lua"

local TestFramework = require("framework")
local Xcode = require("Xcode")

local test = TestFramework.new()

test:describe("Xcode.new()", function()
	test:it("should create an Xcode object with path and version", function()
		local xcode = Xcode.new("/Applications/Xcode.app", "16.4.1")
		test:assert_not_nil(xcode)
		test:assert_equal(xcode.path, "/Applications/Xcode.app")
		test:assert_not_nil(xcode.version)
	end)
	
	test:it("should create a version object from version string", function()
		local xcode = Xcode.new("/Applications/Xcode.app", "16.4.1")
		test:assert_equal(xcode.version.parts[1], 16)
		test:assert_equal(xcode.version.parts[2], 4)
		test:assert_equal(xcode.version.parts[3], 1)
	end)
end)

test:describe("Xcode:__lt (less than)", function()
	test:it("should compare Xcode objects by version", function()
		local xcode1 = Xcode.new("/Applications/Xcode_15.app", "15.0.0")
		local xcode2 = Xcode.new("/Applications/Xcode.app", "16.0.0")
		test:assert_true(xcode1 < xcode2)
		test:assert_false(xcode2 < xcode1)
	end)
	
	test:it("should handle different paths with same version", function()
		local xcode1 = Xcode.new("/Applications/Xcode.app", "16.0.0")
		local xcode2 = Xcode.new("/Users/test/Applications/Xcode.app", "16.0.0")
		test:assert_false(xcode1 < xcode2)
		test:assert_false(xcode2 < xcode1)
	end)
end)

test:describe("Xcode:__tostring", function()
	test:it("should convert Xcode to string with version and path", function()
		local xcode = Xcode.new("/Applications/Xcode.app", "16.4.1")
		local str = tostring(xcode)
		test:assert_true(str:find("Xcode") ~= nil)
		test:assert_true(str:find("16.4.1") ~= nil)
		test:assert_true(str:find("/Applications/Xcode.app") ~= nil)
	end)
end)

test:describe("Xcode:developer_dir()", function()
	test:it("should return the correct developer directory path", function()
		local xcode = Xcode.new("/Applications/Xcode.app", "16.4.1")
		local dev_dir = xcode:developer_dir()
		test:assert_equal(dev_dir, "/Applications/Xcode.app/Contents/Developer")
	end)
	
	test:it("should work with different base paths", function()
		local xcode = Xcode.new("/Users/test/Applications/Xcode_16.app", "16.0.0")
		local dev_dir = xcode:developer_dir()
		test:assert_equal(dev_dir, "/Users/test/Applications/Xcode_16.app/Contents/Developer")
	end)
end)

-- Run tests and exit with appropriate code
local success = test:summary()
os.exit(success and 0 or 1)
