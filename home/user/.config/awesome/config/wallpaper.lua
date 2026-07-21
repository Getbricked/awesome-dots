local awful = require("awful")
local wibox = require("wibox")
local home = os.getenv("HOME")
local default_wp = home .. "/Pictures/wallpapers/anime-original-girl-looking-away-4k-2u.png"
local wallpapers_by_output = {
	["DP-1"] = default_wp,
	["DP-2"] = default_wp,
	["HDMI-0"] = home .. "/Pictures/wallpapers/yourname.jpg",
}

local function wallpaper_for(s)
	local out = next(s.outputs)
	if out and wallpapers_by_output[out] then
		return wallpapers_by_output[out]
	end
	return default_wp
end

screen.connect_signal("request::wallpaper", function(s)
	awful.wallpaper({
		screen = s,
		widget = {
			{
				image = wallpaper_for(s),
				upscale = true,
				downscale = true,
				widget = wibox.widget.imagebox,
			},
			valign = "center",
			halign = "center",
			tiled = false,
			widget = wibox.container.tile,
		},
	})
end)

return wallpaper_for
