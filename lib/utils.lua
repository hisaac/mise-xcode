-- lib/utils.lua

local UTILS = {}
local Xcode = require("Xcode")
local Version = require("Version")

local function trim(s)
	-- ^%s* matches leading whitespace
	-- (.-) matches the content (lazy match)
	-- %s*$ matches trailing whitespace
	-- %1 returns the captured content
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function get_os()
	-- 1. check for Windows via directory separator
	if package.config:sub(1, 1) == "\\" then
		return "windows"
	end

	-- 2. if Unix-like, check specifically for macOS (Darwin) vs Linux
	local handle = io.popen("uname -s")
	if not handle then
		return nil
	end

	local result = handle:read("*a")
	handle:close()

	-- trim whitespace and lowercase
	return trim(result:lower())
end

local function read_plist_key(key, plist_path)
	local command = string.format('/usr/libexec/PlistBuddy -c "Print :%s" "%s" 2>/dev/null', key, plist_path)
	local handle = io.popen(command)
	if not handle then
		return nil
	end
	local result = handle:read("*a")
	handle:close()
	return trim(result)
end

local function find_xcode_versions_in(dir)
	local results = {}

	-- Glob pattern: Match anything starting with Xcode and ending in .app
	local command = string.format('ls -1d "%s"/Xcode*.app 2>/dev/null', dir)
	local handle = io.popen(command)
	if not handle then
		return results
	end

	for path in handle:lines() do
		local plist_path = path .. "/Contents/Info.plist"
		local bundle_id = read_plist_key("CFBundleIdentifier", plist_path)
		if bundle_id == "com.apple.dt.Xcode" then
			local version_number = read_plist_key("CFBundleShortVersionString", plist_path)
			table.insert(results, Xcode.new(path, version_number))
		end
	end
	handle:close()

	return results
end

--- Finds and returns a table of installed Xcode versions.
--- @param additional_search_paths table|string|nil A table of paths to search for Xcode versions, or a single path as a string.
--- @return table A table of installed Xcode versions.
function UTILS.get_installed_xcodes(additional_search_paths)
	local xcode_search_paths = { "/Applications" }
	local user_home_dir = os.getenv("HOME")
	if user_home_dir then
		table.insert(xcode_search_paths, user_home_dir .. "/Applications")
	end
	if additional_search_paths then
		if type(additional_search_paths) == "string" then
			table.insert(xcode_search_paths, additional_search_paths)
		elseif type(additional_search_paths) == "table" then
			for _, path in ipairs(additional_search_paths) do
				table.insert(xcode_search_paths, path)
			end
		end
	end

	local xcodes = {}
	for _, path in ipairs(xcode_search_paths) do
		local found_xcode_versions = find_xcode_versions_in(path)
		for _, xcode_version in ipairs(found_xcode_versions) do
			table.insert(xcodes, xcode_version)
		end
	end
	return xcodes
end

function UTILS.select_best_version(available_xcodes, desired_version)
	local query = Version.new(desired_version)
	local matches = {}

	-- 1. Find all Xcodes that loosely match the query
	for _, xcode in ipairs(available_xcodes) do
		if xcode.version:matches_fuzzy(query) then
			table.insert(matches, xcode)
		end
	end

	if #matches == 0 then
		return nil
	end

	-- 2. Sort by version
	table.sort(matches)

	-- 3. Return the last one (the highest version)
	return matches[#matches]
end

function UTILS.dump_table(table)
	if type(table) == "table" then
		for key, value in pairs(table) do
			print("[" .. key .. "] = " .. tostring(value) .. ",")
		end
	end
end

function UTILS.check_os()
	if get_os() ~= "darwin" then
		error("Xcode is only available for macOS")
	end
end

function UTILS.read_file(path, trimmed)
	local file, err = io.open(path, "r")
	if not file then
		error("Could not open file: " .. err)
	end

	local contents = file:read("*a")
	file:close()

	if trimmed then
		contents = trim(contents)
	end

	return contents
end

return UTILS
