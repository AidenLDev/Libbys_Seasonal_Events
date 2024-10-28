local overlayEnabled = CreateClientConVar("halloween_filter", "1", true, false, "Enable/Disable the filter")
local brightness = CreateClientConVar("halloween_filter_brightness", "-0.02", true, false, "Adjust the brightness of the filter")

local function AdjustColorMod()
	local scr_w, scr_h = ScrW(), ScrH()
	local brightness_adjustment = brightness:GetFloat()

	if scr_w > 1920 then
		brightness_adjustment = brightness_adjustment * 0.9
	end

	return {
		["$pp_colour_addr"] = 0.05,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0.1,
		["$pp_colour_brightness"] = brightness_adjustment,
		["$pp_colour_contrast"] = 1,
		["$pp_colour_colour"] = 0.9,
		["$pp_colour_mulr"] = 0.1,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0.45
	}
end

hook.Add("RenderScreenspaceEffects", "PurpleTintEffect", function()
	if overlayEnabled:GetBool() then
		DrawColorModify(AdjustColorMod())
	end
end)
