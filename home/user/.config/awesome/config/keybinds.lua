local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

awful.mouse.append_global_mousebindings({
	awful.button({}, 3, function()
		awful.spawn("rofi -show drun")
	end),
	awful.button({}, 4, awful.tag.viewprev),
	awful.button({}, 5, awful.tag.viewnext),
})

awful.keyboard.append_global_keybindings({
	awful.key({ modkey }, "h", hotkeys_popup.show_help, { group = "awesome" }),

	awful.key({ modkey, "Control" }, "r", awesome.restart, { group = "awesome" }),

	awful.key({ modkey }, "Return", function()
		awful.spawn(terminal)
	end),

	awful.key({ modkey }, "d", function()
		awful.spawn("rofi -show drun")
	end),

	awful.key({ modkey, "Mod1" }, "v", function()
		awful.spawn.with_shell("CM_LAUNCHER=rofi clipmenu")
	end),

	awful.key({ modkey }, "e", function()
		awful.spawn("thunar")
	end),

	awful.key({ modkey }, "b", function()
		awful.spawn("zen-browser", {
			tag = awful.screen.focused().selected_tag,
		})
	end),

	awful.key({ modkey, "Control" }, "q", awesome.quit, { group = "awesome" }),

	awful.key({}, "XF86MonBrightnessUp", function()
		awful.spawn("brightnessctl s +10%")
	end),

	awful.key({}, "XF86MonBrightnessDown", function()
		awful.spawn("brightnessctl s 10%-")
	end),

	awful.key({}, "XF86AudioRaiseVolume", function()
		awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%", false)
		awesome.emit_signal("widget::volume")
	end),

	awful.key({}, "XF86AudioLowerVolume", function()
		awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%", false)
		awesome.emit_signal("widget::volume")
	end),

	awful.key({}, "XF86AudioMute", function()
		awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle", false)
		awesome.emit_signal("widget::volume")
	end),

	awful.key({}, "XF86AudioMicMute", function()
		awful.spawn("pactl set-source-mute @DEFAULT_SOURCE@ toggle", false)
		awesome.emit_signal("widget::volume")
	end),

	awful.key({}, "XF86AudioMicMute", function()
		awful.spawn("pactl set-source-mute @DEFAULT_SOURCE@ toggle", false)
	end),

	awful.key({}, "XF86AudioPlay", function()
		awful.spawn("playerctl play-pause", false)
	end),

	awful.key({}, "XF86AudioPrev", function()
		awful.spawn("playerctl previous", false)
	end),

	awful.key({}, "XF86AudioNext", function()
		awful.spawn("playerctl next", false)
	end),

	awful.key({}, "XF86AudioStop", function()
		awful.spawn("playerctl stop", false)
	end),

	awful.key({}, "XF86TouchpadToggle", function()
		awful.spawn.with_shell(
			"xinput set-prop $(xinput list --id-only 'pointer:SYNA329D:00 06CB:CE14 Touchpad') 325 0"
		)
	end),

	awful.key({}, "XF86WLAN", function()
		awful.spawn("nmcli radio wifi toggle", false)
	end),

	awful.key({}, "XF86Bluetooth", function()
		awful.spawn.with_shell("bluetoothctl power off && sleep 1 && bluetoothctl power on")
	end),

	awful.key({}, "XF86Sleep", function()
		awful.spawn("systemctl suspend", false)
	end),

	awful.key({ modkey, "Shift" }, "s", function()
		local ss = awful.screenshot({
			interactive = true,
			directory = "/tmp",
		})

		ss:connect_signal("file::saved", function(_, file_path)
			awful.spawn.with_shell(
				"xclip -selection clipboard -t image/png -i '" .. file_path .. "' && rm '" .. file_path .. "'"
			)
		end)

		ss:refresh()
	end),
})

awful.keyboard.append_global_keybindings({
	awful.key({ modkey }, "Escape", awful.tag.history.restore),
	awful.key({ "Mod1" }, "Tab", function()
		local s = awful.screen.focused()
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
})

awful.keyboard.append_global_keybindings({
	awful.key({ modkey }, "Tab", function()
		awful.client.focus.history.previous()
		if client.focus then
			client.focus:raise()
		end
	end),

	awful.key({ modkey }, "Left", function()
		awful.client.focus.global_bydirection("left")
		if client.focus then
			client.focus:raise()
		end
	end),

	awful.key({ modkey }, "Right", function()
		awful.client.focus.global_bydirection("right")
		if client.focus then
			client.focus:raise()
		end
	end),

	awful.key({ modkey }, "Up", function()
		awful.client.focus.global_bydirection("up")
		if client.focus then
			client.focus:raise()
		end
	end),

	awful.key({ modkey }, "Down", function()
		awful.client.focus.global_bydirection("down")
		if client.focus then
			client.focus:raise()
		end
	end),
})

awful.keyboard.append_global_keybindings({
	awful.key({ modkey }, "space", function()
		local c = client.focus
		if c and c.valid then
			c.floating = not c.floating

			if c.floating then
				awful.placement.centered(c, { honor_workarea = true })
			end
		end
	end),

	awful.key({ modkey, "Shift" }, "space", function()
		awful.layout.inc(1)
	end),
})

local function swap_by_direction(dir)
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
	awful.screen.focus_bydirection(dir, scr)
	local new_scr = awful.screen.focused()
	if new_scr and new_scr ~= scr then
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
	end
end

local function move_window_directional(dir)
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
	awful.screen.focus_bydirection(dir, scr)
	local new_scr = awful.screen.focused()
	if new_scr and new_scr ~= scr then
		c:move_to_tag(new_scr.selected_tag)
		client.focus = c
		c:raise()
	end
end

awful.keyboard.append_global_keybindings({
	awful.key({ modkey, "Shift" }, "Left", function()
		local c = client.focus
		if c and c.valid and c.floating then
			c:relative_move(20, 0, -40, 0)
		else
			awful.tag.incmwfact(-0.05)
		end
	end),

	awful.key({ modkey, "Shift" }, "Right", function()
		local c = client.focus
		if c and c.valid and c.floating then
			c:relative_move(-20, 0, 40, 0)
		else
			awful.tag.incmwfact(0.05)
		end
	end),

	awful.key({ modkey, "Shift" }, "Up", function()
		local c = client.focus
		if c and c.valid and c.floating then
			c:relative_move(0, 20, 0, -40)
		else
			awful.tag.incnmaster(1, nil, true)
		end
	end),

	awful.key({ modkey, "Shift" }, "Down", function()
		local c = client.focus
		if c and c.valid and c.floating then
			c:relative_move(0, -20, 0, 40)
		else
			awful.tag.incnmaster(-1, nil, true)
		end
	end),

	awful.key({ modkey, "Mod1" }, "Left", function()
		swap_by_direction("left")
	end),

	awful.key({ modkey, "Mod1" }, "Right", function()
		swap_by_direction("right")
	end),

	awful.key({ modkey, "Control" }, "Left", function()
		move_window_directional("left")
	end),

	awful.key({ modkey, "Control" }, "Right", function()
		move_window_directional("right")
	end),
})

awful.keyboard.append_global_keybindings({
	awful.key({
		modifiers = { modkey },
		keygroup = "numrow",
		group = "tag",
		on_press = function(index)
			local screen = awful.screen.focused()
			local tag = screen.tags[index]
			if tag then
				tag:view_only()
				local c = awful.client.focus.history.get(screen, 0)
				if c and c.valid then
					c:emit_signal("request::activate", "tag.switch", { raise = true })
				end
			end
		end,
	}),
	awful.key({
		modifiers = { modkey, "Control" },
		keygroup = "numrow",
		group = "tag",
		on_press = function(index)
			local screen = awful.screen.focused()
			local tag = screen.tags[index]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end,
	}),
	awful.key({
		modifiers = { modkey, "Shift" },
		keygroup = "numrow",
		group = "tag",
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
	awful.key({
		modifiers = { modkey, "Control", "Shift" },
		keygroup = "numrow",
		group = "tag",
		on_press = function(index)
			if client.focus then
				local tag = client.focus.screen.tags[index]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end,
	}),
	awful.key({
		modifiers = { modkey },
		keygroup = "numpad",
		group = "layout",
		on_press = function(index)
			local t = awful.screen.focused().selected_tag
			if t then
				t.layout = t.layouts[index] or t.layout
			end
		end,
	}),
})

client.connect_signal("request::default_mousebindings", function()
	awful.mouse.append_client_mousebindings({
		awful.button({}, 1, function(c)
			c:activate({ context = "mouse_click" })
		end),
		awful.button({ modkey }, 1, function(c)
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
		awful.button({ modkey }, 3, function(c)
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
	awful.keyboard.append_client_keybindings({
		awful.key({ modkey }, "f", function(c)
			c.maximized = not c.maximized
			c:raise()
		end),

		awful.key({ modkey, "Shift" }, "f", function(c)
			c.fullscreen = not c.fullscreen
			c:raise()
		end),

		awful.key({ modkey }, "q", function(c)
			c:kill()
		end),

		awful.key({ modkey, "Shift" }, "q", function()
			local c = client.focus
			if c and c.valid and c.pid then
				awful.spawn("kill -9 " .. c.pid)
			end
		end),

		awful.key({ modkey }, "v", function()
			awful.spawn.with_shell("GTK_THEME=Flat-Remix-GTK-Blue-Dark pavucontrol")
		end),

	})
end)
