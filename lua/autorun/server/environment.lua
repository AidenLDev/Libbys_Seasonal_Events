util.AddNetworkString("ConfigureClientFog")
AddCSLuaFile("autorun/client/environment.lua")

local HmmrEnvironmentEnts = {
    ["ambient_generic"] = true,
    ["env_fire"] = true,
    ["env_shake"] = true,
    ["env_soundscape_triggerable"] = true,
    ["env_soundscape"] = true,
    ["env_sun"] = true,
    ["env_tonemap_controller"] = true
}    

local function RemoveAllEnvironmentalSounds()
    for _, Entity in ipairs(ents.GetAll()) do
        if HmmrEnvironmentEnts[Entity:GetClass()] then
            Entity:Remove()
        end
    end
    BroadcastLua("RunConsoleCommand('stopsound')")
end

local function ConfigureFog()
    net.Start("ConfigureClientFog")
    net.Broadcast()
end

local function ConfigureEnvironment()
    if not string.find(string.lower(game.GetMap()), "night") then
        RunConsoleCommand("Environment_ambientLightLevel", "2")
        RunConsoleCommand("Environment_SunLightLevel", "1")
        ConfigureFog()
        MsgC(Color(57, 100, 245), "[HalloweenEvent] ", color_white, "environment loaded\n")
    else
        MsgC(Color(245, 143, 47), "[HalloweenEvent - environment] ", color_white, "night map detected. Custom lighting disabled\n")
    end
end

hook.Add("InitPostEntity", "ConfigureEnvironment", function()
    RemoveAllEnvironmentalSounds()
    timer.Simple(1, ConfigureEnvironment)
end)

hook.Add("PostCleanupMap", "ResetEnvironmentAfterCleanup", function()
    RemoveAllEnvironmentalSounds()
    timer.Simple(1, ConfigureEnvironment)
end)

hook.Add("Think", "SetCustomSkybox", function()
    if GetConVar("sv_skyname"):GetString() ~= "sky_halloween" then
        RunConsoleCommand("sv_skyname", "sky_halloween")
    end
end)
