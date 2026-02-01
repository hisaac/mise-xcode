-- tests/test_integration.lua
-- Integration tests for the mise-xcode plugin

package.path = package.path .. ";./lib/?.lua"

local lu = require("luaunit")
local json = require("dkjson")

-- Helper Functions

local function read_file(path)
	local file = assert(io.open(path, "r"))
	local contents = file:read("*a")
	file:close()
	return contents
end

local function run_command_capture(cmd)
	local stdout_path = os.tmpname()
	local stderr_path = os.tmpname()
	local full_cmd = string.format("%s > %s 2> %s", cmd, stdout_path, stderr_path)
	local ok, _, code = os.execute(full_cmd)
	local stdout = read_file(stdout_path)
	local stderr = read_file(stderr_path)
	os.remove(stdout_path)
	os.remove(stderr_path)
	local success = (ok == true or ok == 0)
	return success, code or 0, stdout, stderr
end

local function os_name()
	if package.config:sub(1, 1) == "\\" then
		return "windows"
	else
		local handle = assert(io.popen("uname -s"))
		local result = handle:read("*l"):lower()
		handle:close()
		return result
	end
end

local function set_up()
	local ok, _, stdout, stderr = run_command_capture("mise plugin link --force xcode .")
	lu.assertTrue(ok, "mise plugin link failed: " .. tostring(stderr ~= "" and stderr or stdout))
end

local function get_env()
	local ok, _, stdout, stderr = run_command_capture("mise env --env integration-tests --json")
	lu.assertTrue(ok, "mise env failed: " .. tostring(stderr ~= "" and stderr or stdout))

	local env_data, _, err = json.decode(stdout)
	lu.assertNil(err, "Failed to decode JSON output from 'mise env': " .. tostring(err))
	lu.assertNotNil(env_data, "No data returned from 'mise env'")
	return env_data
end

-- Test Suite

TestIntegration = {}

function TestIntegration:testMacOS()
	lu.skipIf(os_name() ~= "darwin", "Skipping macOS-specific test on non-macOS platform")
	set_up()
	local env_data = get_env()
	lu.assertNotNil(env_data.DEVELOPER_DIR, "DEVELOPER_DIR should be set on macOS")
	lu.assertTrue(#env_data.DEVELOPER_DIR > 0, "DEVELOPER_DIR should not be empty on macOS")
end

function TestIntegration:testNonMacOS()
	lu.skipIf(os_name() == "darwin", "Skipping non-macOS-specific test on macOS platform")
	set_up()
	local env_data = get_env()
	lu.assertNil(env_data.DEVELOPER_DIR, "DEVELOPER_DIR should not be set on non-macOS platforms")
end
