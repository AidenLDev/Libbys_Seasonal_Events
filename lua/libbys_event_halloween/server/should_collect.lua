hook.Add("LibbyEvent_ShouldCollect", "Halloween_NoBuildMode", function(Collectable, Collector)
	if Collector.buildmode then
		return false
	end
end)
