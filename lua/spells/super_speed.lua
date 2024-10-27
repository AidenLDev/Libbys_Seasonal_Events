return {
    Cast = function(ply)
        ply:SetNWBool("SpellInProgress", true)

        ply:EmitSound("libbys/halloween/spell_superspeed.ogg", 60, 100)

        local originalWalkSpeed = ply:GetWalkSpeed()
        local originalRunSpeed = ply:GetRunSpeed()
        local speedMultiplier = 7
        local resistanceMultiplier = 0.8

        ply:SetWalkSpeed(originalWalkSpeed * speedMultiplier)
        ply:SetRunSpeed(originalRunSpeed * speedMultiplier)

        ply:SetNWFloat("OriginalWalkSpeed", originalWalkSpeed)
        ply:SetNWFloat("OriginalRunSpeed", originalRunSpeed)
        ply:SetNWFloat("DamageResistance", resistanceMultiplier)

        local uniqueID = "SuperSpeed_" .. ply:SteamID()

        timer.Create(uniqueID, 17, 1, function()
            if IsValid(ply) then
                ply:SetWalkSpeed(ply:GetNWFloat("OriginalWalkSpeed"))
                ply:SetRunSpeed(ply:GetNWFloat("OriginalRunSpeed"))
                ply:SetNWFloat("DamageResistance", 1)

                ply:EmitSound("libbys/halloween/power_down.ogg", 45, 100)

                hook.Remove("Think", uniqueID)
                hook.Remove("EntityTakeDamage", uniqueID .. "_Damage")
                ply:SetNWBool("SpellInProgress", false)
                ply:SetNWBool("SpellOverlay", false)
            end
        end)

        hook.Add("EntityTakeDamage", uniqueID .. "_Damage", function(target, dmginfo)
            if target == ply and ply:GetNWFloat("DamageResistance", 1) < 1 then
                dmginfo:ScaleDamage(ply:GetNWFloat("DamageResistance"))
            end
        end)

        hook.Add("PlayerDisconnected", uniqueID .. "_Disconnect", function(disconnectedPly)
            if disconnectedPly == ply then
                hook.Remove("Think", uniqueID)
                hook.Remove("EntityTakeDamage", uniqueID .. "_Damage")
                timer.Remove(uniqueID)
            end
        end)

        hook.Add("PlayerDeath", uniqueID .. "_Death", function(deadPly)
            if deadPly == ply then
                hook.Remove("Think", uniqueID)
                hook.Remove("EntityTakeDamage", uniqueID .. "_Damage")
                timer.Remove(uniqueID)
            end
        end)

        return nil
    end,

    GetDisplayName = function()
        return "Super Speed"
    end
}
