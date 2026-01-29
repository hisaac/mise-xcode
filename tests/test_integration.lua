-- tests/test_integration.lua
-- Integration tests for the mise-xcode plugin

package.path = package.path .. ";./lib/?.lua"

local lu = require("luaunit")

local function read_file(path)
	local file = assert(io.open(path, "r"))
	local contents = file:read("*a")
	file:close()
	return contents
end

local function run_command_capture(cmd)
	local temp_path = os.tmpname()
	local full_cmd = string.format("%s > %s 2>&1", cmd, temp_path)
	local ok, _, code = os.execute(full_cmd)
	local output = read_file(temp_path)
	os.remove(temp_path)
	local success = (ok == true or ok == 0)
	return success, code or 0, output
end

local function get_os_name()
	local handle = io.popen("uname -s")
	if not handle then
		return ""
	end
	local result = handle:read("*a")
	handle:close()
	return (result or ""):lower():gsub("%s+", "")
end

local json = require("dkjson")

local function parse_json(payload)
	local obj, _, err = json.decode(payload, 1, nil)
	if err then
		return nil, err
	end
	return obj, nil
end

local os_name = get_os_name()

local link_ok, _, link_output = run_command_capture("mise plugin link --force xcode .")
local env_ok, _, env_output = run_command_capture("mise env --env integration-tests --json")

TestIntegration = {}

function TestIntegration:testSetsDeveloperDirOnMacOS()
	if os_name ~= "darwin" then
		print(string.format("↷ Skipping macOS-only assertion (current OS: %s)", os_name))
		return
	end

	lu.assertTrue(link_ok, "Failed to link plugin: " .. tostring(link_output))
	lu.assertTrue(env_ok, "mise env failed: " .. tostring(env_output))

	local obj, err = parse_json(env_output)
	lu.assertNotNil(obj, "Failed to parse JSON: " .. tostring(err))
	lu.assertNotNil(obj.DEVELOPER_DIR, "DEVELOPER_DIR not found in JSON output")
	lu.assertTrue(#obj.DEVELOPER_DIR > 0, "DEVELOPER_DIR was empty")
end

function TestIntegration:testErrorsOnNonMacOS()
	if os_name == "darwin" then
		print(string.format("↷ Skipping non-macOS assertion (current OS: %s)", os_name))
		return
	end

	lu.assertTrue(link_ok, "Failed to link plugin: " .. tostring(link_output))
	lu.assertFalse(env_ok, "mise env unexpectedly succeeded on non-macOS")
	lu.assertTrue(env_output:find("Xcode is only available for macOS") ~= nil, "Expected macOS-only error in output")
end

os.exit(lu.LuaUnit.run())
