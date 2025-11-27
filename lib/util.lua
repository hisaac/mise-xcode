-- lib/util.lua

local UTIL = {}

UTIL.xcodereleases_api_url = "https://xcodereleases.com/data.json"

function UTIL.get_platform_info()
	local is_windows = package.config:sub(1, 1) == "\\"
	local cmd = require("cmd")
	local strings = require("strings")

	if is_windows then
		return {
			os = "windows",
			arch = os.getenv("PROCESSOR_ARCHITECTURE") or "x64",
		}
	else
		local uname = cmd.exec("uname -s"):lower()
		local arch = cmd.exec("uname -m")

		return {
			os = strings.trim_space(uname),
			arch = strings.trim_space(arch),
		}
	end
end

function UTIL.get_arch()
	return UTIL.get_platform_info().arch
end

function UTIL.get_os()
	return UTIL.get_platform_info().os
end

function UTIL.check_os()
	if UTIL.get_os() ~= "darwin" then
		error("Xcode is only available for macOS")
	end
end

function UTIL.safe_api_call(url)
	local http = require("http")
	local json = require("json")
	local resp, err = http.get({ url = url })

	if err ~= nil then
		error("HTTP request failed: " .. err)
	end

	if resp.status_code ~= 200 then
		error("API returned error: " .. resp.status_code .. " " .. resp.body)
	end

	local success, data = pcall(json.decode, resp.body)
	if not success then
		error("Failed to parse JSON response: " .. data)
	end

	return data
end

return UTIL
