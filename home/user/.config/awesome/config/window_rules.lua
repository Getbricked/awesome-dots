local gears = require("gears")
local awful = require("awful")
local ruled = require("ruled")

local class_rule = {}

local function register(patterns, active, inactive)
	for _, p in ipairs(patterns) do
		class_rule[p] = { active, inactive or active }
	end
end

local browsers = {
	"[Ff]irefox",
	"org%.mozilla%.firefox",
	"[Ff]irefox%-esr",
	"[Ff]irefox%-bin",
	"Navigator",
	"[Gg]oogle%-chrome",
	"[Gg]oogle%-chrome%-beta",
	"[Gg]oogle%-chrome%-dev",
	"[Gg]oogle%-chrome%-unstable",
	"chrome%-.+%-Default",
	"[Cc]hromium",
	"[Mm]icrosoft%-edge",
	"[Mm]icrosoft%-edge%-stable",
	"[Mm]icrosoft%-edge%-beta",
	"[Mm]icrosoft%-edge%-dev",
	"[Mm]icrosoft%-edge%-unstable",
	"[Bb]rave%-browser",
	"[Bb]rave%-browser%-beta",
	"[Bb]rave%-browser%-dev",
	"[Bb]rave%-browser%-unstable",
	"[Tt]horium%-browser",
	"[Cc]achy%-browser",
	"zen%-alpha",
	"zen",
}
register(browsers, 1, 0.9)

local editors = {
	"codium",
	"codium%-url%-handler",
	"VSCodium",
	"VSCode",
	"code",
	"code%-url%-handler",
	"jetbrains%-.+",
	"dev%.zed%.Zed",
	"antigravity",
	"gedit",
	"org%.gnome%.TextEditor",
	"mousepad",
	"kate",
	"org%.kde%.kate",
}
register(editors, 0.9)

local chat = {
	"[Dd]iscord",
	"[Ww]ebCord",
	"[Vv]esktop",
	"[Ff]erdium",
	"[Ww]hatsapp%-for%-linux",
	"ZapZap",
	"com%.rtosta%.zapzap",
	"org%.telegram%.desktop",
	"io%.github%.tdesktop_x64%.TDesktop",
	"teams%-for%-linux",
	"im%.riot%.Riot",
	"Element",
}
register(chat, 0.94)

local file_managers = {
	"[Tt]hunar",
	"org%.gnome%.Nautilus",
	"[Pp]cmanfm%-qt",
	"app%.drey%.Warp",
}
register(file_managers, 0.9)

local media = { "[Mm]pv", "vlc", "com%.github%.rafostar%.Clapper" }
register(media, 1.0)

local utils = {
	"pavucontrol",
	"org%.pulseaudio%.pavucontrol",
	"com%.saivert%.pwvucontrol",
	"nm%-applet",
	"nm%-connection%-editor",
	"blueman%-manager",
	"gnome%-disks",
	"gnome%-system%-monitor",
	"org%.gnome%.SystemMonitor",
	"io%.missioncenter%.MissionCenter",
	"qt5ct",
	"qt6ct",
	"file%-roller",
	"org%.gnome%.FileRoller",
	"[Bb]aobab",
	"org%.gnome%.[Bb]aobab",
	"evince",
	"eog",
	"org%.gnome%.Loupe",
	"btrfs%-assistant",
	"timeshift%-gtk",
	"org%.kde%.polkit%-kde%-authentication%-agent%-1",
}
register(utils, 0.85)

class_rule["kitty"] = { 0.9 }
class_rule["[Aa]udacious"] = { 0.95 }
class_rule["[Nn]otion"] = { 0.95 }
class_rule["com%.github%.th_ch%.youtube_music"] = { 0.85 }

local function apply_opacity(c, id)
	if not id then
		return false
	end
	if c.fullscreen then
		c.opacity = 1
		return true
	end
	for pattern, rule in pairs(class_rule) do
		if id:match(pattern) then
			local active, inactive = rule[1], rule[2]
			c.opacity = active ~= inactive and (c.active and active or inactive) or active
			return true
		end
	end
	return false
end

client.connect_signal("request::manage", function(c)
	if apply_opacity(c, c.class) then
		return
	end
	if c.class and c.instance and c.instance ~= c.class then
		apply_opacity(c, c.instance)
	end
end)

gears.timer({
	timeout = 0,
	autostart = true,
	single_shot = true,
	callback = function()
		for _, c in ipairs(client.get()) do
			if c.valid then
				apply_opacity(c, c.class or c.instance)
			end
		end
	end,
})

client.connect_signal("focus", function(c)
	if not c.valid then
		return
	end
	if c.fullscreen then
		c.opacity = 1
		return
	end
	local id = c.class or c.instance
	if not id then
		return
	end
	for pattern, rule in pairs(class_rule) do
		if id:match(pattern) then
			if rule[1] ~= rule[2] then
				c.opacity = rule[1]
			end
			return
		end
	end
end)

client.connect_signal("unfocus", function(c)
	if not c.valid then
		return
	end
	if c.fullscreen then
		c.opacity = 1
		return
	end
	local id = c.class or c.instance
	if not id then
		return
	end
	for pattern, rule in pairs(class_rule) do
		if id:match(pattern) then
			if rule[1] ~= rule[2] then
				c.opacity = rule[2]
			end
			return
		end
	end
end)

client.connect_signal("property::fullscreen", function(c)
	if not c.valid then
		return
	end

	if c.fullscreen then
		c.opacity = 1
	else
		apply_opacity(c, c.class or c.instance)
	end
end)

-- floating rule
ruled.client.connect_signal("request::rules", function()
	ruled.client.append_rule({
		id = "global",
		rule = {},
		properties = {
			focus = awful.client.focus.filter,
			raise = true,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap + awful.placement.no_offscreen,
		},
	})

	ruled.client.append_rule({
		id = "floating",
		rule_any = {
			instance = { "copyq", "pinentry" },
			class = {
				"Arandr",
				"Blueman-manager",
				"Gpick",
				"Kruler",
				"Sxiv",
				"Tor Browser",
				"Wpa_gui",
				"veromix",
				"xtightvncviewer",
			},
			name = {
				"Event Tester",
			},
			role = {
				"AlarmWindow",
				"ConfigManager",
				"pop-up",
			},
		},
		properties = { floating = true },
	})
end)
