-- lib/Xcode.lua

local Version = require("Version")

local Xcode = {}
Xcode.__index = Xcode

-- Constants
local DEVELOPER_PATH = "/Contents/Developer"

--- Creates a new Xcode object
-- @param path string The file system path to the Xcode app bundle
-- @param version_string string The version number of Xcode
-- @return table A new Xcode object
function Xcode.new(path, version_string)
	local self = setmetatable({}, Xcode)
	self.path = path
	self.version = Version.new(version_string)
	return self
end

-- metamethods

function Xcode:__lt(other)
	return self.version < other.version
end

function Xcode:__tostring()
	return string.format("Xcode %s (%s)", tostring(self.version), self.path)
end

--- Returns the developer directory path for this Xcode installation.
--- @return string The full path to the Developer directory.
function Xcode:developer_dir()
	return self.path .. DEVELOPER_PATH
end

return Xcode
