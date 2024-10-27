if SERVER then
    util.AddNetworkString("SpawnableEntitySpawned")
    util.AddNetworkString("ToggleSpawnableESP")

    local spawnablesEnabled = true

    local spawnableClasses = {
        { class = "pumpkin", weight = 70 },
        { class = "spellbook", weight = 30 }
    }

    local spawnRate = 15
    local maxSpawnables = CreateConVar("halloween_spawnables_max", "100", FCVAR_REPLICATED, "Maximum number of active spawnables on the map")
    local spawnableLifetime = 120
    local eventLifetime = 130
    local collectionRange = 50
    local rayDistance = 100000
    local minSpawnDistance = 100
    local spawnableEntities = {}

    local eventActive = false
    local isEventSpawning = false

    local spawnableDebugger = GetConVar("halloween_spawnables_debug") or CreateConVar("halloween_spawnables_debug", "0", FCVAR_REPLICATED, "Enable debug for spawnable entities for superadmins")

    
    local function PrintMessage(message, isError)
        if spawnableDebugger:GetInt() ~= 1 then return end

        local prefix = "[HalloweenEvent - spawnables] "
        local prefixColor = Color(245, 143, 47)
        local messageColor = color_white

        message = message or "unknown"

        if isError then
            prefixColor = Color(245, 60, 47)
            prefix = prefix .. "[ERROR] "
        end

        MsgC(prefixColor, prefix, messageColor, message .. "\n")
    end

// Raycast Finder // 

    local function GetMapBounds()
        local worldEntity = game.GetWorld()
        local mins, maxs = worldEntity:GetModelBounds()
        return mins, maxs
    end
    
    local function IsPositionClear(pos, radius)
        for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
            if ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() or
               ent:GetClass() == "prop_physics" or
               ent:GetClass() == "gmod_sent_vehicle_fphysics_base" or
               (ent.CPPIGetOwner and IsValid(ent:CPPIGetOwner())) then
                return false
            end
        end
        return true
    end 

    local function ClampSpawnPosition(pos, mins, maxs)
        pos.x = math.Clamp(pos.x, mins.x, maxs.x)
        pos.y = math.Clamp(pos.y, mins.y, maxs.y)
        pos.z = math.Clamp(pos.z, mins.z, maxs.z)
    
        pos.z = math.Clamp(pos.z, -2048, 2048)
    
        local trace = util.TraceLine({
            start = pos,
            endpos = pos + Vector(0, 0, -100000),
            mask = MASK_SOLID_BRUSHONLY,
        })
        if trace.Hit then
            pos.z = trace.HitPos.z
        end
    
        return pos
    end

    local function UpdateSpawnRate(newRate)
        if newRate <= 0 then
            if timer.Exists("SpawnablesControllerTimer") then
                timer.Remove("SpawnablesControllerTimer")
                PrintMessage("Rate set to 0. Spawn timer removed")
            end
            spawnRate = newRate
        else
            if not SpawnRandomEntity then
                PrintMessage("Error: SpawnRandomEntity function is nil", true)
                return
            end

            if timer.Exists("SpawnablesControllerTimer") then
                timer.Adjust("SpawnablesControllerTimer", newRate, 0, SpawnRandomEntity)
                PrintMessage("Spawn rate updated to " .. newRate .. " seconds")
            else
                timer.Create("SpawnablesControllerTimer", newRate, 0, SpawnRandomEntity)
                PrintMessage("Spawn timer created (" .. newRate .. " seconds)")
            end
            spawnRate = newRate
        end
    end
    
// Spawnable Spawner //

    local function SelectRandomSpawnable()
        local totalWeight = 0
        for _, spawnable in ipairs(spawnableClasses) do
            totalWeight = totalWeight + spawnable.weight
        end

        local randomWeight = math.random(totalWeight)
        for _, spawnable in ipairs(spawnableClasses) do
            if randomWeight <= spawnable.weight then
                return spawnable.class
            end
            randomWeight = randomWeight - spawnable.weight
        end
    end

    function SpawnRandomEntity()
        if not spawnablesEnabled then
            PrintMessage("Spawnables disabled", true)
            return
        elseif #spawnableEntities >= maxSpawnables:GetInt() then
            PrintMessage("Reached max spawnables limit ( " .. maxSpawnables:GetInt() .. " )", true)
            return
        end
    
        local attempts, maxAttempts = 0, 20
        local spawnPos
        local mins, maxs = GetMapBounds()
        local mapHeightEstimate = 1500
    
        while attempts < maxAttempts do
            local randX = math.random(mins.x, maxs.x)
            local randY = math.random(mins.y, maxs.y)
            local startZ = mapHeightEstimate
    
            local groundTrace = util.TraceLine({
                start = Vector(randX, randY, startZ),
                endpos = Vector(randX, randY, startZ - rayDistance),
                mask = MASK_SOLID_BRUSHONLY,
            })
    
            if groundTrace.Hit and not groundTrace.HitSky and bit.band(util.PointContents(groundTrace.HitPos), CONTENTS_WATER) == 0 then
                local groundPos = groundTrace.HitPos
    
                groundPos = ClampSpawnPosition(groundPos, mins, maxs)
    
                if IsPositionClear(groundPos, collectionRange) then
                    spawnPos = groundPos
                    PrintMessage("Suitable spawn point found | " .. tostring(groundPos))
                    break
                else
                    PrintMessage("Clearance failed | " .. tostring(groundPos))
                end
            else
                PrintMessage("Empty space/air | X: " .. randX .. " Y: " .. randY)
            end
    
            attempts = attempts + 1
        end
    
        if not spawnPos then
            PrintMessage("No suitable spawn position found after " .. maxAttempts .. " attempts", true)
            return
        end
    
        local chosenSpawnableClass = SelectRandomSpawnable()
        PrintMessage("Creating " .. chosenSpawnableClass .. " at: " .. tostring(spawnPos))
    
        local entity
        if chosenSpawnableClass == "pumpkin" then
            entity = CreatePumpkin(spawnPos)
        elseif chosenSpawnableClass == "spellbook" then
            entity = CreateSpellbook(spawnPos)
        end
    
        if entity then
            table.insert(spawnableEntities, entity)
    
            if not isEventSpawning then
                entity:EmitSound("libbys/halloween/spawn.ogg")
            else
                PrintMessage("Sound suppressed for event-spawned entity")
            end
    
            timer.Simple(spawnableLifetime, function()
                if IsValid(entity) then
                    PrintMessage(chosenSpawnableClass .. " expired. Removed | " .. tostring(entity:GetPos()))
                    entity:Remove()
                    table.RemoveByValue(spawnableEntities, entity)
                end
            end)
    
            return entity
        else
            PrintMessage(chosenSpawnableClass .. " creation failed", true)
            return nil
        end
    end

// Ultimate Spawn Event (UNFINISHED) //

    local function EndSpawnAllEvent()
        if not eventActive then return end
        eventActive = false
        PrintMessage("Spawnall event finished and cleaned up")

        UpdateSpawnRate(spawnRate)
    end
    
    local function SpawnAllEvent()
        local maxSpawnableCount = maxSpawnables:GetInt()
        if maxSpawnableCount <= 0 then
            PrintMessage("Spawnall event aborted: Max spawnables is set to 0", true)
            return
        end

        if eventActive then
            PrintMessage("Spawnall event is already running!", true)
            return
        end

        eventActive = true
        local originalSpawnRate = spawnRate
        local entitiesSpawnedDuringEvent = {}

        PrintMessage("Spawnall event started")
        isEventSpawning = true

        timer.Remove("SpawnablesControllerTimer")

        for _, ent in ipairs(spawnableEntities) do
            if IsValid(ent) then
                PrintMessage("Clearing pre-existing spawnables | " .. tostring(ent))
                ent:Remove()
            end
        end
        spawnableEntities = {}

        for i = 1, maxSpawnableCount do
            local entity = SpawnRandomEntity()
            if entity then
                table.insert(entitiesSpawnedDuringEvent, entity)
            end
        end

        timer.Simple(130, function()
            for _, ent in ipairs(entitiesSpawnedDuringEvent) do
                if IsValid(ent) then
                    ent:Remove()
                end
            end
            isEventSpawning = false
            EndSpawnAllEvent()
        end)
    end
    
// Commands //

    concommand.Add("halloween_spawnables_spawnall", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        SpawnAllEvent()
    end)
    
    if spawnRate > 0 then
        timer.Create("SpawnablesControllerTimer", spawnRate, 0, SpawnRandomEntity)
    end
    
    concommand.Add("halloween_spawnables_clear", function(ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        for _, ent in ipairs(spawnableEntities) do
            if IsValid(ent) then ent:Remove() end
        end
        spawnableEntities = {}
        Print("All active spawnables cleared")
    end)
    
    concommand.Add("halloween_spawnables_rate", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        local newRate = tonumber(args[1])
        if newRate then
            UpdateSpawnRate(newRate)
        else
            PrintMessage("Invalid rate. Specify a number.", true)
        end
    end)

    hook.Add("ShutDown", "SpawnablesCleanup", function()
        for _, ent in ipairs(spawnableEntities) do
            if IsValid(ent) then ent:Remove() end
        end
    end)
end

if CLIENT then 
    MsgC(Color(57, 100, 245), "[HalloweenEvent] ", color_white, "spawnables controller loaded\n")
end