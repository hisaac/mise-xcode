-- hooks/mise_env.lua

local log = require("log")
local utils = require("utils")

function PLUGIN:MiseEnv(ctx)
	local additional_search_paths = ctx.options.additional_search_paths
	local xcode_version = ctx.options.version
	local xcode_version_file = ctx.options.version_file

	log.debug("additional_search_paths:", tostring(additional_search_paths))
	log.debug("xcode_version:", tostring(xcode_version))
	log.debug("xcode_version_file:", tostring(xcode_version_file))

	-- Non-macOS systems should no-op successfully
	if not utils.is_macos() then
		local os_name = utils.os_name() or "unknown"
		log.warn("Skipping. Xcode is only available on macOS")
		log.debug("Current OS is: " .. os_name)
		return {}
	end

	-- If xcode_version is not specified, try reading from version_file
	if not xcode_version then
		if xcode_version_file then
			xcode_version = utils.read_file(xcode_version_file, true)
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
		log.warn("No Xcode installation matching version '" .. xcode_version .. "' was found")
		return {}
	end

	-- Set DEVELOPER_DIR environment variable
	return {
		{
			key = "DEVELOPER_DIR",
			value = best_version:developer_dir(),
		},
	}
end
