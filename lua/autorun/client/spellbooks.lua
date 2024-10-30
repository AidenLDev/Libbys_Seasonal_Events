local Config = {
    baseColor = Color(38, 182, 131),
    targetTextSize = 60,
    randomizingTextSize = 45,
    pulse = {
        scale = 1.35,
        duration = 1.2
    },
    rotation = {
        maxSpeed = 6,
        initialSpeed = 0.1,
        slowSpeed = 0.5,
        deceleration = 0.02
    },
    overlay = {
        texture = Material("ui/screen_edgeglow"),
        fadeDuration = 0.5,
        fadeTargetAlpha = 100,
        fadeSpeed = 255 / 0.5,
        fadeDownTime = 0.9,
        holdOpacity = 100,
        fadeInSpeed = 300,
        brightenFactor = 3.0
    },
    spellWheelTexture = Material("effects/hwn_spell_wheel"),
    initialWheelSize = 200,
    finalWheelSize = 300
}

local State = {
    spellNames = {},
    randomizerActive = false,
    finalizedSpell = "",
    lastRandomized = 0,
    fontCache = {},
    pulseStartTime = 0,
    startOpacityTime = 0,
    currentOpacity = 0,
    wheelRotation = 0,
    wheelRotationSpeed = 0,
    overlayAlpha = 0,
    overlayFadingIn = false,
    overlayFadingOut = false,
    overlayFullyVisible = false
}

// Text //

local function CreateDynamicFont(size)
    if not State.fontCache[size] then
        surface.CreateFont("DynamicSpellFont" .. size, {
            font = "Trebuchet24",
            size = size,
            weight = 500,
            antialias = true,
            shadow = false
        })
        State.fontCache[size] = "DynamicSpellFont" .. size
    end
    return State.fontCache[size]
end

local function DrawOutlinedText(text, font, x, y, color, outlineColor, outlineSize)
    for offsetX = -outlineSize, outlineSize do
        for offsetY = -outlineSize, outlineSize do
            if offsetX ~= 0 or offsetY ~= 0 then
                draw.SimpleText(text, font, x + offsetX, y + offsetY, outlineColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end
    draw.SimpleText(text, font, x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

// Spinning Wheel //

local function DrawSpinningWheel(x, y, size, color, rotation)
    surface.SetDrawColor(color)
    surface.SetMaterial(Config.spellWheelTexture)
    surface.DrawTexturedRectRotated(x, y, size or Config.initialWheelSize, size or Config.initialWheelSize, rotation)
end

local function DrawRandomizerUI()
    local screenWidth, screenHeight = ScrW(), ScrH()
    
    if State.randomizerActive then
        if CurTime() - State.lastRandomized > 0.007 then
            State.finalizedSpell = State.spellNames[math.random(#State.spellNames)]
            State.lastRandomized = CurTime()
        end

        local opacityProgress = math.Clamp((CurTime() - State.startOpacityTime) / 2, 0, 1)
        local easedOpacity = 1 - math.pow(1 - opacityProgress, 3)
        State.currentOpacity = Lerp(easedOpacity, 0, 255)
        local wheelColor = Color(Config.baseColor.r, Config.baseColor.g, Config.baseColor.b, Lerp(easedOpacity, 0, 150))

        State.wheelRotationSpeed = Lerp(opacityProgress, Config.rotation.initialSpeed, Config.rotation.maxSpeed)
        State.wheelRotation = (State.wheelRotation + (State.wheelRotationSpeed * FrameTime() * 100)) % 360
        DrawSpinningWheel(screenWidth / 2, screenHeight - 100, Config.initialWheelSize, wheelColor, State.wheelRotation)

        local randomFont = CreateDynamicFont(Config.randomizingTextSize)
        draw.SimpleText(State.finalizedSpell, randomFont, screenWidth / 2, screenHeight - 100, Color(255, 255, 255, State.currentOpacity), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    elseif State.finalizedSpell ~= "" then
        State.wheelRotationSpeed = Lerp(0.02, State.wheelRotationSpeed, Config.rotation.slowSpeed)
        State.wheelRotation = (State.wheelRotation + (State.wheelRotationSpeed * FrameTime() * 100)) % 360

        local pulseProgress = math.Clamp((CurTime() - State.pulseStartTime) / Config.pulse.duration, 0, 1)
        local currentWheelSize = Lerp(pulseProgress, Config.finalWheelSize * Config.pulse.scale, Config.finalWheelSize)
        local currentWheelColor = Color(Config.baseColor.r, Config.baseColor.g, Config.baseColor.b, Lerp(pulseProgress, 255, 150))

        DrawSpinningWheel(screenWidth / 2, screenHeight - 100, currentWheelSize, currentWheelColor, State.wheelRotation)

        local finalizedFont = CreateDynamicFont(Config.targetTextSize)
        DrawOutlinedText(State.finalizedSpell, finalizedFont, screenWidth / 2, screenHeight - 100, Config.baseColor, Color(0, 0, 0, 255), 2)

        draw.SimpleText("Press 'G' to cast spell", "Trebuchet24", screenWidth / 2, screenHeight - 60, Color(192, 192, 192), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

hook.Add("HUDPaint", "SpellbookRandomizerUI", function()
    DrawRandomizerUI()
end)

// Spell Overlay //

hook.Add("HUDPaint", "SpellOverlayHUD", function()
    local player = LocalPlayer()
    if not IsValid(player) then return end

    local overlayActive = player:GetNWBool("SpellOverlay", false)

    if overlayActive then
        if not State.overlayFullyVisible then
            State.overlayAlpha = math.min(State.overlayAlpha + Config.overlay.fadeInSpeed * FrameTime(), Config.overlay.fadeTargetAlpha)
            if State.overlayAlpha >= Config.overlay.fadeTargetAlpha then
                State.overlayFullyVisible = true
            end
        end
    else
        if State.overlayAlpha > 0 then
            State.overlayAlpha = math.max(State.overlayAlpha - Config.overlay.fadeSpeed * FrameTime(), 0)
            if State.overlayAlpha <= 0 then
                State.overlayFullyVisible = false
            end
        end
    end

    if State.overlayAlpha > 0 then
        surface.SetDrawColor(Config.baseColor.r, Config.baseColor.g, Config.baseColor.b, State.overlayAlpha)
        surface.SetMaterial(Config.overlay.texture)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    end
end)

// Net Messages //

net.Receive("StartSpellRandomizer", function()
    State.spellNames = net.ReadTable()
    State.randomizerActive = true
    State.finalizedSpell = ""
    State.lastRandomized = 0
    State.startOpacityTime = CurTime()
    State.wheelRotationSpeed = Config.rotation.initialSpeed

    timer.Simple(2, function()
        State.randomizerActive = false
    end)
end)

net.Receive("FinalizeSpell", function()
    State.finalizedSpell = net.ReadString()
    State.randomizerActive = false
    State.pulseStartTime = CurTime()
end)

net.Receive("ClearSpellUI", function()
    if IsValid(LocalPlayer()) then
        LocalPlayer():SetNWBool("SpellOverlay", false)
    end
    State.randomizerActive = false
    State.finalizedSpell = ""
    State.currentOpacity = 0
end)
