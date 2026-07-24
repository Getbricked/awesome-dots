local rules_helper = require("config.rules_helper")
local window_rule = rules_helper.window_rule

-- ==========================================
-- APP DEFINITIONS
-- ==========================================

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
window_rule(browsers, { opacity = { 1.0, 0.9 } })

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
window_rule(editors, { opacity = { 0.9 } })

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
window_rule(chat, { opacity = { 0.94 }, screen = "DP-1" })

local file_managers = {
	"[Tt]hunar",
	"org%.gnome%.Nautilus",
	"[Pp]cmanfm%-qt",
	"app%.drey%.Warp",
}
window_rule(file_managers, { opacity = { 0.9 } })

local media = { "[Mm]pv", "vlc", "com%.github%.rafostar%.Clapper" }
window_rule(media, { opacity = { 1.0 } })

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
window_rule(utils, { opacity = { 0.85 }, floating = true })

window_rule({ "kitty" }, { opacity = { 0.9 } })
window_rule({ "[Aa]udacious" }, { opacity = { 0.95 }, floating = true })
window_rule({ "[Nn]otion" }, { opacity = { 0.95 } })
window_rule({ "com%.github%.th_ch%.youtube_music" }, { opacity = { 0.85 }, screen = "HDMI-0" })

-- Default AwesomeWM floating elements
local default_floats = {
	"copyq",
	"pinentry",
	"Arandr",
	"Blueman-manager",
	"Gpick",
	"Kruler",
	"Sxiv",
	"Tor Browser",
	"Wpa_gui",
	"veromix",
	"xtightvncviewer",
	"Event Tester",
	"AlarmWindow",
	"ConfigManager",
	"pop-up",
}
window_rule(default_floats, { floating = true })
