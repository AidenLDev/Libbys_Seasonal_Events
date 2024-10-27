local currentWindow
local playerSouls = 0
local pulseAlpha = 128
local pulseDirection = 1
local soulUpdateTimer = "PlayerSoulsUpdateTimer"


if SERVER then
    AddCSLuaFile("shared/upgrades_data.lua")
end

include("shared/upgrades_data.lua")

local function LerpColor(t, fromColor, toColor)
    return Color(
        Lerp(t, fromColor.r, toColor.r),
        Lerp(t, fromColor.g, toColor.g),
        Lerp(t, fromColor.b, toColor.b),
        Lerp(t, fromColor.a, toColor.a)
    )
end

local function AnimateBackgroundColor(panel, duration)
    panel.animatedColor = Color(37, 126, 95)
    panel.animationStartTime = CurTime()
    panel.animationDuration = duration
end

local function PaintPanelWithAnimation(panel, w, h, outlineColor)
    if panel.animatedColor and panel.animationStartTime then
        local t = (CurTime() - panel.animationStartTime) / panel.animationDuration
        local currentColor = LerpColor(math.Clamp(t, 0, 1), panel.animatedColor, Color(0, 0, 0, 150))
        surface.SetDrawColor(currentColor)
        surface.DrawRect(0, 0, w, h)
    else
        surface.SetDrawColor(Color(0, 0, 0, 150))
        surface.DrawRect(0, 0, w, h)
    end

    surface.SetDrawColor(outlineColor)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
end

local function PlayUpgradeSound()
    surface.PlaySound("libbys/halloween/upgrade_buy.ogg")
end

local function UpdateAllButtons()
    for _, upgradeData in ipairs(upgrades) do
        if upgradeData.updateButton then
            upgradeData.updateButton()
        end
    end
end

local function GetPlayerSouls()
    return LocalPlayer():GetPlayerBalance("souls")
end


local function RequestPlayerUpgrades()
    net.Start("RequestPlayerUpgrades")
    net.SendToServer()
end

local function RequestPlayerSouls()
    net.Start("RequestPlayerSouls")
    net.SendToServer()
end

net.Receive("SendPlayerUpgrades", function()
    for _, upgrade in ipairs(upgrades) do
        upgrade.currentLevel = 0
        upgrade.displayedLevel = 0
    end

    local count = net.ReadUInt(8)
    for i = 1, count do
        local name = net.ReadString()
        local level = net.ReadUInt(8)

        for _, upgrade in ipairs(upgrades) do
            if upgrade.name == name then
                upgrade.currentLevel = level
                upgrade.displayedLevel = level
                break
            end
        end
    end

    if IsValid(currentWindow) then
        UpdateAllButtons()
    end
end)

net.Receive("SendPlayerSouls", function()
    playerSouls = net.ReadInt(32)
    UpdateAllButtons()
end)

net.Receive("UpdatePlayerUpgrade", function()
    local upgradeName = net.ReadString()
    local newLevel = net.ReadUInt(8)

    for _, upgrade in ipairs(upgrades) do
        if upgrade.name == upgradeName then
            upgrade.currentLevel = newLevel
            upgrade.displayedLevel = newLevel
            PlayUpgradeSound()
            break
        end
    end

    if IsValid(currentWindow) then
        UpdateAllButtons()
    end
end)

net.Receive("UpdatePlayerSouls", function()
    playerSouls = net.ReadInt(32)

    if IsValid(currentWindow) then
        UpdateAllButtons()
    end
end)

local function GetPlayerSouls()
    return playerSouls
end

function OpenWindow(contentPanel)
    if IsValid(currentWindow) then
        currentWindow:Remove()
    end

    contentPanel:Clear()
    currentWindow = contentPanel

    RequestPlayerUpgrades()
    RequestPlayerSouls()

    contentPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
    end

    playerSouls = GetPlayerSouls()
    UpdateAllButtons()

    local gradientMaterial = Material("gui/gradient_up")

    local scrollPanel = vgui.Create("DScrollPanel", contentPanel)
    scrollPanel:Dock(FILL)
    scrollPanel:DockMargin(0, 10, 10, 10)

    local sbar = scrollPanel:GetVBar()
    sbar:SetWide(6)
    sbar.Paint = function(self, w, h)
        surface.SetDrawColor(77, 255, 193)
        surface.DrawRect(0, 0, w, 2)
        surface.DrawRect(0, h - 2, 2, h)
    end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(169, 255, 233))
    end

    timer.Create(soulUpdateTimer, 1, 0, function()
        playerSouls = GetPlayerSouls()
    end)

    contentPanel.OnRemove = function()
        timer.Remove(soulUpdateTimer)
    end

    surface.CreateFont("UpgradeTitle", {
        font = "DermaLarge",
        size = 37,
        weight = 600,
    })

    local function AddUpgrade(parent, upgrade)
        upgrade.currentLevel = upgrade.currentLevel or 0
        upgrade.displayedLevel = upgrade.displayedLevel or upgrade.currentLevel

        local upgradePanel = vgui.Create("DPanel", parent)
        upgradePanel:SetTall(100)
        upgradePanel:Dock(TOP)
        upgradePanel:DockMargin(0, 10, 10, 10)
        upgradePanel:SetPaintBackground(false)

        local outlineColor = Color(77, 255, 193, 255)

        upgradePanel.Paint = function(self, w, h)
            PaintPanelWithAnimation(self, w, h, outlineColor)
        end

        upgradePanel.PaintOver = function(self, w, h)
            local nameText = upgrade.name
            local currentValue = upgrade.valuePerLevel * (upgrade.displayedLevel or 0)
            local infoText = upgrade.displayedLevel == 0 and upgrade.defaultDescription
                or upgrade.unit .. tostring(currentValue) .. upgrade.description

            local x = 10
            local y = 15
            local textColor = Color(77, 255, 193)
            local outlineColor = Color(8, 26, 19)
            local infoTextColor = Color(200, 200, 200)
            local dividerColor = Color(150, 150, 150)

            draw.SimpleTextOutlined(nameText, "UpgradeTitle", x, y, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, outlineColor)
            surface.SetFont("UpgradeTitle")
            local nameWidth = surface.GetTextSize(nameText)
            
            local dividerX = x + nameWidth + 8
            draw.SimpleText("|", "DermaDefaultBold", dividerX, y + 15, dividerColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            local infoX = dividerX + 10
            draw.SimpleText(infoText, "DermaDefaultBold", infoX, y + 15, infoTextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local function UpdateInfuseButton(infuseButton, adjustPanel)
            if not IsValid(infuseButton) or not IsValid(adjustPanel) then return end
            
            local playerSouls = GetPlayerSouls()
            local currentCost = CalculateUpgradeCost(upgrade)
            local soulsShortage = currentCost - playerSouls

            if upgrade.currentLevel >= upgrade.maxLevel then
                if IsValid(infuseButton) then infuseButton:Remove() end
                adjustPanel.Paint = function(self, w, h)
                    surface.SetDrawColor(77, 255, 193, 255)
                    surface.DrawRect(10, 0, w - 10, h)
                    draw.SimpleText("MAX LEVEL REACHED", "DermaDefaultBold", w / 2, h / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            elseif playerSouls >= currentCost then
                infuseButton:SetText("Infuse " .. currentCost .. " souls")
                infuseButton:SetTextColor(Color(221, 221, 221))
                infuseButton.Paint = function(self, w, h)
                    surface.SetDrawColor(77, 255, 193)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    surface.SetDrawColor(77, 255, 193, pulseAlpha * 0.5)
                    surface.SetMaterial(gradientMaterial)
                    surface.DrawTexturedRect(0, 0, w, h)
                end
            else
                infuseButton:SetText("Need " .. soulsShortage .. " souls")
                infuseButton:SetTextColor(Color(116, 116, 116))
                infuseButton.Paint = function(self, w, h)
                    surface.SetDrawColor(128, 128, 128)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
            end

            infuseButton:InvalidateLayout(true)
            infuseButton:InvalidateParent(true)

            if upgrade.currentLevel < upgrade.maxLevel then
                adjustPanel.Paint = function(self, w, h)
                    local step = (w - 170) / upgrade.maxLevel
                    for i = 1, upgrade.maxLevel do
                        if i <= upgrade.displayedLevel then
                            surface.SetDrawColor(77, 255, 193)
                        elseif i == upgrade.displayedLevel + 1 and playerSouls >= currentCost then
                            surface.SetDrawColor(LerpColor(pulseAlpha / 255, Color(56, 56, 56), Color(55, 200, 170)))
                        else
                            surface.SetDrawColor(56, 56, 56)
                        end
                        surface.DrawRect(10 + (i - 1) * step, h / 2 - 2, step - 5, 8)
                    end
                end
            end
        end

        local adjustPanel = vgui.Create("DPanel", upgradePanel)
        adjustPanel:Dock(BOTTOM)
        adjustPanel:SetTall(25)
        adjustPanel:DockMargin(0, 0, 10, 10)

        local infuseButton = vgui.Create("DButton", adjustPanel)
        infuseButton:SetSize(160, 25)
        infuseButton:Dock(RIGHT)
        infuseButton:SetFont("DermaDefaultBold")

        upgrade.updateButton = function()
            UpdateInfuseButton(infuseButton, adjustPanel)
        end

        upgrade.updateButton()

        infuseButton.DoClick = function()
            local currentCost = CalculateUpgradeCost(upgrade)
            local playerSouls = GetPlayerSouls()

            if playerSouls >= currentCost and upgrade.currentLevel < upgrade.maxLevel then
                net.Start("RequestUpgradePurchase")
                net.WriteString(upgrade.name)
                net.SendToServer()
                AnimateBackgroundColor(upgradePanel, 3)
                UpdateAllButtons()
            end
        end
    end

    for _, upgrade in ipairs(upgrades) do
        AddUpgrade(scrollPanel, upgrade)
    end

    timer.Create("PulseUpdateTimer", 0.05, 0, function()
        pulseAlpha = pulseAlpha + pulseDirection * 10
        if pulseAlpha >= 255 then pulseDirection = -1 end
        if pulseAlpha <= 0 then pulseDirection = 1 end
    end)
end
