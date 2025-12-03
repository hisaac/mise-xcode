-- tests/test_framework.lua
-- A simple test framework that doesn't require external dependencies

local TestFramework = {}
TestFramework.__index = TestFramework

function TestFramework.new()
	local self = setmetatable({}, TestFramework)
	self.tests = {}
	self.current_suite = nil
	self.passed = 0
	self.failed = 0
	self.errors = {}
	return self
end

function TestFramework:describe(name, func)
	self.current_suite = name
	print("\n" .. name)
	func()
	self.current_suite = nil
end

function TestFramework:it(description, func)
	local full_name = (self.current_suite or "") .. " > " .. description
	local success, err = pcall(func)

	if success then
		self.passed = self.passed + 1
		print("  ✓ " .. description)
	else
		self.failed = self.failed + 1
		print("  ✗ " .. description)
		table.insert(self.errors, { name = full_name, error = err })
	end
end

function TestFramework:assert_equal(actual, expected, message)
	if actual ~= expected then
		local msg = message or string.format("Expected %s but got %s", tostring(expected), tostring(actual))
		error(msg, 2)
	end
end

function TestFramework:assert_true(value, message)
	if not value then
		local msg = message or "Expected true but got false"
		error(msg, 2)
	end
end

function TestFramework:assert_false(value, message)
	if value then
		local msg = message or "Expected false but got true"
		error(msg, 2)
	end
end

function TestFramework:assert_nil(value, message)
	if value ~= nil then
		local msg = message or string.format("Expected nil but got %s", tostring(value))
		error(msg, 2)
	end
end

function TestFramework:assert_not_nil(value, message)
	if value == nil then
		local msg = message or "Expected non-nil value but got nil"
		error(msg, 2)
	end
end

function TestFramework:assert_error(func, message)
	local success = pcall(func)
	if success then
		local msg = message or "Expected function to throw an error but it didn't"
		error(msg, 2)
	end
end

function TestFramework:summary()
	print("\n" .. string.rep("=", 50))
	print(string.format("Tests: %d passed, %d failed, %d total", self.passed, self.failed, self.passed + self.failed))

	if #self.errors > 0 then
		print("\nFailures:")
		for _, err_info in ipairs(self.errors) do
			print("\n" .. err_info.name)
			print("  " .. err_info.error)
		end
	end

	print(string.rep("=", 50))

	return self.failed == 0
end

return TestFramework
