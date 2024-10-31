if LibbyEvent then
	for _ = 1, 5 do
		ErrorNoHalt("EITHER ANOTHER EVENT IS ALREADY INSTALLED OR THE EVENT HAS BEEN RELOADED! PROCEED WITH CAUTION!\n")
	end
end

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
