local Collectables = LibbyEvent.Collectables
Collectables.Spawner = Collectables.Spawner or {}

local Spawner = Collectables.Spawner

Spawner._MetaTable = {}
do
	local SPAWNER = Spawner._MetaTable
	SPAWNER.__index = SPAWNER

	AccessorFunc(SPAWNER, "m_strTimerIdentifier", "TimerIdentifier", FORCE_STRING)

	AccessorFunc(SPAWNER, "m_flSpawnDelay", "SpawnDelay", FORCE_NUMBER)
	AccessorFunc(SPAWNER, "m_flSpawnCount", "SpawnCount", FORCE_NUMBER)
	AccessorFunc(SPAWNER, "m_strClassName", "ClassName", FORCE_STRING)
	AccessorFunc(SPAWNER, "m_strModelName", "ModelName", FORCE_STRING)
	AccessorFunc(SPAWNER, "m_iSpawnAttempts", "SpawnAttempts", FORCE_NUMBER)

	function SPAWNER:GenerateTimerIdentifier()
		local Prefix = "LibbyEvent_CollectableSpawner_"
		local TimeBase = LibbyEvent.util.DecimalDigits(SysTime())

		self:SetTimerIdentifier(Format("%s%u", Prefix, TimeBase))

		return self:GetTimerIdentifier()
	end

	function SPAWNER:Start()
		self:Stop()

		local TimerIdentifier = self:GenerateTimerIdentifier()
		timer.CreateWithArguments(TimerIdentifier, self:GetSpawnDelay(), self:GetSpawnCount(), self.Spawn, self)

		return TimerIdentifier
	end

	function SPAWNER:Stop()
		timer.Remove(self:GetTimerIdentifier())
	end

	function SPAWNER:Spawn()
		LibbyEvent.Collectables:SetClassName(self:GetClassName())
		local SpawnedCollectable = LibbyEvent.Collectables.CreateAtRandom(self:GetModelName(), self:GetSpawnAttempts())

		if IsValid(SpawnedCollectable) then
			if isfunction(self.m_fnOnCollected) then -- Yay useful
				SpawnedCollectable.OnCollected = self.m_fnOnCollected
			end

			hook.Run("LibbysEvent_CollectableSpawned", SpawnedCollectable, self)
		end

		return SpawnedCollectable
	end

	function SPAWNER:OnCollected(Callback)
		if isfunction(Callback) then
			self.m_fnOnCollected = Callback
		else
			self.m_fnOnCollected = nil
		end
	end
end

function Spawner.Create()
	local NewSpawner = setmetatable({}, Spawner._MetaTable)

	NewSpawner:GenerateTimerIdentifier()
	NewSpawner:SetSpawnDelay(5)
	NewSpawner:SetSpawnCount(0) -- Infinite

	NewSpawner:SetClassName("libbys_event_collectable")
	NewSpawner:SetModelName(nil)
	NewSpawner:SetSpawnAttempts(10)

	return NewSpawner
end
