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

	return LibbyEvent.util.RunTrace(true)
end

function Collectables.FindCollectableSpawn(CollectableMins, CollectableMaxs)
	local WorldMins, WorldMaxs = LibbyEvent.util.GetWorldBounds()

	local SpawnCeiling, ChosenSpawn = LibbyEvent.util.GetSpawnCeiling()
	local ChosenSpawnPos = ChosenSpawn:GetPos()
	local MinX, MinY, MaxX, MaxY = LibbyEvent.util.FindWorldEdges(Vector(ChosenSpawnPos.x, ChosenSpawnPos.y, SpawnCeiling))

	local SpawnX = math.Rand(MinX, MaxX)
	local SpawnY = math.Rand(MinY, MaxY)

	local CeilingPos = Vector(SpawnX, SpawnY, SpawnCeiling)
	local TraceResult = Collectables.TraceToFloor(WorldMins, CollectableMins, CollectableMaxs, CeilingPos)

	if not TraceResult.Hit then return end
	if bit.band(TraceResult.Contents, CONTENTS_WATER) == CONTENTS_WATER then return end
	if TraceResult.HitNonWorld or TraceResult.HitNoDraw then return end

	local SpawnPos = Vector(TraceResult.HitPos)
	SpawnPos:Add(TraceResult.HitNormal)

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
	local SpawnPos = LibbyEvent.util.TryXTimes(Collectables.FindCollectableSpawn, Attempts, CollectableMins, CollectableMaxs)

	if not SpawnPos then
		Collectable:Remove()
		return NULL
	end

	Collectable:SetPos(SpawnPos)
	Collectable:SetNoDraw(false)

	return Collectable
end
