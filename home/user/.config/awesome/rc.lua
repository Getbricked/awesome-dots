pcall(require, "luarocks.loader")

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local ruled = require("ruled")

beautiful.init("~/.config/awesome/themes/theme.lua")

terminal = "kitty"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

modkey = "Mod4"

require("config.error_handling")
require("config.cursor")
require("config.system_settings")
require("config.layout")
require("config.wallpaper")
require("config.wibar")
require("config.keybinds")
require("config.touchpad")
require("config.window_rules")
require("config.client_rules")
require("config.notifications")
require("config.sloppy_focus")
