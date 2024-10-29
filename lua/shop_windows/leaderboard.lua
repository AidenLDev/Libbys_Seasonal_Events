local gradient = Material("gui/gradient_up")
local currentWindow

local function PrintDebug(message)
    print("[HalloweenEvent - leaderboard] " .. message)
end

function OpenWindow(contentPanel)
    if IsValid(currentWindow) then
        currentWindow:Remove()
    end

    contentPanel:Clear()

    contentPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
    end

    currentWindow = contentPanel

    PrintDebug("Requesting leaderboard from server")
    net.Start("RequestLeaderboard")
    net.SendToServer()

    local top10Color = Color(34, 153, 111)
    local top3rdColor = Color(189, 98, 14)
    local top2ndColor = Color(92, 165, 170)
    local top1stColor = Color(231, 211, 24)

    local leaderboardPanel = vgui.Create("DPanel", contentPanel)
    leaderboardPanel:Dock(FILL)
    leaderboardPanel:SetPaintBackground(false)

    local scrollPanel = vgui.Create("DScrollPanel", leaderboardPanel)
    scrollPanel:Dock(FILL)
    scrollPanel:DockMargin(10, 10, 10, 10)

    local sbar = scrollPanel:GetVBar()
    sbar:SetWide(6)

    sbar.Paint = function(self, w, h)
        surface.SetDrawColor(top10Color)
        surface.DrawRect(0, 0, w, 2)
        surface.DrawRect(0, h - 2, w, 2)
    end

    sbar.btnUp.Paint = function(self, w, h) end
    sbar.btnDown.Paint = function(self, w, h) end

    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, top10Color)
    end

    local function GetRowColor(rank)
        if rank == 1 then
            return top1stColor
        elseif rank == 2 then
            return top2ndColor
        elseif rank == 3 then
            return top3rdColor
        else
            return top10Color
        end
    end

    local function GetScaledFont(name, maxWidth)
        surface.SetFont("ScaledShopBodyFont")
        local textWidth, _ = surface.GetTextSize(name)
    
        if textWidth > maxWidth then // This barely works
            local scaleFactor = maxWidth / textWidth
            local scaledSize = math.max(12, 20 * scaleFactor)
            local scaledFontName = "ScaledFont_" .. math.floor(scaledSize)
    
            if not surface.CreateFont then return "ScaledShopBodyFont" end
    
            surface.CreateFont(scaledFontName, {
                font = "Arial",
                size = scaledSize,
                weight = 500
            })
    
            return scaledFontName
        end
    
        return "ScaledShopBodyFont"
    end    

    local function AddLeaderboardRow(parent, rank, name, steamID, candycorn, souls)

        local row = vgui.Create("DPanel", parent)
        row:SetTall(35)
        row:Dock(TOP)
        row:DockMargin(5, 5, 5, 5)
        row:SetPaintBackground(false)

        local rowColor = GetRowColor(rank)
        row.fontCache = GetScaledFont(name, 150)

        row.Paint = function(self, w, h)
            surface.SetDrawColor(rowColor.r, rowColor.g, rowColor.b, 55)
            surface.SetMaterial(gradient)
            surface.DrawTexturedRect(0, 0, w, h)
            surface.SetDrawColor(rowColor)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        local rankLabel = vgui.Create("DPanel", row)
        rankLabel:SetWide(50)
        rankLabel:Dock(LEFT)
        rankLabel.Paint = function(self, w, h)
            draw.SimpleText(tostring(rank), "ScaledShopBodyFont", w / 2, h / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleTextOutlined(tostring(rank), "ScaledShopBodyFont", w / 2, h / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, rowColor)
        end

        local nameLabel = vgui.Create("DPanel", row)
        nameLabel:SetWide(150)
        nameLabel:Dock(LEFT)
        nameLabel.Paint = function(self, w, h)
            local font = GetScaledFont(name, w)
            surface.SetFont(font)
        
            local textWidth = surface.GetTextSize(name)
        
            if textWidth > w - 10 then // Wanted name scaler to work. Gave up and used this
                for i = #name, 1, -1 do
                    local clippedName = string.sub(name, 1, i) .. "..."
                    textWidth = surface.GetTextSize(clippedName)
                    if textWidth <= w - 10 then
                        name = clippedName
                        break
                    end
                end
            end
        
            draw.SimpleText(name, font, 5, h / 2, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
            draw.SimpleTextOutlined(name, font, 5, h / 2, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, rowColor)
        end                  

        local button = vgui.Create("DButton", nameLabel)
        button:SetSize(150, 35)
        button:SetText("")
        button:SetPaintBackground(false)
        button.DoClick = function()
            PrintDebug("Opening Steam profile for " .. name)
            gui.OpenURL("https://steamcommunity.com/profiles/" .. steamID)
        end

        local soulsPanel = vgui.Create("DPanel", row)
        soulsPanel:SetWide(140)
        soulsPanel:Dock(LEFT)
        soulsPanel:SetPaintBackground(false)
        soulsPanel.Paint = function(self, w, h)
            local text = "Souls: " .. tostring(souls)
            draw.SimpleText(text, "ScaledShopBodyFont", 5, h / 2, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleTextOutlined(text, "ScaledShopBodyFont", 5, h / 2, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, rowColor)
        end

        local candyPanel = vgui.Create("DPanel", row)
        candyPanel:SetWide(200)
        candyPanel:Dock(LEFT)
        candyPanel:SetPaintBackground(false)
        candyPanel.Paint = function(self, w, h)
            local text = "Candy Corn: " .. tostring(candycorn)
            draw.SimpleText(text, "ScaledShopBodyFont", 5, h / 2, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleTextOutlined(text, "ScaledShopBodyFont", 5, h / 2, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, rowColor)
        end
    end

    net.Receive("SendLeaderboard", function() // Bots have a chance to get in here as Unknown. Don't care
        local leaderboardSize = net.ReadUInt(16)
        PrintDebug("Received leaderboard data with " .. leaderboardSize .. " entries")

        scrollPanel:Clear()

        for i = 1, leaderboardSize do
            local name = net.ReadString()
            local steamID = net.ReadString()
            local candycorn = net.ReadUInt(32)
            local souls = net.ReadUInt(32)

            AddLeaderboardRow(scrollPanel, i, name, steamID, candycorn, souls)
        end
    end)
end
