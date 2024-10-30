local material = "sprites/heatwave"
local spellActive = false

local function SetMaterialRecursively(entity, material)
    if not IsValid(entity) then return end

    // Queue to prevent overflow
    local queue = {entity}
    while #queue > 0 do
        local current = table.remove(queue, 1)
        if current:GetMaterial() ~= material then
            current:SetMaterial(material)
        end
        for _, child in ipairs(current:GetChildren()) do
            if IsValid(child) then
                table.insert(queue, child)
            end
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
    local viewModel = ply:GetViewModel()
    if IsValid(viewModel) then
        SetMaterialRecursively(viewModel, material)
    end
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

local function CleanupSpell(ply, uniqueID)
    if not IsValid(ply) then return end

    spellActive = false
    ply:SetMaterial("")
    ResetMaterialForViewModelAndWeapon(ply)
    ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    ply:SetNWBool("IsInvulnerable", false)
    ply:SetNWBool("SpellInProgress", false)
    ply:SetNWBool("SpellOverlay", false)

    ply:StopSound("libbys/halloween/spell_stealth.ogg")
    ply:EmitSound("libbys/halloween/power_down.ogg", 45, 100)

    // Cleanup all hooks to prevent double calls
    timer.Remove(uniqueID)
    hook.Remove("EntityTakeDamage", uniqueID .. "_NoDamage")
    hook.Remove("PlayerDeath", uniqueID .. "_Death")
    hook.Remove("Think", uniqueID .. "_MaintainMaterial")
end

// More efficient hook setup w/o dumb timer
hook.Add("PlayerSwitchWeapon", "SwitchWeaponApplyMaterial", function(ply, oldWeapon, newWeapon)
    if spellActive and IsValid(ply) and ply:GetNWBool("SpellInProgress") then
        ApplyMaterialToWeaponAndViewModel(ply)
    end
end)


return {
    Cast = function(ply)
        if not IsValid(ply) then return end
        local uniqueID = "Stealth_" .. ply:SteamID()

        ply:SetNWBool("SpellInProgress", true)
        ply:SetNWBool("SpellOverlay", true)

        ply:SetMaterial(material)
        ply:EmitSound("libbys/halloween/spell_stealth.ogg", 60, 100)

        spellActive = true
        ApplyMaterialToWeaponAndViewModel(ply)

        ply:SetNWBool("IsInvulnerable", true)
        ply:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

        hook.Add("EntityTakeDamage", uniqueID .. "_NoDamage", function(target, dmginfo)
            if target == ply then
                dmginfo:SetDamage(0)
                return true
            end
        end)

        hook.Add("Think", uniqueID .. "_MaintainMaterial", function()
            if not IsValid(ply) or not ply:GetNWBool("SpellInProgress") then
                CleanupSpell(ply, uniqueID)
                return
            end

            ApplyMaterialToWeaponAndViewModel(ply)
        end)

        // Spell duration
        timer.Create(uniqueID, 18, 1, function()
            if IsValid(ply) then
                CleanupSpell(ply, uniqueID)
            end
        end)

        hook.Add("PlayerDeath", uniqueID .. "_Death", function(deadPly)
            if deadPly == ply then
                CleanupSpell(ply, uniqueID)
            end
        end)
    end,

    GetDisplayName = function()
        return "Stealth"
    end
}
