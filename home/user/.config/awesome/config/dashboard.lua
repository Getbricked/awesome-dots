-- By nhktmdzhg
---@diagnostic disable: undefined-global
local awful = require("awful")
local gears = require("gears")
local palette = require("themes.mocha")
local theme = require("themes.theme")
local wibox = require("wibox")
local lockscreen = require("config.lockscreen")
local popup = require("config.popup")

local dashboard = {}

local dashboard_wibox = nil
local dashboard_visible = false

local avatar_path = os.getenv("HOME") .. "/Pictures/getbrick.png"

local function create_avatar_widget()
	return wibox.widget({
		{
			image = avatar_path,
			resize = true,
			forced_height = 100,
			forced_width = 100,
			widget = wibox.widget.imagebox,
		},
		margins = 20,
		widget = wibox.container.margin,
	})
end

local function create_name_widget()
	return wibox.widget({
		{
			text = "Hello Aki",
			font = "Maple Mono NF CN 18",
			halign = "center",
			widget = wibox.widget.textbox,
		},
		fg = palette.text.hex,
		widget = wibox.container.background,
	})
end

local function create_info_rows()
	return {
		{
			create_avatar_widget(),
			create_name_widget(),
			spacing = 10,
			layout = wibox.layout.fixed.horizontal,
		},
		margins = 20,
		widget = wibox.container.margin,
	}
end

local function create_current_playing()
	local current_widget = wibox.widget({
		{
			font = "Maple Mono NF CN 12",
			widget = wibox.widget.textbox,
			halign = "center",
			valign = "center",
		},
		fg = palette.text.hex,
		widget = wibox.container.background,
	})

	local scroll_container = wibox.container.scroll.horizontal(
		current_widget,
		1,
		400,
		wibox.container.scroll.step_functions.linear_back_and_forth
	)
	scroll_container.timeout = 0.05

	gears.timer({
		timeout = 1,
		autostart = true,
		call_now = true,
		callback = function()
			awful.spawn.easy_async(
				{ "playerctl", "metadata", "--format", "{{ title }} - {{ artist }}" },
				function(stdout)
					local current_song = stdout:gsub("%s+$", "")
					if current_song == "" then
						current_song = "No song playing"
					else
						current_song = "Now Playing: " .. current_song
					end
					if current_widget.widget.text ~= current_song then
						current_widget.widget.text = current_song
						scroll_container:emit_signal("widget::redraw_needed")
					end
				end
			)
		end,
	})

	return scroll_container
end

local function create_media_button(icon, command)
	local button = wibox.widget({
		{
			{
				text = icon,
				font = "JetBrainsMono Nerd Font Mono 16",
				halign = "center",
				widget = wibox.widget.textbox,
			},
			margins = 10,
			widget = wibox.container.margin,
		},
		bg = palette.surface0.hex,
		shape = gears.shape.rounded_rect,
		widget = wibox.container.background,
	})

	-- Click handler
	button:connect_signal("button::press", function(_, _, _, button)
		if button == 1 then
			awful.spawn(command)
		end
	end)

	-- Hover effects
	button:connect_signal("mouse::enter", function()
		button.bg = palette.surface1.hex
	end)

	button:connect_signal("mouse::leave", function()
		button.bg = palette.surface0.hex
	end)

	return button
end

local function create_media_controls()
	return wibox.widget({
		create_media_button("󰒮", { "playerctl", "previous" }),
		create_media_button("󰐎", { "playerctl", "play-pause" }),
		create_media_button("󰒭", { "playerctl", "next" }),
		layout = wibox.layout.flex.horizontal,
		spacing = 8,
	})
end

local function create_control(cfg)
	local muted = false
	local value = 0

	local slider = wibox.widget({
		widget = wibox.widget.slider,
		bar_shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, 3)
		end,
		bar_height = 25,
		bar_color = palette.surface0.hex,
		bar_active_color = theme.focus,
		handle_shape = gears.shape.rectangle,
		handle_color = theme.focus,
		handle_width = 15,
		handle_border_width = 1,
		handle_border_color = theme.focus,
		minimum = cfg.minimum,
		maximum = cfg.maximum,
	})

	local icon = wibox.widget({
		{
			{
				id = "icon_text",
				text = cfg.icon,
				font = "JetBrainsMono Nerd Font Mono 16",
				halign = "center",
				widget = wibox.widget.textbox,
			},
			widget = wibox.container.margin,
			margins = 10,
		},
		id = "icon_bg",
		bg = palette.surface0.hex,
		shape = gears.shape.rounded_rect,
		widget = wibox.container.background,
	})

	local function update_icon()
		icon:get_children_by_id("icon_text")[1].text = cfg.icon_for(value, muted)
	end

	local updating = false
	local function refresh()
		cfg.get(function(result)
			updating = true
			if result.value then
				value = result.value
				slider.value = value
			end
			muted = result.muted or false
			updating = false
			update_icon()
		end)
	end

	gears.timer({
		timeout = 1,
		call_now = true,
		autostart = true,
		callback = refresh,
	})

	slider:connect_signal("property::value", function(_, new_value)
		if updating then
			return
		end
		value = math.floor(new_value)
		cfg.apply(value)
		update_icon()
	end)

	icon:connect_signal("mouse::enter", function()
		icon:get_children_by_id("icon_bg")[1].bg = palette.surface1.hex
	end)

	icon:connect_signal("mouse::leave", function()
		icon:get_children_by_id("icon_bg")[1].bg = palette.surface0.hex
	end)

	icon:connect_signal("button::press", function(_, _, _, button)
		if button == 1 and cfg.toggle then
			cfg.toggle(function()
				muted = not muted
				update_icon()
			end)
		end
	end)

	return wibox.widget({
		icon,
		{
			slider,
			widget = wibox.container.margin,
			margins = 10,
		},
		layout = wibox.layout.fixed.horizontal,
		forced_height = 50,
	})
end

local function create_volume_control()
	return create_control({
		minimum = 0,
		maximum = 150,
		icon = "󰕾",
		get = function(cb)
			awful.spawn.easy_async({ "wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@" }, function(stdout)
				local vol = stdout:match("Volume: ([%d%.]+)")
				cb({
					value = vol and math.floor(tonumber(vol) * 100) or nil,
					muted = stdout:find("%[MUTED%]") ~= nil,
				})
			end)
		end,
		apply = function(v)
			awful.spawn({ "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v .. "%" })
		end,
		toggle = function(cb)
			awful.spawn.easy_async({ "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle" }, cb)
		end,
		icon_for = function(v, m)
			if m or v == 0 then
				return "󰖁"
			elseif v < 30 then
				return ""
			elseif v < 70 then
				return "󰖀"
			else
				return "󰕾"
			end
		end,
	})
end

local function create_brightness_control()
	return create_control({
		minimum = 0,
		maximum = 95,
		icon = "󰃚",
		get = function(cb)
			awful.spawn.easy_async({ "brightnessctl", "i" }, function(stdout)
				local cur = tonumber(stdout:match("Current brightness: (%d+)"))
					or tonumber(stdout:match("brightness: (%d+)"))
				local max = tonumber(stdout:match("Max brightness: (%d+)"))
					or tonumber(stdout:match("max_brightness: (%d+)"))
					or 65535
				cb({ value = cur and max > 0 and math.floor((cur / max) * 100) or nil })
			end)
		end,
		apply = function(v)
			awful.spawn({ "brightnessctl", "set", v .. "%" })
		end,
		icon_for = function(v)
			if v == 0 then
				return "󰃛"
			elseif v < 30 then
				return "󰃞"
			elseif v < 70 then
				return "󰃠"
			else
				return "󰃚"
			end
		end,
	})
end

local function create_round_button(icon, cmd)
	local button = wibox.widget({
		{
			{
				text = icon,
				font = "JetBrainsMono Nerd Font Mono 50",
				halign = "center",
				valign = "center",
				widget = wibox.widget.textbox,
			},
			widget = wibox.container.margin,
			margins = 15,
		},
		id = "button_bg",
		bg = palette.surface0.hex,
		shape = gears.shape.circle,
		widget = wibox.container.background,
		forced_width = 90,
		forced_height = 90,
	})

	button:connect_signal("mouse::enter", function()
		button:get_children_by_id("button_bg")[1].bg = palette.surface1.hex
	end)

	button:connect_signal("mouse::leave", function()
		button:get_children_by_id("button_bg")[1].bg = palette.surface0.hex
	end)

	button:connect_signal("button::press", function(_, _, _, button)
		if button == 1 then
			if type(cmd) == "function" then
				cmd()
			else
				awful.spawn(cmd)
			end
		end
	end)

	return button
end

local function create_power_grid()
	local grid_content = wibox.widget({
		layout = wibox.layout.grid,
		spacing = 10,
		forced_num_cols = 4,
	})

	local btn_lists = {
		create_round_button("", function()
			lockscreen.show()
		end),
		create_round_button("", { "systemctl", "--no-ask-password", "poweroff" }),
		create_round_button("󰜉", { "systemctl", "--no-ask-password", "reboot" }),
		create_round_button(
			"󰍃",
			{ "loginctl", "--no-ask-password", "kill-user", os.getenv("USER"), "--signal=SIGKILL" }
		),
	}

	for _, btn in ipairs(btn_lists) do
		grid_content:add(btn)
	end

	return grid_content
end

function dashboard.create()
	if dashboard_wibox then
		return
	end

	dashboard_wibox = wibox({
		screen = screen.primary,
		width = screen.primary.geometry.width / 2,
		height = 520,
		x = screen.primary.geometry.width / 4,
		y = 30,
		ontop = true,
		visible = false,
		bg = "#000000cc",
		border_width = 2,
		border_color = theme.focus,
		type = "dock",
		shape = gears.shape.rounded_rect,
	})

	dashboard_wibox:setup({
		{
			{
				{
					create_info_rows(),
					halign = "center",
					widget = wibox.container.place,
				},
				{
					create_current_playing(),
					halign = "center",
					widget = wibox.container.place,
				},
				{
					create_media_controls(),
					halign = "center",
					widget = wibox.container.place,
				},
				{
					create_volume_control(),
					halign = "center",
					widget = wibox.container.place,
				},
				{
					create_brightness_control(),
					halign = "center",
					widget = wibox.container.place,
				},
				{
					create_power_grid(),
					halign = "center",
					widget = wibox.container.place,
				},
				spacing = 10,
				layout = wibox.layout.fixed.vertical,
			},
			margins = 20,
			widget = wibox.container.margin,
		},
		valign = "top",
		widget = wibox.container.place,
	})
end

function dashboard.toggle()
	dashboard.create()
	if dashboard_visible then
		dashboard.hide()
	else
		dashboard.show()
	end
end

function dashboard.show()
	dashboard.create()
	if dashboard_wibox then
		popup.show(dashboard_wibox, dashboard.hide)
		dashboard_visible = true
	end
end

function dashboard.hide()
	if dashboard_wibox then
		dashboard_wibox.visible = false
		dashboard_visible = false
	end
	popup.hide()
end

return dashboard
