local beautiful = require("beautiful")
local awful = require("awful")

-- mouse cursor
awful.spawn("xrdb -merge ~/.Xresources", false)

screen.connect_signal("property::geometry", function()
	awful.spawn("xsetroot -cursor_name left_ptr", false)
end)

awful.spawn("xsetroot -cursor_name left_ptr", false)

-- border
beautiful.border_width = 2
beautiful.border_color_normal = "#000000"
beautiful.border_color_active = "#87CEEB"
beautiful.useless_gap = 5
beautiful.gap_single_client = true

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
