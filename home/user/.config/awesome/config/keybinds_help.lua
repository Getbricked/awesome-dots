---@diagnostic disable: undefined-global
local awful = require("awful")
local gears = require("gears")
local theme = require("themes.theme")
local wibox = require("wibox")
local popup = require("config.popup")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local M = {}

local box = nil
local visible = false

-- {title, {{keys, action}, ...}}; keys == "" renders an indented plain line
local sections_left = {
	{ "Launchers", {
		{ "Mod + Return", "Terminal" },
		{ "Mod + d", "App launcher (rofi)" },
		{ "Mod + e", "File manager (thunar)" },
		{ "Mod + b", "Browser (about:blank)" },
		{ "Mod + v", "Volume control (pavucontrol)" },
		{ "Mod + Alt + v", "Clipboard menu (clipmenu)" },
	} },
	{ "Windows", {
		{ "Mod + f", "Toggle maximized" },
		{ "Mod + Shift + f", "Toggle fullscreen" },
		{ "Mod + q", "Close window gracefully" },
		{ "Mod + Shift + q", "Force kill window (SIGKILL)" },
		{ "Mod + space", "Toggle floating / centered" },
		{ "Mod + Shift + space", "Cycle tiling layouts" },
	} },
	{ "Focus & Navigation", {
		{ "Mod + Tab", "Focus previous window" },
		{ "Mod + Arrows", "Focus window in direction" },
		{ "Mod + Escape", "Jump to previous tag" },
		{ "Alt + Tab", "Cycle tags with windows" },
	} },
	{ "Tags (Workspaces)", {
		{ "Mod + 1-9", "Switch to tag N" },
		{ "Mod + Shift + 1-9", "Move window to tag N and switch" },
		{ "Mod + Ctrl + Shift + 1-9", "Toggle window on tag N" },
	} },
	{ "Layouts", {
		{ "Mod + Numpad 1-9", "Set layout by index" },
	} },
	{ "Mouse", {
		{ "", "Right-click on desktop: app launcher (rofi)" },
		{ "", "Scroll on desktop: previous/next tag" },
		{ "", "Mod + Left click: move window" },
		{ "", "Mod + Right click: resize window" },
	} },
}

local sections_right = {
	{ "Resize & Master", {
		{ "Mod + Shift + Left/Right", "Master width / resize window" },
		{ "Mod + Shift + Up/Down", "Master clients / resize window" },
	} },
	{ "Swap & Move Between Screens", {
		{ "Mod + Alt + Left/Right", "Swap window with neighbor (cross-screen)" },
		{ "Mod + Ctrl + Left/Right", "Move window to adjacent tag/screen" },
	} },
	{ "Media & Hardware", {
		{ "Brightness Up/Down", "Brightness +/-10%" },
		{ "Audio Raise/Lower", "Volume +/-5%" },
		{ "Audio Mute / MicMute", "Toggle mute" },
		{ "Audio Play/Pause", "Play/Pause (playerctl)" },
		{ "Audio Prev/Next", "Previous/Next track" },
		{ "Audio Stop", "Stop playback" },
		{ "Touchpad Toggle", "Disable touchpad" },
		{ "WLAN / Bluetooth", "Toggle Wi-Fi / restart Bluetooth" },
		{ "Sleep", "Suspend" },
	} },
	{ "Screen Capture", {
		{ "Mod + Shift + s", "Interactive screenshot (clipboard)" },
	} },
	{ "System", {
		{ "Mod + Ctrl + r", "Restart AwesomeWM" },
		{ "Mod + Ctrl + q", "Quit AwesomeWM" },
		{ "Mod + l", "Lock screen" },
		{ "Mod + n", "Nightmode toggle" },
		{ "Mod + a", "Dashboard" },
		{ "Mod + c", "Calendar" },
		{ "Mod + w", "Wallpaper picker" },
		{ "Mod + h", "This help" },
	} },
}

local function esc(s)
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function column_markup(sections)
	local parts = {}
	for _, sec in ipairs(sections) do
		parts[#parts + 1] = string.format(
			'<span foreground="%s" size="larger"><b>%s</b></span>\n',
			theme.focus,
			esc(sec[1])
		)
		for _, row in ipairs(sec[2]) do
			if row[1] == "" then
				parts[#parts + 1] = "  " .. esc(row[2]) .. "\n"
			else
				parts[#parts + 1] = string.format(
					"<b>%s</b>  %s\n",
					esc(row[1] .. string.rep(" ", math.max(1, 26 - #row[1]))),
					esc(row[2])
				)
			end
		end
		parts[#parts + 1] = "\n"
	end
	return table.concat(parts)
end

local function create()
	local s = awful.screen.focused()
	local geo = s.geometry
	local width = math.floor(geo.width * 0.6)
	local height = math.floor(geo.height * 0.7)

	box = wibox({
		screen = s,
		width = width,
		height = height,
		x = math.floor(geo.width / 2 - width / 2),
		y = math.floor(geo.height / 2 - height / 2),
		ontop = true,
		visible = false,
		bg = "#000000cc",
		fg = "#ffffff",
		border_width = 2,
		border_color = theme.focus,
		type = "dock",
		shape = gears.shape.rounded_rect,
	})

	local function text_widget(markup)
		return {
			{
				markup = markup,
				font = "monospace 9",
				widget = wibox.widget.textbox,
			},
			fg = "#ffffff",
			widget = wibox.container.background,
		}
	end

	box:setup({
		{
			{
				text_widget(column_markup(sections_left)),
				text_widget(column_markup(sections_right)),
				spacing = dpi(24),
				layout = wibox.layout.fixed.horizontal,
			},
			halign = "center",
			valign = "top",
			widget = wibox.container.place,
		},
		margins = dpi(20),
		widget = wibox.container.margin,
	})
end

function M.show()
	if not box then
		create()
	end
	popup.show(box, M.hide)
	box.visible = true
	visible = true
end

function M.hide()
	if box then
		box.visible = false
	end
	popup.hide()
	visible = false
end

function M.toggle()
	if visible then
		M.hide()
	else
		M.show()
	end
end

return M
