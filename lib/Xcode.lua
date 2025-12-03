-- lib/Xcode.lua

local Version = require("Version")

local Xcode = {}
Xcode.__index = Xcode

--- Creates a new Xcode object
-- @param version string The version number of Xcode
-- @param path string The file system path to the Xcode app bundle
-- @reurn table A new Xcode object
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

function Xcode:developer_dir()
	return self.path .. "/Contents/Developer"
end

return Xcode
