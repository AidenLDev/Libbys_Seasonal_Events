function LibbyEvent.PrintToPlayer(Player, ...)
	local ParameterCount = select("#", ...)
	local Parameters = { ... }

	for i = 1, ParameterCount do
		local Converted, ConstructorStr = LibbyEvent.util.ObjectToConstructorStr(Parameters[i])

		if not ConstructorStr then -- If we don't get a constructor it was tostring'd
			Converted = string.EncapsulateOC(Parameters[i])
		end

		Parameters[i] = Converted
	end

	LibbyEvent.SendLongLua(Player, [[MsgC(%s, "\n")]], table.concat(Parameters, ", "))
end
