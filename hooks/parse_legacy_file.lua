-- hooks/parse_legacy_file.lua
function PLUGIN:ParseLegacyFile(ctx)
	local file = require("file")
	local strings = require("strings")

	local content = file.read(ctx.filepath)
	return {
		version = strings.trim(content),
	}
end
