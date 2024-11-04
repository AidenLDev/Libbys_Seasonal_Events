local PumpkinSpawner = LibbyEvent.Collectables.Spawner.Create()
PumpkinSpawner:SetModelName("models/libbys_event/halloween/pumpkin_loot_alt.mdl")

PumpkinSpawner:OnCollected(function(Collectable, Collector)
	LibbyEvent.PrintToPlayerChat(Collector, Color(150, 150, 255, 255), "You collected a Pumpkin!")
end)

hook.Add("LibbysEvent_CollectableSpawned", "Halloween_Pumpkins", function(Collectable, CollectableSpawner)
	if CollectableSpawner ~= PumpkinSpawner then return end

	print("Created Pumpkin at ", Collectable:GetPos())
end)

PumpkinSpawner:Start()
