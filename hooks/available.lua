-- hooks/available.lua

-- Returns a list of available versions for the tool
-- @return table A list of available versions for the tool
function PLUGIN:Available(ctx)
	local util = require("util")
	util.check_os()

	local data = util.safe_api_call(util.xcodereleases_api_url)
	local result = {}

	local current_arch = util.get_arch()

	local has_arm64_specific = {}

	if current_arch == "arm64" then
		for _, item in ipairs(data) do
			local archs = item.links and item.links.download and item.links.download.architectures
			if archs then
				local is_arm64 = false
				local is_x86_64 = false

				for _, a in ipairs(archs) do
					if a == "arm64" then
						is_arm64 = true
					end
					if a == "x86_64" then
						is_x86_64 = true
					end
				end

				-- If it contains arm64 but NOT x86_64, it is specific
				if is_arm64 and not is_x86_64 then
					local key = item.version.number .. "-" .. item.version.build
					has_arm64_specific[key] = true
				end
			end
		end
	end

	for _, item in ipairs(data) do
		repeat
			-- Skip non-release versions
			if not (item.version.release and item.version.release.release) then
				break
			end

			-- Skip versions without the current processor architecture available
			local archs = item.links and item.links.download and item.links.download.architectures
			if archs then
				local supports_current = false
				local is_universal = false
				local has_arm64 = false
				local has_x86_64 = false

				for _, a in ipairs(archs) do
					if a == current_arch then
						supports_current = true
					end
					if a == "arm64" then
						has_arm64 = true
					end
					if a == "x86_64" then
						has_x86_64 = true
					end
				end

				if has_arm64 and has_x86_64 then
					is_universal = true
				end

				-- Must support the machine's architecture
				if not supports_current then
					break
				end

				-- If on arm64, avoid universal if a specific build exists
				if current_arch == "arm64" and is_universal then
					local key = item.version.number .. "-" .. item.version.build
					if has_arm64_specific[key] then
						-- Skip this universal item because a specific one exists
						break
					end
				end
			end

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
						version = build,
					},
					{
						name = "swift",
						version = swift,
					},
				},
			})
		until true
	end

	return result
end
