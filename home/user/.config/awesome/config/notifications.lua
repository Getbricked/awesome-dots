local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local xresources = require("beautiful.xresources")
local rnotification = require("ruled.notification")
local dpi = xresources.apply_dpi

local M = {}

local notification_ids = {}

function M.notify(category, title, text, extra)
	local opts = {
		title = title,
		text = text,
		replaces_id = notification_ids[category],
	}
	if extra then
		for k, v in pairs(extra) do
			opts[k] = v
		end
	end
	local n = naughty.notify(opts)
	notification_ids[category] = n.id
end

rnotification.connect_signal("request::rules", function()
	rnotification.append_rule({
		rule = {},
		properties = {
			screen = awful.screen.preferred,
			position = "top_middle",
			implicit_timeout = 3,
			border_width = dpi(2),
		},
	})

	rnotification.append_rule({
		rule = { urgency = "critical" },
		properties = { bg = "#ff0000", fg = "#ffffff" },
	})
end)

naughty.connect_signal("request::display", function(n)
	naughty.layout.box({ notification = n })
end)

-- Layout switching notification
tag.connect_signal("property::layout", function(t)
	if not t.selected then
		return
	end
	local name = awful.layout.getname(t.layout) or "unknown"
	M.notify("layout", "Layout", name:gsub("^%l", string.upper))
end)

local function clean(s)
	return (s or ""):gsub("%s+$", ""):gsub("^%s+", "")
end

-- Media key notification (play-pause/previous/next/stop)
local media_gen = 0

function M.media(action)
	media_gen = media_gen + 1
	local gen = media_gen

	local function metadata(cb)
		awful.spawn.easy_async(
			{ "playerctl", "metadata", "--format", "{{ status }}\t{{ artist }}\t{{ title }}" },
			function(stdout)
				local status, artist, title = stdout:match("^([^\t]*)\t([^\t]*)\t([^\t]*)$")
				cb(clean(status), clean(artist), clean(title))
			end
		)
	end

	local function show(title, artist)
		if title == "" then
			return
		end
		local text = artist ~= "" and (title .. " — " .. artist) or title
		M.notify("media", "Now Playing", text)
	end

	-- Poll metadata until `check` passes (then call `done`), no more than 30 tries.
	-- A newer key press supersedes this one, so stale chains abort early.
	local function poll_until(done, check, tries)
		if gen ~= media_gen then
			return
		end
		metadata(function(status, artist, title)
			if gen ~= media_gen then
				return
			end
			if check(status, artist, title) then
				done(status, artist, title)
			elseif tries < 30 then
				gears.timer.start_new(0.1, function()
					poll_until(done, check, tries + 1)
					return false
				end)
			end
		end)
	end

	if action == "stop" then
		awful.spawn({ "playerctl", "stop" })
		return
	end

	if action == "play-pause" then
		metadata(function(status)
			-- was paused -> toggle resumes; was playing -> toggle pauses (no notif)
			local was_paused = status == "Paused"
			awful.spawn.easy_async({ "playerctl", "play-pause" }, function()
				if gen ~= media_gen then
					return
				end
				if was_paused then
					poll_until(function(_, artist, title)
						show(title, artist)
					end, function(_, _, title)
						return title ~= ""
					end, 0)
				end
			end)
		end)
		return
	end

	-- next/previous: the player switches tracks asynchronously, so poll until the
	-- title actually changes before notifying.
	metadata(function(_, _, old_title)
		awful.spawn.easy_async({ "playerctl", action }, function()
			if gen ~= media_gen then
				return
			end
			poll_until(function(_, artist, title)
				show(title, artist)
			end, function(_, _, title)
				return title ~= "" and title ~= old_title
			end, 0)
		end)
	end)
end

return M