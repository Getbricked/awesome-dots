pcall(require, "luarocks.loader")

require("awful.autofocus")
local beautiful = require("beautiful")
local naughty = require("naughty")

-- error handler
naughty.connect_signal("request::display_error", function(message, startup)
	naughty.notification({
		urgency = "critical",
		title = "Oops, an error happened" .. (startup and " during startup!" or "!"),
		message = message,
	})
end)

require("config.startup")
require("config.wallpaper")
require("config.keybinds")
require("config.touchpad")
require("config.window_rules")
require("config.notifications")
require("wibar.wibar")
beautiful.init("~/.config/awesome/themes/theme.lua")
require("config.system_settings")
require("config.layout")

terminal = "kitty"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

client.connect_signal("mouse::enter", function(c)
	c:activate({ context = "mouse_enter", raise = false })
end)
