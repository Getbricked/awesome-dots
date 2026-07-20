local gears = require("gears")

local class_rule = {}

local function add(pattern, active, inactive)
	class_rule[pattern] = { active, inactive or active }
end

add("[Ff]irefox", 1, 0.9)
add("org%.mozilla%.firefox", 1, 0.9)
add("[Ff]irefox%-esr", 1, 0.9)
add("[Ff]irefox%-bin", 1, 0.9)
add("Navigator", 1, 0.9)
add("[Gg]oogle%-chrome", 1, 0.9)
add("[Gg]oogle%-chrome%-beta", 1, 0.9)
add("[Gg]oogle%-chrome%-dev", 1, 0.9)
add("[Gg]oogle%-chrome%-unstable", 1, 0.9)
add("chrome%-.+%-Default", 1, 0.9)
add("[Cc]hromium", 1, 0.9)
add("[Mm]icrosoft%-edge", 1, 0.9)
add("[Mm]icrosoft%-edge%-stable", 1, 0.9)
add("[Mm]icrosoft%-edge%-beta", 1, 0.9)
add("[Mm]icrosoft%-edge%-dev", 1, 0.9)
add("[Mm]icrosoft%-edge%-unstable", 1, 0.9)
add("[Bb]rave%-browser", 1, 0.9)
add("[Bb]rave%-browser%-beta", 1, 0.9)
add("[Bb]rave%-browser%-dev", 1, 0.9)
add("[Bb]rave%-browser%-unstable", 1, 0.9)
add("[Tt]horium%-browser", 1, 0.9)
add("[Cc]achy%-browser", 1, 0.9)
add("zen%-alpha", 1, 0.9)
add("zen", 1, 0.9)

add("kitty", 0.9)

add("codium", 0.9)
add("codium%-url%-handler", 0.9)
add("VSCodium", 0.9)
add("VSCode", 0.9)
add("code", 0.9)
add("code%-url%-handler", 0.9)
add("jetbrains%-.+", 0.9)
add("dev%.zed%.Zed", 0.9)
add("antigravity", 0.9)

add("gedit", 0.9)
add("org%.gnome%.TextEditor", 0.9)
add("mousepad", 0.9)
add("kate", 0.9)
add("org%.kde%.kate", 0.9)

add("[Dd]iscord", 0.94)
add("[Ww]ebCord", 0.94)
add("[Vv]esktop", 0.94)
add("[Ff]erdium", 0.94)
add("[Ww]hatsapp%-for%-linux", 0.94)
add("ZapZap", 0.94)
add("com%.rtosta%.zapzap", 0.94)
add("org%.telegram%.desktop", 0.94)
add("io%.github%.tdesktop_x64%.TDesktop", 0.94)
add("teams%-for%-linux", 0.94)
add("im%.riot%.Riot", 0.94)
add("Element", 0.94)

add("[Tt]hunar", 0.9)
add("org%.gnome%.Nautilus", 0.9)
add("[Pp]cmanfm%-qt", 0.9)
add("app%.drey%.Warp", 0.9)

add("[Aa]udacious", 0.94)

add("[Mm]pv", 1.0)
add("vlc", 1.0)
add("com%.github%.rafostar%.Clapper", 1.0)

add("[Nn]otion", 0.95)

add("com%.github%.th_ch%.youtube_music", 0.8)

add("[Dd]eluge", 0.9)

add("[Ss]eahorse", 0.9)

add("pavucontrol", 0.85)
add("org%.pulseaudio%.pavucontrol", 0.85)
add("com%.saivert%.pwvucontrol", 0.85)
add("nm%-applet", 0.85)
add("nm%-connection%-editor", 0.85)
add("blueman%-manager", 0.85)
add("gnome%-disks", 0.85)
add("gnome%-system%-monitor", 0.85)
add("org%.gnome%.SystemMonitor", 0.85)
add("io%.missioncenter%.MissionCenter", 0.85)
add("qt5ct", 0.85)
add("qt6ct", 0.85)
add("file%-roller", 0.85)
add("org%.gnome%.FileRoller", 0.85)
add("[Bb]aobab", 0.85)
add("org%.gnome%.[Bb]aobab", 0.85)
add("evince", 0.85)
add("eog", 0.85)
add("org%.gnome%.Loupe", 0.85)
add("btrfs%-assistant", 0.85)
add("timeshift%-gtk", 0.85)
add("org%.kde%.polkit%-kde%-authentication%-agent%-1", 0.85)

local function apply_opacity(c, id)
	if not id then
		return false
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
