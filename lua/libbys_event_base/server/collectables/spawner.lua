timer.Create("LibbyEvent_CollectableSpawner", 1, 0, function()
	local Collectable = LibbyEvent.Collectables.CreateAtRandom()
	if not IsValid(Collectable) then return end

	Collectable:EmitSound("libbys/collectable_spawn.ogg")
end)
