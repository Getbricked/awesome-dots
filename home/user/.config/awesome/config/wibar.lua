local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local font = "JetBrainsMono semi-bold 11"

local powerdaemon = require("config.powerdaemon")
local battery = require("config.battery")

local mytextclock = wibox.widget.textclock()

local volume_widget = wibox.widget.textbox()
volume_widget.font = font

local vol_icons = { "󰕿", "󰖀", "󰕾", "󰝟" }

local function update_volume()
	awful.spawn.easy_async(
		"pactl get-sink-volume @DEFAULT_SINK@ && pactl get-sink-mute @DEFAULT_SINK@",
		function(stdout)
			local vol = tonumber(stdout:match("Volume:.-(%d+)%%"))
			local muted = stdout:match("Mute: yes")
			if not vol then
				vol = 0
			end
			local icon
			if muted then
				icon = vol_icons[4]
			elseif vol >= 66 then
				icon = vol_icons[3]
			elseif vol >= 33 then
				icon = vol_icons[2]
			else
				icon = vol_icons[1]
			end
			volume_widget:set_markup(icon .. " " .. vol .. "% ")
		end
	)
end

volume_widget:connect_signal("button::press", function(_, _, _, button)
	if button == 1 then
		awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle", false)
		update_volume()
	elseif button == 4 then
		awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%", false)
		update_volume()
	elseif button == 5 then
		awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%", false)
		update_volume()
	end
end)

gears.timer({
	timeout = 1.5,
	autostart = true,
	single_shot = false,
	callback = update_volume,
})

awesome.connect_signal("widget::volume", update_volume)

update_volume()
beautiful.tasklist_font = font
beautiful.taglist_font = font
mytextclock.font = font
powerdaemon.font = font
battery.font = font

screen.connect_signal("request::desktop_decoration", function(s)
	awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.suit.tile)

	s.mypromptbox = awful.widget.prompt()

	s.mylayoutbox = awful.widget.layoutbox({
		screen = s,
		buttons = {
			awful.button({}, 1, function()
				awful.layout.inc(1)
			end),
			awful.button({}, 3, function()
				awful.layout.inc(-1)
			end),
			awful.button({}, 4, function()
				awful.layout.inc(-1)
			end),
			awful.button({}, 5, function()
				awful.layout.inc(1)
			end),
		},
	})

	s.mytaglist = awful.widget.taglist({
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = {
			awful.button({}, 1, function(t)
				t:view_only()
			end),
			awful.button({ modkey }, 1, function(t)
				if client.focus then
					client.focus:move_to_tag(t)
				end
			end),
			awful.button({}, 3, awful.tag.viewtoggle),
			awful.button({ modkey }, 3, function(t)
				if client.focus then
					client.focus:toggle_tag(t)
				end
			end),
			awful.button({}, 4, function(t)
				awful.tag.viewprev(t.screen)
			end),
			awful.button({}, 5, function(t)
				awful.tag.viewnext(t.screen)
			end),
		},
	})

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
