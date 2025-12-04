-- lib/Xcode.lua

local Version = require("Version")

local Xcode = {}
Xcode.__index = Xcode

--- Constants
local DEVELOPER_PATH = "/Contents/Developer"

--- Creates a new Xcode object
--- @param path string The file system path to the Xcode app bundle
--- @param version_string string The version number of Xcode
--- @return table A new Xcode object
function Xcode.new(path, version_string)
	local self = setmetatable({}, Xcode)
	self.path = path
	self.version = Version.new(version_string)
	return self
end

--- Metamethods for Xcode object comparison and display

--- Compares if this Xcode installation has a lower version than another.
--- @param other table The other Xcode object to compare with.
--- @return boolean True if this Xcode version is less than the other.
function Xcode:__lt(other)
	return self.version < other.version
end

--- Converts the Xcode object to a human-readable string.
--- @return string A formatted string with version and path.
function Xcode:__tostring()
	return string.format("Xcode %s (%s)", tostring(self.version), self.path)
end

--- Returns the developer directory path for this Xcode installation.
--- @return string The full path to the Developer directory.
function Xcode:developer_dir()
	return self.path .. DEVELOPER_PATH
end

return Xcode
