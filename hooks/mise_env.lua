-- hooks/mise_env.lua

local log = require("log")
local file = require("file")
local strings = require("strings")
local utils = require("utils")

log.debug("mise is using " .. _VERSION)

function PLUGIN:MiseEnv(ctx)
	local additional_search_paths = ctx.options.additional_search_paths
	local xcode_version = ctx.options.version
	local xcode_version_file = ctx.options.version_file
	local config_root = ctx.config_root

	log.debug("additional_search_paths: " .. tostring(additional_search_paths))
	log.debug("xcode_version: " .. tostring(xcode_version))
	log.debug("xcode_version_file: " .. tostring(xcode_version_file))
	log.debug("config_root: " .. tostring(config_root))

	-- Non-macOS systems should no-op successfully
	if not utils.is_macos() then
		local os_name = utils.os_name() or "unknown"
		log.warn("Skipping: Xcode is only available on macOS (current OS: " .. os_name .. ")")
		return {}
	end

	-- If xcode_version is not specified, try reading from version_file
	local resolved_version_file
	if not xcode_version then
		if xcode_version_file then
			resolved_version_file = utils.resolve_path(xcode_version_file, config_root)
			log.debug("xcode_version_file (resolved): " .. resolved_version_file)
			if not file.exists(resolved_version_file) then
				log.warn("version_file not found: " .. resolved_version_file)
				return {}
			end
			xcode_version = strings.trim_space(file.read(resolved_version_file))
		else
			log.warn("Either 'version' or 'version_file' must be specified in mise configuration")
			return {}
		end
	end

	-- Find all installed Xcode versions
	local installed_xcodes = utils.get_installed_xcodes(additional_search_paths)
	log.debug("Found " .. #installed_xcodes .. " Xcode installations:")
	log.debug("-----------------------------------------------------")
	for _, app in ipairs(installed_xcodes) do
		log.debug(app)
	end

	-- Select the best matching version
	local best_version = utils.select_best_version(installed_xcodes, xcode_version)
	if not best_version then
		log.warn("No Xcode installation matching version " .. tostring(xcode_version) .. " was found")
		return {}
	end

	-- Return with caching support: cache result and watch the version_file for changes
	local env = {
		{
			key = "DEVELOPER_DIR",
			value = best_version:developer_dir(),
		},
	}

	if resolved_version_file then
		return {
			cacheable = true,
			watch_files = { resolved_version_file },
			env = env,
		}
	end

	return env
end
