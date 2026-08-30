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
			implicit_timeout = 7,
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
	-- Keep the notification alive while the mouse hovers it.
	local w = n.widget
	if w then
		w:connect_signal("mouse::enter", function()
			n:suspend()
		end)
		w:connect_signal("mouse::leave", function()
			n:resume()
		end)
	end
end)

-- Layout switching notification
tag.connect_signal("property::layout", function(t)
	if not t.selected then
		return
	end
	local name = awful.layout.getname(t.layout) or "unknown"
	M.notify("layout", "Layout", (name:gsub("^%l", string.upper)))
end)

local function clean(s)
	return (s or ""):gsub("%s+$", ""):gsub("^%s+", "")
end

-- Media key notification (play-pause/previous/next/stop)
local media_gen = 0
local media_player = nil

function M.media(action)
	media_gen = media_gen + 1
	local gen = media_gen

	local function show(title, artist)
		if title == "" then
			return
		end
		local text = artist ~= "" and (title .. " — " .. artist) or title
		M.notify("media", "Now Playing", text)
	end

	local function metadata_of(player, cb)
		awful.spawn.easy_async(
			{ "playerctl", "--player", player, "metadata", "--format", "{{ status }}\t{{ artist }}\t{{ title }}" },
			function(stdout)
				local status, artist, title = stdout:match("^([^\t]*)\t([^\t]*)\t([^\t]*)$")
				cb(clean(status), clean(artist), clean(title))
			end
		)
	end

	-- Poll one player's metadata until `check` passes (max 30 tries).
	-- A newer key press supersedes this one, so stale chains abort early.
	local function poll_until(player, done, check, tries)
		if gen ~= media_gen then
			return
		end
		metadata_of(player, function(status, artist, title)
			if gen ~= media_gen then
				return
			end
			if check(status, artist, title) then
				done(status, artist, title)
			elseif tries < 30 then
				gears.timer.start_new(0.1, function()
					poll_until(player, done, check, tries + 1)
					return false
				end)
			end
		end)
	end

	-- List every player once and pick the relevant one. Preference order:
	-- the player we last controlled while it is Playing, then any Playing
	-- player, then the last-controlled one (paused), then the first listed.
	awful.spawn.easy_async(
		{ "playerctl", "-a", "metadata", "--format", "{{ playerName }}\t{{ status }}\t{{ artist }}\t{{ title }}" },
		function(stdout)
			if gen ~= media_gen then
				return
			end
			local entries = {}
			for line in stdout:gmatch("[^\r\n]+") do
				local name, status, artist, title = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$")
				name, status, artist, title = clean(name), clean(status), clean(artist), clean(title)
				if name ~= "" and title ~= "" then
					entries[#entries + 1] = { name = name, status = status, artist = artist, title = title }
				end
			end
			local function find(pred)
				for _, e in ipairs(entries) do
					if pred(e) then
						return e
					end
				end
			end
			local target = find(function(e)
				return e.status == "Playing" and e.name == media_player
			end) or find(function(e)
				return e.status == "Playing"
			end) or find(function(e)
				return e.name == media_player
			end) or entries[1]
			if not target then
				return
			end
			media_player = target.name

			if action == "stop" then
				awful.spawn({ "playerctl", "--player", target.name, "stop" })
				return
			end

			if action == "play-pause" then
				-- was playing -> toggles to paused (no notif); was paused -> resumes
				awful.spawn({ "playerctl", "--player", target.name, "play-pause" })
				if target.status == "Playing" then
					return
				end
				poll_until(target.name, function(_, artist, title)
					show(title, artist)
				end, function(_, _, title)
					return title ~= ""
				end, 0)
				return
			end

			-- next/previous: the player switches tracks asynchronously, so poll
			-- until ITS title actually changes before notifying.
			local old_title = target.title
			awful.spawn({ "playerctl", "--player", target.name, action })
			poll_until(target.name, function(_, artist, title)
				show(title, artist)
			end, function(_, _, title)
				return title ~= "" and title ~= old_title
			end, 0)
		end
	)
end

return M
