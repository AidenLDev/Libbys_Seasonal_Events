AddCSLuaFile("shared/upgrades_data.lua")
include("shared/upgrades_data.lua")


// Need to find a better way to do this
function PrintMessage(message, isError, errorType)
    message = message or "No message provided"

    local prefix = "[HalloweenEvent - upgrades] "

    if isError then
        prefix = prefix .. (errorType == "SQL" and "[SQL ERROR] " or "[ERROR] ")
    end

    print(prefix .. message)
end


if SERVER then
    util.AddNetworkString("RequestPlayerUpgrades")
    util.AddNetworkString("SendPlayerUpgrades")
    util.AddNetworkString("RequestUpgradePurchase")
    util.AddNetworkString("UpdatePlayerUpgrade")
    util.AddNetworkString("ClientMessage")

    local function InitializeUpgradeTable()
        if not sql.TableExists("player_upgrades") then
            local createTable = sql.Query([[
                CREATE TABLE IF NOT EXISTS player_upgrades (
                    steamid64 TEXT,
                    name TEXT,
                    upgrade TEXT,
                    level INTEGER DEFAULT 0,
                    PRIMARY KEY (steamid64, upgrade)
                )
            ]])
            if createTable then
                PrintMessage("player_upgrades table created successfully.")
            else
                PrintMessage(sql.LastError(), true, "SQL")
            end
        else
            PrintMessage("player_upgrades table already exists.")
        end
    end

    InitializeUpgradeTable()

    local function ExecuteSQL(query)
        local result = sql.Query(query)
        if not result then
            PrintMessage(sql.LastError(), true, "SQL")
        end
        return result
    end

// Save + Load //

    function SavePlayerUpgrade(ply, upgrade, level)
        local steamID64 = sql.SQLStr(ply:SteamID64())
        local name = sql.SQLStr(ply:Nick())
        local upgrade = sql.SQLStr(upgrade)
        local level = tonumber(level) or 0
    
        local query = string.format(
            "INSERT OR REPLACE INTO player_upgrades (steamid64, name, upgrade, level) VALUES (%s, %s, %s, %d)",
            steamID64, name, upgrade, level
        )
    
        local result = sql.Query(query)
        if result == false then
            PrintMessage(sql.LastError(), true, "SQL")
        else
            PrintMessage(upgrade .. " ( lvl. " .. level .. " )" .. " data saved for " .. ply:Nick())
    
            ply.Upgrades[upgrade] = level
            ApplyUpgrades(ply)
    
            net.Start("UpdatePlayerUpgrade")
            net.WriteString(upgrade)
            net.WriteUInt(level, 8)
            net.Send(ply)
        end
    end


    local function LoadPlayerUpgrades(ply)
        local steamID64 = sql.SQLStr(ply:SteamID64())
        ply.Upgrades = {}

        local query = "SELECT upgrade, level FROM player_upgrades WHERE steamid64 = " .. steamID64
        local results = sql.Query(query)
        
        if results then
            for _, row in ipairs(results) do
                local upgradeName = row.upgrade
                local level = tonumber(row.level) or 0
                ply.Upgrades[upgradeName] = level
                PrintMessage(upgradeName .. " ( lvl. " .. level .. " )" .. " data loaded for " .. ply:Nick())
            end
        else
            PrintMessage(sql.LastError(), true, "SQL")
        end

        net.Start("SendPlayerUpgrades")
        net.WriteTable(ply.Upgrades)
        net.Send(ply)
    end

    net.Receive("RequestPlayerUpgrades", function(len, ply)
        local steamID64 = ply:SteamID64()
        local upgrades = sql.Query("SELECT upgrade, level FROM player_upgrades WHERE steamid64 = '" .. steamID64 .. "'")
    
        if upgrades then
            net.Start("SendPlayerUpgrades")
            net.WriteUInt(#upgrades, 8)
            for _, row in ipairs(upgrades) do
                net.WriteString(row.upgrade)
                net.WriteUInt(tonumber(row.level) or 0, 8)
            end
            net.Send(ply)
        else
            PrintMessage("No upgrade data found for " .. ply:Nick())
        end
    end)


    local function CalculateUpgradeCost(upgrade, currentLevel)
        return math.floor(upgrade.baseCost * math.pow(1.25, currentLevel))
    end

    local function ApplyRegeneration(ply)
        if timer.Exists("PlayerRegeneration_" .. ply:SteamID64()) then
            timer.Remove("PlayerRegeneration_" .. ply:SteamID64())
        end

        local regenLevel = ply.Upgrades and ply.Upgrades["Regeneration"] or 0

        if regenLevel > 0 and ply:Health() < ply:GetMaxHealth() then
            local regenAmount = regenLevel * upgrades[4].valuePerLevel
            timer.Create("PlayerRegeneration_" .. ply:SteamID64(), 1, 0, function()
                if not IsValid(ply) or not ply:Alive() then
                    timer.Remove("PlayerRegeneration_" .. ply:SteamID64())
                    ply.RegenerationActive = false
                    return
                end

                if ply:Health() >= ply:GetMaxHealth() then
                    timer.Remove("PlayerRegeneration_" .. ply:SteamID64())
                    ply.RegenerationActive = false
                    return
                end

                local newHealth = math.min(ply:Health() + regenAmount, ply:GetMaxHealth())
                ply:SetHealth(newHealth)
            end)
        else
            ply.RegenerationActive = false
        end
    end

// Upgrade Applicator + Handler //

    function ApplyUpgrades(ply)
        if not IsValid(ply) then return end
        PrintMessage("Applying upgrade effects for " .. ply:Nick())
        
        for _, upgradeData in ipairs(upgrades) do
            local level = ply.Upgrades and ply.Upgrades[upgradeData.name] or 0
            if level and level > 0 then
                if upgradeData.name == "Health" then
                    local newMaxHealth = 100 + level * upgradeData.valuePerLevel
                    ply:SetMaxHealth(newMaxHealth)
                    ply:SetHealth(ply:GetMaxHealth())
                    PrintMessage("  Health - " .. newMaxHealth)
                elseif upgradeData.name == "Agility" then
                    local newRunSpeed = 500 + level * upgradeData.valuePerLevel
                    local newWalkSpeed = 200 + level * upgradeData.valuePerLevel
                    ply:SetRunSpeed(newRunSpeed)
                    ply:SetWalkSpeed(newWalkSpeed)
                    PrintMessage("  RunSpeed - " .. newRunSpeed .. "    WalkSpeed - " .. newWalkSpeed)
                elseif upgradeData.name == "Power Legs" then
                    local newJumpPower = 240 + level * upgradeData.valuePerLevel
                    ply:SetJumpPower(newJumpPower)
                    PrintMessage("  JumpPower - " .. newJumpPower)
                elseif upgradeData.name == "Health Regen" then
                    ApplyRegeneration(ply)
                    PrintMessage("  Health Regen level " .. level)
                elseif upgradeData.name == "Blunt Resistance" then
                    ply.BluntResistanceLevel = level
                    PrintMessage("  Blunt Resistance level " .. level)
                end
            end
        end
    end

    net.Receive("RequestUpgradePurchase", function(len, ply)
        local upgradeName = net.ReadString()
        local playerSouls = ply:GetPlayerBalance("souls")
    
        for _, upgrade in pairs(upgrades) do
            if upgrade.name == upgradeName then
                local currentLevel = ply.Upgrades[upgrade.name] or 0
                if currentLevel < upgrade.maxLevel then
                    local currentCost = math.floor(upgrade.baseCost * math.pow(1.25, currentLevel))
    
                    if playerSouls >= currentCost then
                        playerSouls = playerSouls - currentCost
                        ply:SetPlayerBalance("souls", playerSouls)
    
                        ply.Upgrades[upgrade.name] = currentLevel + 1
                        SavePlayerUpgrade(ply, upgrade.name, ply.Upgrades[upgrade.name])
                        ApplyUpgrades(ply)
    
                        net.Start("UpdatePlayerUpgrade")
                        net.WriteString(upgrade.name)
                        net.WriteUInt(ply.Upgrades[upgrade.name], 8)
                        net.Send(ply)

                        PrintMessage("Purchase confirmed for " .. ply:Nick() .. " | " .. upgrade.name .. " ( lvl. " .. ply.Upgrades[upgrade.name] .. " )")
    
                        if upgrade.name == "Regeneration" and ply.RegenerationActive then
                            ApplyRegeneration(ply)
                        end
                    else
                        PrintMessage(ply:Nick() .. " doesn't have enough souls to purchase " .. upgrade.name)
                    end
                    break
                end
            end
        end
    end)

    hook.Add("PlayerSpawn", "ApplyPlayerUpgradesOnSpawn", function(ply)
        timer.Simple(0.2, function()
            ApplyUpgrades(ply)
            if ply:Health() < ply:GetMaxHealth() then
                ApplyRegeneration(ply)
            end
        end)
    end)
    

    hook.Add("PlayerInitialSpawn", "LoadPlayerData", function(ply)
        LoadPlayerUpgrades(ply)
    end)

// HP Regen //

    hook.Add("PlayerDeath", "StopRegenerationOnDeath", function(ply)
        timer.Remove("PlayerRegeneration_" .. ply:SteamID64())
        ply.RegenerationActive = false
    end)
    
    hook.Add("PlayerSpawn", "ResetRegenerationOnSpawn", function(ply)
        ply.PreviousHealth = ply:Health()
        ply.RegenerationActive = false
    end)
    
    hook.Add("Think", "DetectHealthChangeForRegen", function()
        for _, ply in ipairs(player.GetAll()) do
            if not ply.PreviousHealth then
                ply.PreviousHealth = ply:Health()
            end
    
            if ply:Health() < ply.PreviousHealth then
                local regenLevel = ply.Upgrades and ply.Upgrades["Regeneration"] or 0
    
                if regenLevel > 0 and ply:Health() < ply:GetMaxHealth() then
                    if not ply.RegenerationActive then
                        ply.RegenerationActive = true
                        ApplyRegeneration(ply)
                    end
                end
            end
    
            ply.PreviousHealth = ply:Health()
        end
    end)    

    hook.Add("EntityTakeDamage", "ResumeRegenerationOnDamage", function(target, dmginfo)
        if IsValid(target) and target:IsPlayer() then
            local ply = target
            local regenLevel = ply.Upgrades and ply.Upgrades["Regeneration"] or 0
    
            ply:SetHealth(math.max(ply:Health() - dmginfo:GetDamage(), 0))
    
            if regenLevel > 0 and ply:Health() < ply:GetMaxHealth() then
                if not ply.RegenerationActive then
                    ply.RegenerationActive = true
                    ApplyRegeneration(ply)
                end
            end
        end
    end)  

// Static Damage Resistances //

    hook.Add("EntityTakeDamage", "ApplyDamageResistances", function(target, dmginfo)
        if IsValid(target) and target:IsPlayer() then
            local ply = target
    
            local bluntResistPercentages = {96.5, 97, 98, 99, 99.9}
    
            local bluntResistLevel = ply.Upgrades and ply.Upgrades["Blunt Resistance"] or 0
            if bluntResistLevel > 0 then
                local dmgType = dmginfo:GetDamageType()
    
                if dmgType == DMG_CRUSH or dmgType == DMG_VEHICLE or dmgType == DMG_PHYSGUN then
                    local originalDamage = dmginfo:GetDamage()
    
                    local resistance = bluntResistPercentages[bluntResistLevel] or 0
    
                    local newDamage = originalDamage * ((100 - resistance) / 100)
    
                    local minHealthAfterHit = ply:GetMaxHealth() * 0.1
                    if ply:Health() - newDamage <= 0 then
                        newDamage = ply:Health() - minHealthAfterHit
                    end
    
                    if bluntResistLevel == upgrades[5].maxLevel then
                        local maxDamagePerHit = ply:GetMaxHealth() * 0.25
                        newDamage = math.min(newDamage, maxDamagePerHit)
                    end
    
                    dmginfo:SetDamage(newDamage)
                    PrintMessage("Blunt Resistance Level " .. bluntResistLevel .. ": Damage reduced to " .. newDamage)
    
                    return
                end
            end
    
            local bulletResistLevel = ply.Upgrades and ply.Upgrades["Bullet Resistance"] or 0
            if bulletResistLevel > 0 then
                local dmgType = dmginfo:GetDamageType()
                if dmgType == DMG_BULLET or dmgType == DMG_SNIPER or dmgType == DMG_ENERGYBEAM or 
                   dmgType == DMG_PLASMA or dmgType == DMG_SHOCK or dmgType == DMG_AIRBOAT then
                    local resistance = bulletResistLevel * upgrades[6].valuePerLevel
                    local newDamage = dmginfo:GetDamage() * ((100 - resistance) / 100)
                    dmginfo:SetDamage(newDamage)
                end
            end
    
            local blastResistLevel = ply.Upgrades and ply.Upgrades["Blast Resistance"] or 0
            if blastResistLevel > 0 then
                local dmgType = dmginfo:GetDamageType()
                if dmgType == DMG_BLAST or dmgType == DMG_PHYSGUN or dmgType == DMG_MISSILEDEFENSE or 
                   dmgType == DMG_BLAST_SURFACE or dmgType == DMG_SONIC then
                    local resistance = blastResistLevel * upgrades[7].valuePerLevel
                    local newDamage = dmginfo:GetDamage() * ((100 - resistance) / 100)
                    dmginfo:SetDamage(newDamage)
                end
            end
    
            local chemicalResistLevel = ply.Upgrades and ply.Upgrades["Chemical Resistance"] or 0
            if chemicalResistLevel > 0 then
                local dmgType = dmginfo:GetDamageType()
                if dmgType == DMG_ACID or dmgType == DMG_RADIATION or dmgType == DMG_POISON or
                   dmgType == DMG_NERVEGAS or dmgType == DMG_PARALYZE or dmgType == DMG_SHOCK then
                    if chemicalResistLevel >= 2 then
                        dmginfo:SetDamage(0)
                    else
                        local resistance = chemicalResistLevel * upgrades[8].valuePerLevel
                        local newDamage = dmginfo:GetDamage() * ((100 - resistance) / 100)
                        dmginfo:SetDamage(newDamage)
                    end
                end
            end
    
            local fireResistLevel = ply.Upgrades and ply.Upgrades["Fire Resistance"] or 0
            if fireResistLevel > 0 then
                local dmgType = dmginfo:GetDamageType()
                if dmgType == DMG_SLOWBURN or dmgType == DMG_BURN then
                    local resistance = fireResistLevel * upgrades[9].valuePerLevel
                    local newDamage = dmginfo:GetDamage() * ((100 - resistance) / 100)
    
                    if fireResistLevel == upgrades[9].maxLevel then
                        newDamage = 0
                        ply:Extinguish()
                    end
    
                    dmginfo:SetDamage(newDamage)
                end
            end
        end
    end)
end

if CLIENT then

    concommand.Add("halloween_upgrades_check", function(ply, cmd, args)
        if not ply:IsSuperAdmin() then
            ply:ChatPrint("You do not have access to this command.")
            return
        end
    
        local identifier = args[1]
        local sqlQuery = ""
        local results = {}
        
        if identifier then
            if tonumber(identifier) then
                local index = tonumber(identifier)
                local indexedPlayers = sql.Query("SELECT DISTINCT steamid64, name FROM player_upgrades")
                if indexedPlayers and indexedPlayers[index] then
                    identifier = indexedPlayers[index].steamid64
                else
                    PrintMessage("No player found at " .. index, true)
                    return
                end
            end
            
            sqlQuery = string.format("SELECT * FROM player_upgrades WHERE steamid64 = '%s' OR name LIKE '%%%s%%'", identifier, identifier)
            results = sql.Query(sqlQuery)
            if not results then
                PrintMessage("No upgrades found for " .. identifier)
                return
            end
        else
            sqlQuery = "SELECT steamid64, name, upgrade, level FROM player_upgrades ORDER BY steamid64"
            results = sql.Query(sqlQuery)
            if not results then
                PrintMessage("Table data empty")
                return
            end
        end
    
        local currentIndex = 1
        local lastSteamID = nil
    
        for _, row in ipairs(results) do
            if row.steamid64 ~= lastSteamID then
                PrintMessage(string.format("%d | %s | %s", currentIndex, row.name, row.steamid64))
                lastSteamID = row.steamid64
                currentIndex = currentIndex + 1
            end
            PrintMessage(string.format("   %s  - lvl.%s", row.upgrade, row.level))
        end
    end)

    concommand.Add("halloween_upgrades_edit", function(ply, cmd, args)
        if not ply:IsSuperAdmin() then
            ply:ChatPrint("You do not have access to this command.")
            return
        end
    
        if #args < 3 then
            PrintMessage("Usage: halloween_upgrades_edit <index/name/steamid> <upgrade name> <level>")
            return
        end
    
        local identifier = args[1]
        local upgradeName = table.concat(args, " ", 2, #args - 1)
        local level = tonumber(args[#args])
    
        if not level then
            PrintMessage("Invalid level specified", true)
            return
        end
    
        local steamid64
        if tonumber(identifier) then
            local indexedPlayers = sql.Query("SELECT DISTINCT steamid64, name FROM player_upgrades ORDER BY steamid64")
            if indexedPlayers and indexedPlayers[tonumber(identifier)] then
                steamid64 = indexedPlayers[tonumber(identifier)].steamid64
            else
                PrintMessage("No player found at " .. identifier, true)
                return
            end
        else
            local results = sql.Query(string.format(
                "SELECT steamid64 FROM player_upgrades WHERE steamid64 = %s OR name LIKE '%%%s%%' LIMIT 1",
                sql.SQLStr(identifier), sql.SQLStr(identifier)
            ))
            if results and results[1] then
                steamid64 = results[1].steamid64
            else
                PrintMessage("No player found with " .. identifier, true)
                return
            end
        end
    
        local upgradeData
        for _, upgrade in ipairs(upgrades) do
            if upgrade.name == upgradeName then
                upgradeData = upgrade
                break
            end
        end
    
        if not upgradeData then
            PrintMessage(upgradeName .. " does not exist", true)
            return
        end
    
        local targetLevel = math.Clamp(level, 0, upgradeData.maxLevel)
        local query
        if targetLevel <= 0 then
            query = string.format("DELETE FROM player_upgrades WHERE steamid64 = %s AND upgrade = %s", sql.SQLStr(steamid64), sql.SQLStr(upgradeName))
            PrintMessage("Removing " .. upgradeName .. " for " .. steamid64)
        else
            query = string.format(
                "INSERT OR REPLACE INTO player_upgrades (steamid64, name, upgrade, level) VALUES (%s, (SELECT name FROM player_upgrades WHERE steamid64 = %s LIMIT 1), %s, %d)",
                sql.SQLStr(steamid64), sql.SQLStr(steamid64), sql.SQLStr(upgradeName), targetLevel
            )
        end
    
        local result = sql.Query(query)
        if result == false then
            PrintMessage(sql.LastError(), true, "SQL")
            return
        end
    
        for _, onlinePly in ipairs(player.GetAll()) do
            if onlinePly:SteamID64() == steamid64 then
                onlinePly.Upgrades = onlinePly.Upgrades or {}
                onlinePly.Upgrades[upgradeName] = targetLevel
                ApplyUpgrades(onlinePly)
    
                net.Start("UpdatePlayerUpgrade")
                net.WriteString(upgradeName)
                net.WriteUInt(targetLevel, 8)
                net.Send(onlinePly)
    
                PrintMessage(string.format("Upgrades window updated for %s ( lvl. %d )", upgradeName, targetLevel))
                break
            end
        end
    
        PrintMessage(string.format("Set %s level to %d for %s", upgradeName, targetLevel, steamid64))
    end)

    MsgC(Color(57, 100, 245), "[HalloweenEvent] ", color_white, "upgrades core loaded\n")
end