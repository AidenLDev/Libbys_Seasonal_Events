net.Receive("PumpkinCollected", function()
    local credits = net.ReadUInt(12)
    chat.AddText(
        Color(245, 126, 47), "◖You collected ",
        Color(255, 196, 137), tostring(credits),
        Color(245, 126, 47), " Social Credits!◗"
    )
end)
