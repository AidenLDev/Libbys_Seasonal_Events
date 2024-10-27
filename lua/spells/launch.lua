local function CleanupSpell(ply, uniqueID, smokeTrail)
    if IsValid(ply) then
        ply:SetMoveType(MOVETYPE_WALK)
        ply:SetGravity(1)
        ply.CanNoclip = oldCanNoclip
        ply:SetNWBool("SpellInProgress", false)
        ply:SetNWBool("SpellOverlay", false)
        ply:StopSound("weapons/rpg/rocket1.wav")
    end

    if IsValid(smokeTrail) then
        smokeTrail:Remove()
    end

    hook.Remove("Think", uniqueID)
    hook.Remove("PlayerDeath", uniqueID .. "_Death")
    timer.Remove(uniqueID .. "_Timer")
end

return {
    Cast = function(ply)
        if not IsValid(ply) then return nil end

        ply:SetNWBool("SpellInProgress", true)
        ply:SetNWBool("SpellOverlay", true)

        ply:EmitSound("libbys/halloween/spell_mirv_cast.wav", 60, 100)
        ply:EmitSound("weapons/rpg/rocket1.wav", 100, 100)

        local flightSpeed = 5000
        local maxVelocity = 4500
        local velocityDecayRate = 0.99
        local disintegrationActive = true
        local explosionEnabled = false
        local uniqueID = "Launch_" .. ply:SteamID()

        local oldCanNoclip = ply.CanNoclip or function() return true end
        ply.CanNoclip = function() return false end

        ply.SpellBackup = ply.SpellBackup or {}
        ply.SpellBackup.Gravity = ply:GetGravity()

        ply:SetGravity(0.1)

        local playerRankColor = team.GetColor(ply:Team())
        local smokeTrail = util.SpriteTrail(ply, 0, playerRankColor, true, 30, 30, 0.25, 0.5, "trails/smoke.vmt")

        local tickCount = 0

        timer.Create(uniqueID .. "_Timer", 0.1, 30, function()
            tickCount = tickCount + 1

            if not IsValid(ply) then
                CleanupSpell(ply, uniqueID, smokeTrail)
                return
            end

            if tickCount >= 9 then
                explosionEnabled = true
            end

            if tickCount == 30 then
                disintegrationActive = false
                ply:SetMoveType(MOVETYPE_WALK)
                ply.CanNoclip = oldCanNoclip
                ply:SetGravity(ply.SpellBackup.Gravity or 1)

                CleanupSpell(ply, uniqueID, smokeTrail)
            end
        end)

        hook.Add("Think", uniqueID, function()
            if not IsValid(ply) then
                CleanupSpell(ply, uniqueID, smokeTrail)
                return
            end
            local aimVector = ply:GetAimVector()
            local currentVelocity = ply:GetVelocity()
            local desiredVelocity = aimVector * flightSpeed
            if currentVelocity:Length() > maxVelocity then
                desiredVelocity = currentVelocity:GetNormalized() * maxVelocity
            end
            ply:SetLocalVelocity(desiredVelocity)

            flightSpeed = flightSpeed * velocityDecayRate

            local trace = util.TraceHull({
                start = ply:GetPos(),
                endpos = ply:GetPos() + desiredVelocity * FrameTime(),
                filter = ply,
                mins = ply:OBBMins(),
                maxs = ply:OBBMaxs(),
            })

            if trace.Hit and explosionEnabled then
                if trace.HitWorld or (not disintegrationActive and IsValid(trace.Entity)) then
                    util.BlastDamage(ply, ply, ply:GetPos(), 800, 3500)
                    local effect = EffectData()
                    effect:SetOrigin(ply:GetPos())
                    util.Effect("Explosion", effect)
                    ply:Kill()
                elseif IsValid(trace.Entity) then
                    if disintegrationActive and (trace.Entity:IsPlayer() or trace.Entity:IsNPC()) then
                        if trace.Entity:Health() > 620 then
                            util.BlastDamage(ply, ply, ply:GetPos(), 300, 500)
                            local effect = EffectData()
                            effect:SetOrigin(ply:GetPos())
                            util.Effect("Explosion", effect)
                            ply:Kill()
                        else
                            trace.Entity:TakeDamage(trace.Entity:Health(), ply, ply)
                        end
                    elseif not disintegrationActive then
                        util.BlastDamage(ply, ply, ply:GetPos(), 300, 500)
                        local effect = EffectData()
                        effect:SetOrigin(ply:GetPos())
                        util.Effect("Explosion", effect)
                        ply:Kill()
                    end
                end
            end
        end)

        hook.Add("PlayerDeath", uniqueID .. "_Death", function(deadPly)
            if deadPly == ply then
                ply:StopSound("weapons/rpg/rocket1.wav")
                CleanupSpell(ply, uniqueID, smokeTrail)
            end
        end)

        return nil
    end,

    GetDisplayName = function()
        return "Launch"
    end
}
