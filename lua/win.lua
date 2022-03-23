local M = {}
local api = vim.api

function M.create_split_window()
	vim.cmd("vsplit") -- split vertically
	vim.cmd("wincmd L") -- move to the right side of the screen
	return api.nvim_get_current_win()
end

function M.create_temp_window()
	local buf = api.nvim_create_buf(false, false)
	local win = api.nvim_open_win(buf, true, {
		relative = "editor",
		border = "rounded",
		width = 80,
		height = 10,
		row = 0,
		col = 0,
	})

	return win, buf
end

return M
