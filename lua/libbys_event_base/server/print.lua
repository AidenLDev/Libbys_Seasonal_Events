function LibbyEvent.PrintToPlayer(Player, Message, ...)
	Message = Format(Message, ...)
	Message = string.EncapsulateOC(Message)

	LibbyEvent.SendLongLua(Player, [[MsgN(%s, "\n")]], Message)
end
