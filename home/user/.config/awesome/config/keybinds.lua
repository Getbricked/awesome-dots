local awful = require("awful")
local key = require("awful.key")
local button = require("awful.button")
local keyboard = require("awful.keyboard")
local tag = require("awful.tag")
local screen = require("awful.screen")
local spawn = require("awful.spawn")
local gears = require("gears")
local settings = require("config.settings")

local super = "Mod4"
local alt = "Mod1"
local ctrl = "Control"
local shift = "Shift"

local lockscreen = require("config.lockscreen")
local nightmode = os.getenv("HOME") .. "/.config/awesome/config/.nightmode"

awful.mouse.append_global_mousebindings({
	button({}, 3, function()
		spawn("rofi -show drun")
	end),
	button({}, 4, tag.viewprev),
	button({}, 5, tag.viewnext),
})

keyboard.append_global_keybindings({

	key({ super, ctrl }, "r", awesome.restart),

	key({ super }, "Return", function()
		spawn(settings.terminal)
	end),

	key({ super }, "l", function()
		lockscreen.show()
	end),

	key({ super }, "d", function()
		spawn("rofi -show drun")
	end),

	key({ super, alt }, "v", function()
		spawn.with_shell("CM_LAUNCHER=rofi clipmenu")
	end),

	key({ super }, "v", function()
		spawn("env GTK_THEME=Flat-Remix-GTK-Blue-Dark pavucontrol")
	end),

	key({ super }, "n", function()
		local is_on = false

		local f_read = io.open(nightmode, "r")
		if f_read then
			local content = f_read:read("*all")
			is_on = content and content:match("true")
			f_read:close()
		end

		local f_write = io.open(nightmode, "w")

		if is_on then
			spawn("redshift -x", false)
			if f_write then
				f_write:write("false")
				f_write:close()
			end
		else
			spawn("redshift -O 4500", false)
			if f_write then
				f_write:write("true")
				f_write:close()
			end
		end
	end),

	key({ super }, "e", function()
		spawn("thunar")
	end),

	key({ super }, "b", function()
		spawn("xdg-open https://about:blank")
	end),

	key({ super, ctrl }, "q", awesome.quit),

	key({}, "XF86MonBrightnessUp", function()
		spawn("brightnessctl s +10%")
	end),

	key({}, "XF86MonBrightnessDown", function()
		spawn("brightnessctl s 10%-")
	end),

	key({}, "XF86AudioRaiseVolume", function()
		spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%", false)
		awesome.emit_signal("widget::volume")
	end),

	key({}, "XF86AudioLowerVolume", function()
		spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%", false)
		awesome.emit_signal("widget::volume")
	end),

	key({}, "XF86AudioMute", function()
		spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle", false)
		awesome.emit_signal("widget::volume")
	end),

	key({}, "XF86AudioMicMute", function()
		spawn("pactl set-source-mute @DEFAULT_SOURCE@ toggle", false)
		awesome.emit_signal("widget::volume")
	end),

	key({}, "XF86AudioPlay", function()
		spawn("playerctl play-pause", false)
	end),

	key({}, "XF86AudioPrev", function()
		spawn("playerctl previous", false)
	end),

	key({}, "XF86AudioNext", function()
		spawn("playerctl next", false)
	end),

	key({}, "XF86AudioStop", function()
		spawn("playerctl stop", false)
	end),

	key({}, "XF86TouchpadToggle", function()
		spawn.with_shell("xinput set-prop $(xinput list --id-only 'pointer:SYNA329D:00 06CB:CE14 Touchpad') 325 0")
	end),

	key({}, "XF86WLAN", function()
		spawn("nmcli radio wifi toggle", false)
	end),

	key({}, "XF86Bluetooth", function()
		spawn.with_shell("bluetoothctl power off && sleep 1 && bluetoothctl power on")
	end),

	key({}, "XF86Sleep", function()
		spawn("systemctl suspend", false)
	end),

	key({ super, shift }, "s", function()
		spawn.with_shell("systemctl --user stop clipmenud.service")
		local ss = awful.screenshot({
			interactive = true,
			directory = "/tmp",
		})

		ss:connect_signal("file::saved", function(_, file_path)
			spawn.with_shell(
				"xclip -selection clipboard -t image/png -i '" .. file_path .. "' && rm '" .. file_path .. "'"
			)

			gears.timer.start_new(1, function()
				spawn.with_shell("systemctl --user start clipmenud.service")
				return false
			end)
		end)

		ss:connect_signal("snipping::cancelled", function()
			spawn.with_shell("systemctl --user start clipmenud.service")
		end)

		ss:refresh()
	end),

	key({ super }, "Escape", tag.history.restore),
	key({ alt }, "Tab", function()
		local s = screen.focused()
		local tags = s.tags
		local active = {}
		for _, t in ipairs(tags) do
			if #t:clients() > 0 then
				table.insert(active, t)
			end
		end
		if #active == 0 then
			return
		end
		local cur = s.selected_tag
		for i, t in ipairs(active) do
			if t == cur then
				local next = active[i % #active + 1]
				next:view_only()
				return
			end
		end
		active[1]:view_only()
	end),

	key({ super }, "Tab", function()
		awful.client.focus.history.previous()
		if client.focus then
			client.focus:raise()
		end
	end),

	key({ super }, "Left", function()
		awful.client.focus.global_bydirection("left")
		if client.focus then
			client.focus:raise()
		end
	end),

	key({ super }, "Right", function()
		awful.client.focus.global_bydirection("right")
		if client.focus then
			client.focus:raise()
		end
	end),

	key({ super }, "Up", function()
		awful.client.focus.global_bydirection("up")
		if client.focus then
			client.focus:raise()
		end
	end),

	key({ super }, "Down", function()
		awful.client.focus.global_bydirection("down")
		if client.focus then
			client.focus:raise()
		end
	end),

	key({ super }, "space", function()
		local c = client.focus
		if c and c.valid then
			c.floating = not c.floating

			if c.floating then
				awful.placement.centered(c, { honor_workarea = true })
			end
		end
	end),

	key({ super, shift }, "space", function()
		awful.layout.inc(1)
	end),
})

local function move_window_directional(dir, swap)
	local c = client.focus
	if not c or not c.valid then
		return
	end

	awful.client.focus.bydirection(dir, c)
	local target = client.focus

	if target and target ~= c then
		c:swap(target)
		client.focus = c
		c:raise()
		return
	end

	local scr = c.screen
	screen.focus_bydirection(dir, scr)
	local new_scr = screen.focused()
	if new_scr and new_scr ~= scr then
		if swap then
			local tag = new_scr.selected_tag
			local others = tag:clients()
			if #others > 0 then
				local other = others[1]
				local c_screen = c.screen
				c:move_to_screen(other.screen)
				other:move_to_screen(c_screen)
				client.focus = c
				c:raise()
			else
				c:move_to_tag(tag)
				client.focus = c
				c:raise()
			end
		else
			c:move_to_tag(new_scr.selected_tag)
			client.focus = c
			c:raise()
		end
	end
end

keyboard.append_global_keybindings({
	key({ super, shift }, "Left", function()
		local c = client.focus
		if c and c.valid and c.floating then
			c:relative_move(30, 0, -60, 0)
		else
			tag.incmwfact(-0.05)
		end
	end),

	key({ super, shift }, "Right", function()
		local c = client.focus
		if c and c.valid and c.floating then
			c:relative_move(-30, 0, 60, 0)
		else
			tag.incmwfact(0.05)
		end
	end),

	key({ super, shift }, "Up", function()
		local c = client.focus
		if c and c.valid and c.floating then
			c:relative_move(0, 30, 0, -60)
		else
			tag.incnmaster(1, nil, true)
		end
	end),

	key({ super, shift }, "Down", function()
		local c = client.focus
		if c and c.valid and c.floating then
			c:relative_move(0, -30, 0, 60)
		else
			tag.incnmaster(-1, nil, true)
		end
	end),

	key({ super, alt }, "Left", function()
		move_window_directional("left", true)
	end),

	key({ super, alt }, "Right", function()
		move_window_directional("right", true)
	end),

	key({ super, ctrl }, "Left", function()
		move_window_directional("left")
	end),

	key({ super, ctrl }, "Right", function()
		move_window_directional("right")
	end),

	key({
		modifiers = { super },
		keygroup = "numrow",
		on_press = function(index)
			local s = screen.focused()
			local tag = s.tags[index]
			if tag then
				tag:view_only()
				local c = tag:clients()[1]
				if c then
					client.focus = c
					c:raise()
				end
			end
		end,
	}),
	key({
		modifiers = { super, ctrl },
		keygroup = "numrow",
		on_press = function(index)
			local s = screen.focused()
			local tag = s.tags[index]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end,
	}),
	key({
		modifiers = { super, shift },
		keygroup = "numrow",
		on_press = function(index)
			if client.focus then
				local tag = client.focus.screen.tags[index]
				if tag then
					client.focus:move_to_tag(tag)
					tag:view_only()
				end
			end
		end,
	}),
	key({
		modifiers = { super, ctrl, shift },
		keygroup = "numrow",
		on_press = function(index)
			if client.focus then
				local tag = client.focus.screen.tags[index]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end,
	}),
	key({
		modifiers = { super },
		keygroup = "numpad",
		on_press = function(index)
			local t = screen.focused().selected_tag
			if t then
				t.layout = t.layouts[index] or t.layout
			end
		end,
	}),
})

client.connect_signal("request::default_mousebindings", function()
	awful.mouse.append_client_mousebindings({
		button({}, 1, function(c)
			c:activate({ context = "mouse_click" })
		end),
		button({ super }, 1, function(c)
			if c.maximized then
				c.maximized = false
				c.maximized_vertical = false
				c.maximized_horizontal = false
			end
			if not c.floating then
				c._was_tiled = true
				local geo = c:geometry()
				c.floating = true
				c:geometry(geo)
			end
			c._drag_start = mouse.coords()
			c:activate({ context = "mouse_click" })
			awful.mouse.client.move(c)
		end),
		button({ super }, 3, function(c)
			c:activate({ context = "mouse_click" })
			awful.mouse.client.resize(c)
		end),
	})
end)

awful.mouse.resize.add_leave_callback(function(c)
	if c._was_tiled then
		c._was_tiled = nil
		local finish = mouse.coords()
		local wa = c.screen and c.screen.workarea
		if wa then
			local midpoint = wa.x + wa.width / 2
			if finish.x < midpoint then
				c:to_primary_section()
			else
				c:to_secondary_section()
			end
		end
		c.floating = false
	end
end, "mouse.move")

client.connect_signal("request::default_keybindings", function()
	keyboard.append_client_keybindings({
		key({ super }, "f", function(c)
			c.maximized = not c.maximized
			c:raise()
		end),

		key({ super, shift }, "f", function(c)
			c.fullscreen = not c.fullscreen
			c:raise()
		end),

		key({ super }, "q", function(c)
			c:kill()
		end),

		key({ super, shift }, "q", function()
			local c = client.focus
			if c and c.valid and c.pid then
				spawn("kill -9 " .. c.pid)
			end
		end),
	})
end)
