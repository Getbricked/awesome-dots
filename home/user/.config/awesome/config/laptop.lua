local awful = require("awful")
local naughty = require("naughty")

-- Touchpad
local function find_touchpad_id()
	local handle = io.popen("xinput list --id-only 'pointer:SYNA329D:00 06CB:CE14 Touchpad' 2>/dev/null")
	local result = handle:read("*a")
	handle:close()
	return tonumber(result)
end

local function enable_natural_scrolling()
	local id = find_touchpad_id()
	if not id then
		return
	end
	awful.spawn.with_shell("xinput set-prop " .. id .. " 311 0")
end

local function reduce_scroll_speed()
	local id = find_touchpad_id()
	if not id then
		return
	end
	awful.spawn.with_shell("xinput set-prop " .. id .. " 342 30")
end

-- Brightness notification
local brightness_notification_id = nil

local function update_brightness()
	awful.spawn.easy_async_with_shell("brightnessctl i", function(stdout)
		local level = tonumber(stdout:match("(%d+)%%"))
		if not level then
			return
		end

		local bar_length = 25
		local filled = math.floor((level / 100) * bar_length + 0.5)
		if filled > bar_length then
			filled = bar_length
		end
		if filled < 0 then
			filled = 0
		end
		local bar = string.rep("█", filled) .. string.rep(" ", bar_length - filled)

		local notif = naughty.notify({
			title = "Brightness",
			text = "☀ " .. bar .. " " .. level .. "%",
			timeout = 1.5,
			replaces_id = brightness_notification_id,
		})
		brightness_notification_id = notif.id
	end)
end

awesome.connect_signal("startup", function()
	enable_natural_scrolling()
	reduce_scroll_speed()
end)

awesome.connect_signal("widget::brightness", update_brightness)
