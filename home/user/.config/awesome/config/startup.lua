local spawn = require("awful.spawn")
local gears = require("gears")
local nightmode = require("config.nightmode")

awesome.connect_signal("startup", function()
	gears.timer({
		timeout = 1,
		autostart = true,
		single_shot = true,
		callback = function()
			spawn.with_shell("xset r rate 300 50")
		end,
	})

	spawn.once("picom --config " .. os.getenv("HOME") .. "/.config/picom/picom.conf")

	spawn("fcitx5 -d --replace", false)

	spawn(os.getenv("HOME") .. "/.screenlayout/default.sh")

	if nightmode.is_on() then
		spawn.with_shell("redshift -x && redshift -O 4500")
	end

	--spawn("discord", false)
end)
