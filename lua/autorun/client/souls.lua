local PARTICLE_RISE_TIME = 1.5

local SOUND_SOUL_HOVER = "libbys/halloween/soul_hover.wav"
local SOUND_SOUL_COLLECT = "libbys/halloween/souls_receive%u.ogg"

-- _G.SoundDuration is broken
local SOUND_DURATIONS = {
	["libbys/halloween/soul_hover.wav"] = 4.931,
	["libbys/halloween/souls_receive1.ogg"] = 3.564,
	["libbys/halloween/souls_receive2.ogg"] = 3.022,
	["libbys/halloween/souls_receive3.ogg"] = 3.458
}

local function CollectSoul(ParticleSystem, Attacker, HookIdentifier)
	hook.Remove("Think", HookIdentifier)

	if IsValid(Attacker) then
		local CollectSound = Format(SOUND_SOUL_COLLECT, math.random(1, 3))
		Attacker:EmitSound(CollectSound, 65)

		timer.Simple(SOUND_DURATIONS[CollectSound], function()
			if IsValid(Attacker) then
				Attacker:StopSound(CollectSound)
			end
		end)
	end

	if IsValid(ParticleSystem) then
		ParticleSystem:StopEmissionAndDestroyImmediately()
	end
end

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
		if CurrentPosition:IsEqualTol(GoalPosition, 10) or (not IsValid(Attacker) or not Attacker:Alive()) then
			CollectSoul(ParticleSystem, Attacker, HookIdentifier)
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

	Victim:EmitSound(SOUND_SOUL_HOVER, 65)

	timer.Simple(SOUND_DURATIONS[SOUND_SOUL_HOVER], function()
		if IsValid(Victim) then
			Victim:StopSound(SOUND_SOUL_HOVER)
		end
	end)

	hook.Run("Halloween_Soul_Rise", ParticleSystem, Attacker, Victim)
end)
