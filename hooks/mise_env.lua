-- hooks/mise_env.lua

local utils = require("utils")

function PLUGIN:MiseEnv(ctx)
	local env_vars = {}

	local additional_search_paths = ctx.options.additional_search_paths
	local xcode_version = ctx.options.version
	local xcode_version_file = ctx.options.version_file
	local debug_mode = ctx.options.debug or false

	-- Ensure we're running on macOS
	utils.check_os()

	-- Determine the Xcode version to use
	if not xcode_version then
		if xcode_version_file then
			xcode_version = utils.read_file(xcode_version_file, true)
		else
			error("Either 'version' or 'version_file' must be specified in mise configuration")
		end
	end

	-- Find all installed Xcode versions
	local installed_xcodes = utils.get_installed_xcodes(additional_search_paths)

	if debug_mode then
		if #installed_xcodes == 0 then
			print("No Xcode installations found.")
		else
			print("\nFound " .. #installed_xcodes .. " Xcode installations:")
			print("-----------------------------------------------------")
			for _, app in ipairs(installed_xcodes) do
				print(app)
			end
		end
	end

	-- Select the best matching version
	local best_version = utils.select_best_version(installed_xcodes, xcode_version)

	if not best_version then
		error(string.format("No Xcode installation matching version '%s' was found", xcode_version))
	end

	table.insert(env_vars, {
		key = "DEVELOPER_DIR",
		value = best_version:developer_dir(),
	})

	return env_vars
end
