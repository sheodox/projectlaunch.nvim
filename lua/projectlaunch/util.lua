local M = {}
local api = vim.api

M.augroup = vim.api.nvim_create_augroup("ProjectLaunch", { clear = true })

function M.table_contains(tbl, item)
	for _, value in ipairs(tbl) do
		if value == item then
			return true
		end
	end
	return false
end

function M.table_has_items(tbl)
	for _, _ in pairs(tbl) do
		return true
	end
	return false
end

function M.remove_item(tbl, item)
	local new_table = {}
	for _, value in ipairs(tbl) do
		if value == item then
			table.insert(new_table, value)
		end
	end

	return new_table
end

function M.find_index(tbl, item)
	assert(type(tbl) == "table", "first argument must be a table, got " .. type(tbl))

	local found_index = nil
	for index, value in ipairs(tbl) do
		if value == item then
			found_index = index
		end
	end

	return found_index
end

function M.join(tbl, separator)
	local str = ""

	for i, value in ipairs(tbl) do
		if i == 1 then
			str = value
		else
			str = str .. separator .. value
		end
	end
	return str
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
