local StringOpeners = { "\"", "[[", "[=[" }
local StringClosers = { "\"", "]]", "]=]" }

local OpenerPairs = {
	["\""] = "\"",
	["[["] = "]]",
	["[=["] = "]=]"
}

local CloserPairs = {
	["\""] = "\"",
	["]]"] = "[[",
	["]=]"] = "[=["
}

local function TestOpener(_, Opener, String)
	if string.StartsWith(String, Opener) then
		return true, Opener
	end
end

local function TestCloser(_, Closer, String)
	if string.EndsWith(String, Closer) then
		return true, Closer
	end
end

function string.HasOpener(String)
	return table.ForEach(StringOpeners, TestOpener, String)
end

function string.HasCloser(String)
	return table.ForEach(StringClosers, TestCloser, String)
end

function string.IsOCEncapsulated(String)
	local HasOpener, Opener = string.HasOpener(String)
	local HasCloser, Closer = string.HasCloser(String)

	if HasOpener and HasCloser then
		-- Make sure the opener/closer pair is valid
		return OpenerPairs[Opener] == Closer and CloserPairs[Closer] == Opener, HasOpener, HasCloser
	end

	return false, HasOpener, HasCloser
end
