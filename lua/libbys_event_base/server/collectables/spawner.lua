timer.Create("LibbyEvent_CollectableSpawner", 10, 0, function()
	local Collectable = LibbyEvent.Collectables.CreateAtRandom()
	if not IsValid(Collectable) then return end

	Entity(1):SetPos(Collectable:GetPos() + Vector(0, 0, 50))
end)
