---@diagnostic disable: undefined-global
local awful = require("awful")
local gears = require("gears")
local palette = require("themes.mocha")
local theme = require("themes.theme")
local wibox = require("wibox")

local calendar = {}

local cal_wibox = nil
local visible = false
local cur_y = os.date("*t").year
local cur_m = os.date("*t").month

local notes_dir = os.getenv("HOME") .. "/notes"
local accent = theme.focus
local weekdays = { "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su" }
local cell_size = 44

local body = wibox.layout.fixed.vertical()
body.spacing = 6

local function note_file(day)
	return string.format("%s/%04d-%02d-%02d.txt", notes_dir, cur_y, cur_m, day)
end

local edit_day = nil
local edit_buf = ""
local edit_grabber = nil

local edit_display = wibox.widget.textbox()
edit_display.font = "Maple Mono NF CN Bold 11"

local edit_row = wibox.widget({
	{
		{
			{
				text = "Note:",
				font = "Maple Mono NF CN Bold 11",
				widget = wibox.widget.textbox,
			},
			edit_display,
			spacing = 6,
			layout = wibox.layout.fixed.horizontal,
		},
		left = 8,
		right = 8,
		top = 4,
		bottom = 4,
		widget = wibox.container.margin,
	},
	bg = palette.surface0.hex,
	shape = gears.shape.rounded_rect,
	widget = wibox.container.background,
})

local function stop_edit_grabber()
	if edit_grabber then
		edit_grabber:stop()
		edit_grabber = nil
	end
end

local function save_note()
	if not edit_day then
		return
	end
	os.execute('mkdir -p "' .. notes_dir .. '"')
	local f = io.open(note_file(edit_day), "w")
	if f then
		f:write(edit_buf)
		f:close()
	end
end

local function start_edit(day)
	stop_edit_grabber()
	local f = io.open(note_file(day), "r")
	edit_buf = (f and f:read("*a")) or ""
	if f then
		f:close()
	end
	edit_day = day
	edit_display.text = edit_buf
	calendar.rebuild()

	edit_grabber = awful.keygrabber({
		autostart = false,
		keypressed_callback = function(_, modifiers, key)
			if key == "BackSpace" then
				edit_buf = edit_buf:sub(1, -2)
				edit_display.text = edit_buf
			elseif key == "Escape" then
				edit_day = nil
				edit_display.text = ""
				calendar.rebuild()
				stop_edit_grabber()
			elseif #key == 1 and not (modifiers.Control or modifiers.Mod1 or modifiers.Mod4) then
				edit_buf = edit_buf .. key
				edit_display.text = edit_buf
			end
		end,
		keyreleased_callback = function(_, _, key)
			if key == "Return" or key == "KP_Enter" then
				save_note()
				edit_day = nil
				edit_display.text = ""
				stop_edit_grabber()
				calendar.rebuild()
				calendar.hide()
			end
		end,
	})
	edit_grabber:start()
end

local function make_header_button(label, action)
	local b = wibox.widget({
		{
			{
				text = label,
				font = "Maple Mono NF CN Bold 11",
				widget = wibox.widget.textbox,
			},
			left = 10,
			right = 10,
			top = 3,
			bottom = 3,
			widget = wibox.container.margin,
		},
		bg = palette.surface0.hex,
		shape = gears.shape.rounded_rect,
		widget = wibox.container.background,
	})
	b:connect_signal("mouse::enter", function()
		b.bg = palette.surface1.hex
	end)
	b:connect_signal("mouse::leave", function()
		b.bg = palette.surface0.hex
	end)
	b:connect_signal("button::press", function(_, _, _, button)
		if button == 1 then
			action()
		end
	end)
	return b
end

local function prev_month()
	cur_m = cur_m - 1
	if cur_m < 1 then
		cur_m = 12
		cur_y = cur_y - 1
	end
	calendar.rebuild()
end

local function next_month()
	cur_m = cur_m + 1
	if cur_m > 12 then
		cur_m = 1
		cur_y = cur_y + 1
	end
	calendar.rebuild()
end

local function goto_today()
	local now = os.date("*t")
	cur_y = now.year
	cur_m = now.month
	calendar.rebuild()
end

local function read_note_snippet(day)
	local f = io.open(note_file(day), "r")
	if not f then
		return nil
	end
	local first = f:read("*l")
	f:close()
	if not first then
		return nil
	end
	first = first:gsub("^%s+", ""):gsub("%s+$", "")
	if #first > 14 then
		first = first:sub(1, 14) .. "…"
	end
	return first
end

local function make_day_cell(day)
	local now = os.date("*t")
	local is_today = day == now.day and cur_m == now.month and cur_y == now.year
	local has_note = read_note_snippet(day) ~= nil

	local dot = nil
	if has_note then
		dot = wibox.widget({
			wibox.widget({
				bg = accent,
				shape = gears.shape.circle,
				forced_width = 7,
				forced_height = 7,
				widget = wibox.container.background,
			}),
			top = 5,
			right = 5,
			widget = wibox.container.margin,
		})
		dot = wibox.widget({
			dot,
			halign = "right",
			valign = "top",
			widget = wibox.container.place,
		})
	end

	local cell = wibox.widget({
		{
			{
				text = tostring(day),
				font = "Maple Mono NF CN Bold 11",
				halign = "center",
				valign = "center",
				widget = wibox.widget.textbox,
			},
			dot,
			layout = wibox.layout.stack,
		},
		bg = is_today and accent or palette.surface0.hex,
		fg = is_today and "#000000" or "#ffffff",
		shape = gears.shape.rounded_rect,
		forced_width = cell_size,
		forced_height = cell_size,
		widget = wibox.container.background,
	})

	cell:connect_signal("mouse::enter", function()
		cell.bg = is_today and accent or palette.surface1.hex
	end)

	cell:connect_signal("mouse::leave", function()
		cell.bg = is_today and accent or palette.surface0.hex
	end)

	cell:connect_signal("button::press", function(_, _, _, button)
		if button == 1 then
			start_edit(day)
		end
	end)

	return cell
end

local function make_placeholder()
	return wibox.widget({
		bg = "transparent",
		forced_width = cell_size,
		forced_height = cell_size,
		widget = wibox.container.background,
	})
end

function calendar.rebuild()
	if not cal_wibox then
		return
	end

	body:reset()

	local title = wibox.widget.textbox(os.date("%B %Y", os.time({ year = cur_y, month = cur_m, day = 1 })))
	title.font = "Maple Mono NF CN Bold 11"
	title.halign = "center"
	-- Removed title.forced_width so it sizes dynamically to the text content

	local header = wibox.widget({
		{
			make_header_button("‹", prev_month),
			title,
			make_header_button("›", next_month),
			spacing = 8,
			layout = wibox.layout.fixed.horizontal,
		},
		nil,
		make_header_button("Today", goto_today),
		layout = wibox.layout.align.horizontal,
	})

	local weekday_row = wibox.widget({
		spacing = 4,
		layout = wibox.layout.fixed.horizontal,
	})
	for _, d in ipairs(weekdays) do
		local w = wibox.widget({
			{
				text = d,
				font = "Maple Mono NF CN Bold 11",
				halign = "center",
				widget = wibox.widget.textbox,
			},
			forced_width = cell_size,
			widget = wibox.container.place,
		})
		weekday_row:add(w)
	end

	local grid = wibox.widget({
		spacing = 4,
		forced_num_cols = 7,
		layout = wibox.layout.grid,
	})
	local dim = os.date("*t", os.time({ year = cur_y, month = cur_m + 1, day = 0 })).day
	local offset = tonumber(os.date("%u", os.time({ year = cur_y, month = cur_m, day = 1 }))) - 1
	for i = 1, 42 do
		local day = i - offset
		if day >= 1 and day <= dim then
			grid:add(make_day_cell(day))
		else
			grid:add(make_placeholder())
		end
	end

	body:add(header)
	body:add(weekday_row)
	body:add(grid)
	if edit_day then
		body:add(edit_row)
	end
end

local esc_key = awful.key({}, "Escape", function()
	calendar.hide()
end)
local saved_root_keys = nil

function calendar.create()
	if cal_wibox then
		return
	end

	local width = math.floor(screen.primary.geometry.width / 4)
	local height = math.floor(screen.primary.geometry.height / 2)
	local cell_by_h = math.floor((height - 176) / 6)
	cell_size = math.max(20, math.min(math.floor((width - 40 - 24) / 7), cell_by_h))

	cal_wibox = wibox({
		screen = screen.primary,
		width = width,
		height = height,
		x = screen.primary.geometry.width / 2 - width / 2,
		y = 30,
		ontop = true,
		visible = false,
		bg = "#000000cc",
		fg = "#ffffff",
		border_width = 2,
		border_color = theme.focus,
		type = "dock",
		shape = gears.shape.rounded_rect,
	})

	cal_wibox:setup({
		{
			body,
			margins = 20,
			widget = wibox.container.margin,
		},
		valign = "top",
		widget = wibox.container.place,
	})

	calendar.rebuild()
end

function calendar.toggle()
	calendar.create()
	if visible then
		calendar.hide()
	else
		calendar.show()
	end
end

function calendar.show()
	calendar.create()
	if cal_wibox then
		saved_root_keys = root.keys()
		root.keys(gears.table.join(saved_root_keys, esc_key))
		calendar.rebuild()
		cal_wibox.visible = true
		visible = true
	end
end

function calendar.hide()
	stop_edit_grabber()
	edit_day = nil
	edit_display.text = ""
	if saved_root_keys then
		root.keys(saved_root_keys)
		saved_root_keys = nil
	end
	if cal_wibox then
		cal_wibox.visible = false
		visible = false
	end
end

return calendar
