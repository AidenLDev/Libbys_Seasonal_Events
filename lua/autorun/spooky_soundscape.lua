if SERVER then
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
end

if CLIENT then
    local outdoorSoundscape = {
        looping = {
            { sound = "libbys/halloween/ambient/volcano_rumble.wav", volume = 10 },
            { sound = "libbys/halloween/ambient/hallowloop.wav", volume = 30 }
        },
        random = {
            { sound = "libbys/halloween/ambient/hallow02.ogg", volume = 30, chance = 30 },
            { sound = "libbys/halloween/ambient/hallow01.ogg", volume = 30, chance = 30 },
            { sound = "libbys/halloween/ambient/hallow03.ogg", volume = 30, chance = 30 },
            { sound = "libbys/halloween/ambient/shutter4.ogg", volume = 40, chance = 15 },
            { sound = "libbys/halloween/ambient/shutter5.ogg", volume = 40, chance = 15 },
            { sound = "libbys/halloween/ambient/shutter6.ogg", volume = 40, chance = 15 },
            { sound = "libbys/halloween/ambient/wolf02.ogg", volume = 25, chance = 20 },
            { sound = "libbys/halloween/ambient/wolf01.ogg", volume = 25, chance = 20 },
            { sound = "libbys/halloween/ambient/owl3.ogg", volume = 100, chance = 20 },
            { sound = "libbys/halloween/ambient/owl4.ogg", volume = 100, chance = 20 }
        }
    }

    local halloweenSoundscapeConVar = CreateClientConVar("halloween_soundscape", "1", true, false, "Toggle Halloween soundscape")
    local currentLoopingSounds = {}
    local randomSoundPlaying = false
    local randomSoundDelay = 5
    local blendAmount = 1
    local targetBlend = 1
    local blendTime = 7
    local transitionSpeed = 1 / blendTime
    local confinedVolumeFactor = 0.5
    local fullyIndoorVolumeFactor = 0.3

    local function PlayLoopingSound(soundData, soundKey)
        if not IsValid(LocalPlayer()) then return end
        if not currentLoopingSounds[soundKey] then
            local sound = CreateSound(LocalPlayer(), soundData.sound)
            sound:PlayEx(0, 100)
            sound:ChangeVolume(soundData.volume / 100, 2)
            sound:SetSoundLevel(0)
            currentLoopingSounds[soundKey] = sound
        end
    end

    local function StopLoopingSound(soundKey)
        if currentLoopingSounds[soundKey] then
            currentLoopingSounds[soundKey]:FadeOut(2)
            timer.Simple(2, function()
                if currentLoopingSounds[soundKey] then
                    currentLoopingSounds[soundKey]:Stop()
                    currentLoopingSounds[soundKey] = nil
                end
            end)
        end
    end

    local function StopAllLoopingSounds()
        for soundKey, sound in pairs(currentLoopingSounds) do
            if sound then
                sound:FadeOut(2)
                timer.Simple(2, function()
                    if currentLoopingSounds[soundKey] then
                        currentLoopingSounds[soundKey]:Stop()
                        currentLoopingSounds[soundKey] = nil
                    end
                end)
            end
        end
    end

    local function GetEnclosedRatio()
        local playerPos = LocalPlayer():GetPos()
        local traceDirections = {
            Vector(0, 0, 500),
            Vector(100, 0, 500),
            Vector(-100, 0, 500),
            Vector(0, 100, 500),
            Vector(0, -100, 500)
        }
        local enclosedHits = 0
        for _, dir in ipairs(traceDirections) do
            local traceData = util.TraceLine({
                start = playerPos,
                endpos = playerPos + dir,
                filter = LocalPlayer()
            })
            if traceData.HitWorld then
                enclosedHits = enclosedHits + 1
            end
        end
        return enclosedHits / #traceDirections
    end

    local function PlayRandomSound(soundData)
        if not randomSoundPlaying then
            randomSoundPlaying = true
            local pitch = math.random(80, 100)
            local sound = CreateSound(LocalPlayer(), soundData.sound)
            sound:PlayEx(soundData.volume / 100, pitch)
            sound:SetSoundLevel(0)
            timer.Simple(SoundDuration(soundData.sound), function()
                sound:Stop()
                randomSoundPlaying = false
            end)
        end
    end

    local function HandleRandomSounds(isFullyEnclosed)
        if isFullyEnclosed or randomSoundPlaying or halloweenSoundscapeConVar:GetInt() == 0 then return end
        for _, soundData in ipairs(outdoorSoundscape.random) do
            if math.random(1, 100) <= soundData.chance then
                PlayRandomSound(soundData)
                break
            end
        end
    end

    local function UpdateLoopingSounds()
        if halloweenSoundscapeConVar:GetInt() == 0 then
            StopAllLoopingSounds()
            return
        end
        for i, soundData in ipairs(outdoorSoundscape.looping) do
            local soundKey = "outdoor_" .. i
            PlayLoopingSound(soundData, soundKey)
            currentLoopingSounds[soundKey]:ChangeVolume(soundData.volume / 100 * blendAmount, 0)
        end
    end

    local function BlendSoundscapes()
        if halloweenSoundscapeConVar:GetInt() == 0 then return end
        blendAmount = math.Approach(blendAmount, targetBlend, transitionSpeed * FrameTime())
        UpdateLoopingSounds()
    end

    local function InitializeCustomSoundscape()
        StopAllLoopingSounds()
        for i, soundData in ipairs(outdoorSoundscape.looping) do
            PlayLoopingSound(soundData, "outdoor_" .. i)
        end

        if not timer.Exists("RandomSoundTimer") then
            timer.Create("RandomSoundTimer", randomSoundDelay, 0, function()
                HandleRandomSounds(GetEnclosedRatio() > 0.75)
            end)
        end
    end

    net.Receive("StopAllMapSounds", function()
        RunConsoleCommand("stopsound")
        timer.Simple(0.1, InitializeCustomSoundscape)
    end)

    net.Receive("HalloweenSoundscapeReset", function()
        StopAllLoopingSounds()
        timer.Simple(0.1, InitializeCustomSoundscape)
    end)

    timer.Create("SoundscapeIntegrityCheck", 5, 0, function()
        if halloweenSoundscapeConVar:GetInt() == 1 then
            for _, sound in pairs(currentLoopingSounds) do
                if sound and not sound:IsPlaying() then
                    InitializeCustomSoundscape()
                    break
                end
            end
        end
    end)

    hook.Add("Think", "CustomSoundscapeThink", function()
        if halloweenSoundscapeConVar:GetInt() == 0 then
            StopAllLoopingSounds()
            return
        end
        local enclosedRatio = GetEnclosedRatio()
        local isFullyEnclosed = enclosedRatio > 0.75
        if isFullyEnclosed then
            targetBlend = fullyIndoorVolumeFactor
        elseif enclosedRatio > 0.3 then
            targetBlend = confinedVolumeFactor
        else
            targetBlend = 1
        end
        BlendSoundscapes()
    end)

    hook.Add("ShutDown", "CleanupSoundscapes", function()
        StopAllLoopingSounds()
    end)

    MsgC(Color(57, 100, 245), "[HalloweenEvent] ", color_white, "soundscape loaded\n")
end
