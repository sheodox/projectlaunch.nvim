local util = require("util")
local api = vim.api

local function set_buffer_lines(buf, lines, win)
	-- need to blank the window out before rendering to get rid of the ~ column on empty lines
	local blank_lines = {}
	local height = api.nvim_win_get_height(win)
	for _ = 1, height do
		table.insert(blank_lines, "")
	end

	api.nvim_buf_set_lines(buf, 0, -1, false, blank_lines)
	api.nvim_buf_set_lines(buf, 0, #lines, false, lines)
end

local InteractiveMenu = {}

function InteractiveMenu:new(options)
	if options.keymaps == nil then
		options.keymaps = {}
	end

	local data = {
		-- header lines is a table of strings
		header_lines = options.header_lines,
		-- body lines is a table of {data, text} tables, where 'data' is relevant data to pass to your
		-- keymap handlers identifying the row the cursor was on, and 'text' is the display text
		body_lines = options.body_lines,
		max_height = options.max_height,
		max_width = options.max_width,
		header_win = nil,
		header_buf = nil,
		body_win = nil,
		body_buf = nil,
		-- keymaps is a table of {key = {handler = <function>, with_row = <boolean>, destroy = <boolean>}}.
		-- with_row (optional, default true) determines if the handler should only be called on valid rows
		-- of body text, in which case the handler will be given the data passed in that row in body_lines.
		-- destroy (optional, default false) if the menu should be destroyed when a key is pressed
		keymaps = options.keymaps,
		on_destroy = options.on_destroy,
		autocmd_ids = {},
		destroyed = false,
	}
	self.__index = self

	return setmetatable(data, self)
end

function InteractiveMenu:render()
	self:setup_windows()

	self:render_header()
	self:render_body()
	self:set_keymaps()
end

function InteractiveMenu:render_header(header_lines)
	if header_lines ~= nil then
		self.header_lines = header_lines
	end

	local centered_lines = {} -- padding
	local header_width = api.nvim_win_get_width(self.header_win)
	for _, line in ipairs(self.header_lines) do
		table.insert(centered_lines, util.center(line, header_width))
	end

	api.nvim_buf_set_option(self.header_buf, "modifiable", true)
	set_buffer_lines(self.header_buf, centered_lines, self.header_win)
	api.nvim_buf_set_option(self.header_buf, "modifiable", false)
end

function InteractiveMenu:render_body(body_lines)
	if body_lines ~= nil then
		self.body_lines = body_lines
	end

	-- body_lines is a table of {data, display_text} tables, need
	-- to extract the display text to render it
	local display_lines = {}
	for _, line in ipairs(self.body_lines) do
		table.insert(display_lines, line[2])
	end

	api.nvim_buf_set_option(self.body_buf, "modifiable", true)
	set_buffer_lines(self.body_buf, display_lines, self.body_win)
	api.nvim_buf_set_option(self.body_buf, "modifiable", false)
end

function InteractiveMenu:_make_float(options)
	local buf = api.nvim_create_buf(false, false)

	local win = api.nvim_open_win(buf, true, {
		relative = "editor",
		border = "rounded",
		height = options.height,
		width = options.width,
		row = options.row,
		col = options.col,
	})

	api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	api.nvim_buf_set_option(buf, "buftype", "nofile")

	vim.opt_local.number = false
	vim.opt_local.relativenumber = false
	vim.opt_local.signcolumn = "no"
	vim.opt_local.colorcolumn = "0"
	vim.opt_local.list = false

	self:setup_highlights(win)

	return buf, win
end

function InteractiveMenu:setup_highlights(win)
	vim.api.nvim_win_set_option(win, "winhl", string.format("Normal:%s,EndOfBuffer:%s", "Normal", "Normal"))
end

function InteractiveMenu:setup_windows()
	-- the height and width of nvim
	local editor_width = api.nvim_get_option("columns")
	local editor_height = api.nvim_get_option("lines")

	local max_width = self.max_width
	if max_width == nil then
		max_width = editor_width
	end

	local max_height = self.max_height
	if max_height == nil then
		max_height = editor_height
	end

	-- the amount of the visible area the menu should take up
	local available_width = math.min(max_width, math.ceil(editor_width * 0.8))
	local available_height = math.min(max_height, math.ceil(editor_height * 0.8 - 4))

	-- get row/col that would center the windows in the editor
	local start_row = math.ceil((editor_height - available_height) / 2 - 1)
	local start_col = math.ceil((editor_width - available_width) / 2)

	local inner_header_height = #self.header_lines -- we add blank lines above and below for padding
	self.header_buf, self.header_win = self:_make_float({
		height = inner_header_height,
		width = available_width,
		row = start_row,
		col = start_col,
	})
	vim.opt_local.cursorcolumn = false
	vim.opt_local.cursorline = false

	-- inner height is the number of header lines, the total height inclues two more
	-- lines for the top and bottom borders
	local outer_header_height = inner_header_height + 2

	local body_height = available_height - outer_header_height

	self.body_buf, self.body_win = self:_make_float({
		height = body_height,
		width = available_width,
		row = start_row + outer_header_height,
		col = start_col,
	})

	self:setup_autocmds()
end

function InteractiveMenu:replace_body_buffer(new_buf)
	-- if we set a bufleave autocmd to close the buffer already we need to delete
	-- it so we can replace the buffer without closing the menu
	self:teardown_autocmds()

	api.nvim_win_set_buf(self.body_win, new_buf)
	self.body_buf = new_buf

	-- re-bind the bufleave autocmd
	self:setup_autocmds()
	self:set_keymaps()
	self:setup_highlights(self.body_win)
end

function InteractiveMenu:teardown_autocmds()
	for _, id in ipairs(self.autocmd_ids) do
		api.nvim_del_autocmd(id)
	end
	self.autocmd_ids = {}
end

function InteractiveMenu:setup_autocmds()
	table.insert(
		self.autocmd_ids,
		api.nvim_create_autocmd("BufLeave", {
			once = true,
			buffer = self.body_buf,
			callback = function()
				-- ensure we don't try to automatically reopen if they're closing the menu
				if not self.destroyed then
					-- close the menu when it loses focus
					self:destroy()
				end
			end,
		})
	)

	table.insert(
		self.autocmd_ids,
		api.nvim_create_autocmd("CursorMoved", {
			buffer = self.body_buf,
			callback = function()
				local last_row_possible = #self.body_lines

				if last_row_possible == 0 then
					return
				end

				local cursor = api.nvim_win_get_cursor(self.body_win)
				local new_row = nil

				if cursor[1] > last_row_possible then
					new_row = last_row_possible
				end

				if new_row ~= nil then
					api.nvim_win_set_cursor(self.body_win, { new_row, cursor[2] })
				end
			end,
		})
	)
end

function InteractiveMenu:destroy()
	if self.destroyed then
		return
	end

	self.destroyed = true

	api.nvim_win_close(self.body_win, true)
	api.nvim_win_close(self.header_win, true)

	if self.on_destroy ~= nil then
		self.on_destroy()
	end
end

function InteractiveMenu:set_keymaps()
	local function map(key, data)
		vim.keymap.set("n", key, function()
			local with_row = true

			if data.with_row ~= nil then
				with_row = data.with_row
			end

			local destroy = false
			if data.destroy ~= nil then
				destroy = data.destroy
			end

			if with_row then
				local cursor_row = api.nvim_win_get_cursor(self.body_win)[1]
				local body_line = self.body_lines[cursor_row]

				if body_line ~= nil then
					if destroy then
						self:destroy()
					end

					-- if a line is just for presentation then nil can be passed, skip the handler
					if body_line[1] ~= nil then
						data.handler(body_line[1])
					end
				end
			else
				if destroy then
					self:destroy()
				end

				data.handler()
			end
		end, {
			nowait = true,
			noremap = true,
			buffer = true,
		})
	end

	map("<esc>", { destroy = true, with_row = false, handler = function() end })

	for key, data in pairs(self.keymaps) do
		map(key, data)
	end
end

return InteractiveMenu
