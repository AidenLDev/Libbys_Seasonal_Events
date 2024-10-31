util.AddNetworkString("SendLongLua")

local function PrepareLua(Lua, ...)
	Lua = Format(Lua, ...)

	local Data = util.Compress(Lua)
	local Size = string.len(Data)

	return Data, Size
end

-- SendLua but with 65535 character limit
function LibbyEvent.SendLongLua(Player, Lua, ...)
	local Data, Size = PrepareLua(Lua, ...)

	net.Start("SendLongLua")
	do
		net.WriteUInt(Size, 16)
		net.WriteData(Data, Size)
	end
	net.Send(Player)
end

function LibbyEvent.BroadcastLongLua(Lua, ...)
	local Data, Size = PrepareLua(Lua, ...)

	net.Start("SendLongLua")
	do
		net.WriteUInt(Size, 16)
		net.WriteData(Data, Size)
	end
	net.Broadcast()
end
