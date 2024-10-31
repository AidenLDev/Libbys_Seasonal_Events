timer.Create("LibbyEvent_CollectableSpawner", 1, 0, function()
	local Collectable = LibbyEvent.Collectables.Create(Entity(1):GetPos() + Vector(0, 0, 150))
	if not IsValid(Collectable) then return end

	Collectable:EmitSound("libbys/collectable_spawn.ogg")
end)
