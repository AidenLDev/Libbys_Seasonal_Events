if SERVER then
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
end


if CLIENT then

    local buttonScale = 1.0
    local buttonHeight = 120 * buttonScale
    local buttonMargin = 5 * buttonScale
    local buttonTextScale = 24 * buttonScale

    local normalTextColor = Color(128, 0, 128)
    local hoverTextColor = Color(175, 0, 175)
    local outlineColor = Color(0, 0, 0)

    local candyCornColor = Color(245, 126, 47)
    local candyCornAmountColor = Color(255, 196, 137)
    local soulsColor = Color(77, 255, 193)
    local soulsAmountColor = Color(169, 255, 233)
    local whiteColor = Color(255, 255, 255)
    local outlineBalanceColor = Color(62, 0, 104)

    local spacingBetweenGroups = 30 * buttonScale

// Fonts //

    surface.CreateFont("ShopTitleFont", {
        font = "DermaLarge",
        size = 48 * buttonScale,
        weight = 700,
    })

    surface.CreateFont("ShopBodyFont", {
        font = "DermaDefaultBold",
        size = 18 * buttonScale,
        weight = 500,
    })

    surface.CreateFont("ScaledButtonText", {
        font = "DermaDefaultBold",
        size = buttonTextScale,
        weight = 500,
    })

// Spooky Muszak //

    local ambientSound, shopLoop

    local function ClearSounds()
        if IsValid(ambientSound) then
            ambientSound:Stop()
            ambientSound = nil
        end
        if IsValid(shopLoop) then
            shopLoop:Stop()
            shopLoop = nil
        end
    end

    local function FadeInSound(soundObj, targetVolume, duration)
        if not IsValid(soundObj) then return end
        local currentVolume = 0
        local step = targetVolume / (duration / 0.1)

        timer.Create("FadeInSound_" .. tostring(soundObj), 0.1, duration / 0.1, function()
            if IsValid(soundObj) then
                currentVolume = math.min(currentVolume + step, targetVolume)
                soundObj:SetVolume(currentVolume)
            end
        end)
    end

    local function FadeOutSound(soundObj, duration)
        if not IsValid(soundObj) then return end
        local currentVolume = soundObj:GetVolume()
        local step = currentVolume / (duration / 0.1)

        timer.Create("FadeOutSound_" .. tostring(soundObj), 0.1, duration / 0.1, function()
            if IsValid(soundObj) then
                currentVolume = math.max(currentVolume - step, 0)
                soundObj:SetVolume(currentVolume)
                if currentVolume <= 0 then
                    soundObj:Stop()
                end
            end
        end)
    end

    local function StopSounds()
        if IsValid(shopLoop) then
            FadeOutSound(shopLoop, 3)
        end
    end

// Shop Menu //

    local function CreateShopMenu(defaultTab)
        ClearSounds()
        
        local frame = vgui.Create("DFrame")
        frame:SetTitle("")
        frame:SetSize(ScrW() * 0.43, ScrH() * 0.39)
        frame:Center()
        frame:SetDraggable(false)
        frame:MakePopup()
        frame:SetDeleteOnClose(true)
        frame:ShowCloseButton(false)

        local balanceCheckTimer = "BalanceCheck_" .. tostring(LocalPlayer():SteamID())

        sound.PlayFile("sound/ambient/levels/labs/coinslot1.wav", "noplay", function(station)
            if IsValid(station) then
                ambientSound = station
                ambientSound:SetVolume(0.5)
                ambientSound:Play()
            end
        end)

        sound.PlayFile("sound/libbys/halloween/shop_music.wav", "noplay", function(station)
            if IsValid(station) then
                shopLoop = station
                shopLoop:SetVolume(0)
                shopLoop:Play()
                FadeInSound(shopLoop, 0.2, 3)
            end
        end)

        frame.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(Material("ui/shop_overlay_glow"))
            surface.DrawTexturedRect(0, 0, w, h)

            draw.RoundedBox(0, 41, 22, w - 81, h - 63, Color(0, 0, 0, 200))
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(Material("ui/shop_overlay"))
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local exitButton = vgui.Create("DButton", frame)
        exitButton:SetSize(32, 32)
        exitButton:SetPos(frame:GetWide() - 80, 30)
        exitButton:SetText("")
        exitButton.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(Material("ui/shop_exitx"))
            surface.DrawTexturedRect(0, 0, w, h)
        end

        exitButton.DoClick = function()
            frame:Close()
            StopSounds()
            timer.Remove(balanceCheckTimer)
        end

        local balanceLabel = vgui.Create("Panel", frame)
        balanceLabel:SetPos(55, 33)
        balanceLabel:SetSize(300, 50)

        balanceLabel.Paint = function(self, w, h)
            local candycorn = self.candycorn or 0
            local souls = self.souls or 0

            local xPos = 0
            draw.SimpleText("Candy Corn: ", "DermaDefaultBold", xPos, 0, candyCornColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            xPos = xPos + surface.GetTextSize("Candy Corn: ")
            draw.SimpleText(tostring(candycorn), "DermaDefaultBold", xPos, 0, candyCornAmountColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            xPos = xPos + surface.GetTextSize(tostring(candycorn))
            draw.SimpleText(" | ", "DermaDefaultBold", xPos, 0, whiteColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            xPos = xPos + surface.GetTextSize(" | ")
            draw.SimpleText("Souls: ", "DermaDefaultBold", xPos, 0, soulsColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            xPos = xPos + surface.GetTextSize("Souls: ")
            draw.SimpleText(tostring(souls), "DermaDefaultBold", xPos, 0, soulsAmountColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local function RequestBalance()
            net.Start("CheckBalance")
            net.SendToServer()
        end

        net.Receive("ReturnBalance", function()
            local candycorn = net.ReadInt(32)
            local souls = net.ReadInt(32)

            balanceLabel.candycorn = candycorn
            balanceLabel.souls = souls
            balanceLabel:InvalidateLayout()
        end)

        RequestBalance()

        timer.Create(balanceCheckTimer, 2, 0, function()
            if IsValid(frame) then
                RequestBalance()
            else
                timer.Remove(balanceCheckTimer)
            end
        end)

        frame.OnClose = function()
            timer.Remove(balanceCheckTimer)
        end

        local buttonPanel = vgui.Create("DPanel", frame)
        buttonPanel:SetSize(150 * buttonScale, frame:GetTall())
        buttonPanel:Dock(LEFT)
        buttonPanel:DockMargin(40, 0, 0, 0)
        buttonPanel.Paint = function(self, w, h) end
        
        local buttonHolder = vgui.Create("DPanel", buttonPanel)
        buttonHolder:SetTall(buttonHeight * 6 + spacingBetweenGroups)
        buttonHolder:Dock(FILL)
        buttonHolder:DockMargin(0, 45, 0, 0)
        buttonHolder.Paint = function(self, w, h)
        end

        
        local contentPanel = vgui.Create("DPanel", frame)
        contentPanel:SetSize(frame:GetWide() - buttonPanel:GetWide() - 110, frame:GetTall() - 150)
        contentPanel:SetPos(buttonPanel:GetWide() + 50, 65)

        local windowLoaded = false

        function LoadWindowScript(windowName)
            contentPanel:Clear()
            windowLoaded = true

            if file.Exists("lua/shop_windows/" .. windowName .. ".lua", "GAME") then
                include("shop_windows/" .. windowName .. ".lua")
                OpenWindow(contentPanel)
            else
                contentPanel.Paint = function(self, w, h)
                    draw.SimpleText("What have you done.", "ShopBodyFont", w / 2, h / 2, Color(255, 0, 0, 255), TEXT_ALIGN_CENTER)
                end
            end
        end

// Base Window //

        local function WrapText(text, font, maxWidth)
            surface.SetFont(font)
            local words = string.Explode(" ", text)
            local lines = {}
            local currentLine = ""

            for _, word in ipairs(words) do
                local testLine = currentLine == "" and word or currentLine .. " " .. word
                local textWidth, _ = surface.GetTextSize(testLine)

                if textWidth > maxWidth then
                    table.insert(lines, currentLine)
                    currentLine = word
                else
                    currentLine = testLine
                end
            end

            table.insert(lines, currentLine)
            return lines
        end

        local titleScale = 1.3
        local bodyScale = 1.2

        local soulsColor = Color(77, 255, 193)
        local candyCornColor = Color(245, 126, 47)
        local purpleColor = Color(128, 0, 128)

        surface.CreateFont("ScaledShopTitleFont", {
            font = "DermaLarge",
            size = 48 * titleScale,
            weight = 700,
        })

        surface.CreateFont("ScaledShopBodyFont", {
            font = "DermaDefaultBold",
            size = 18 * bodyScale,
            weight = 500,
        })

        local function ShowDefaultContent()
            contentPanel:Clear()
            
            windowLoaded = false
            local playerName = LocalPlayer():Nick()
            local bodyText = "Welcome " .. playerName .. " to Libby's seasonal shop! You can spend your souls on special upgrades and view the leaderboard to see who is at the top! DO IT. SPEND EVERYTHING YOU HAVE... SELL YOUR SOUL"
        
            contentPanel.Paint = function(self, w, h)
                surface.SetFont("ScaledShopTitleFont")
                local soulsWidth = surface.GetTextSize("Souls")
                local fourWidth = surface.GetTextSize("4")
                local stuffWidth = surface.GetTextSize("Stuff")
        
                local spaceBetween = 20
        
                local totalTitleWidth = soulsWidth + fourWidth + stuffWidth + (2 * spaceBetween)
                local titleXPos = (w / 2) - (totalTitleWidth / 2)
        
                draw.SimpleText("Souls", "ScaledShopTitleFont", titleXPos, 20, soulsColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
                titleXPos = titleXPos + soulsWidth + spaceBetween
                draw.SimpleText("4", "ScaledShopTitleFont", titleXPos, 20, purpleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
                titleXPos = titleXPos + fourWidth + spaceBetween
                draw.SimpleText("Stuff", "ScaledShopTitleFont", titleXPos, 20, candyCornColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
                local wrappedText = WrapText(bodyText, "ScaledShopBodyFont", w - 40)
        
                local yOffset = 100
                local _, textHeight = surface.GetTextSize("Test")
        
                for _, line in ipairs(wrappedText) do
                    draw.SimpleText(line, "ScaledShopBodyFont", 20, yOffset, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    yOffset = yOffset + textHeight
                end
            end
        end        
        

        ShowDefaultContent()

        local selectedButton = nil

// Button Panel //

        local function CreateMenuButton(text, windowScriptName)
            local btn = vgui.Create("DButton", buttonHolder)
            btn:SetText(text)
            btn:SetTall(buttonHeight)
            btn:Dock(TOP)
            btn:DockMargin(10, buttonMargin, 10, buttonMargin)
            btn:SetFont("ScaledButtonText")
            btn:SetTextColor(normalTextColor)

            local isSelected = false
            local brightening = false
            local fillColor = normalTextColor

            local function SetSelected()
                selectedButton = btn
                isSelected = true
                btn:SetTextColor(Color(0, 0, 0))
                brightening = true

                timer.Simple(0.05, function()
                    if IsValid(btn) then
                        fillColor = hoverTextColor
                        brightening = false
                    end
                end)
            end

            local function SetDeselected()
                isSelected = false
                fillColor = normalTextColor
                btn:SetTextColor(normalTextColor)
            end

            btn.DoClick = function()
                if isSelected then
                    surface.PlaySound("buttons/lightswitch2.wav")
                    ShowDefaultContent()
                    SetDeselected()

                    if selectedButton == btn then
                        selectedButton = nil
                    end
                else
                    surface.PlaySound("buttons/lightswitch2.wav")
                    LoadWindowScript(windowScriptName)

                    if selectedButton then
                        selectedButton:DoDeselection()
                    end

                    SetSelected()
                end
            end

            btn.DoDeselection = function()
                SetDeselected()
            end

            btn.Paint = function(self, w, h)
                if isSelected then
                    if brightening then
                        surface.SetDrawColor(hoverTextColor.r + 80, hoverTextColor.g + 80, hoverTextColor.b + 80)
                    else
                        surface.SetDrawColor(fillColor)
                    end
                    surface.DrawRect(0, 0, w, h)
                else
                    if self:IsHovered() then
                        self:SetTextColor(hoverTextColor)
                        surface.SetDrawColor(hoverTextColor)
                    else
                        self:SetTextColor(normalTextColor)
                        surface.SetDrawColor(normalTextColor)
                    end
                    surface.DrawOutlinedRect(0, 0, w, h)
                end
            end
        end

        CreateMenuButton("Leaderboard", "leaderboard")

        if defaultTab then
            LoadWindowScript(defaultTab)
        end

        CreateMenuButton("Upgrades", "upgrades")
    end

// Net Messages //

    function RequestLeaderboard()
        net.Start("RequestLeaderboard")
        net.SendToServer()
    end

    net.Receive("SendLeaderboard", function()
        local leaderboardSize = net.ReadUInt(16)
        cachedLeaderboard = {}

        for i = 1, leaderboardSize do
            local name = net.ReadString()
            local candycorn = net.ReadUInt(32)
            local souls = net.ReadUInt(32)
            
            table.insert(cachedLeaderboard, {
                name = name,
                candycorn = candycorn,
                souls = souls
            })

            AddLeaderboardRow(scrollPanel, i, name, candycorn, souls)
        end
    end)

    net.Receive("OpenShopMenu", function()
        CreateShopMenu()
    end)
end

