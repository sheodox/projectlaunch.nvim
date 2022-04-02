local M = {}
local Job = require("projectlaunch.jobs")
local util = require("projectlaunch.util")
local InteractiveMenu = require("projectlaunch.interactive_menu")
local win = require("projectlaunch.win")
local api = vim.api

local viewing_index = {
	float = 1,
	split = 1,
}
M.jobs = {}
local split_win = nil
local floating_menu = nil

local function assert_valid_win_type(win_type)
	assert(
		win_type == "float" or win_type == "split",
		'win_type must be "split" or "float", got "' .. tostring(win_type) .. '"'
	)
end

function M.spawn_term(command, opts)
	local job = Job:new(command, opts)
	table.insert(M.jobs, job)
end

function M.show_term(win_type)
	assert_valid_win_type(win_type)

	if win_type == "split" then
		local job = M.jobs[viewing_index[win_type]]
		api.nvim_win_set_buf(split_win, job.buf)

		-- InteractiveMenu handles these hotkeys for the floating window, not so much for the split
		vim.keymap.set("n", "(", function()
			M.show_prev()
		end, {
			nowait = true,
			noremap = true,
			buffer = true,
		})

		vim.keymap.set("n", ")", function()
			M.show_next()
		end, {
			nowait = true,
			noremap = true,
			buffer = true,
		})
	elseif win_type == "float" then
		M.show_float()
	end
end

function M.next_terminal(win_type)
	assert_valid_win_type(win_type)
	viewing_index[win_type] = viewing_index[win_type] + 1

	if viewing_index[win_type] > #M.jobs then
		viewing_index[win_type] = 1
	end

	M.show_term(win_type)
end

function M.scroll_to_bottom()
	api.nvim_win_set_cursor(0, { api.nvim_buf_line_count(0), 0 })
end

function M.prev_terminal(win_type)
	assert_valid_win_type(win_type)
	viewing_index[win_type] = viewing_index[win_type] - 1

	if viewing_index[win_type] < 1 then
		viewing_index[win_type] = #M.jobs
	end

	M.show_term(win_type)
end

function M.has_jobs()
	return #M.jobs > 0
end

local function has_jobs()
	if not M.has_jobs() then
		util.log("No commands are running.")
		return false
	end
	return true
end

local function is_split_usable()
	if split_win == nil or not vim.api.nvim_win_is_valid(split_win) then
		return false
	end

	-- the buffer in the split window could have changed, check if it still has a terminal buffer in it
	-- otherwise we need to open a new split
	local buf_in_last_known_split = vim.api.nvim_win_get_buf(split_win)

	local term_bufs = {}
	for _, job in ipairs(M.jobs) do
		table.insert(term_bufs, job.buf)
	end

	return vim.tbl_contains(term_bufs, buf_in_last_known_split)
end

function M.toggle_float()
	if not has_jobs() then
		return
	end

	if floating_menu == nil then
		M.show_term("float")
	else
		floating_menu:destroy()
		floating_menu = nil
	end
end

function M.toggle_split()
	if not has_jobs() then
		return
	end

	if is_split_usable() then
		api.nvim_win_close(split_win, true)
		split_win = nil
	else
		M.show_split()
	end
end

function M.show_split(job_index)
	if job_index ~= nil then
		viewing_index.split = util.clamp(job_index, 0, #M.jobs)
	end

	if not is_split_usable() then
		split_win = win.create_split_window()
	end

	M.show_term("split")
	M.scroll_to_bottom()
end

function M.show_float(job_index)
	if job_index ~= nil then
		viewing_index.float = util.clamp(job_index, 0, #M.jobs)
	else
		job_index = viewing_index.float
	end

	local job = M.jobs[viewing_index.float]

	if floating_menu == nil then
		floating_menu = InteractiveMenu:new({
			header_lines = { "", "" },
			body_lines = {},
			keymaps = {
				["("] = {
					with_row = false,
					handler = function()
						M.show_prev()
					end,
				},
				[")"] = {
					with_row = false,
					handler = function()
						M.show_next()
					end,
				},
			},
			on_destroy = function()
				floating_menu = nil
			end,
		})
		floating_menu:render()

		-- when a window is closed, if it's one of the terminals we need to nil it
		-- out so it can be recreated when it it's toggled again
		api.nvim_create_autocmd("WinClosed", {
			buffer = job.buf,
			once = true,
			callback = function()
				if floating_menu ~= nil then
					floating_menu:destroy()
				end
			end,
		})
	end

	floating_menu:render_header({ job.name, "(" .. job_index .. "/" .. #M.jobs .. ")" })
	floating_menu:replace_body_buffer(job.buf)

	M.scroll_to_bottom()
end

function M.restart_job(old_job)
	if old_job.running then
		old_job:kill()
	end

	-- TODO call vim.api.jobwait?

	local job_index = util.find_index(M.jobs, old_job)
	local new_job = Job:new(old_job._args[1], old_job._args[2])
	local active_win_type = M.get_active_window_type()

	M.jobs[job_index] = new_job

	if active_win_type ~= nil then
		M.show_term(active_win_type)
	end
end

function M.get_active_window_type()
	-- floating menus cannot be open and not be focused, if a floating menu terminal is open it's all there is
	if floating_menu ~= nil then
		return "float"
	elseif is_split_usable() then
		return "split"
	end
end

function M.show_next()
	local active = M.get_active_window_type()
	if active ~= nil then
		M.next_terminal(active)
	end
end

function M.show_prev()
	local active = M.get_active_window_type()
	if active ~= nil then
		M.prev_terminal(active)
	end
end

function M.restart_job_in_split()
	if not is_split_usable() then
		return
	end

	local split_job = M.jobs[viewing_index.split]

	if split_job ~= nil then
		M.restart_job(split_job)
	end
end

return M
