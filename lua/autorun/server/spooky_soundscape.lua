util.AddNetworkString("StopAllMapSounds")
util.AddNetworkString("HalloweenSoundscapeReset")

hook.Add("Initialize", "StopMapSoundsOnServerStart", function()
    timer.Simple(1, function()
        net.Start("StopAllMapSounds")
        net.Broadcast()
    end)
end)

hook.Add("PlayerInitialSpawn", "StopMapSoundsForNewPlayer", function(ply)
    net.Start("StopAllMapSounds")
    net.Send(ply)
end)

concommand.Add("halloween_soundscape_reset", function(ply)
    if IsValid(ply) and ply:IsAdmin() then
        net.Start("HalloweenSoundscapeReset")
        net.Broadcast()
    end
end)
