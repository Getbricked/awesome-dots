local gears = require("gears")
local awful = require("awful")
local lockscreen = require("config.lockscreen")

gears.timer({
	timeout = 5,
	autostart = true,
	callback = function()
		awful.spawn.easy_async("xprintidle", function(stdout)
			local idle_ms = tonumber(stdout:match("%d+"))
			if idle_ms and idle_ms >= 600000 then
				lockscreen.show()
			end
		end)
	end,
})
