local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")
local cairo = require("lgi").cairo
local home = os.getenv("HOME")

local M = {}

local WALL_DIR = home .. "/Pictures/wallpapers"
local CACHE_DIR = home .. "/.cache/wallpapers"
local LEGACY_CACHE = home .. "/.cache/current_wallpaper"
local DEFAULT_WP = WALL_DIR .. "/anime-original-girl-looking-away-4k-2u.png"

local defaults_by_output = {
	["HDMI-0"] = WALL_DIR .. "/yourname.jpg",
}

local function ensure_cache_dir()
	os.execute("mkdir -p " .. CACHE_DIR)
end

local function read_cached(out)
	local f = io.open(CACHE_DIR .. "/" .. out, "r")
	if f then
		local path = f:read("*l")
		f:close()
		if path and path ~= "" and gears.filesystem.file_readable(path) then
			return path
		end
	end
	return nil
end

function M.wallpaper_for(s)
	local out = next(s.outputs)
	local path = out and read_cached(out)
	if path then
		return path
	end
	local f = io.open(LEGACY_CACHE, "r")
	if f then
		local legacy = f:read("*l")
		f:close()
		if legacy and legacy ~= "" and gears.filesystem.file_readable(legacy) then
			return legacy
		end
	end
	if out and defaults_by_output[out] and gears.filesystem.file_readable(defaults_by_output[out]) then
		return defaults_by_output[out]
	end
	return DEFAULT_WP
end

function M.set_wallpaper(path, out)
	if not path or path == "" or not gears.filesystem.file_readable(path) then
		return false
	end
	if not out then
		local s = awful.screen.focused()
		out = s and next(s.outputs)
	end
	if not out then
		return false
	end
	ensure_cache_dir()
	local f = io.open(CACHE_DIR .. "/" .. out, "w")
	if not f then
		return false
	end
	f:write(path .. "\n")
	f:close()
	for s in screen do
		s:emit_signal("request::wallpaper")
	end
	return true
end

function M.select()
	local s = awful.screen.focused()
	local out = s and next(s.outputs)
	local prompt = out and ("󰸉 " .. out .. ":") or "󰸉 Wallpaper:"
	awful.spawn.easy_async_with_shell(
		"find "
			.. WALL_DIR
			.. " -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%f\\0icon\\037%p\\n' | sort | rofi -dmenu -i -show-icons -theme wallpaper.rasi "
			.. "-kb-move-char-back 'Control+b' -kb-move-char-forward 'Control+f' "
			.. "-kb-row-left 'Left,Control+Page_Up' -kb-row-right 'Right,Control+Page_Down' "
			.. "-p '" .. prompt .. "'",
		function(stdout)
			local pic = stdout:gsub("%s+$", "")
			if pic == "" then
				return
			end
			local path = WALL_DIR .. "/" .. pic
			if M.set_wallpaper(path, out) then
				naughty.notification({
					title = "Wallpaper Changed",
					message = out and (pic .. " on " .. out) or pic,
					icon = path,
				})
			end
		end
	)
end

local function cover_image(path, geometry)
	local surface_img = gears.surface.load_uncached(path)
	if not surface_img then
		return nil
	end
	local iw, ih = gears.surface.get_size(surface_img)
	if iw <= 0 or ih <= 0 then
		return nil
	end
	local target = geometry.width / geometry.height
	local src = iw / ih
	local x, y, cw, ch = 0, 0, iw, ih
	if src > target then
		cw = math.floor(ih * target)
		x = math.floor((iw - cw) / 2)
	elseif src < target then
		ch = math.floor(iw / target)
		y = math.floor((ih - ch) / 2)
	end
	if cw <= 0 or ch <= 0 then
		return nil
	end
	local cropped = cairo.ImageSurface(cairo.Format.ARGB32, cw, ch)
	local cr = cairo.Context(cropped)
	cr:set_source_surface(surface_img, -x, -y)
	cr:paint()
	return cropped
end

screen.connect_signal("request::wallpaper", function(s)
	local path = M.wallpaper_for(s)
	local img = cover_image(path, s.geometry)
	awful.wallpaper({
		screen = s,
		widget = {
			{
				image = img or path,
				upscale = true,
				downscale = true,
				widget = wibox.widget.imagebox,
			},
			valign = "center",
			halign = "center",
			tiled = false,
			widget = wibox.container.tile,
		},
	})
end)

return M
