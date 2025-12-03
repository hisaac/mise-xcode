-- lib/Version.lua

local Version = {}
Version.__index = Version

-- Constants
local MAX_VERSION_PARTS = 3 -- Major.Minor.Patch

--- Creates a new Version object from a version string.
--- @param version_string string The version string to parse (e.g., "16.4", "15.0.1").
--- @return table A new Version object.
function Version.new(version_string)
	local self = setmetatable({}, Version)

	self.raw = version_string
	self.parts = {}

	-- Extract numeric parts from version string
	for number in version_string:gmatch("%d+") do
		table.insert(self.parts, tonumber(number))
	end

	-- Store the "precision" (how many segments the user actually typed)
	-- We need this for the fuzzy matching logic later.
	self.precision = #self.parts

	-- Pad with zeros up to 3 places (Major.Minor.Patch)
	-- 16.4 becomes {16, 4, 0}
	for i = 1, MAX_VERSION_PARTS do
		if not self.parts[i] then
			self.parts[i] = 0
		end
	end

	return self
end

-- Metamethods for version comparison

--- Compares if this version is less than another version.
--- @param other table The other Version object to compare with.
--- @return boolean True if this version is less than the other.
function Version:__lt(other)
	for i = 1, MAX_VERSION_PARTS do
		if self.parts[i] ~= other.parts[i] then
			return self.parts[i] < other.parts[i]
		end
	end
	return false -- they are equal
end

--- Checks if this version is equal to another version.
--- @param other table The other Version object to compare with.
--- @return boolean True if versions are equal.
function Version:__eq(other)
	return self.parts[1] == other.parts[1] and self.parts[2] == other.parts[2] and self.parts[3] == other.parts[3]
end

--- Converts the version to a string representation.
--- @return string The version as a string (e.g., "16.4.0").
function Version:__tostring()
	return table.concat(self.parts, ".")
end

--- Checks if this version matches a query version based on the query's precision.
--- For example, if query is "16" (precision 1), only the major version is compared.
--- If query is "16.4" (precision 2), major and minor versions are compared.
--- @param query_version table The query Version object with a specific precision.
--- @return boolean True if this version matches the query.
function Version:matches_fuzzy(query_version)
	-- if `query_version` is "16" (precision 1) we only compare Major
	-- if `query_version` is "16.4" (precision 2) we compare Major and Minor
	for i = 1, query_version.precision do
		if self.parts[i] ~= query_version.parts[i] then
			return false
		end
	end
	return true
end

return Version
