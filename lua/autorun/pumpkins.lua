if SERVER then
    util.AddNetworkString("PumpkinCollected")
    util.AddNetworkString("SpawnPumpkin")

    include("autorun/server/ween_balances_core.lua")

    local COLLECTION_RANGE = 50
    local HEALTH_MIN = 15
    local HEALTH_MAX = 23
    // local CANDYCORN_MIN = 23
    // local CANDYCORN_MAX = 34
    local CREDIT_MIN = 1000
    local CREDIT_MAX = 3000
    local spawnableLifetime = 120
    local pumpkinEntities = {}

    net.Receive("SpawnPumpkin", function()
        local spawnPos = net.ReadVector()
        CreatePumpkin(spawnPos)
    end)

    function CreatePumpkin(pos)
        local pumpkin = ents.Create("prop_dynamic")
        if not IsValid(pumpkin) then return end

        pumpkin:SetModel("models/libbys/halloween/pumpkin_loot_alt.mdl")
        pumpkin:SetPos(pos)
        pumpkin:SetSolid(SOLID_NONE)
        pumpkin:SetTrigger(true)
        pumpkin:SetMoveType(MOVETYPE_NONE)
        pumpkin:Spawn()

        pumpkin:EmitSound("libbys/halloween/spawn.ogg", 85)
        pumpkin:ResetSequence(pumpkin:LookupSequence("idle"))

        table.insert(pumpkinEntities, pumpkin)
        timer.Simple(spawnableLifetime, function()
            if IsValid(pumpkin) then
                pumpkin:Remove()
                table.RemoveByValue(pumpkinEntities, pumpkin)
            end
        end)
        return pumpkin
    end

    local function CheckPumpkinCollect(pumpkin)
        for _, ply in ipairs(player.GetAll()) do
            if not ply:IsBot() then
                local inRange = ply:GetPos():DistToSqr(pumpkin:GetPos()) <= (COLLECTION_RANGE * COLLECTION_RANGE)
                if IsValid(ply) and inRange then
                    ply:EmitSound("libbys/halloween/pumpkin_pickup.ogg", 40)
        
                    if ply:Health() < ply:GetMaxHealth() then
                        local healthGain = math.random(HEALTH_MIN, HEALTH_MAX)
                        ply:SetHealth(math.min(ply:Health() + healthGain, ply:GetMaxHealth()))
                    end
        
                    // local candycorn = math.random(CANDYCORN_MIN, CANDYCORN_MAX)
                    // ply:ModifyPlayerBalance("candycorn", candycorn)
        
                    // SavePlayerBalances(ply)
        
                    // net.Start("PumpkinCollected")
                    // net.WriteUInt(candycorn, 8)
                    // net.Send(ply)


                    // NOTE: Can be kept for next year or revert back to candycorn
                    local credits = math.random(CREDIT_MIN, CREDIT_MAX)
                    UpdateCredits(ply, credits)
        
                    pumpkin:Remove()
                    table.RemoveByValue(pumpkinEntities, pumpkin)
                    break
                end
            end
        end
    end    

    hook.Add("Think", "PumpkinGlobalRangeCheck", function()
        for _, pumpkin in ipairs(pumpkinEntities) do
            if IsValid(pumpkin) then
                CheckPumpkinCollect(pumpkin)
            end
        end
    end)

    hook.Add("ShutDown", "PumpkinCleanupOnShutdown", function()
        for _, pumpkin in ipairs(pumpkinEntities) do
            if IsValid(pumpkin) then
                pumpkin:Remove()
            end
        end
    end)
end

if CLIENT then
    net.Receive("PumpkinCollected", function()
        local candycorn = net.ReadUInt(8)
        chat.AddText(
            Color(245, 126, 47), "◖You got ",
            Color(255, 196, 137), tostring(candycorn),
            Color(245, 126, 47), " Social Credits!◗"
        )
    end)

    MsgC(Color(57, 100, 245), "[HalloweenEvent] ", color_white, "pumpkins loaded\n")
end
