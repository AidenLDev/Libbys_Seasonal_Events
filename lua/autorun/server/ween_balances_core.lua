if SERVER then
    util.AddNetworkString("SystemModifyBalance")
    util.AddNetworkString("AdminModifyBalance")
    util.AddNetworkString("RequestLeaderboard")
    util.AddNetworkString("SendLeaderboard")
    util.AddNetworkString("RequestCandycornDeduction")
    util.AddNetworkString("UpdPlayerSCCBalances")
    util.AddNetworkString("RequestPlayerSouls")
    util.AddNetworkString("UpdatePlayerSouls")

    local candyCornColor = Color(245, 126, 47)
    local candyCornAmountColor = Color(255, 196, 137)
    local soulsColor = Color(77, 255, 193)
    local soulsAmountColor = Color(169, 255, 233)

    local SOUL_WEIGHT = 2

    local function CreatePlayerBalanceTable()
        sql.Query([[
            CREATE TABLE IF NOT EXISTS player_balances (
                steamid64 TEXT PRIMARY KEY,
                name TEXT,
                candycorn INTEGER DEFAULT 0,
                souls INTEGER DEFAULT 0
            )
        ]])
    end

    CreatePlayerBalanceTable()

// Save + Load //

    function SavePlayerBalances(ply)
        if ply:IsBot() then return end

        local steamID64 = ply:SteamID64()
        local name = ply:Nick()
        local candycorn = ply:GetPlayerBalance("candycorn")
        local souls = ply:GetPlayerBalance("souls")

        local exists = sql.QueryValue("SELECT steamid64 FROM player_balances WHERE steamid64 = " .. sql.SQLStr(steamID64))

        if exists then
            sql.Query(string.format("UPDATE player_balances SET name = %s, candycorn = %d, souls = %d WHERE steamid64 = %s",
                sql.SQLStr(name), candycorn, souls, sql.SQLStr(steamID64)))
        else
            if candycorn > 0 or souls > 0 then
                sql.Query(string.format("INSERT INTO player_balances (steamid64, name, candycorn, souls) VALUES (%s, %s, %d, %d)",
                    sql.SQLStr(steamID64), sql.SQLStr(name), candycorn, souls))
            end
        end
    end

    function LoadPlayerBalances(ply)
        if ply:IsBot() then return end

        local steamID64 = ply:SteamID64()
        local result = sql.QueryRow("SELECT candycorn, souls FROM player_balances WHERE steamid64 = " .. sql.SQLStr(steamID64))

        if result then
            ply:SetPlayerBalance("candycorn", tonumber(result.candycorn)) 
            ply:SetPlayerBalance("souls", tonumber(result.souls))
        else
            ply:SetPlayerBalance("candycorn", 0)
            ply:SetPlayerBalance("souls", 0)
        end
    end

    hook.Add("PlayerInitialSpawn", "InitPlayerPoints", function(ply)
        if not ply:IsBot() then
            LoadPlayerBalances(ply)
        end
    end)

    hook.Add("PlayerDisconnected", "SavePlayerPointsOnDisconnect", function(ply)
        if not ply:IsBot() then
            SavePlayerBalances(ply)
        end
    end)

    function GetPlayerBalance(steamID64)
        local result = sql.QueryRow("SELECT candycorn, souls FROM player_balances WHERE steamid64 = " .. sql.SQLStr(steamID64))
        if result then
            return tonumber(result.candycorn), tonumber(result.souls)
        else
            return 0, 0
        end
    end

    local function GetLeaderboardData()
        local result = sql.Query("SELECT steamid64, name, candycorn, souls FROM player_balances ORDER BY (candycorn + (souls * 2)) DESC LIMIT 20")
        
        if not result then
            return {}
        end
        
        local leaderboard = {}
        
        for _, row in ipairs(result) do
            local playerName = row.name or "Unknown"
            local steamID = row.steamid64
            local candyCorn = tonumber(row.candycorn) or 0
            local souls = tonumber(row.souls) or 0
            local totalPoints = candyCorn + (souls * 2)
        
            table.insert(leaderboard, {
                name = playerName,
                steamid64 = steamID,
                candycorn = candyCorn,
                souls = souls,
                totalPoints = totalPoints
            })
        end
        
        table.sort(leaderboard, function(a, b)
            return a.totalPoints > b.totalPoints
        end)
        
        return leaderboard
    end

    function SetPlayerBalance(steamID64, balanceType, value)
        local exists = sql.QueryValue("SELECT steamid64 FROM player_balances WHERE steamid64 = " .. sql.SQLStr(steamID64))
        local column = balanceType == "candycorn" and "candycorn" or "souls"
        value = tonumber(value) or 0
        if exists then
            sql.Query(string.format("UPDATE player_balances SET %s = %d WHERE steamid64 = %s", column, value, sql.SQLStr(steamID64)))
        else
            sql.Query(string.format("INSERT INTO player_balances (steamid64, name, %s) VALUES (%s, 'Unknown', %d)", column, sql.SQLStr(steamID64), value))
        end
    end

    function ModifyPlayerBalance(steamID64, balanceType, change)
        local candycorn, souls = GetPlayerBalance(steamID64)
        if balanceType == "candycorn" then
            SetPlayerBalance(steamID64, "candycorn", candycorn + change)
        elseif balanceType == "souls" then
            SetPlayerBalance(steamID64, "souls", souls + change)
        end
    end

    function DeletePlayerBalance(steamID64)
        sql.Query("DELETE FROM player_balances WHERE steamid64 = " .. sql.SQLStr(steamID64))
    end

    local PLAYER = FindMetaTable("Player")
    if not PLAYER then return end

    function PLAYER:ModifyPlayerBalance(balanceType, change)
        local steamID64 = self:SteamID64()
        ModifyPlayerBalance(steamID64, balanceType, change)
        self:SetPlayerBalance(balanceType, self:GetPlayerBalance(balanceType) + change)

        if balanceType == "souls" then
            net.Start("UpdatePlayerSouls")
            net.WriteInt(self:GetPlayerBalance("souls"), 32)
            net.Send(self)
        end
    end

    function PLAYER:SetPlayerBalance(balanceType, value)
        local steamID64 = self:SteamID64()
        SetPlayerBalance(steamID64, balanceType, value)
        self:SetNWInt(balanceType == "candycorn" and "CandyCorn" or "Souls", value)

        if balanceType == "souls" then
            net.Start("UpdatePlayerSouls")
            net.WriteInt(value, 32)
            net.Send(self)
        end
    end

    function PLAYER:GetPlayerBalance(balanceType)
        return self:GetNWInt(balanceType == "candycorn" and "CandyCorn" or "Souls", 0)
    end

    timer.Create("PeriodicSavePlayerPoints", 300, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if not ply:IsBot() then
                SavePlayerBalances(ply)
            end
        end
    end)

// Chat + Console Commands //

    hook.Add("PlayerSay", "CheckBalanceCommand", function(ply, text)
        if string.lower(text) == "!balance" then
            if ply:IsBot() then return "" end

            local candycorn = ply:GetPlayerBalance("candycorn")
            local souls = ply:GetPlayerBalance("souls")

            ply:SendLua(string.format(
                [[chat.AddText(Color(%d, %d, %d), "Candy Corn: ", Color(%d, %d, %d), "%d", Color(255, 255, 255), " | ", Color(%d, %d, %d), "Souls: ", Color(%d, %d, %d), "%d")]],
                candyCornColor.r, candyCornColor.g, candyCornColor.b,
                candyCornAmountColor.r, candyCornAmountColor.g, candyCornAmountColor.b, candycorn,
                soulsColor.r, soulsColor.g, soulsColor.b,
                soulsAmountColor.r, soulsAmountColor.g, soulsAmountColor.b, souls
            ))
            return ""
        end
    end)

    concommand.Add("halloween_balance_check", function(ply, cmd, args)
        if not ply:IsSuperAdmin() then
            print("You do not have permission to use this command.")
            return
        end

        local result = sql.Query("SELECT * FROM player_balances")

        if not result then
            print("No player balances found.")
            return
        end

        for i, row in ipairs(result) do
            print(string.format("%d. Player: %s | SteamID64: %s | CandyCorn: %s | Souls: %s", i, row.name or "Unknown", row.steamid64, row.candycorn, row.souls))
        end
    end)

    concommand.Add("halloween_balance_edit", function(ply, cmd, args)
        if #args < 3 then
            print("Usage: halloween_balance_edit <player_index/steamid64/name> <candycorn/souls> <new_amount>")
            return
        end

        if not ply:IsSuperAdmin() then
            print("You do not have permission to use this command.")
            return
        end
    
        local identifier, balanceType, amount = args[1], args[2], tonumber(args[3])
        local result = sql.Query("SELECT steamid64, name FROM player_balances WHERE steamid64 = " .. sql.SQLStr(identifier) .. " OR name LIKE '%" .. identifier .. "%'")
        
        if not result or #result == 0 then
            print("Player not found!")
            return
        end

        local steamID64 = result[1].steamid64
        SetPlayerBalance(steamID64, balanceType, amount)

        local targetPlayer = player.GetBySteamID64(steamID64)
        if IsValid(targetPlayer) then
            targetPlayer:SetPlayerBalance(balanceType, amount)
        end

        print(string.format("Updated %s balance for %s to %d", balanceType, result[1].name, amount))
    end)

    concommand.Add("halloween_balance_delete", function(ply, cmd, args)
        if #args < 1 then
            print("Usage: halloween_balance_delete <player_name/steamid64>")
            return
        end

        if not ply:IsSuperAdmin() then
            print("You do not have permission to use this command.")
            return
        end

        local identifier = args[1]
        local result = sql.Query("SELECT steamid64, name FROM player_balances WHERE steamid64 = " .. sql.SQLStr(identifier) .. " OR name LIKE '%" .. identifier .. "%'")

        if not result or #result == 0 then
            print("Player not found!")
            return
        end

        local steamID64 = result[1].steamid64
        DeletePlayerBalance(steamID64)

        print(result[1].name .. "'s balances deleted from the database.")

        local targetPlayer = player.GetBySteamID64(steamID64)
        if IsValid(targetPlayer) then
            targetPlayer:SetPlayerBalance("candycorn", 0)
            targetPlayer:SetPlayerBalance("souls", 0)
        end
    end)

// Net Messages //

    net.Receive("SystemModifyBalance", function(len, ply)
        local balanceType = net.ReadString()
        local amount = net.ReadInt(32)

        ply:ModifyPlayerBalance(balanceType, amount)
        print("[INFO] Modified " .. balanceType .. " for " .. ply:Nick() .. " by " .. amount)
    end)

    net.Receive("RequestPlayerSouls", function(len, ply)
        local souls = ply:GetPlayerBalance("souls")
        net.Start("UpdatePlayerSouls")
        net.WriteInt(souls, 32)
        net.Send(ply)
    end)

    net.Receive("RequestLeaderboard", function(len, ply)
        local leaderboard = GetLeaderboardData()
        
        net.Start("SendLeaderboard")
        net.WriteUInt(#leaderboard, 16)
        
        for _, playerData in ipairs(leaderboard) do
            net.WriteString(playerData.name)
            net.WriteString(playerData.steamid64)
            net.WriteUInt(playerData.candycorn, 32)
            net.WriteUInt(playerData.souls, 32)
        end
        
        net.Send(ply)
    end)

    net.Receive("RequestCandycornDeduction", function(len, ply)
        local cost = net.ReadInt(32)
        local currentBalance = ply:GetPlayerBalance("candycorn")
        
        if currentBalance >= cost then
            ply:ModifyPlayerBalance("candycorn", -cost)
            local newBalance = ply:GetPlayerBalance("candycorn")
    
            net.Start("RequestCandycornDeduction")
            net.WriteBool(true)
            net.WriteInt(newBalance, 32)
            net.Send(ply)
        else
            net.Start("RequestCandycornDeduction")
            net.WriteBool(false)
            net.Send(ply)
        end
    end)

    MsgC(Color(57, 100, 245), "[HalloweenEvent] ", color_white, "balances core loaded\n")
end
