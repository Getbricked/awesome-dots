local gears = require("gears")
local awful = require("awful")

local M = {}

local saved_root_keys = nil
local hide_callback = nil

local esc_key = awful.key({}, "Escape", function()
	if hide_callback then
		hide_callback()
	end
end)

function M.show(w, hide_fn)
	saved_root_keys = root.keys()
	root.keys(gears.table.join(saved_root_keys, esc_key))
	hide_callback = hide_fn
	if w then
		w.visible = true
	end
end

function M.hide()
	if saved_root_keys then
		root.keys(saved_root_keys)
		saved_root_keys = nil
	end
	hide_callback = nil
end

return M