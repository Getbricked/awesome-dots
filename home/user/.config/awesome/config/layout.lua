local awful = require("awful")
local beautiful = require("beautiful")

tag.connect_signal("request::default_layouts", function()
    awful.layout.append_default_layouts({
        awful.layout.suit.tile,
    })
end)

beautiful.useless_gap = 5

for s in screen do
    for _, t in pairs(s.tags) do
        t.master_width_factor = 0.5
    end
end

local function reset_master_width(t)
    if t then
        t.master_width_factor = 0.5
    end
end

client.connect_signal("tagged", function(c, t) reset_master_width(t) end)
client.connect_signal("untagged", function(c, t) reset_master_width(t) end)

beautiful.gap_single_client = true

client.connect_signal("request::manage", awful.client.setslave)
