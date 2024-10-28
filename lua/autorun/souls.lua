if SERVER then
    util.AddNetworkString("PlaySoulEffect")
    util.AddNetworkString("AddSoulToPlayer")

    PrecacheParticleSystem("vortigaunt_hand_glow")

    local function AddSouls(ply, amount)
        if not IsValid(ply) or ply:IsBot() then return end

        ply:ModifyPlayerBalance("souls", amount)
        SavePlayerBalances(ply)
    end

    hook.Add("PlayerDeath", "RewardSoulsOnKill", function(victim, inflictor, attacker)
        if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim and IsValid(victim) and not victim:IsBot() then
            local victimCenterPos = victim:LocalToWorld(victim:OBBCenter())
    
            net.Start("PlaySoulEffect")
            net.WriteVector(victimCenterPos)
            net.WriteEntity(attacker)
            net.Broadcast()
    
            net.Start("AddSoulToPlayer")
            net.Send(attacker)
        end
    end)

    net.Receive("AddSoulToPlayer", function(len, ply)
        AddSouls(ply, 1)
    end)
end

if CLIENT then
    local lastSoulEffectTime = 0
    local soulEffectCooldown = 2

    local function AnimateParticleRise(particleSystem, startPos, endPos, duration, onComplete, uniqueID)
        local startTime = CurTime()
        local endTime = startTime + duration

        hook.Add("Think", "AnimateParticleRise_" .. uniqueID, function()
            if not IsValid(particleSystem) then
                hook.Remove("Think", "AnimateParticleRise_" .. uniqueID)
                return
            end

            local currentTime = CurTime()
            if currentTime > endTime then
                particleSystem:SetControlPoint(0, endPos)
                hook.Remove("Think", "AnimateParticleRise_" .. uniqueID)
                if onComplete then onComplete() end
            else
                local t = (currentTime - startTime) / duration
                local newPos = LerpVector(t, startPos, endPos)
                particleSystem:SetControlPoint(0, newPos)
            end
        end)
    end

    local function AnimateParticleToAttacker(particleSystem, startPos, attacker, duration, sound, soundEntity, uniqueID)
        local startTime = CurTime()
        local endTime = startTime + duration

        hook.Add("Think", "AnimateParticleToAttacker_" .. uniqueID, function()
            if not IsValid(particleSystem) or not IsValid(attacker) or not IsValid(soundEntity) then
                hook.Remove("Think", "AnimateParticleToAttacker_" .. uniqueID)
                return
            end

            if attacker:Health() <= 0 then
                particleSystem:StopEmission(false, false)
                soundEntity:StopSound(sound)

                timer.Simple(1.5, function()
                    if IsValid(particleSystem) then
                        particleSystem:StopEmissionAndDestroyImmediately()
                    end
                    if IsValid(soundEntity) then
                        soundEntity:Remove()
                    end
                end)

                hook.Remove("Think", "AnimateParticleToAttacker_" .. uniqueID)
                return
            end

            local attackerPos = attacker:GetPos() + attacker:OBBCenter()
            local currentTime = CurTime()
            if currentTime > endTime then
                particleSystem:SetControlPoint(0, attackerPos)
                particleSystem:StopEmission(false, false)
                
                soundEntity:StopSound(sound)

                local randomSound = "libbys/halloween/souls_receive" .. math.random(1, 3) .. ".ogg"
                attacker:EmitSound(randomSound, 65)

                if LocalPlayer() == attacker then
                    net.Start("AddSoulToPlayer")
                    net.SendToServer()
                end

                hook.Remove("Think", "AnimateParticleToAttacker_" .. uniqueID)
            else
                local t = (currentTime - startTime) / duration
                local newPos = LerpVector(t, startPos, attackerPos)
                particleSystem:SetControlPoint(0, newPos)

                soundEntity:SetPos(newPos)
            end
        end)
    end

    local function PlaySoulEffect(victimCenterPos, attacker)
        if not IsValid(attacker) then return end

        local currentTime = CurTime()
        if currentTime - lastSoulEffectTime < soulEffectCooldown then
            return
        end

        lastSoulEffectTime = currentTime

        local uniqueID = tostring(victimCenterPos) .. "_" .. tostring(attacker:EntIndex()) .. "_" .. tostring(CurTime())
        
        local particleSystem = CreateParticleSystem(game.GetWorld(), "vortigaunt_hand_glow", PATTACH_ABSORIGIN, 0, victimCenterPos)

        if particleSystem then
            local sound = "libbys/halloween/soul_hover.wav"

            local soundEntity = ClientsideModel("models/props_junk/PopCan01a.mdl")
            soundEntity:SetNoDraw(true)
            soundEntity:SetPos(victimCenterPos)

            soundEntity:EmitSound(sound, 65)

            local endPos = victimCenterPos + Vector(0, 0, 50)
            AnimateParticleRise(particleSystem, victimCenterPos, endPos, 1.5, function()
                AnimateParticleToAttacker(particleSystem, endPos, attacker, 0.8, sound, soundEntity, uniqueID)
            end, uniqueID)

            timer.Simple(3.0, function()
                if IsValid(soundEntity) then
                    soundEntity:Remove()
                end
            end)
        end
    end

// Awesome Sound //

    net.Receive("PlaySoulEffect", function()
        local victimCenterPos = net.ReadVector()
        local attacker = net.ReadEntity()

        PlaySoulEffect(victimCenterPos, attacker)
    end)

    MsgC(Color(57, 100, 245), "[HalloweenEvent] ", color_white, "souls system loaded\n")
end
