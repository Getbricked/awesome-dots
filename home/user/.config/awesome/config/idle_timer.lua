local gears = require("gears")
local awful = require("awful")
local lockscreen = require("config.lockscreen")

-- Helper function to check if any window on any monitor is fullscreen
local function is_fullscreen_active()
	for _, c in ipairs(client.get()) do
		if c.fullscreen then
			return true
		end
	end
	return false
end

gears.timer({
	timeout = 10,
	autostart = true,
	callback = function()
		if is_fullscreen_active() then
			return
		end

		local check_browser_media = "playerctl --player=zen,firefox,chromium,chrome,mpv,vlc status 2>/dev/null"

		awful.spawn.easy_async_with_shell(check_browser_media, function(stdout)
			-- If a video is playing restart idle timer
			if stdout and stdout:match("Playing") then
				return
			end

			-- 3. If no browser video/media is playing, check physical inactivity (10 minutes = 600,000 ms)
			awful.spawn.easy_async("xprintidle", function(idle_stdout)
				local idle_stdout_cleaned = idle_stdout:match("%d+")
				local idle_ms = tonumber(idle_stdout_cleaned)
				if idle_ms and idle_ms >= 600000 then
					lockscreen.show()
				end
			end)
		end)
	end,
})
