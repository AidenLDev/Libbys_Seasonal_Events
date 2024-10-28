local JoinCues = {
	"sound/libbys/halloween/cues/mcue1.ogg",
	"sound/libbys/halloween/cues/mcue2.ogg",
	"sound/libbys/halloween/cues/mcue3.ogg",
	"sound/libbys/halloween/cues/mcue4.ogg",
	"sound/libbys/halloween/cues/mcue5.ogg"
}

local CueChannelRef

local function CheckForCue()
	if not system.HasFocus() then return end

	timer.Remove("WaitForFocusToPlayCue")

	local CueToPlay = JoinCues[math.random(#JoinCues)]

	sound.PlayFile(CueToPlay, "noplay", function(Channel)
		if not IsValid(Channel) then return end

		CueChannelRef = Channel

		Channel:SetVolume(0.35)
		Channel:Play()
	end)
end

hook.Add("InitPostEntity", "JoinCue", function()
	timer.Create("WaitForFocusToPlayCue", 1, 0, CheckForCue)
end)
