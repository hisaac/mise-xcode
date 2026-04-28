-- scripts/debug_env.lua
-- Runs the plugin via mise and prints the environment variables it sees.
--
-- Usage: lua scripts/debug_env.lua
--
-- This is a diagnostic script for debugging path resolution issues.
-- It links the local plugin, invokes `mise env --env debug-env --json`,
-- and prints both the env vars returned by the hook and the full
-- environment that mise passed to the process.

local json = require("dkjson")

local function run(cmd)
	local stdout_path = os.tmpname()
	local stderr_path = os.tmpname()
	local ok, _, code = os.execute(string.format("%s > %s 2> %s", cmd, stdout_path, stderr_path))
	local function read(path)
		local f = assert(io.open(path, "r"))
		local s = f:read("*a")
		f:close()
		os.remove(path)
		return s
	end
	return (ok == true or ok == 0), code or 0, read(stdout_path), read(stderr_path)
end

local function heading(s)
	print("\n" .. string.rep("=", 60))
	print("  " .. s)
	print(string.rep("=", 60))
end

-- 1. Link the local plugin so mise uses this working copy
print("Linking plugin...")
local ok, _, _, stderr = run("mise plugin link --force xcode .")
if not ok then
	io.stderr:write("mise plugin link failed: " .. stderr .. "\n")
	os.exit(1)
end
print("Plugin linked.")

-- 2. Run `mise env` with the debug-env config and capture JSON output
print("Running: mise env --env debug-env --json ...")
local ok2, _, stdout, stderr2 = run("MISE_DEBUG=1 mise env --env debug-env --json")
if not ok2 then
	heading("mise env FAILED")
	print(stderr2 ~= "" and stderr2 or stdout)
	print("\nDebug log (/tmp/mise-debug.log):")
	local f = io.open("/tmp/mise-debug.log", "r")
	if f then
		print(f:read("*a"))
		f:close()
	end
	os.exit(1)
end

-- 3. Decode and pretty-print the env vars the plugin returned
heading("Environment variables returned by plugin")
local env_data, _, err = json.decode(stdout)
if err then
	print("Failed to decode JSON: " .. tostring(err))
	print("Raw output:\n" .. stdout)
	os.exit(1)
end

local keys = {}
for k in pairs(env_data) do
	table.insert(keys, k)
end
table.sort(keys)

for _, k in ipairs(keys) do
	print(string.format("  %-30s = %s", k, tostring(env_data[k])))
end

-- 4. Print the mise debug log (captured from stderr)
heading("mise debug output")
if stderr2 and stderr2 ~= "" then
	print(stderr2)
else
	print("  (no debug output)")
end

print("")
