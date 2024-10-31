AddCSLuaFile("shop_windows/leaderboard.lua")
AddCSLuaFile("shop_windows/upgrades.lua")

util.AddNetworkString("OpenShopMenu")
util.AddNetworkString("CheckBalance")
util.AddNetworkString("ReturnBalance")
util.AddNetworkString("CloseShopMenu")
util.AddNetworkString("RequestLeaderboard")
util.AddNetworkString("SendLeaderboard")

local leaderboardData = {}
local cachedLeaderboard = {}
local shopCommandCooldown = {}

// Garbage Collector //

timer.Create("GarbageCollector", 600, 0, function()
    collectgarbage("collect")
end)

// Data updater //

hook.Add("PlayerDisconnected", "StoreDisconnectedPlayerData", function(ply)
    leaderboardData[ply:SteamID()] = {
        name = ply:Nick(),
        candycorn = ply:GetNWInt("CandyCorn", 0),
        souls = ply:GetNWInt("Souls", 0)
    }
end)

hook.Add("Think", "UpdateConnectedPlayersData", function()
    for _, ply in pairs(player.GetAll()) do
        leaderboardData[ply:SteamID()] = {
            name = ply:Nick(),
            candycorn = ply:GetNWInt("CandyCorn", 0),
            souls = ply:GetNWInt("Souls", 0)
        }
    end
end)

// Leaderboard Data Sender //

net.Receive("RequestLeaderboard", function(_, ply)
    if #cachedLeaderboard > 0 then
        net.Start("SendLeaderboard")
        net.WriteUInt(#cachedLeaderboard, 16)

        for _, data in ipairs(cachedLeaderboard) do
            net.WriteString(data.name)
            net.WriteUInt(data.candycorn, 32)
            net.WriteUInt(data.souls, 32)
        end

        net.Send(ply)
    else
        net.Start("SendLeaderboard")
        net.WriteUInt(table.Count(leaderboardData), 16)

        for _, data in pairs(leaderboardData) do
            net.WriteString(data.name)
            net.WriteUInt(data.candycorn, 32)
            net.WriteUInt(data.souls, 32)
        end

        net.Send(ply)
    end
end)

// Chat commands //

hook.Add("PlayerSay", "OpenShopCommand", function(ply, text)
    if string.lower(text) == "!shop" then
        if shopCommandCooldown[ply:SteamID()] and CurTime() - shopCommandCooldown[ply:SteamID()] < 3 then
            return ""
        end

        net.Start("OpenShopMenu")
        net.Send(ply)
        shopCommandCooldown[ply:SteamID()] = CurTime()

        return ""
    end
end)

concommand.Add("shop", function(ply)
    net.Start("OpenShopMenu")
    net.Send(ply)
end)

net.Receive("CheckBalance", function(_, ply)
    local candycorn = ply:GetNWInt("CandyCorn", 0)
    local souls = ply:GetNWInt("Souls", 0)

    net.Start("ReturnBalance")
    net.WriteInt(candycorn, 32)
    net.WriteInt(souls, 32)
    net.Send(ply)
end)

MsgC(Color(57, 100, 245), "[HalloweenEvent] ", color_white, "spookshop core loaded\n")
