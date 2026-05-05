-- lib/utils.lua

local UTILS = {}
local Xcode = require("Xcode")
local Version = require("Version")

-- Constants
local XCODE_BUNDLE_ID = "com.apple.dt.Xcode"
local PLIST_INFO_PATH = "/Contents/Info.plist"

-- Built-in mise modules (available in plugin hooks context)
-- These are loaded lazily to allow unit tests to run without them
local function get_file_module()
	local ok, mod = pcall(require, "file")
	return ok and mod or nil
end

local function get_strings_module()
	local ok, mod = pcall(require, "strings")
	return ok and mod or nil
end

local function trim(s)
	local strings = get_strings_module()
	if strings then
		return strings.trim_space(s)
	end
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

--- Resolves a file path to an absolute path.
--- Absolute paths (those that begin with `/`) are returned unchanged.
--- Paths with a leading `~` are expanded to `$HOME`.
--- Relative paths are resolved against the provided `config_root`, or `$PWD` if no `config_root` is given.
--- Uses the built-in `file.join_path()` when available (in mise plugin context).
--- @param path string The path to resolve.
--- @param config_root string|nil The config root directory to resolve relative paths against.
--- @return string The resolved absolute path.
function UTILS.resolve_path(path, config_root)
	if not path or path == "" then
		error("File path cannot be nil or empty")
	end

	-- Absolute paths pass through unchanged
	if path:sub(1, 1) == "/" then
		return path
	end

	-- Expand leading ~ to $HOME
	if path:sub(1, 1) == "~" then
		local home = os.getenv("HOME")
		if not home or home == "" then
			error("Cannot expand '~': $HOME is not set")
		end
		local file_mod = get_file_module()
		if file_mod and path:sub(2) ~= "" then
			return file_mod.join_path(home, path:sub(3)) -- skip ~/
		end
		return home .. path:sub(2)
	end

	-- Relative path: resolve against config_root if provided, otherwise $PWD
	local base = config_root or os.getenv("PWD")
	if not base or base == "" then
		error("Cannot resolve relative path '" .. path .. "': no config_root provided and $PWD is not set")
	end
	local file_mod = get_file_module()
	if file_mod then
		return file_mod.join_path(base, path)
	end
	return base .. "/" .. path
end

--- Checks whether a file exists at the given path.
--- Uses the built-in `file.exists()` when available (in mise plugin context),
--- falls back to attempting to open the file.
--- @param path string The path to check.
--- @return boolean
function UTILS.file_exists(path)
	if not path or path == "" then
		return false
	end
	local file_mod = get_file_module()
	if file_mod then
		return file_mod.exists(path)
	end
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

--- Reads the contents of a file.
--- Uses the built-in `file.read()` when available (in mise plugin context),
--- falls back to io.open.
--- @param path string The path to the file to read.
--- @param trimmed boolean|nil Whether to trim whitespace from the content.
--- @return string The file contents.
function UTILS.read_file(path, trimmed)
	if not path or path == "" then
		error("File path cannot be nil or empty")
	end

	local contents
	local file_mod = get_file_module()
	if file_mod then
		if not file_mod.exists(path) then
			error("Could not open file '" .. path .. "': No such file or directory")
		end
		contents = file_mod.read(path)
	else
		local f, err = io.open(path, "r")
		if not f then
			error("Could not open file '" .. path .. "': " .. tostring(err or "unknown error"))
		end
		contents = f:read("*a")
		f:close()
	end

	if trimmed then
		contents = trim(contents)
	end

	return contents
end

return UTILS
