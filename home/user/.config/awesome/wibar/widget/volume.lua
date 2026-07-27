local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local theme = require("themes.theme")

local font = theme.font
local volume_widget = wibox.widget.textbox()
volume_widget.font = font

local mic_widget = wibox.widget.textbox()
mic_widget.font = font

local vol_icons = { "󰕿", "󰖀", "󰕾", "󰝟" }
local mic_icons = { "󰍬", "󰍭" }
local vol_notification_id = nil

local last_vol = -1
local last_muted = nil
local is_first_run = true
local last_mic_muted = nil

local function update_volume()
	awful.spawn.easy_async_with_shell(
		"pactl get-sink-volume @DEFAULT_SINK@ && pactl get-sink-mute @DEFAULT_SINK@",
		function(stdout)
			local vol = tonumber(stdout:match("Volume:.-(%d+)%%"))
			local muted = stdout:match("Mute: yes") and true or false
			if not vol then
				vol = 0
			end

			local icon_markup
			local icon_plain
			if muted then
				icon_markup = "<span foreground='red'>" .. vol_icons[4] .. "</span>"
				icon_plain = vol_icons[4]
			elseif vol >= 66 then
				icon_markup = vol_icons[3]
				icon_plain = vol_icons[3]
			elseif vol >= 33 then
				icon_markup = vol_icons[2]
				icon_plain = vol_icons[2]
			else
				icon_markup = vol_icons[1]
				icon_plain = vol_icons[1]
			end

			volume_widget:set_markup(icon_markup .. " " .. vol .. "% ")

			if is_first_run then
				last_vol = vol
				last_muted = muted
				is_first_run = false
			elseif vol ~= last_vol or muted ~= last_muted then
				local bar_length = 25
				local filled = math.floor((vol / 100) * bar_length + 0.5)
				if filled > bar_length then
					filled = bar_length
				end
				if filled < 0 then
					filled = 0
				end
				local vol_bar = string.rep("█", filled) .. string.rep(" ", bar_length - filled)

				local notif_text = muted and "Speaker muted" or (vol_bar .. " " .. vol .. "%")
				local notif = naughty.notify({
					title = "Volume",
					text = icon_plain .. " " .. notif_text,
					timeout = 1.5,
					replaces_id = vol_notification_id,
				})
				vol_notification_id = notif.id

				last_vol = vol
				last_muted = muted
			end
		end
	)
end

local function update_mic()
	awful.spawn.easy_async_with_shell("pactl get-source-mute @DEFAULT_SOURCE@", function(stdout)
		local muted = stdout:match("Mute: yes") and true or false
		if muted then
			mic_widget:set_markup("<span foreground='red'>" .. mic_icons[2] .. "</span>")
		else
			mic_widget:set_markup(mic_icons[1])
		end

		if last_mic_muted == nil then
			last_mic_muted = muted
		end
	end)
end

mic_widget:connect_signal("button::press", function()
	awful.spawn("pactl set-source-mute @DEFAULT_SOURCE@ toggle")
end)

volume_widget:connect_signal("button::press", function(_, _, _, button)
	if button == 1 then
		awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
	elseif button == 4 then
		awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%")
	elseif button == 5 then
		awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%")
	end
end)

awful.spawn.with_line_callback("pactl subscribe", {
	stdout = function(line)
		if line:match("Event 'change' on sink") then
			update_volume()
		elseif line:match("Event 'change' on source") then
			update_mic()
		end
	end,
})

awesome.connect_signal("widget::volume", update_volume)

update_volume()
update_mic()

local layout = wibox.widget({
	mic_widget,
	volume_widget,
	spacing = 10,
	layout = wibox.layout.fixed.horizontal,
})

return layout
