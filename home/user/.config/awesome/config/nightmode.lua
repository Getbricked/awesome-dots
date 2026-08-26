local M = {}

local cache_dir = os.getenv("HOME") .. "/.cache/awesome"
local file = cache_dir .. "/nightmode"

local function ensure_dir()
	os.execute("mkdir -p " .. cache_dir)
end

function M.is_on()
	local f = io.open(file, "r")
	if not f then
		ensure_dir()
		M.set(false)
		return false
	end
	local content = f:read("*all")
	f:close()
	return content ~= nil and content:match("true") ~= nil
end

function M.set(on)
	ensure_dir()
	local f = io.open(file, "w")
	if not f then
		return
	end
	f:write(on and "true" or "false")
	f:close()
end

return M