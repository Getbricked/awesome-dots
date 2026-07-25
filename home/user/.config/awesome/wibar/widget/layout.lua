local awful = require("awful")
local beautiful = require("beautiful")
local theme = require("themes.theme")

beautiful.layout_tile = theme.layout_tile
beautiful.layout_floating = theme.layout_floating

return function(s)
	local layoutbox = awful.widget.layoutbox({
		screen = s,
		buttons = {
			awful.button({}, 1, function()
				awful.layout.inc(1)
			end),
			awful.button({}, 3, function()
				awful.layout.inc(-1)
			end),
			awful.button({}, 4, function()
				awful.layout.inc(-1)
			end),
			awful.button({}, 5, function()
				awful.layout.inc(1)
			end),
		},
	})

	return layoutbox
end
