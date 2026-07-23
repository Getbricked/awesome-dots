local wibox = require("wibox")
local spawn = require("awful.spawn")

local icons = {
	performance = "",
	balanced = "",
	["power-saver"] = "",
}

local profiles = { "performance", "balanced", "power-saver" }

local colors = {
	performance = "#FFA07A",
	balanced = "#FFFACD",
	["power-saver"] = "#90EE90",
}

local ppd_widget = wibox.widget.textbox()

local function update_ppd()
	spawn.easy_async("powerprofilesctl get", function(stdout)
		if not stdout or stdout == "" then
			ppd_widget:set_markup("")
			return
		end
		local profile = stdout:match("^%s*(.-)%s*$")
		local icon = icons[profile] or ""
		local color = colors[profile] or "#FFFFFF"

		ppd_widget:set_markup("<span foreground='" .. color .. "'>" .. icon .. "</span> ")
	end)
end

update_ppd()

spawn.with_line_callback({
	"dbus-monitor",
	"--session",
	"sender=net.hadess.PowerProfiles,type=signal,interface=org.freedesktop.DBus.Properties,member=PropertiesChanged",
}, {
	stdout = function(line)
		if line:match("ActiveProfile") then
			update_ppd()
		end
	end,
})

ppd_widget:connect_signal("button::press", function(_, _, _, button)
	if button ~= 1 then
		return
	end
	spawn.easy_async("powerprofilesctl get", function(stdout)
		local current = stdout:match("^%s*(.-)%s*$")
		local idx
		for i, p in ipairs(profiles) do
			if p == current then
				idx = i
				break
			end
		end
		local next_idx = idx and (idx % #profiles) + 1 or 2
		spawn.easy_async("powerprofilesctl set " .. profiles[next_idx], function()
			update_ppd()
		end)
	end)
end)

return ppd_widget
