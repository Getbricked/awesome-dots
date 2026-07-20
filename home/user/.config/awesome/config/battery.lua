local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")

local battery_widget = wibox.widget.textbox()

local icons = { "󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹" }

local bat_path
for _, name in ipairs({ "BAT1", "BAT0", "bat1", "bat0", "BAT" }) do
    local f = io.open("/sys/class/power_supply/" .. name .. "/uevent")
    if f then f:close(); bat_path = name; break end
end

local function update_battery()
    if not bat_path then
        battery_widget:set_markup("")
        return
    end
    local f = io.open("/sys/class/power_supply/" .. bat_path .. "/uevent")
    if not f then
        battery_widget:set_markup("")
        return
    end
    local content = f:read("*a")
    f:close()

    local capacity = tonumber(content:match("POWER_SUPPLY_CAPACITY=(%d+)"))
    local status = content:match("POWER_SUPPLY_STATUS=(%w+)")
    if not capacity then
        battery_widget:set_markup("")
        return
    end

    local icon_idx = math.min(math.floor(capacity / 10) + 1, #icons)
    local icon = icons[icon_idx]

    if status == "Charging" then
        battery_widget:set_markup(" " .. capacity .. "%")
    elseif status == "Full" then
        battery_widget:set_markup("󱘖 " .. capacity .. "%")
    else
        battery_widget:set_markup(icon .. " " .. capacity .. "%")
    end
end

update_battery()

gears.timer {
    timeout = 30,
    autostart = true,
    single_shot = false,
    callback = update_battery,
}

return battery_widget
