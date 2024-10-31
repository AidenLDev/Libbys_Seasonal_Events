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

	AccessorFunc(ENT, "m_bRenderDebug", "RenderDebug", FORCE_BOOL)

	AccessorFunc(ENT, "m_flBobAmount", "BobAmount", FORCE_NUMBER)
	AccessorFunc(ENT, "m_bAllowNegativeBob", "AllowNegativeBob", FORCE_BOOL)
	AccessorFunc(ENT, "m_flSpinSpeed", "SpinSpeed", FORCE_NUMBER)
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

	if CLIENT then
		self:SetBobAmount(10)
		self:SetSpinSpeed(64)
		self:SetAllowNegativeBob(false)
	end

	if SERVER then
		self:SetTrigger(true)
		self:SetUseType(SIMPLE_USE)
	end

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
end

if CLIENT then
	function ENT:Spin()
		local SpinSpeed = self:GetSpinSpeed()
		if SpinSpeed <= 0 then return end

		local Spin = SpinSpeed * FrameTime()

		local RenderAngle = self:GetRenderAngles() or self:EyeAngles()
		RenderAngle.yaw = math.NormalizeAngle(RenderAngle.yaw + Spin)

		self:SetRenderAngles(RenderAngle)
	end

	function ENT:Bob()
		local BobAmount = self:GetBobAmount()
		if BobAmount <= 0 then return end

		local BobPercentage = math.sin(CurTime())
		BobAmount = math.Remap(BobPercentage, -1, 1, -BobAmount, BobAmount)

		if BobAmount < 0 and not self:GetAllowNegativeBob() then
			BobAmount = -BobAmount
		end

		local RenderOrigin = self:GetNetworkOrigin()
		RenderOrigin.z = RenderOrigin.z + BobAmount

		self:SetRenderOrigin(RenderOrigin)
	end

	function ENT:Draw()
		-- Debug visual of where it actually is
		if self:GetRenderDebug() then
			local RenderAngle = self:GetRenderAngles()
			local RenderOrigin = self:GetRenderOrigin()

			self:SetRenderAngles(angle_zero)
			self:SetRenderOrigin(self:GetNetworkOrigin())
			do
				render.SetColorModulation(1, 0, 0)
				do
					self:DrawModel()
					self:InvalidateBoneCache()
				end
				render.SetColorModulation(1, 1, 1)
			end
			self:SetRenderAngles(RenderAngle)
			self:SetRenderOrigin(RenderOrigin)
		end

		self:Spin()
		self:Bob()

		self:DrawModel()
	end
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
