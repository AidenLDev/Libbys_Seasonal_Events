SWEP.PrintName = "spellcaster"
SWEP.Author = "Merio"
SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.DrawCrosshair = false

function SWEP:DrawWorldModel()
    return false
end

function SWEP:Initialize()
    self:SetHoldType("magic")
end

function SWEP:Deploy()
    local vm = self:GetOwner():GetViewModel()
    if not IsValid(vm) then return end

    local animID = vm:LookupSequence("cast_spell")
    if animID and animID >= 0 then
        vm:SendViewModelMatchingSequence(animID)
    end

    local animDuration = vm:SequenceDuration(animID)
    timer.Simple(animDuration, function()
        if IsValid(self) and IsValid(self:GetOwner()) then
            local ply = self:GetOwner()
            local previousWeaponClass = ply:GetNWString("PreviousWeaponClass", "")
            if previousWeaponClass ~= "" and ply:HasWeapon(previousWeaponClass) then
                ply:SelectWeapon(previousWeaponClass)
            end
            ply:StripWeapon(self:GetClass())
        end
    end)
end