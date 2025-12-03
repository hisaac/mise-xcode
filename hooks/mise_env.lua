-- hooks/mise_env.lua

local utils = require("utils")

function PLUGIN:MiseEnv(ctx)
	local env_vars = {}

	local additional_search_paths = ctx.options.additional_search_paths
	local xcode_version = ctx.options.version
	local xcode_version_file = ctx.options.version_file
	local debug_mode = ctx.options.debug or false

	utils.check_os()

	if not xcode_version then
		if xcode_version_file then
			xcode_version = utils.read_file(xcode_version_file, true)
		else
			error("Either an Xcode version or a file containing the Xcode version must be specified")
		end
	end

	local installed_xcodes = utils.get_installed_xcodes(additional_search_paths)

	if debug_mode then
		if #installed_xcodes == 0 then
			print("No Xcode installations found.")
		else
			print("\nFound " .. #installed_xcodes .. "")
			print("-----------------------------------------------------")
			for _, app in ipairs(installed_xcodes) do
				print(app)
			end
		end
	end

	local best_version = utils.select_best_version(installed_xcodes, xcode_version)

	if best_version then
		local developer_dir = best_version:developer_dir()
		if developer_dir then
			table.insert(env_vars, {
				key = "DEVELOPER_DIR",
				value = developer_dir,
			})
		end
	end

	return env_vars
end
