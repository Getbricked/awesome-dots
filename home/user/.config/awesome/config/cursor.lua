local awful = require("awful")

awful.spawn("xrdb -merge ~/.Xresources", false)
screen.connect_signal("property::geometry", function()
    awful.spawn("xsetroot -cursor_name left_ptr", false)
end)
awful.spawn("xsetroot -cursor_name left_ptr", false)
