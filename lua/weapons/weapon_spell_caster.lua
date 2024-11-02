AddCSLuaFile()

AccessorFunc(SWEP, "m_flSpellDuration", "SpellDuration", FORCE_NUMBER)

SWEP.AdminOnly = true

if CLIENT then
	SWEP.PrintName = "Spell Caster"
	SWEP.Author = "Coin & Merio"

	SWEP.Purpose = "Cast spells with animations"
	SWEP.Instructions = "Primary fire to cast your spell"

	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end

if SERVER then
	SWEP.DisableDuplicator = true
end

-- The wiki says ViewModel is client only and WorldModel is server only
-- It lied
SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = ""

SWEP.Primary.Ammo = "none"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false

SWEP.Secondary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false

SWEP.UseHands = true

SWEP.m_bPlayPickupSound = false

function SWEP:Initialize()
	self:SetSpellDuration(3)

	self:SetHoldType("magic")
end

if SERVER then
	function SWEP:Deploy()
		if not IsFirstTimePredicted() then return end

		-- TODO?
	end

	function SWEP:UnDeploy()
		local Owner = self:GetOwner()

		if Owner:IsPlayer() then
			Owner:SwitchToDefaultWeapon() -- GetPreviousWeapon is broken serverside, don't bother
			Owner:StripWeapon(self:GetClass())
		end
	end
end

function SWEP:PlayCastAnimation()
	local Owner = self:GetOwner()
	local ViewModel = Owner:GetViewModel()
	if not IsValid(ViewModel) then return end

	local CastAnimation = ViewModel:LookupSequence("cast_spell")

	if CastAnimation != -1 then
		ViewModel:SendViewModelMatchingSequence(CastAnimation)

		return ViewModel:SequenceDuration(CastAnimation)
	end

	return 0
end

function SWEP:CanPrimaryAttack()
	if CurTime() < self:GetNextPrimaryFire() then return false end

	return true
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetNextPrimaryFire(CurTime() + self:GetSpellDuration())

	if self:GetOwner():IsPlayer() then
		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

		local CastTime = self:PlayCastAnimation()

		if SERVER then
			timer.SimpleWithArguments(CastTime, self.UnDeploy, self)
		end
	end
end
