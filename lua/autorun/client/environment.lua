if CLIENT then
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
end
