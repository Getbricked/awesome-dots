local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")

beautiful.border_width = 2
beautiful.border_color_normal = "#000000"
beautiful.border_color_active = "#87CEEB"

local function keep_border_on_maximize(c)
	local function update_border()
		if c.maximized or c.maximized_vertical or c.maximized_horizontal then
			c.border_width = beautiful.border_width
		end
	end
	c:connect_signal("property::maximized", update_border)
	c:connect_signal("property::maximized_vertical", update_border)
	c:connect_signal("property::maximized_horizontal", update_border)
end

client.connect_signal("request::manage", keep_border_on_maximize)

awesome.connect_signal("startup", function()
	gears.timer({
		timeout = 1,
		autostart = true,
		single_shot = true,
		callback = function()
			awful.spawn.with_shell("xset r rate 300 50")
		end,
	})
	awful.spawn("picom --config " .. os.getenv("HOME") .. "/.config/picom/picom.conf", false)
	awful.spawn("fcitx5 -d --replace", false)
	awful.spawn(os.getenv("HOME") .. "/.screenlayout/default.sh")
end)
