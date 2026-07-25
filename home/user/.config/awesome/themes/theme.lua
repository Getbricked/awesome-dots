local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local gfs = require("gears.filesystem")
local gears = require("gears")
local cairo = require("lgi").cairo
local themes_path = gfs.get_themes_dir()
local theme = {}

local focus = "#87CEEB"
local normal = "#000000"

theme.font = "monospace bold 11"

theme.bg_normal = normal
theme.bg_focus = focus
theme.bg_urgent = "#ff0000"
theme.bg_minimize = "#444444"
theme.bg_systray = theme.bg_normal

theme.fg_normal = "#aaaaaa"
theme.fg_focus = "#000000"
theme.fg_urgent = "#ffffff"
theme.fg_minimize = "#ffffff"

theme.layout_tile = themes_path .. "default/layouts/tilew.png"
theme.layout_floating = themes_path .. "default/layouts/floatingw.png"

theme.useless_gap = dpi(0)
theme.border_width = dpi(1)
theme.border_color_normal = "#000000"
theme.border_color_active = focus
theme.border_color_marked = "#91231c"

theme.notification_font = theme.font
theme.notification_bg = "#00000066"
theme.notification_fg = focus
theme.notification_border_color = focus
theme.notification_shape = gears.shape.rounded_rect

local function draw_circle(size, color)
	local surface = cairo.ImageSurface.create(cairo.Format.ARGB32, size, size)
	local cr = cairo.Context(surface)

	cr:set_source(gears.color(color))
	cr:arc(size / 2, size / 2, size / 2, 0, 2 * math.pi)
	cr:fill()

	return surface
end

local taglist_circle_size = dpi(6)

theme.taglist_squares_sel = draw_circle(taglist_circle_size, focus)
theme.taglist_squares_unsel = draw_circle(taglist_circle_size, focus)
theme.taglist_shape = function(cr, width, height)
	gears.shape.rounded_rect(cr, width, height, dpi(4))
end

return theme
