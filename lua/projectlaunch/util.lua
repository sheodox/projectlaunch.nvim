local M = {}

M.augroup = vim.api.nvim_create_augroup("ProjectLaunch", { clear = true })

function M.table_has_items(tbl)
	for _, _ in pairs(tbl) do
		return true
	end
	return false
end

function M.find_index(tbl, item)
	assert(type(tbl) == "table", "first argument must be a table, got " .. type(tbl))

	for index, value in ipairs(tbl) do
		if value == item then
			return index
		end
	end

	return nil
end

function M.clamp(num, min, max)
	return math.max(min, math.min(max, num))
end

function M.center(str, win_width)
	local shift = math.floor(win_width / 2) - math.floor(string.len(str) / 2)
	return string.rep(" ", shift) .. str
end
function M.justify(str1, str2, win_width)
	local shift = win_width - string.len(str1) - string.len(str2)
	return str1 .. string.rep(" ", shift) .. str2
end

function M.log(str)
	print("ProjectLaunch: " .. str)
end

return M
