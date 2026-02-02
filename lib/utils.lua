-- lib/utils.lua

local UTILS = {}
local Xcode = require("Xcode")
local Version = require("Version")

-- Constants
local XCODE_BUNDLE_ID = "com.apple.dt.Xcode"
local PLIST_INFO_PATH = "/Contents/Info.plist"

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function read_plist_key(key, plist_path)
	if not key or key == "" then
		return nil
	end
	if not plist_path or plist_path == "" then
		return nil
	end

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

	if not dir or dir == "" then
		return results
	end

	-- Glob pattern: Match anything starting with Xcode and ending in .app
	local command = string.format('ls -1d "%s"/Xcode*.app 2>/dev/null', dir)
	local handle = io.popen(command)
	if not handle then
		return results
	end

	for path in handle:lines() do
		local plist_path = path .. PLIST_INFO_PATH
		local bundle_id = read_plist_key("CFBundleIdentifier", plist_path)
		if bundle_id == XCODE_BUNDLE_ID then
			local version_number = read_plist_key("CFBundleShortVersionString", plist_path)
			if version_number and version_number ~= "" then
				table.insert(results, Xcode.new(path, version_number))
			end
		end
	end
	handle:close()

	return results
end

function UTILS.os_name()
	-- 1. check for Windows via directory separator
	if package.config:sub(1, 1) == "\\" then
		return "windows"
	end

	-- 2. if Unix-like, check specifically for macOS (Darwin) vs Linux
	local handle = io.popen("uname -s")
	if not handle then
		return nil
	end
	local result = handle:read("*l")
	handle:close()
	return result:lower()
end

function UTILS.is_macos()
	return UTILS.os_name() == "darwin"
end

--- Finds and returns a table of installed Xcode versions.
--- @param additional_search_paths table|string|nil A table of paths to search for Xcode versions, or a single path as a string.
--- @return table A table of installed Xcode versions.
function UTILS.get_installed_xcodes(additional_search_paths)
	local xcode_search_paths = { "/Applications" }
	local user_home_dir = os.getenv("HOME")
	if user_home_dir and user_home_dir ~= "" then
		table.insert(xcode_search_paths, user_home_dir .. "/Applications")
	end
	if additional_search_paths then
		if type(additional_search_paths) == "string" then
			table.insert(xcode_search_paths, additional_search_paths)
		elseif type(additional_search_paths) == "table" then
			for _, path in ipairs(additional_search_paths) do
				if path and path ~= "" then
					table.insert(xcode_search_paths, path)
				end
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

--- Selects the best matching Xcode version from available installations.
--- @param available_xcodes table A table of Xcode objects to search through.
--- @param desired_version string The desired version string (can be partial like "16" or "16.4").
--- @return table|nil The best matching Xcode object, or nil if no match found.
function UTILS.select_best_version(available_xcodes, desired_version)
	if not available_xcodes or #available_xcodes == 0 then
		return nil
	end
	if not desired_version or desired_version == "" then
		return nil
	end

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

--- Reads the contents of a file.
--- @param path string The path to the file to read.
--- @param trimmed boolean|nil Whether to trim whitespace from the content.
--- @return string The file contents.
function UTILS.read_file(path, trimmed)
	if not path or path == "" then
		error("File path cannot be nil or empty")
	end

	local file, err = io.open(path, "r")
	if not file then
		error("Could not open file '" .. path .. "': " .. tostring(err or "unknown error"))
	end

	local contents = file:read("*a")
	file:close()

	if trimmed then
		contents = trim(contents)
	end

	return contents
end

return UTILS
