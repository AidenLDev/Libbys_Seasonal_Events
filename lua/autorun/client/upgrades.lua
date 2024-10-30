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
