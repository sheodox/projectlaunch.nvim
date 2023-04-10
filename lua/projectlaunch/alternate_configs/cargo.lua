local M = {}
-- local path = require("projectlaunch.path")
local config_utils = require("projectlaunch.config_utils")
local util = require("projectlaunch.util")

M.name = "Cargo"
M.runner = "cargo"

M.is_runner_executable = function()
	return vim.fn.executable(M.runner) == 1
end

M.is_detected = function(project_files)
	-- matching `src/` and `Cargo.toml`
	return vim.tbl_contains(project_files, "src") and vim.tbl_contains(project_files, "Cargo.toml")
end

M.get_config = function(project_files)
	if M.is_detected(project_files) then
		if not M.is_runner_executable() then
			util.log(M.runner .. " is not executable.")
		end

		-- available cargo commands in project scope
		local available_commands = {
			"run",
			"build",
			"build --release",
			"check",
			"clean",
			"init",
			"update",
			"test",
			"bench",
		}

		local config = {
			commands = {},
		}

		for i = 1, #available_commands, 1 do
			table.insert(config.commands, { cmd = M.runner .. " " .. available_commands[i] })
		end

		return config_utils.Config:new(config)
	end

	return nil
end

return M
