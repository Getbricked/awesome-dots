local awful = require("awful")

awful.layout.layouts = {
	awful.layout.suit.tile,
	awful.layout.suit.floating,
}

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

client.connect_signal("tagged", function(c, t)
	reset_master_width(t)
end)
client.connect_signal("untagged", function(c, t)
	reset_master_width(t)
end)
client.connect_signal("request::manage", awful.client.setslave)
