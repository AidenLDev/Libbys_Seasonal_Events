util.AddNetworkString("SendLongLua")

-- SendLua but with 65535 character limit
function LibbyEvent.SendLongLua(Player, Lua, ...)
	Lua = Format(Lua, ...)

	local Data = util.Compress(Lua)
	local Size = string.len(Data)

	net.Start("SendLongLua")
	do
		net.WriteUInt(Size, 16)
		net.WriteData(Data, Size)
	end
	net.Send(Player)
end
