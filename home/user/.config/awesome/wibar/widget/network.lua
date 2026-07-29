local awful = require("awful")
local wibox = require("wibox")
local theme = require("themes.theme")

local font = theme.font
local network_widget = wibox.widget.textbox()
network_widget.font = font

local wifi_icons = { "󰤯", "󰤟", "󰤢", "󰤥" }
local ethernet_icon = ""
local disconnected_icon = ""

local function get_wifi_info()
	awful.spawn.easy_async_with_shell(
		"nmcli -t -f IN-USE,SSID,SIGNAL dev wifi list 2>/dev/null | grep '^\\*' | head -1",
		function(stdout)
			local ssid, signal = stdout:match("^%*:(.-):(%d+)")
			if ssid and signal then
				local level = tonumber(signal)
				local idx
				if level >= 75 then
					idx = 4
				elseif level >= 50 then
					idx = 3
				elseif level >= 25 then
					idx = 2
				else
					idx = 1
				end
				network_widget:set_markup(wifi_icons[idx] .. " " .. ssid .. " ")
			else
				network_widget:set_markup("<span foreground='red'>" .. disconnected_icon .. " ✕</span> ")
			end
		end
	)
end

local function update_network()
	awful.spawn.easy_async_with_shell(
		"nmcli -t -f TYPE,NAME con show --active 2>/dev/null",
		function(stdout)
			if stdout == "" then
				network_widget:set_markup("<span foreground='red'>" .. disconnected_icon .. " ✕</span> ")
			elseif stdout:match("802%-3%-ethernet") then
				network_widget:set_markup(ethernet_icon .. " ")
			else
				get_wifi_info()
			end
		end
	)
end

network_widget:connect_signal("button::press", function()
	awful.spawn("kitty -e nmtui", false)
end)

awful.spawn.with_line_callback("nmcli monitor", {
	stdout = function(line)
		if line:match(": connected$") or line:match(": disconnected$") then
			update_network()
		end
	end,
})

update_network()

return network_widget
