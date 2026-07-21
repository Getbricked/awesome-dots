local spawn = require("awful.spawn")
local gears = require("gears")

awesome.connect_signal("startup", function()
	gears.timer({
		timeout = 1,
		autostart = true,
		single_shot = true,
		callback = function()
			spawn.with_shell("xset r rate 300 50")
		end,
	})

	spawn("picom --config " .. os.getenv("HOME") .. "/.config/picom/picom.conf", false)

	spawn("fcitx5 -d --replace", false)

	spawn(os.getenv("HOME") .. "/.screenlayout/default.sh")
end)
