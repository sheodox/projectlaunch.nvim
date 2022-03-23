local M = {}
local Job = require("jobs")
local util = require("util")
local InteractiveMenu = require("interactive_menu")
local win = require("win")
local api = vim.api

local viewing_index = {
	float = 1,
	split = 1,
}
M.jobs = {}
local split_win = nil
local floating_menu = nil

function M.spawn_term(command, opts)
	local job = Job:new(command, opts)
	table.insert(M.jobs, job)
end

function M.show_term(win_type)
	local job = M.jobs[viewing_index[win_type]]

	if win_type == "split" then
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
	else
		M.show_float()
	end
end

local function assert_valid_win_type(win_type)
	assert(
		win_type == "float" or win_type == "split",
		'win_type must be "split" or "float", got "' .. tostring(win_type) .. '"'
	)
end

function M.next_terminal(win_type)
	assert_valid_win_type(win_type)
	viewing_index[win_type] = viewing_index[win_type] + 1

	if viewing_index[win_type] > #M.jobs then
		viewing_index[win_type] = 1
	end

	M.show_term(win_type)
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

function M.toggle_float()
	if not has_jobs() then
		return
	end

	if floating_menu == nil then
		M.show_float()
	else
		floating_menu:destroy()
		floating_menu = nil
	end
end

function M.toggle_split()
	if not has_jobs() then
		return
	end

	if split_win == nil then
		M.show_split()
	else
		api.nvim_win_close(split_win, true)
		split_win = nil
	end
end

function M.show_split(job_index)
	if job_index ~= nil then
		viewing_index.split = util.clamp(job_index, 0, #M.jobs)
	end

	if split_win == nil then
		split_win = win.create_split_window()
	end
	M.show_term("split")
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
end

-- when a window is closed, if it's one of the terminals we need to nil it
-- out so it can be recreated when it it's toggled again
api.nvim_create_autocmd("WinClosed", {
	group = util.augroup,
	callback = function()
		local closing_win = api.nvim_get_current_win()
		if closing_win == split_win then
			split_win = nil
		end
	end,
})

function M.restart_job(old_job)
	if old_job.running then
		old_job:kill()
	end

	-- TODO call vim.api.jobwait?

	local job_index = util.find_index(M.jobs, old_job)
	local new_job = Job:new(old_job._args[1], old_job._args[2])

	M.jobs[job_index] = new_job

	local active = M.get_active_window_type()
	if active ~= nil then
		M.show_term(active)
	end
end

function M.get_active_window_type()
	-- floating menus cannot be open and not be focused, if a floating menu terminal is open it's all there is
	if floating_menu ~= nil then
		return "float"
	elseif split_win ~= nil then
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

return M
