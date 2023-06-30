local config_utils = require("projectlaunch.config_utils")
local win = require("projectlaunch.win")
local api = vim.api

local term_name_prefix = "ProjectLaunch terminal - "

local Job = {}
runtimeVars = {}

function Job:new(command, opts)
    runtimeVars = {}
    local finalCommand = generateCommand(command)
	
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
		name = generateJobName(command),
		cmd = finalCommand,
		job_id = nil,
		buf = buf,
		running = true,
		exit_code = nil,
		-- store this for duplicating the job when restarting
		_args = { command, opts },
	}

	j.job_id = vim.fn.termopen(vim.split(finalCommand, " "), {
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

function generateCommand(originalCommand) 
	local finalCommand = originalCommand.cmd 

    for i = 1,5,1
    do
        local substitutionString = "$" .. i

        if string.find(originalCommand.cmd, substitutionString) then
            setRuntimeVarViaPrompt(substitutionString, finalCommand)
            finalCommand = string.gsub(finalCommand, substitutionString, runtimeVars[i])
        end
    end

    return finalCommand
end

function generateJobName(command) 
    if(table.getn(runtimeVars) > 0) then
       local args = "" 
       
       for key, value in pairs(runtimeVars) do
          args = args .. value .. "," 
       end 

       args = args:sub(1, -2) --Remove trailing comma

       return command.name .. " (" .. args .. ")"
    end 

    return command.name
end


function setRuntimeVarViaPrompt(var, command)
    vim.ui.input({ prompt = "ProjectLaunch: Enter argument " .. var .. " for\n" .. command .. "\n:"}, function(input)
        table.insert(runtimeVars, input) 
    end)
end


function replaceVariableInCommand(var, finalCommand)
    vim.ui.input({ prompt = "ProjectLaunch: Enter argument " .. var .. ": "}, function(cmd)
        finalCommand = string.gsub(finalCommand, var, cmd)
    end)

    return finalCommand
end

return Job

