-- metadata.lua
-- Plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#metadata-lua

PLUGIN = { -- luacheck: ignore
	name = "xcode",
	version = "1.0.0",
	description = "A mise tool plugin for xcode",
	author = "Isaac Halvorson",
	updateUrl = "https://github.com/hisaac/mise-xcode",
	legacyFilenames = {
		".xcode-version",
		".config/.xcode-version",
	},
}
