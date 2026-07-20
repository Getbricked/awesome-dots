local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")

local icons = {
    performance = "",
    balanced    = "",
    ["power-saver"] = "",
}

local profiles = { "performance", "balanced", "power-saver" }

local ppd_widget = wibox.widget.textbox()

local function update_ppd()
    awful.spawn.easy_async("powerprofilesctl get", function(stdout)
        if not stdout or stdout == "" then
            ppd_widget:set_markup("")
            return
        end
        local profile = stdout:match("^%s*(.-)%s*$")
        ppd_widget:set_markup((icons[profile] or "") .. " ")
    end)
end

update_ppd()

gears.timer {
    timeout = 5,
    autostart = true,
    single_shot = false,
    callback = update_ppd,
}

ppd_widget:connect_signal("button::press", function(_, _, _, button)
    if button ~= 1 then return end
    awful.spawn.easy_async("powerprofilesctl get", function(stdout)
        local current = stdout:match("^%s*(.-)%s*$")
        local idx
        for i, p in ipairs(profiles) do
            if p == current then idx = i; break end
        end
        local next_idx = idx and (idx % #profiles) + 1 or 2
        awful.spawn("powerprofilesctl set " .. profiles[next_idx], false)
        update_ppd()
    end)
end)

return ppd_widget
