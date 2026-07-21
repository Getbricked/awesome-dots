local awful = require("awful")
local naughty = require("naughty")
local ruled = require("ruled")
local gears = require("gears")

ruled.notification.connect_signal("request::rules", function()
	ruled.notification.append_rule({
		rule = {},
		properties = {
			screen = awful.screen.preferred,
			position = "top_middle",
			implicit_timeout = 5,
			bg = "#000000",
			--border_width = 2,
			--border_color = "#87CEEB",
			--shape = function(cr, width, height)
			--gears.shape.rounded_rect(cr, width, height, 10)
			--end,
		},
	})
end)

naughty.connect_signal("request::display", function(n)
	naughty.layout.box({ notification = n })
end)
