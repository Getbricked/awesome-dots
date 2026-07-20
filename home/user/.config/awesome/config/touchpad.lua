local awful = require("awful")

local function find_touchpad_id()
    local handle = io.popen("xinput list --id-only 'pointer:SYNA329D:00 06CB:CE14 Touchpad' 2>/dev/null")
    local result = handle:read("*a")
    handle:close()
    return tonumber(result)
end

local function enable_natural_scrolling()
    local id = find_touchpad_id()
    if not id then return end
    awful.spawn.with_shell("xinput set-prop " .. id .. " 311 1")
end

local function reduce_scroll_speed()
    local id = find_touchpad_id()
    if not id then return end
    awful.spawn.with_shell("xinput set-prop " .. id .. " 342 30")
end

awesome.connect_signal("startup", function()
    enable_natural_scrolling()
    reduce_scroll_speed()
end)
