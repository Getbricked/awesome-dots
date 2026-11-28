---@diagnostic disable: undefined-global
local awful = require("awful")
local gears = require("gears")
local gsurface = require("gears.surface")
local wibox = require("wibox")
local base = require("wibox.widget.base")
local palette = require("themes.mocha")
local theme = require("themes.theme")

local M = {}

local alt = "Mod1"
local shift = "Shift"

local GAP, PAD = 10, 12
local LABEL_H = 18

local TMP = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/awesome-tagsw"
os.execute("mkdir -p " .. TMP)

local box, labels, tags, sel, cancelled
local mru = {}
local cache = setmetatable({}, { __mode = "k" })
local active = {}

local function capture_client(c)
	local path = TMP .. "/" .. tostring(c.window) .. ".png"
	awful.spawn.easy_async({ "import", "-window", tostring(c.window), path }, function()
		local surf, err = gsurface.load_uncached_silently(path)
		if not err then
			cache[c] = surf
			for _, w in ipairs(active) do
				w:emit_signal("widget::redraw_needed")
			end
		end
	end)
end

local function capture_tag(t)
	for _, c in ipairs(t:clients()) do
		if not c.minimized then
			capture_client(c)
		end
	end
end

tag.connect_signal("property::selected", function(t)
	if not t.selected then
		return
	end
	local list = mru[t.screen]
	if not list then
		list = {}
		mru[t.screen] = list
	end
	for i, other in ipairs(list) do
		if other == t then
			table.remove(list, i)
			break
		end
	end
	table.insert(list, 1, t)

	gears.timer({
		timeout = 0.3,
		single_shot = true,
		autostart = true,
		callback = function()
			capture_tag(t)
		end,
	})
end)

local function create_preview(t, s, pw, ph)
	local w = base.make_widget()
	active[#active + 1] = w

	function w:fit()
		return pw, ph
	end

	function w:draw(context, cr, width, height)
		local wa = s.workarea
		local sx, sy = width / wa.width, height / wa.height

		cr:save()
		cr:rectangle(0, 0, width, height)
		cr:clip()
		cr:set_source(gears.color(palette.base.hex))
		cr:paint()

		for _, c in ipairs(t:clients()) do
			if not c.minimized then
				local g = c:geometry()
				local rx = (g.x - wa.x) * sx
				local ry = (g.y - wa.y) * sy
				local rw = math.max(1, g.width * sx)
				local rh = math.max(1, g.height * sy)
				local surf = cache[c]
				if surf then
					local iw, ih = gsurface.get_size(surf)
					if iw > 0 and ih > 0 then
						local scale = math.min(rw / iw, rh / ih)
						local dw, dh = iw * scale, ih * scale
						cr:save()
						cr:translate(rx + (rw - dw) / 2, ry + (rh - dh) / 2)
						cr:scale(scale, scale)
						cr:set_source_surface(surf, 0, 0)
						cr:paint()
						cr:restore()
					end
				else
					local color = palette.overlay1.hex
					if c.floating then
						color = palette.blue.hex
					end
					if c == client.focus then
						color = palette.text.hex
					end
					cr:set_source(gears.color(color))
					cr:rectangle(rx, ry, rw, rh)
					cr:fill()
				end
			end
		end

		cr:restore()
	end

	return w
end

local function render()
	for i, label in ipairs(labels) do
		if i == sel then
			label.bg = theme.focus
			label.fg = "#000000"
			label.border_color = theme.focus
			label.border_width = 3
		else
			label.bg = palette.surface1.hex
			label.fg = palette.text.hex
			label.border_color = nil
			label.border_width = 0
		end
	end
end

local function hide()
	if box then
		box.visible = false
		box = nil
	end
	labels = {}
	active = {}
end

local function advance(delta)
	if #tags == 0 then
		return
	end
	sel = (sel - 1 + delta) % #tags + 1
	render()
end

local grabber

grabber = awful.keygrabber({
	stop_key = alt,
	stop_event = "release",
	keybindings = {
		awful.key({ alt }, "Tab", function()
			advance(1)
		end),
		awful.key({ alt, shift }, "Tab", function()
			advance(-1)
		end),
		awful.key({ alt }, "Escape", function()
			cancelled = true
			grabber:stop()
		end),
	},
	start_callback = function()
		local s = awful.screen.focused()
		local cur = s.selected_tag

		tags = {}
		local seen = {}
		local function add(t)
			if t and not seen[t] and #t:clients() > 0 then
				seen[t] = true
				tags[#tags + 1] = t
			end
		end
		for _, t in ipairs(mru[s] or {}) do
			add(t)
		end
		for _, t in ipairs(s.tags) do
			add(t)
		end

		sel = 0
		for i, t in ipairs(tags) do
			if t == cur then
				sel = i
				break
			end
		end
		cancelled = false

		if #tags == 0 then
			return
		end

		local geo = s.geometry
		local bw = math.floor(geo.width * 0.5)
		local bh = math.floor(geo.height * 0.5)

		box = wibox({
			screen = s,
			width = bw,
			height = bh,
			x = geo.x + math.floor((geo.width - bw) / 2),
			y = geo.y + math.floor((geo.height - bh) / 2),
			ontop = true,
			visible = true,
			bg = "#000000cc",
			border_width = 2,
			border_color = theme.focus,
			type = "dock",
			shape = gears.shape.rounded_rect,
		})

		local n = #tags
		local cols = math.max(1, math.ceil(math.sqrt(n)))
		local rows = math.ceil(n / cols)
		local cell_w = math.floor((bw - PAD * 2 - (cols - 1) * GAP) / cols)
		local cell_h = math.floor((bh - PAD * 2 - (rows - 1) * GAP) / rows)
		local preview_h = cell_h - LABEL_H

		local grid = wibox.widget({
			layout = wibox.layout.grid,
			forced_num_cols = cols,
			spacing = GAP,
		})

		labels = {}
		for i, t in ipairs(tags) do
			local cell = wibox.widget({
				{
					create_preview(t, s, cell_w, preview_h),
					{
						text = t.name,
						font = "Maple Mono NF CN 10",
						align = "center",
						valign = "center",
						widget = wibox.widget.textbox,
					},
					spacing = 2,
					layout = wibox.layout.fixed.vertical,
				},
				bg = palette.surface0.hex,
				fg = palette.text.hex,
				shape = gears.shape.rounded_rect,
				widget = wibox.container.background,
				forced_width = cell_w,
				forced_height = cell_h,
			})
			labels[i] = cell
			grid:add(cell)
		end
		box:setup({ grid, margins = PAD, widget = wibox.container.margin })
		render()
	end,
	stop_callback = function()
		if not cancelled and tags and tags[sel] then
			tags[sel]:view_only()
		end
		hide()
	end,
	export_keybindings = true,
})

function M.start()
	grabber:start()
end

return M
