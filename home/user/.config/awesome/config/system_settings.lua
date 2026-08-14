local beautiful = require("beautiful")
local awful = require("awful")
local theme = require("themes.theme")

-- mouse cursor
awful.spawn("xrdb -merge ~/.Xresources", false)

screen.connect_signal("property::geometry", function()
	awful.spawn("xsetroot -cursor_name left_ptr", false)
end)

awful.spawn("xsetroot -cursor_name left_ptr", false)

-- border
beautiful.border_width = 2
beautiful.border_color_normal = "#000000"
beautiful.border_color_active = theme.focus
beautiful.useless_gap = 8
beautiful.gap_single_client = true
