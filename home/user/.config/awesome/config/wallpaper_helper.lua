local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")
local home = os.getenv("HOME")

local M = {}

local WALL_DIR = home .. "/Pictures/wallpapers"
local CACHE_FILE = home .. "/.cache/current_wallpaper"
local DEFAULT_WP = WALL_DIR .. "/anime-original-girl-looking-away-4k-2u.png"

local wallpapers_by_output = {
	["DP-1"] = DEFAULT_WP,
	["DP-2"] = DEFAULT_WP,
	["HDMI-0"] = WALL_DIR .. "/yourname.jpg",
}

local function ensure_cache_file()
	local dir = CACHE_FILE:match("^(.*)/")
	if dir then
		os.execute("mkdir -p " .. dir)
	end
end

function M.get_default_wp()
	local f = io.open(CACHE_FILE, "r")
	if f then
		local path = f:read("*l")
		f:close()
		if path and path ~= "" and gears.filesystem.file_readable(path) then
			return path
		end
	end
	return DEFAULT_WP
end

function M.wallpaper_for(s)
	local out = next(s.outputs)
	if out and wallpapers_by_output[out] then
		return wallpapers_by_output[out]
	end
	return M.get_default_wp()
end

function M.set_wallpaper(path)
	if not path or path == "" or not gears.filesystem.file_readable(path) then
		return false
	end
	ensure_cache_file()
	local f = io.open(CACHE_FILE, "w")
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
	awful.spawn.easy_async_with_shell(
		"find "
			.. WALL_DIR
			.. " -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%f\\0icon\\037%p\\n' | sort | rofi -dmenu -i -show-icons -theme wallpaper.rasi "
			.. "-kb-move-char-back 'Control+b' -kb-move-char-forward 'Control+f' "
			.. "-kb-row-left 'Left,Control+Page_Up' -kb-row-right 'Right,Control+Page_Down' "
			.. "-p '󰸉 Wallpaper:'",
		function(stdout)
			local pic = stdout:gsub("%s+$", "")
			if pic == "" then
				return
			end
			local path = WALL_DIR .. "/" .. pic
			if M.set_wallpaper(path) then
				naughty.notification({
					title = "Wallpaper Changed",
					message = pic,
					icon = path,
				})
			end
		end
	)
end

screen.connect_signal("request::wallpaper", function(s)
	awful.wallpaper({
		screen = s,
		widget = {
			{
				image = M.wallpaper_for(s),
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
