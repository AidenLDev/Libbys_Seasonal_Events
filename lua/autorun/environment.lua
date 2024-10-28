if SERVER then
    util.AddNetworkString("ConfigureClientFog")

// Environment Cleanser //

	local EnvironmentSounds = {
		["ambient_generic"] = true,
		["env_fire"] = true,
		["env_shake"] = true,
		["env_soundscape_triggerable"] = true,
		["env_soundscape"] = true,
		["env_sun"] = true,
		["env_tonemap_controller"] = true
	}

    local function RemoveAllEnvironmentalSounds()
		for _, Entity in ents.Iterator() do
			if EnvironmentSounds[Entity:GetClass()] then
				Entity:Remove()
			end
		end

		BroadcastLua("RunConsoleCommand(\"stopsound\")")
    end

// Custom Environment //

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
            MsgC(Color(245, 143, 47), "[HalloweenEvent] ", color_white, "night map detected. Custom lighting disabled\n")
        end
    end

    hook.Add("InitPostEntity", "ConfigureEnvironment", function()
        RemoveAllEnvironmentalSounds()
        timer.Simple(1, ConfigureEnvironment) // Removing this causes lighting to fail
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
else

    hook.Add("InitPostEntity", "ConfigureFogOnClient", function()
        net.Start("ConfigureClientFog")
        net.SendToServer()
    end)
end

if CLIENT then
    hook.Add("InitPostEntity", "TestFogDirectlyOnClient", function()
        hook.Add("SetupWorldFog", "HalloweenFogSetupDirect", function()
            render.FogMode(MATERIAL_FOG_LINEAR)
            render.FogStart(0)
            render.FogEnd(11150)
            render.FogMaxDensity(0.75)
            render.FogColor(37, 38, 52)
            return true
        end)

        hook.Add("SetupSkyboxFog", "HalloweenFogSkyboxSetupDirect", function(scale)
            render.FogMode(MATERIAL_FOG_LINEAR)
            render.FogStart(0 * scale)
            render.FogEnd(19750 * scale)
            render.FogMaxDensity(0.85)
            render.FogColor(37, 38, 52)
            return true
        end)
    end)

    net.Receive("ConfigureClientFog", function()
        hook.Add("SetupWorldFog", "HalloweenFogSetup", function()
            render.FogMode(MATERIAL_FOG_LINEAR)
            render.FogStart(0)
            render.FogEnd(11150)
            render.FogMaxDensity(0.75)
            render.FogColor(37, 38, 52)
            return true
        end)

        hook.Add("SetupSkyboxFog", "HalloweenFogSkyboxSetup", function(scale)
            render.FogMode(MATERIAL_FOG_LINEAR)
            render.FogStart(0 * scale)
            render.FogEnd(19750 * scale)
            render.FogMaxDensity(0.85)
            render.FogColor(37, 38, 52)
            return true
        end)
    end)
end
