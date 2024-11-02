local function BuildMsg(...)
	local ParameterCount = select("#", ...)
	local Parameters = { ... }

	for i = 1, ParameterCount do
		local Converted, ConstructorStr = LibbyEvent.util.ObjectToConstructorStr(Parameters[i])

		if not ConstructorStr then -- If we don't get a constructor it was tostring'd
			Converted = string.EncapsulateOC(Parameters[i])
		end

		Parameters[i] = Converted
	end

	return table.concat(Parameters, ", ")
end

function LibbyEvent.PrintToPlayerConsole(Player, ...)
	LibbyEvent.SendLongLua(Player, [[MsgC(%s, "\n")]], BuildMsg(...))
end

function LibbyEvent.PrintToPlayerChat(Player, ...)
	LibbyEvent.SendLongLua(Player, [[chat.AddText(%s)]], BuildMsg(...))
end
