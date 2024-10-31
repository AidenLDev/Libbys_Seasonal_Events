LibbyEvent = LibbyEvent or {}

function LibbyEvent.IncludeShared(Path) -- includeCS
	if SERVER then
		AddCSLuaFile(Path)
	end

	include(Path)
end

function LibbyEvent.IncludeClient(Path)
	if SERVER then
		AddCSLuaFile(Path)
	elseif CLIENT then
		include(Path)
	end
end

function LibbyEvent.IncludeServer(Path)
	if SERVER then
		include(Path)
	end
end

-- Woohoo
LibbyEvent.IncludeShared("libbys_event_base/shared/init.lua")
