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

	spawn.with_shell(
		"if ! pgrep -x 9router > /dev/null; then "
			.. "expect -c 'set timeout 15; spawn /usr/bin/9router --host 127.0.0.1 --no-browser; "
			.. 'expect "☆ Exit"; '
			.. "set items [regexp -all {[☆★]} $expect_out(buffer)]; "
			.. "if {$items >= 3} { for {set i 0} {$i < [expr {$items - 2}]} {incr i} { "
			.. 'send "\\033\\[B" '
			.. "} }; "
			.. 'send "\\r"; '
			.. "expect eof' "
			.. "> /tmp/9router.log 2>&1 & "
			.. "fi"
	)

	--spawn("discord", false)
end)
