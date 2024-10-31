AddCSLuaFile()

ENT.Type = "anim"
ENT.AdminOnly = true

ENT.PhysgunDisabled = true
ENT.PhysicsSolidMask = CONTENTS_EMPTY

if CLIENT then
	ENT.PrintName = "Libby's Event Collectable"
	ENT.Author = "Coin"

	ENT.Purpose = "Collectable item(s) for Libby's server events"
	ENT.Instructions = "Touch it"

	ENT.RenderGroup = RENDERGROUP_OPAQUE
end

if SERVER then
	ENT.DoNotDuplicate = true
end

function ENT:SelectModel()
	-- For override
	self:SetModel("models/props_junk/watermelon01.mdl")
end

function ENT:Initialize()
	self:SelectModel()

	if SERVER then
		self:SetTrigger(true)
		self:SetUseType(SIMPLE_USE)
	end

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
end

if SERVER then
	function ENT:StartTouch(Toucher)
		if not Toucher:IsPlayer() then return end

		self:Collect(Toucher)
	end

	function ENT:Use(Activator)
		if not Activator:IsPlayer() then return end

		self:Collect(Activator)
	end

	function ENT:Collect(Collector)
		ProtectedCall(self.OnCollected, self, Collector)

		self:Remove()
	end

	function ENT:OnCollected(Collector)
		-- For override
	end
end
