-- lib/Version.lua

local Version = {}
Version.__index = Version

function Version.new(version_string)
	local self = setmetatable({}, Version)

	self.raw = version_string
	self.parts = {}

	for number in version_string:gmatch("%d+") do
		table.insert(self.parts, tonumber(number))
	end

	-- Store the "precision" (how many segments the user actually typed)
	-- We need this for the fuzzy matching logic later.
	self.precision = #self.parts

	-- Pad with zeros up to 3 places (Major.Minor.Patch)
	-- 16.4 becomes {16, 4, 0}
	for i = 1, 3 do
		if not self.parts[i] then
			self.parts[i] = 0
		end
	end

	return self
end

-- metamethods

function Version:__lt(other)
	for i = 1, 3 do
		if self.parts[i] ~= other.parts[i] then
			return self.parts[i] < other.parts[i]
		end
	end
	return false -- they are equal
end

function Version:__eq(other)
	return self.parts[1] == other.parts[1] and self.parts[2] == other.parts[2] and self.parts[3] == other.parts[3]
end

function Version:__tostring()
	return table.concat(self.parts, ".")
end

-- fuzzy match: Checks if 'self' matches 'other' based on the precision of 'other'
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
