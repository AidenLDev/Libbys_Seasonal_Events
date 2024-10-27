return {
    Cast = function(ply)
        ply:SetNWBool("SpellInProgress", true)
        ply:SetNWBool("SpellOverlay", true)

        local critSound = "libbys/halloween/critpower_loop.wav"
        ply:EmitSound(critSound, 60, 100)

        local function createLightningEffect()
            if IsValid(ply) then
                local weapon = ply:GetActiveWeapon()
                local playerPos = ply:GetPos()
                
                local randomPosAroundPlayer = playerPos + Vector(math.random(-20, 20), math.random(-20, 20), 0)
                local randomPosOnGround = playerPos + Vector(math.random(-50, 50), math.random(-50, 50), -10)
                
                if IsValid(weapon) then
                    local teslaZapEffect = EffectData()
                    teslaZapEffect:SetEntity(weapon)
                    teslaZapEffect:SetStart(weapon:GetPos())
                    teslaZapEffect:SetOrigin(playerPos)
                    teslaZapEffect:SetMagnitude(1)
                    teslaZapEffect:SetScale(1)
                    teslaZapEffect:SetRadius(1)
                    util.Effect("TeslaZap", teslaZapEffect)
                    
                    local teslaHitboxesEffect = EffectData()
                    teslaHitboxesEffect:SetEntity(ply)
                    teslaHitboxesEffect:SetOrigin(playerPos)
                    teslaHitboxesEffect:SetMagnitude(1)
                    teslaHitboxesEffect:SetScale(1)
                    teslaHitboxesEffect:SetRadius(1)
                    util.Effect("TeslaHitboxes", teslaHitboxesEffect)
                    
                    local groundTeslaEffect = EffectData()
                    groundTeslaEffect:SetEntity(ply)
                    groundTeslaEffect:SetStart(playerPos)
                    groundTeslaEffect:SetOrigin(randomPosOnGround)
                    util.Effect("TeslaZap", groundTeslaEffect)
                end
            end
        end
        
        
        timer.Create("CritsSpell_LightningEffect", 0.08, 350, createLightningEffect)

        hook.Add("EntityTakeDamage", "CritsSpell_DamageAmplifier", function(target, dmginfo)
            local attacker = dmginfo:GetAttacker()
            if attacker == ply and ply:GetNWBool("SpellInProgress") then
                dmginfo:ScaleDamage(9)

                -- Apply a strong pushing force
                if IsValid(target) and not target:IsWorld() then
                    local direction = (target:GetPos() - ply:GetPos()):GetNormalized()
                    local force = direction * 900000

                    local phys = target:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:ApplyForceCenter(force)
                    else
                        if target:IsPlayer() or target:IsNPC() then
                            target:SetVelocity(force)
                        end
                    end
                end
            end
        end)

        local function cleanupSpell()
            if IsValid(ply) then
                ply:EmitSound("libbys/halloween/power_down.ogg", 45, 100)

                ply:SetNWBool("SpellInProgress", false)
                ply:SetNWBool("SpellOverlay", false)

                ply:StopSound(critSound)

                hook.Remove("EntityTakeDamage", "CritsSpell_DamageAmplifier")
                timer.Remove("CritsSpell_LightningEffect")
            end
        end

        timer.Simple(23, function()
            if IsValid(ply) then
                cleanupSpell()
            end
        end)

        hook.Add("PlayerDeath", "CritsSpell_PlayerDeathCleanup", function(victim)
            if victim == ply then
                cleanupSpell()
                hook.Remove("PlayerDeath", "CritsSpell_PlayerDeathCleanup")
            end
        end)

        return nil
    end,

    GetDisplayName = function()
        return "Crits"
    end
}