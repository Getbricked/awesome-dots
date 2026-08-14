local M = {}

local file = os.getenv("HOME") .. "/.config/awesome/config/.nightmode"

function M.is_on()
	local f = io.open(file, "r")
	if not f then
		return false
	end
	local content = f:read("*all")
	f:close()
	return content ~= nil and content:match("true") ~= nil
end

function M.set(on)
	local f = io.open(file, "w")
	if not f then
		return
	end
	f:write(on and "true" or "false")
	f:close()
end

return M