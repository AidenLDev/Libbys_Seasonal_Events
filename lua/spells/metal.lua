return {
    Cast = function(ply)
        ply:SetNWBool("SpellInProgress", true)

        local originalWalkSpeed = ply:GetWalkSpeed()
        local originalRunSpeed = ply:GetRunSpeed()
        local originalJumpPower = ply:GetJumpPower()
        local originalGravity = ply:GetGravity()

        ply:EmitSound("libbys/halloween/zap.wav", 60, 100)
        ply:EmitSound("libbys/halloween/metaltheme.wav", 100, 100)

        ply:SetMaterial("debug/env_cubemap_model")
        ply:GetViewModel():SetMaterial("debug/env_cubemap_model")

        ply:SetWalkSpeed(100)
        ply:SetRunSpeed(140)
        ply:SetJumpPower(0)
        ply:SetGravity(2.2)
        ply:SetNWBool("IsMetal", true)

        hook.Add("PlayerFootstep", "MetalFootstep_" .. ply:SteamID(), function(player, pos, foot, sound, volume, rf)
            if player == ply and player:GetNWBool("IsMetal") then
                local pitch = math.random(90, 110)
                player:EmitSound("libbys/halloween/clang_short.wav", 85, pitch)
                util.ScreenShake(player:GetPos(), 5, 3, 0.5, 500)
                return true
            end
        end)

        hook.Add("EntityTakeDamage", "MetalDamageIgnore_" .. ply:SteamID(), function(target, dmginfo)
            if target == ply and target:GetNWBool("IsMetal") then
                dmginfo:SetDamage(0)
                return true
            end
        end)

        hook.Add("OnPlayerHitGround", "MetalCrush_" .. ply:SteamID(), function(player, inWater, onFloater, speed)
            if player == ply and ply:GetNWBool("IsMetal") and speed > 200 then
                local crushRadius = 200
                local entities = ents.FindInSphere(ply:GetPos(), crushRadius)
                for _, ent in ipairs(entities) do
                    if ent:IsPlayer() and ent ~= ply then
                        ent:Kill()
                    elseif ent:IsNPC() then
                        ent:TakeDamage(2500, ply, ply)
                    elseif ent:GetClass() == "prop_physics" then
                        ent:Fire("Break")
                    end
                end
            end
        end)

        local timerUniqueID = "Metal_" .. ply:SteamID()
        timer.Create(timerUniqueID, 37, 1, function()
            if IsValid(ply) then
                ply:SetMaterial("")
                ply:GetViewModel():SetMaterial("")
                ply:SetWalkSpeed(originalWalkSpeed)
                ply:SetRunSpeed(originalRunSpeed)
                ply:SetJumpPower(originalJumpPower)
                ply:SetGravity(originalGravity)
                ply:SetNWBool("IsMetal", false)

                ply:StopSound("libbys/halloween/metaltheme.wav")
                ply:EmitSound("libbys/halloween/power_down.ogg", 45, 100)

                hook.Remove("PlayerFootstep", "MetalFootstep_" .. ply:SteamID())
                hook.Remove("EntityTakeDamage", "MetalDamageIgnore_" .. ply:SteamID())
                hook.Remove("OnPlayerHitGround", "MetalCrush_" .. ply:SteamID())

                ply:SetNWBool("SpellInProgress", false)
                ply:SetNWBool("SpellOverlay", false)
            end
        end)

        hook.Add("PlayerDeath", "MetalDeathCleanup_" .. ply:SteamID(), function(victim)
            if victim == ply then
                timer.Remove(timerUniqueID)
                ply:SetMaterial("")
                ply:GetViewModel():SetMaterial("")
                ply:SetWalkSpeed(originalWalkSpeed)
                ply:SetRunSpeed(originalRunSpeed)
                ply:SetJumpPower(originalJumpPower)
                ply:SetGravity(originalGravity)
                ply:SetNWBool("IsMetal", false)
                ply:StopSound("libbys/halloween/metaltheme.wav")
                hook.Remove("PlayerFootstep", "MetalFootstep_" .. ply:SteamID())
                hook.Remove("EntityTakeDamage", "MetalDamageIgnore_" .. ply:SteamID())
                hook.Remove("OnPlayerHitGround", "MetalCrush_" .. ply:SteamID())
                hook.Remove("PlayerDeath", "MetalDeathCleanup_" .. ply:SteamID())
            end
        end)

        return nil
    end,

    GetDisplayName = function()
        return "Metal"
    end
}


