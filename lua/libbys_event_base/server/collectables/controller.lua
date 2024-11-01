LibbyEvent.Collectables = LibbyEvent.Collectables or {}
local Collectables = LibbyEvent.Collectables

AccessorFunc(Collectables, "m_strClassName", "ClassName", FORCE_STRING)
Collectables:SetClassName("libbys_event_collectable")

function Collectables.Create(Position, Model)
	local Collectable = ents.Create(Collectables:GetClassName())
	if not IsValid(Collectable) then return NULL end

	Collectable:SetPos(Position)
	Collectable:Spawn()
	Collectable:Activate()

	if isstring(Model) and util.IsValidModel(Model) then
		Collectable:SetModel(Model)
	end

	return Collectable
end

function Collectables.TraceToFloor(WorldMins, CollectableMins, CollectableMaxs, StartPos)
	local TraceData = LibbyEvent.util.GetTraceData()
	LibbyEvent.util.CleanTraceData()

	TraceData.start = StartPos
	TraceData.endpos = Vector(StartPos.x, StartPos.y, WorldMins.z)
	TraceData.mins = CollectableMins
	TraceData.maxs = CollectableMaxs
	TraceData.mask = MASK_ALL

	return LibbyEvent.util.RunTrace() -- Don't hull because TraceHull is broken serverside (Goes thru displacements)
end

function Collectables.GetSpawnParameters(CollectableMins, CollectableMaxs)
	local SpawnCeiling, ChosenSpawn = LibbyEvent.util.GetSpawnCeiling()
	local ChosenSpawnPos = ChosenSpawn:GetPos()

	local MinX, MinY, MaxX, MaxY = LibbyEvent.util.FindWorldEdges(Vector(ChosenSpawnPos.x, ChosenSpawnPos.y, SpawnCeiling), CollectableMins, CollectableMaxs)

	return SpawnCeiling, MinX, MinY, MaxX, MaxY
end

function Collectables.FindCollectableSpawn(CollectableMins, CollectableMaxs, SpawnCeiling, MinX, MinY, MaxX, MaxY)
	local WorldMins, WorldMaxs = LibbyEvent.util.GetWorldBounds()

	local SpawnX = math.Rand(MinX, MaxX)
	local SpawnY = math.Rand(MinY, MaxY)

	local CeilingPos = Vector(SpawnX, SpawnY, SpawnCeiling)
	local TraceResult = Collectables.TraceToFloor(WorldMins, CollectableMins, CollectableMaxs, CeilingPos)

	if not TraceResult.Hit then return end
	if bit.band(TraceResult.Contents, CONTENTS_WATER) == CONTENTS_WATER then return end
	if TraceResult.HitNonWorld then return end

	local SpawnPos = Vector(TraceResult.HitPos)
	SpawnPos:Add(TraceResult.HitNormal)

	-- Adjust for the lack of a hull trace
	local CollectableHeight = (math.abs(CollectableMins.z) + math.abs(CollectableMaxs.z)) * 0.5
	SpawnPos.z = SpawnPos.z + CollectableHeight

	if not util.IsInWorld(SpawnPos) then return end

	return SpawnPos
end

function Collectables.CreateAtRandom(Model, Attempts)
	Attempts = tonumber(Attempts) or 10

	local Collectable = ents.Create(Collectables:GetClassName())
	if not IsValid(Collectable) then return NULL end

	Collectable:SetNoDraw(true)
	Collectable:Spawn()
	Collectable:Activate()

	if isstring(Model) and util.IsValidModel(Model) then
		Collectable:SetModel(Model)
	end

	local CollectableMins, CollectableMaxs = Collectable:GetCollisionBounds()
	local SpawnCeiling, MinX, MinY, MaxX, MaxY = Collectables.GetSpawnParameters(CollectableMins, CollectableMaxs)

	local SpawnPos = LibbyEvent.util.TryXTimes(Collectables.FindCollectableSpawn, Attempts, CollectableMins, CollectableMaxs, SpawnCeiling, MinX, MinY, MaxX, MaxY)

	if not SpawnPos then
		Collectable:Remove()
		return NULL
	end

	Collectable:SetPos(SpawnPos)
	Collectable:SetNoDraw(false)

	return Collectable
end
