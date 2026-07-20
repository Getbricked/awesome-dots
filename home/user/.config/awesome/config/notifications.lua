local awful = require("awful")
local naughty = require("naughty")
local ruled = require("ruled")

ruled.notification.connect_signal('request::rules', function()
    ruled.notification.append_rule {
        rule       = { },
        properties = {
            screen           = awful.screen.preferred,
            position         = "top_middle",
            implicit_timeout = 5,
        }
    }
end)

naughty.connect_signal("request::display", function(n)
    naughty.layout.box { notification = n }
end)
