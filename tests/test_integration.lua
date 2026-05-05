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

local _os_name
local function os_name()
	if not _os_name then
		if package.config:sub(1, 1) == "\\" then
			_os_name = "windows"
		else
			local handle = assert(io.popen("uname -s"))
			local result = handle:read("*l"):lower()
			handle:close()
			_os_name = result
		end
	end
	return _os_name
end

local _env
local function env_with_version()
	if not _env then
		local ok, _, stdout, stderr = run_command_capture("mise env --env integration-tests_version --json")
		lu.assertTrue(ok, "mise env failed: " .. tostring(stderr ~= "" and stderr or stdout))

		local env_data, _, err = json.decode(stdout)
		lu.assertNil(err, "Failed to decode JSON output from 'mise env': " .. tostring(err))
		lu.assertNotNil(env_data, "No data returned from 'mise env'")
		_env = env_data
	end
	return _env
end

local function env_with_version_file(workdir)
	local cmd = "mise env --env integration-tests_version_file --json"
	if workdir then
		-- Run mise from a subdirectory to verify version_file resolution
		-- uses config_root rather than cwd
		cmd = string.format("cd %q && %s", workdir, cmd)
	end
	local ok, _, stdout, stderr = run_command_capture(cmd)
	lu.assertTrue(ok, "mise env (version_file) failed: " .. tostring(stderr ~= "" and stderr or stdout))

	local env_data, _, err = json.decode(stdout)
	lu.assertNil(err, "Failed to decode JSON output from 'mise env': " .. tostring(err))
	lu.assertNotNil(env_data, "No data returned from 'mise env'")
	return env_data
end

-- Test Suite

local function set_up()
	local ok, _, stdout, stderr = run_command_capture("mise plugin link --force xcode .")
	lu.assertTrue(ok, "mise plugin link failed: " .. tostring(stderr ~= "" and stderr or stdout))
end

TestIntegration = {}

function TestIntegration:testMacOS()
	lu.skipIf(os_name() ~= "darwin", "Skipping: Current platform is " .. os_name())
	set_up()
	lu.assertNotNil(env_with_version().DEVELOPER_DIR, "DEVELOPER_DIR should be set on macOS")
	lu.assertTrue(#env_with_version().DEVELOPER_DIR > 0, "DEVELOPER_DIR should not be empty on macOS")
end

function TestIntegration:testNonMacOS()
	lu.skipIf(os_name() == "darwin", "Skipping: Current platform is " .. os_name())
	set_up()
	lu.assertNil(env_with_version().DEVELOPER_DIR, "DEVELOPER_DIR should not be set on non-macOS platforms")
end

function TestIntegration:testVersionFileFromProjectRoot()
	lu.skipIf(os_name() ~= "darwin", "Skipping: Current platform is " .. os_name())
	set_up()
	local result = env_with_version_file()
	lu.assertNotNil(result.DEVELOPER_DIR, "DEVELOPER_DIR should be set when using version_file from project root")
	lu.assertTrue(#result.DEVELOPER_DIR > 0, "DEVELOPER_DIR should not be empty")
end

function TestIntegration:testVersionFileFromSubdirectory()
	lu.skipIf(os_name() ~= "darwin", "Skipping: Current platform is " .. os_name())
	set_up()
	-- Run mise from a subdirectory to simulate the CI scenario where
	-- a Makefile cd's into a subpackage before invoking mise
	local result = env_with_version_file("tests/test-data")
	lu.assertNotNil(result.DEVELOPER_DIR, "DEVELOPER_DIR should be set when using version_file from a subdirectory")
	lu.assertTrue(#result.DEVELOPER_DIR > 0, "DEVELOPER_DIR should not be empty")
end
