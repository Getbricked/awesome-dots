local awful = require("awful")
local lockscreen = require("config.lockscreen")
local gears = require("gears")

local function is_idle_inhibited()
	for _, c in ipairs(client.get()) do
		if c.fullscreen or c.maximized then
			return true
		end
	end
	return false
end

local idle_timer = gears.timer({
	timeout = 600,
	autostart = true,
	single_shot = true,
	callback = function()
		if is_idle_inhibited() then
			idle_timer:again()
			return
		end
		lockscreen.show()
	end,
})

local function reset_idle_timer()
	idle_timer:again()
end

client.connect_signal("mouse::move", reset_idle_timer)
client.connect_signal("mouse::press", reset_idle_timer)
client.connect_signal("mouse::release", reset_idle_timer)
client.connect_signal("key::press", reset_idle_timer)
client.connect_signal("key::release", reset_idle_timer)
client.connect_signal("client::focus", reset_idle_timer)
client.connect_signal("focus", reset_idle_timer)
