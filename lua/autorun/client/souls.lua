local PARTICLE_RISE_TIME = 1.5

hook.Add("Halloween_Soul_Rise", "SoulRiser", function(ParticleSystem, Attacker, Victim)
	local VictimOrigin = Victim:GetPos()

	local VictimTop = Victim:OBBCenter()
	VictimTop:Mul(4) -- 2 is the top of their bounds. 4 is twice that
	VictimTop = Victim:LocalToWorld(VictimTop)

	local RiseStart = CurTime()
	local RiseEnd = RiseStart + PARTICLE_RISE_TIME

	local HookIdentifier = "Halloween_Soul_Rise_" .. RiseEnd

	-- Ew
	hook.Add("Think", HookIdentifier, function()
		local CurrentTime = CurTime()

		local DeltaTime = CurrentTime - RiseStart
		local Percentage = math.Remap(RiseStart + DeltaTime, RiseStart, RiseEnd, 0, 1)

		local ParticlePosition = LerpVector(Percentage, VictimOrigin, VictimTop)
		ParticleSystem:SetControlPoint(0, ParticlePosition)

		if CurrentTime >= RiseEnd then
			hook.Remove("Think", HookIdentifier)

			hook.Run("Halloween_Soul_Home", ParticleSystem, Attacker, Victim, VictimOrigin, VictimTop)
		end
	end)
end)

hook.Add("Halloween_Soul_Home", "SoulHomer", function(ParticleSystem, Attacker, Victim, VictimOrigin, VictimTop)
	local CurrentPosition = Vector(VictimTop)
	local HookIdentifier = "Halloween_Soul_Home_" .. CurTime()

	hook.Add("Think", HookIdentifier, function()
		local GoalPosition = Attacker:LocalToWorld(Attacker:OBBCenter())

		-- Move 500 units towards the player per thing
		local MoveDirection = GoalPosition - CurrentPosition
		MoveDirection:Normalize()
		MoveDirection:Mul(500 * FrameTime())

		local NewPosition = Vector(CurrentPosition)
		NewPosition:Add(MoveDirection)

		ParticleSystem:SetControlPoint(0, NewPosition)
		CurrentPosition:Set(NewPosition)

		-- Ghetto collision
		if CurrentPosition:IsEqualTol(GoalPosition, 10) then
			hook.Remove("Think", HookIdentifier)

			local CollectSound = Format("libbys/halloween/souls_receive%u.ogg", math.random(1, 3))
			Attacker:EmitSound(CollectSound, 65)

			ParticleSystem:StopEmissionAndDestroyImmediately()
		end
	end)
end)

gameevent.Listen("entity_killed")
hook.Add("entity_killed", "PlaySoul", function(Data)
	local Attacker = Entity(Data.entindex_attacker)
	local Victim = Entity(Data.entindex_killed)

	if Attacker == Victim then return end
	if not IsValid(Attacker) or not IsValid(Victim) then return end
	if not Attacker:IsPlayer() then return end

	local ParticleSystem = CreateParticleSystem(game.GetWorld(), "vortigaunt_hand_glow", PATTACH_ABSORIGIN, 0, vector_origin)
	if not IsValid(ParticleSystem) then return end

	Victim:EmitSound("libbys/halloween/soul_hover.wav", 65)

	hook.Run("Halloween_Soul_Rise", ParticleSystem, Attacker, Victim)
end)
