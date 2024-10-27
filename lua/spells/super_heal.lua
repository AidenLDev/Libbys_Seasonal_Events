local healthPerSecond = 100
local spellDuration = 4.4
local interval = 0.05

return {
    Cast = function(ply)
        if not IsValid(ply) then return nil end

        ply:SetNWBool("SpellInProgress", true)
        ply:SetNWBool("Undying", true)
        ply:EmitSound("libbys/halloween/spell_overheal.ogg", 60, 100)

        local totalHealthIncrements = spellDuration / interval
        local healAmount = healthPerSecond * interval

        local function PreventDeath(ply, dmginfo)
            if ply:GetNWBool("Undying") and ply:Health() - dmginfo:GetDamage() <= 1 then
                dmginfo:SetDamage(ply:Health() - 1)
            end
        end
        hook.Add("EntityTakeDamage", "SuperHealthPreventDeath" .. ply:EntIndex(), PreventDeath)

        for i = 1, totalHealthIncrements do
            timer.Simple(i * interval, function()
                if IsValid(ply) then
                    ply:SetHealth(ply:Health() + healAmount)
                end
            end)
        end

        timer.Simple(spellDuration, function()
            if IsValid(ply) then
                ply:SetNWBool("SpellInProgress", false)
                ply:SetNWBool("Undying", false)
                ply:SetNWBool("SpellOverlay", false)
                hook.Remove("EntityTakeDamage", "SuperHealthPreventDeath" .. ply:EntIndex())
            end
        end)

        ply:CallOnRemove("SuperHealthCleanUp", function()
            ply:SetNWBool("SpellInProgress", false)
            ply:SetNWBool("Undying", false)
            ply:SetNWBool("SpellOverlay", false)
            hook.Remove("EntityTakeDamage", "SuperHealthPreventDeath" .. ply:EntIndex())
        end)

        return nil
    end,

    GetDisplayName = function()
        return "Super Health"
    end
}
