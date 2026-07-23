local spawn = require("awful.spawn")
local gears = require("gears")
local nightmode = os.getenv("HOME") .. "/.config/awesome/config/.nightmode"

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

	local f_init = io.open(nightmode, "r")
	if f_init then
		local content = f_init:read("*all")
		f_init:close()
		if content and content:match("true") then
			spawn("redshift -x && sleep 1", false)
			spawn("redshift -O 4500", false)
		end
	end
end)
