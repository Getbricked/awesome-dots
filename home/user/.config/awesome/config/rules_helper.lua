local gears = require("gears")
local awful = require("awful")
local ruled = require("ruled")

local class_rule = {}
local unified_window_rules = {}

-- Helper function to allow using screen names like "DP-1"
local function screen_by_name(name)
	for s in screen do
		if s.outputs[name] then
			return s
		end
	end
	return awful.screen.preferred
end

-- ==========================================
-- THE UNIFIED MANAGER FUNCTION
-- ==========================================
local function window_rule(patterns, options)
	-- 1. Handle Opacity Setup
	if options.opacity then
		local active = options.opacity[1]
		local inactive = options.opacity[2] or active

		for _, p in ipairs(patterns) do
			class_rule[p] = { active, inactive }
		end
	end

	-- 2. Handle AwesomeWM Window Rules (Screen, Floating)
	local rule_properties = {}

	if options.screen ~= nil then
		if type(options.screen) == "string" then
			rule_properties.screen = screen_by_name(options.screen)
		else
			rule_properties.screen = options.screen
		end
	end

	if options.floating ~= nil then
		rule_properties.floating = options.floating
	end

	-- 3. Handle Tag Assignment natively via Property Function
	if options.tag ~= nil then
		rule_properties.tag = function(c)
			local s = c.screen
			if not s or not s.tags then
				return nil
			end

			if type(options.tag) == "number" then
				return s.tags[options.tag] -- Tag by index
			else
				return awful.tag.find_by_name(s, tostring(options.tag)) -- Tag by name
			end
		end
	end

	-- Save the rule if any properties exist
	if next(rule_properties) ~= nil then
		table.insert(unified_window_rules, {
			rule_any = {
				class = patterns,
				instance = patterns,
				name = patterns,
				role = patterns,
			},
			properties = rule_properties,
		})
	end
end

-- ==========================================
-- OPACITY SIGNALS
-- ==========================================
local function apply_opacity(c, id)
	if not id then
		return false
	end
	if c.fullscreen then
		c.opacity = 1
		return true
	end
	for pattern, rule in pairs(class_rule) do
		if id:match(pattern) then
			local active, inactive = rule[1], rule[2]
			c.opacity = active ~= inactive and (c.active and active or inactive) or active
			return true
		end
	end
	return false
end

client.connect_signal("request::manage", function(c)
	if apply_opacity(c, c.class) then
		return
	end
	if c.class and c.instance and c.instance ~= c.class then
		apply_opacity(c, c.instance)
	end
end)

gears.timer({
	timeout = 0,
	autostart = true,
	single_shot = true,
	callback = function()
		for _, c in ipairs(client.get()) do
			if c.valid then
				apply_opacity(c, c.class or c.instance)
			end
		end
	end,
})

client.connect_signal("focus", function(c)
	if not c.valid then
		return
	end
	if c.fullscreen then
		c.opacity = 1
		return
	end
	local id = c.class or c.instance
	if not id then
		return
	end
	for pattern, rule in pairs(class_rule) do
		if id:match(pattern) then
			if rule[1] ~= rule[2] then
				c.opacity = rule[1]
			end
			return
		end
	end
end)

client.connect_signal("unfocus", function(c)
	if not c.valid then
		return
	end
	if c.fullscreen then
		c.opacity = 1
		return
	end
	local id = c.class or c.instance
	if not id then
		return
	end
	for pattern, rule in pairs(class_rule) do
		if id:match(pattern) then
			if rule[1] ~= rule[2] then
				c.opacity = rule[2]
			end
			return
		end
	end
end)

client.connect_signal("property::fullscreen", function(c)
	if not c.valid then
		return
	end
	if c.fullscreen then
		c.opacity = 1
	else
		apply_opacity(c, c.class or c.instance)
	end
end)

-- ==========================================
-- RULE INJECTION
-- ==========================================
ruled.client.connect_signal("request::rules", function()
	-- 1. Default Global Rule
	ruled.client.append_rule({
		id = "global",
		rule = {},
		properties = {
			focus = awful.client.focus.filter,
			raise = true,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap + awful.placement.no_offscreen,
		},
	})

	-- 2. Apply Custom Unified Rules
	for i, custom_rule in ipairs(unified_window_rules) do
		ruled.client.append_rule({
			id = "unified_rule_" .. i,
			rule_any = custom_rule.rule_any,
			properties = custom_rule.properties,
		})
	end
end)

return {
	window_rule = window_rule,
}
