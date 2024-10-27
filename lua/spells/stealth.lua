local material = "sprites/heatwave"
local spellActive = false

local function SetMaterialRecursively(entity, material)
    if IsValid(entity) then
        entity:SetMaterial(material)

        for _, child in ipairs(entity:GetChildren()) do
            SetMaterialRecursively(child, material)
        end
    end
end

local function ApplyMaterialToViewModel(ply)
    local viewModel = ply:GetViewModel()
    if IsValid(viewModel) then
        SetMaterialRecursively(viewModel, material)
    end
end

local function ApplyMaterialToWeaponAndViewModel(ply)
    local activeWeapon = ply:GetActiveWeapon()
    if IsValid(activeWeapon) then
        activeWeapon:SetMaterial(material)
    end

    ApplyMaterialToViewModel(ply)
end

local function ResetMaterialForViewModelAndWeapon(ply)
    local activeWeapon = ply:GetActiveWeapon()
    if IsValid(activeWeapon) then
        activeWeapon:SetMaterial("")
    end

    local viewModel = ply:GetViewModel()
    if IsValid(viewModel) then
        SetMaterialRecursively(viewModel, "")
    end
end

hook.Add("PlayerSwitchWeapon", "SwitchWeaponApplyMaterial", function(ply, oldWeapon, newWeapon)
    if spellActive and IsValid(newWeapon) then
        timer.Simple(0.1, function()
            if IsValid(ply) then
                ApplyMaterialToWeaponAndViewModel(ply)
            end
        end)
    end
end)

local function CleanupSpell(ply, uniqueID)
    timer.Remove(uniqueID)
    spellActive = false
    ResetMaterialForViewModelAndWeapon(ply)
    ply:SetMaterial("")
    ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    ply:SetNWBool("IsInvulnerable", false)
    ply:SetNWBool("SpellInProgress", false)
    ply:SetNWBool("SpellOverlay", false)

    ply:StopSound("libbys/halloween/spell_stealth.ogg")
    ply:EmitSound("libbys/halloween/power_down.ogg", 45, 100)

    hook.Remove("EntityTakeDamage", uniqueID .. "_NoDamage")
end

return {
    Cast = function(ply)
        ply:SetNWBool("SpellInProgress", true)
        ply:SetNWBool("SpellOverlay", true)

        ply:SetMaterial(material)

        ply:EmitSound("libbys/halloween/spell_stealth.ogg", 60, 100)

        spellActive = true
        ApplyMaterialToWeaponAndViewModel(ply)

        ply:SetNWBool("IsInvulnerable", true)
        ply:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

        local uniqueID = "Stealth_" .. ply:SteamID()

        hook.Add("EntityTakeDamage", uniqueID .. "_NoDamage", function(target, dmginfo)
            if target == ply then
                dmginfo:SetDamage(0)
                return true
            end
        end)

        timer.Create(uniqueID, 28, 1, function()
            if IsValid(ply) then
                CleanupSpell(ply, uniqueID)
            end
        end)

        hook.Add("PlayerDeath", uniqueID .. "_Death", function(deadPly)
            if deadPly == ply then
                CleanupSpell(ply, uniqueID)
                hook.Remove("PlayerDeath", uniqueID .. "_Death")
            end
        end)

        return nil
    end,

    GetDisplayName = function()
        return "Stealth"
    end
}

