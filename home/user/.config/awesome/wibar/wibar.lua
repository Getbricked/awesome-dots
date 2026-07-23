local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local theme = require("themes.theme")
local font = theme.font

local powerdaemon = require("wibar.widget.powerdaemon")
local battery = require("wibar.widget.battery")
local volume_widget = require("wibar.widget.volume")
local create_taglist = require("wibar.widget.tag")

local mytextclock = wibox.widget.textclock()

beautiful.tasklist_font = font
beautiful.taglist_font = font
mytextclock.font = font
powerdaemon.font = font
battery.font = font

screen.connect_signal("request::desktop_decoration", function(s)
	s.mytaglist = create_taglist(s)

	s.mytasklist = awful.widget.tasklist({
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = {
			awful.button({}, 1, function(c)
				c:activate({ context = "tasklist", action = "toggle_minimization" })
			end),
			awful.button({}, 3, function()
				awful.menu.client_list({ theme = { width = 250 } })
			end),
			awful.button({}, 4, function()
				awful.client.focus.byidx(-1)
			end),
			awful.button({}, 5, function()
				awful.client.focus.byidx(1)
			end),
		},
	})

	s.mywibox = awful.wibar({
		position = "top",
		screen = s,
		bg = "transparent",
		margins = {
			left = 10,
			right = 10,
		},
		shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, 8)
		end,
		widget = {
			layout = wibox.layout.stack,
			{
				layout = wibox.layout.align.horizontal,
				{
					layout = wibox.layout.fixed.horizontal,
					powerdaemon,
					s.mytaglist,
				},
				nil,
				{
					layout = wibox.layout.fixed.horizontal,
					volume_widget,
					wibox.widget.systray(),
					battery,
				},
			},
			{
				mytextclock,
				widget = wibox.container.place,
			},
		},
	})
end)
