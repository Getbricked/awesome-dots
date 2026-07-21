local gears = require("gears")
local awful = require("awful")
local ruled = require("ruled")

local class_rule = {}

local function opacity(pattern, active, inactive)
	class_rule[pattern] = { active, inactive or active }
end

-- opacity rule
opacity("[Ff]irefox", 1, 0.9)
opacity("org%.mozilla%.firefox", 1, 0.9)
opacity("[Ff]irefox%-esr", 1, 0.9)
opacity("[Ff]irefox%-bin", 1, 0.9)
opacity("Navigator", 1, 0.9)
opacity("[Gg]oogle%-chrome", 1, 0.9)
opacity("[Gg]oogle%-chrome%-beta", 1, 0.9)
opacity("[Gg]oogle%-chrome%-dev", 1, 0.9)
opacity("[Gg]oogle%-chrome%-unstable", 1, 0.9)
opacity("chrome%-.+%-Default", 1, 0.9)
opacity("[Cc]hromium", 1, 0.9)
opacity("[Mm]icrosoft%-edge", 1, 0.9)
opacity("[Mm]icrosoft%-edge%-stable", 1, 0.9)
opacity("[Mm]icrosoft%-edge%-beta", 1, 0.9)
opacity("[Mm]icrosoft%-edge%-dev", 1, 0.9)
opacity("[Mm]icrosoft%-edge%-unstable", 1, 0.9)
opacity("[Bb]rave%-browser", 1, 0.9)
opacity("[Bb]rave%-browser%-beta", 1, 0.9)
opacity("[Bb]rave%-browser%-dev", 1, 0.9)
opacity("[Bb]rave%-browser%-unstable", 1, 0.9)
opacity("[Tt]horium%-browser", 1, 0.9)
opacity("[Cc]achy%-browser", 1, 0.9)
opacity("zen%-alpha", 1, 0.9)
opacity("zen", 1, 0.9)

opacity("kitty", 0.9)

opacity("codium", 0.9)
opacity("codium%-url%-handler", 0.9)
opacity("VSCodium", 0.9)
opacity("VSCode", 0.9)
opacity("code", 0.9)
opacity("code%-url%-handler", 0.9)
opacity("jetbrains%-.+", 0.9)
opacity("dev%.zed%.Zed", 0.9)
opacity("antigravity", 0.9)

opacity("gedit", 0.9)
opacity("org%.gnome%.TextEditor", 0.9)
opacity("mousepad", 0.9)
opacity("kate", 0.9)
opacity("org%.kde%.kate", 0.9)

opacity("[Dd]iscord", 0.94)
opacity("[Ww]ebCord", 0.94)
opacity("[Vv]esktop", 0.94)
opacity("[Ff]erdium", 0.94)
opacity("[Ww]hatsapp%-for%-linux", 0.94)
opacity("ZapZap", 0.94)
opacity("com%.rtosta%.zapzap", 0.94)
opacity("org%.telegram%.desktop", 0.94)
opacity("io%.github%.tdesktop_x64%.TDesktop", 0.94)
opacity("teams%-for%-linux", 0.94)
opacity("im%.riot%.Riot", 0.94)
opacity("Element", 0.94)

opacity("[Tt]hunar", 0.9)
opacity("org%.gnome%.Nautilus", 0.9)
opacity("[Pp]cmanfm%-qt", 0.9)
opacity("app%.drey%.Warp", 0.9)

opacity("[Aa]udacious", 0.94)

opacity("[Mm]pv", 1.0)
opacity("vlc", 1.0)
opacity("com%.github%.rafostar%.Clapper", 1.0)

opacity("[Nn]otion", 0.95)

opacity("com%.github%.th_ch%.youtube_music", 0.8)

opacity("[Dd]eluge", 0.9)

opacity("[Ss]eahorse", 0.9)

opacity("pavucontrol", 0.85)
opacity("org%.pulseaudio%.pavucontrol", 0.85)
opacity("com%.saivert%.pwvucontrol", 0.85)
opacity("nm%-applet", 0.85)
opacity("nm%-connection%-editor", 0.85)
opacity("blueman%-manager", 0.85)
opacity("gnome%-disks", 0.85)
opacity("gnome%-system%-monitor", 0.85)
opacity("org%.gnome%.SystemMonitor", 0.85)
opacity("io%.missioncenter%.MissionCenter", 0.85)
opacity("qt5ct", 0.85)
opacity("qt6ct", 0.85)
opacity("file%-roller", 0.85)
opacity("org%.gnome%.FileRoller", 0.85)
opacity("[Bb]aobab", 0.85)
opacity("org%.gnome%.[Bb]aobab", 0.85)
opacity("evince", 0.85)
opacity("eog", 0.85)
opacity("org%.gnome%.Loupe", 0.85)
opacity("btrfs%-assistant", 0.85)
opacity("timeshift%-gtk", 0.85)
opacity("org%.kde%.polkit%-kde%-authentication%-agent%-1", 0.85)

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
		-- When exiting fullscreen, re-evaluate normal opacity rules
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
