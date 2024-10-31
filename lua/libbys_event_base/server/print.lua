function LibbyEvent.PrintToPlayer(Player, Message, ...)
	Message = Format(Message, ...)

	local Valid, HasOpener, HasCloser = string.IsOCEncapsulated(Message)

	if not Valid then
		if HasOpener or HasCloser then
			-- Bad pair
			error("Got invalid string encapsulation in 'PrintToPlayer'", 2)
			return
		else
			-- Has no opener or closer, add some
			Message = Format("[=[%s]=]", Message)
		end
	end

	LibbyEvent.SendLongLua(Player, [[MsgC(%s, "\n")]], Message)
end
