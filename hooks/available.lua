-- hooks/available.lua

-- Returns a list of available versions for the tool
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#available-hook
-- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
	local http = require("http")
	local json = require("json")

	local xcodereleases_api_url = "https://xcodereleases.com/data.json"

	local response, error = http.get({
		url = xcodereleases_api_url
	})

	if error ~= nil then
		error("Failed to fetch versions: " .. error)
	end

	local data = json.decode(response.body)
	local result = {}

	for _, item in ipairs(data) do
		if item.version.release and item.version.release.release == true then
			local version = item.version.number
			local build = item.version.build

			local note = nil

			local swift = nil
			if item.compilers and item.compilers.swift then
				swift = item.compilers.swift.number
			end

			table.insert(result, {
				version = version,
				note = note,
				addition = {
					{
						name = "build",
						version = build
					},
					{
						name = "swift",
						version = swift
					}
				}
			})
		end
	end

	return result
end
