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

	spawn.with_shell(
		"if ! pgrep -x 9router > /dev/null; then "
			.. "expect -c 'set timeout 15; spawn /usr/bin/9router --host 127.0.0.1 --no-browser; "
			.. 'expect "Choose Interface"; send "\\033\\[B\\033\\[B\\r"; expect eof\' '
			.. "> /tmp/9router.log 2>&1 & "
			.. "fi"
	)

	local f_init = io.open(nightmode, "r")
	if f_init then
		local content = f_init:read("*all")
		f_init:close()
		if content and content:match("true") then
			spawn.with_shell("redshift -x && redshift -O 4500")
		end
	end

	spawn("discord", false)
end)
