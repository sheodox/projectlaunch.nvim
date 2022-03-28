local M = {}
local path = require("projectlaunch.path")
local config_utils = require("projectlaunch.config_utils")

function M.get_config(project_files)
	if not vim.tbl_contains(project_files, "package.json") then
		return
	end

	local packagejson_path = path.join(config_utils.get_project_root(), "package.json")
	local ok, packagejson = pcall(config_utils.read_json_file, packagejson_path)

	local runner = "npm"
	-- if they have a yarn.lock file they probably want to run using yarn instead of npm
	if vim.tbl_contains(project_files, "yarn.lock") then
		runner = "yarn"
	end

	if ok and packagejson.scripts ~= nil then
		local config = { commands = {} }

		for name, _ in pairs(packagejson.scripts) do
			table.insert(config.commands, { cmd = runner .. " run " .. name })
		end

		return config_utils.Config:new(config)
	else
		return nil
	end
end

return M
