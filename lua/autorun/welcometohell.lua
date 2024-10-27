if SERVER then
    util.AddNetworkString("PlayJoinCue")

    hook.Add("PlayerInitialSpawn", "PlayWelcomeCueOnJoin", function(ply)
        net.Start("PlayJoinCue")
        net.Send(ply)
    end)
end

if CLIENT then
    local joinCues = {
        "sound/libbys/halloween/cues/mcue1.ogg",
        "sound/libbys/halloween/cues/mcue2.ogg",
        "sound/libbys/halloween/cues/mcue3.ogg",
        "sound/libbys/halloween/cues/mcue4.ogg",
        "sound/libbys/halloween/cues/mcue5.ogg"
    }

    local cueChannel

    local function PlayWelcomeCue()
        local randomCue = joinCues[math.random(#joinCues)]
        sound.PlayFile(randomCue, "noplay", function(channel)
            if IsValid(channel) then
                cueChannel = channel
                cueChannel:SetVolume(0.35)
                cueChannel:Play()
            end
        end)
    end

    net.Receive("PlayJoinCue", function()
        timer.Create("WaitForFocusToPlayCue", 1, 0, function()
            if system.HasFocus() then
                PlayWelcomeCue()
                timer.Remove("WaitForFocusToPlayCue")
            end
        end)
    end)
end