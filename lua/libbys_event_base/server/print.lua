function LibbyEvent.PrintToPlayer(Player, Message, ...)
	Message = Format(Message, ...)

	LibbyEvent.SendLongLua(Player, [[MsgC([=[%s]=], "\n")]], Message)
end
