local awful = require("awful")
local naughty = require("naughty")
local xresources = require("beautiful.xresources")
local rnotification = require("ruled.notification")
local dpi = xresources.apply_dpi

rnotification.connect_signal("request::rules", function()
	rnotification.append_rule({
		rule = {},
		properties = {
			screen = awful.screen.preferred,
			position = "top_middle",
			implicit_timeout = 3,
			border_width = dpi(2),
		},
	})

	rnotification.append_rule({
		rule = { urgency = "critical" },
		properties = { bg = "#ff0000", fg = "#ffffff" },
	})
end)

naughty.connect_signal("request::display", function(n)
	naughty.layout.box({ notification = n })
end)
