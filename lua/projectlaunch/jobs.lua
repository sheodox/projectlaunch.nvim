local config_utils = require("projectlaunch.config_utils")
local win = require("projectlaunch.win")
local api = vim.api

local term_name_prefix = "ProjectLaunch terminal - "

local Job = {}
function Job:new(command, opts)
	local temp_win, buf = win.create_temp_window()
	vim.opt_local.spell = false

	api.nvim_buf_set_name(buf, term_name_prefix .. command.name)

	local cwd = config_utils.get_project_root()
	if command.cwd ~= nil then
		cwd = command.cwd
	end

	local j = {
		-- duplicating the name lets commands be edited and
		-- jobs won't get the updated command until it's rerun,
		-- so it won't look like the newly edited command had been run automatically
		name = command.name,
		cmd = command.cmd,
		job_id = nil,
		buf = buf,
		running = true,
		exit_code = nil,
		-- store this for duplicating the job when restarting
		_args = { command, opts },
	}

	j.job_id = vim.fn.termopen(vim.split(command.cmd, " "), {
		cwd = cwd,
		on_exit = function(_, exit_code)
			j.running = false
			j.exit_code = exit_code

			if opts.on_exit ~= nil then
				opts.on_exit()
			end
		end,
	})

	api.nvim_win_close(temp_win, true)

	api.nvim_buf_set_option(buf, "bufhidden", "hide")
	api.nvim_buf_set_option(buf, "buflisted", false)

	self.__index = self
	return setmetatable(j, self)
end

function Job:kill()
	vim.fn.jobstop(self.job_id)
end

return Job
