net.Receive("SendLongLua", function()
	local Size = net.ReadUInt(16)
	local Data = net.ReadData(Size)

	local Lua = util.Decompress(Data)

	if not Lua or string.len(Lua) < 1 then
		ErrorNoHalt("Received invalid LongLua\n")
		return
	end

	RunString(Lua, "LongLua")
end)
