return {
    Cast = function(ply)
        ply:EmitSound("libbys/halloween/spell_fly.ogg", 65, 100)

        local flightSpeed = 55
        local verticalSpeed = 40
        local maxVelocity = 2500
        local velocityDecayRate = 0.95
        local pitchDivider = 50
        local uniqueID = "Flight_" .. ply:SteamID()
        local flyingUp = false
        local inflightSound = CreateSound(ply, "libbys/halloween/inflight_loop.wav")
        inflightSound:PlayEx(0.7, 115)

        local oldCanNoclip = ply.CanNoclip or function() return true end
        ply.CanNoclip = function() return false end

        ply:SetGravity(-0.001)

        timer.Create(uniqueID, 24, 1, function()
            if IsValid(ply) then
                ply:SetMoveType(MOVETYPE_WALK)
                ply:SetGravity(1)
                inflightSound:Stop()
                ply:EmitSound("libbys/halloween/power_down.ogg", 45, 100)

                ply.CanNoclip = oldCanNoclip

                hook.Remove("Think", uniqueID)
                hook.Remove("PlayerButtonDown", uniqueID .. "_Up")
                hook.Remove("PlayerButtonUp", uniqueID .. "_Up")
                ply:SetNWBool("SpellInProgress", false)
                ply:SetNWBool("SpellOverlay", false)
            end
        end)

        hook.Add("PlayerButtonDown", uniqueID .. "_Up", function(plyPressed, button)
            if plyPressed == ply and button == KEY_SPACE then
                flyingUp = true
            end
        end)

        hook.Add("PlayerButtonUp", uniqueID .. "_Up", function(plyPressed, button)
            if plyPressed == ply and button == KEY_SPACE then
                flyingUp = false
            end
        end)

        local function TraceForCollision(desiredVelocity)
            local trace = util.TraceHull({
                start = ply:GetPos(),
                endpos = ply:GetPos() + desiredVelocity * FrameTime(),
                filter = ply,
                mins = ply:OBBMins(),
                maxs = ply:OBBMaxs(),
            })
            return trace
        end

        hook.Add("Think", uniqueID, function()
            if IsValid(ply) then
                ply:SetMoveType(MOVETYPE_NOCLIP)

                local aimVector = ply:GetAimVector()
                local rightVector = ply:GetRight()
                local currentVelocity = ply:GetVelocity()
                local inputVelocity = Vector(0, 0, 0)
                local isMoving = false

                if ply:KeyDown(IN_FORWARD) then
                    inputVelocity = inputVelocity + aimVector * flightSpeed
                    isMoving = true
                elseif ply:KeyDown(IN_BACK) then
                    inputVelocity = inputVelocity - aimVector * flightSpeed
                    isMoving = true
                end

                if ply:KeyDown(IN_MOVERIGHT) then
                    inputVelocity = inputVelocity + rightVector * flightSpeed
                    isMoving = true
                elseif ply:KeyDown(IN_MOVELEFT) then
                    inputVelocity = inputVelocity - rightVector * flightSpeed
                    isMoving = true
                end

                if flyingUp then
                    inputVelocity = inputVelocity + Vector(0, 0, verticalSpeed)
                    isMoving = true
                elseif ply:KeyDown(IN_WALK) then
                    inputVelocity = inputVelocity - Vector(0, 0, verticalSpeed)
                    isMoving = true
                end

                local desiredVelocity = currentVelocity + inputVelocity

                if not isMoving then
                    desiredVelocity = desiredVelocity * velocityDecayRate
                end

                if desiredVelocity:Length() > maxVelocity then
                    desiredVelocity = desiredVelocity:GetNormalized() * maxVelocity
                end

                local trace = TraceForCollision(desiredVelocity)
                if trace.Hit then
                    local hitNormal = trace.HitNormal
                    desiredVelocity = desiredVelocity - desiredVelocity:Dot(hitNormal) * hitNormal
                end

                ply:SetLocalVelocity(desiredVelocity)

                local velocityLength = desiredVelocity:Length()
                local pitch = math.Clamp(80 + (velocityLength / pitchDivider), 70, 160)
                inflightSound:ChangePitch(pitch, 0.1)

                ply:SetMoveType(MOVETYPE_WALK)
            end
        end)

        -- Cleanup function to restore player state
        local function Cleanup()
            if IsValid(ply) then
                ply:SetMoveType(MOVETYPE_WALK)
                ply:SetGravity(1)
                inflightSound:Stop()

                ply.CanNoclip = oldCanNoclip

                timer.Remove(uniqueID)
                hook.Remove("Think", uniqueID)
                hook.Remove("PlayerButtonDown", uniqueID .. "_Up")
                hook.Remove("PlayerButtonUp", uniqueID .. "_Up")
                hook.Remove("PlayerDisconnected", uniqueID .. "_Disconnect")
                hook.Remove("PlayerDeath", uniqueID .. "_Death")
            end
        end

        -- Cleanup on player death
        hook.Add("PlayerDeath", uniqueID .. "_Death", function(deadPly)
            if deadPly == ply then
                Cleanup()
            end
        end)

        -- Cleanup on player disconnect
        hook.Add("PlayerDisconnected", uniqueID .. "_Disconnect", function(disconnectedPly)
            if disconnectedPly == ply then
                Cleanup()
            end
        end)

        ply:SetNWBool("SpellInProgress", true) -- Spell is ongoing
        return nil -- Indicate spell is ongoing
    end,

    GetDisplayName = function()
        return "Flight" -- Set the display name for the spell
    end
}
