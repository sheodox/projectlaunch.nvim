local M = {}

-- from https://github.com/nvim-lua/plenary.nvim/blob/0d660152000a40d52158c155625865da2aa7aa1b/lua/plenary/path.lua#L21
local path_separator = (function()
	local jit = require("jit")
	if jit then
		local os = string.lower(jit.os)
		if os == "linux" or os == "osx" or os == "bsd" then
			return "/"
		else
			return "\\"
		end
	else
		return package.config:sub(1, 1)
	end
end)()

local function trim_separator(segment)
	return segment:gsub("[\\/]*", "")
end

function M.join(...)
	local new_path = ""

	for i, segment in ipairs({ ... }) do
		if i == 1 then
			-- don't trim the first segment's separator, don't want to turn an
			-- absolute path into a relative one unwittingly
			new_path = segment
		else
			new_path = new_path .. path_separator .. trim_separator(segment)
		end
	end

	return new_path
end

return M
