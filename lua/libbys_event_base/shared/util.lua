LibbyEvent.util = LibbyEvent.util or {}
local LibbyUtil = LibbyEvent.util

LibbyUtil.TraceOutput = {}
LibbyUtil.TraceData = { output = LibbyUtil.TraceOutput }

function LibbyUtil.CleanTraceData(TraceData)
	if not TraceData then
		TraceData = LibbyUtil.GetTraceData()
	end

	TraceData.start = nil
	TraceData.endpos = nil
	TraceData.mins = nil
	TraceData.maxs = nil
	TraceData.filter = nil
	TraceData.mask = nil
	TraceData.collisiongroup = nil
	TraceData.ignoreworld = nil
	TraceData.whitelist = nil
	TraceData.hitclientonly = nil
end

function LibbyUtil.GetTraceData()
	return LibbyUtil.TraceData
end

function LibbyUtil.RunTrace(IsHull)
	(IsHull and util.TraceHull or util.TraceLine)(LibbyUtil.TraceData)

	return LibbyUtil.TraceOutput
end

function LibbyUtil.GetWorldBounds()
	local World = game.GetWorld()

	return World:GetModelBounds()
end

function LibbyUtil.GetPlayerSpawns()
	if istable(LibbyUtil.PlayerSpawns) and IsTableOfEntitiesValid(LibbyUtil.PlayerSpawns) then
		return LibbyUtil.PlayerSpawns
	end

	-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/gamemode/player.lua
	-- Fucking hell

	local PlayerSpawns = ents.FindByClass("info_player_start")

	table.Add(PlayerSpawns, ents.FindByClass("info_player_deathmatch"))
	table.Add(PlayerSpawns, ents.FindByClass("info_player_combine"))
	table.Add(PlayerSpawns, ents.FindByClass("info_player_rebel"))

	-- CS Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_player_counterterrorist"))
	table.Add(PlayerSpawns, ents.FindByClass("info_player_terrorist"))

	-- DOD Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_player_axis"))
	table.Add(PlayerSpawns, ents.FindByClass("info_player_allies"))

	-- (Old) GMod Maps
	table.Add(PlayerSpawns, ents.FindByClass("gmod_player_start"))

	-- TF Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_player_teamspawn"))

	-- INS Maps
	table.Add(PlayerSpawns, ents.FindByClass("ins_spawnpoint"))

	-- AOC Maps
	table.Add(PlayerSpawns, ents.FindByClass("aoc_spawnpoint"))

	-- Dystopia Maps
	table.Add(PlayerSpawns, ents.FindByClass("dys_spawn_point"))

	-- PVKII Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_player_pirate"))
	table.Add(PlayerSpawns, ents.FindByClass("info_player_viking"))
	table.Add(PlayerSpawns, ents.FindByClass("info_player_knight"))

	-- DIPRIP Maps
	table.Add(PlayerSpawns, ents.FindByClass("diprip_start_team_blue"))
	table.Add(PlayerSpawns, ents.FindByClass("diprip_start_team_red"))

	-- OB Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_player_red"))
	table.Add(PlayerSpawns, ents.FindByClass("info_player_blue"))

	-- SYN Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_player_coop"))

	-- ZPS Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_player_human"))
	table.Add(PlayerSpawns, ents.FindByClass("info_player_zombie"))

	-- ZM Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_player_zombiemaster"))

	-- FOF Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_player_fof"))
	table.Add(PlayerSpawns, ents.FindByClass("info_player_desperado"))
	table.Add(PlayerSpawns, ents.FindByClass("info_player_vigilante"))

	-- L4D Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_survivor_rescue"))

	-- NEOTOKYO Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_player_attacker"))
	table.Add(PlayerSpawns, ents.FindByClass("info_player_defender"))

	-- Fortress Forever Maps
	table.Add(PlayerSpawns, ents.FindByClass("info_ff_teamspawn"))

	LibbyUtil.PlayerSpawns = PlayerSpawns

	return PlayerSpawns
end

function LibbyUtil.GetSpawnCeiling()
	local PlayerSpawns = LibbyUtil.GetPlayerSpawns()
	local ChosenSpawn = table.RandomValueI(PlayerSpawns)

	local WorldMins, WorldMaxs = LibbyUtil.GetWorldBounds()

	if not IsValid(ChosenSpawn) then
		ErrorNoHaltWithStack("Can't find valid spawn to test ceiling")
		return WorldMaxs.z
	end

	local SpawnPos = ChosenSpawn:GetPos()
	SpawnPos.z = SpawnPos.z + 72 -- What the fuck why is it underground

	local TraceData = LibbyUtil.GetTraceData()
	LibbyUtil.CleanTraceData()

	TraceData.start = SpawnPos
	TraceData.endpos = Vector(TraceData.start.x, TraceData.start.y, WorldMaxs.z)
	TraceData.mask = MASK_PLAYERSOLID_BRUSHONLY
	TraceData.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT

	local TraceResult = LibbyUtil.RunTrace()

	if not TraceResult.Hit then
		ErrorNoHaltWithStack("Can't find ceiling ???")
		return WorldMaxs.z
	end

	return TraceResult.HitPos.z + TraceResult.HitNormal.z, ChosenSpawn
end

function LibbyUtil.FindWorldEdge(CeilingPos, EndPos, Hull)
	local TraceData = LibbyUtil.GetTraceData()

	TraceData.start = CeilingPos
	TraceData.endpos = EndPos

	local TraceResult = LibbyUtil.RunTrace(Hull)

	if not TraceResult.Hit then
		return CeilingPos
	end

	return TraceResult.HitPos + TraceResult.HitNormal
end

function LibbyUtil.FindWorldEdges(CeilingPos, Mins, Maxs)
	local WorldMins, WorldMaxs = LibbyUtil.GetWorldBounds()

	local TraceData = LibbyUtil.GetTraceData()
	LibbyUtil.CleanTraceData()

	TraceData.mask = MASK_PLAYERSOLID_BRUSHONLY
	TraceData.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT

	local Hull = isvector(Mins) and isvector(Maxs)
	if Hull then
		TraceData.mins = Mins
		TraceData.maxs = Maxs
	end

	local MinsX = LibbyUtil.FindWorldEdge(CeilingPos, Vector(WorldMins.x, CeilingPos.y, CeilingPos.z), Hull)
	local MinsY = LibbyUtil.FindWorldEdge(CeilingPos, Vector(CeilingPos.x, WorldMins.y, CeilingPos.z), Hull)
	local MaxsX = LibbyUtil.FindWorldEdge(CeilingPos, Vector(WorldMaxs.x, CeilingPos.y, CeilingPos.z), Hull)
	local MaxsY = LibbyUtil.FindWorldEdge(CeilingPos, Vector(CeilingPos.x, WorldMaxs.y, CeilingPos.z), Hull)

	return MinsX.x, MinsY.y, MaxsX.x, MaxsY.y
end

function LibbyUtil.TryXTimes(Callback, Times, ...)
	local A, B, C, D, E, F

	for _ = 1, Times do
		A, B, C, D, E, F = Callback(...)

		if A ~= nil then
			return A, B, C, D, E, F
		end
	end

	return nil
end

function LibbyUtil.DecimalDigits(Number)
	local String = tostring(Number)
	String = string.Replace(String, ".", "")

	return tonumber(String) or -1
end
