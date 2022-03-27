local M = {}
local path = require("projectlaunch.path")
local util = require("projectlaunch.util")

local cached_config = nil
local cached_ecosystem_specific_configs = nil

function M.get_project_root()
	-- TODO make this search for the closest directory containing .git
	return vim.fn.getcwd()
end

--[[
interface Config {
	commands: {
		name: string; // the name for this command
		cmd: string; // the command to run
		// array of group names this belongs to, all commands in a group can be
		// launched at once so multiple groups can be used for different workflows
		groups: string[];
		cwd?: string;
    }[]
}
--]]

local function read_json_file(p)
	local json_text = vim.fn.readfile(p)
	return vim.fn.json_decode(json_text)
end

local function get_groups(config)
	local groups = {}
	for _, command in ipairs(config.commands) do
		if command.groups ~= nil then
			for _, group in ipairs(command.groups) do
				if not vim.tbl_contains(groups, group) then
					table.insert(groups, group)
				end
			end
		end
	end

	return groups
end

local Config = {}
function Config:new(cfg)
	table.sort(cfg.commands, function(a, b)
		return a.name < b.name
	end)

	local groups = get_groups(cfg)
	table.sort(groups, function(a, b)
		return a < b
	end)

	local c = {
		commands = cfg.commands,
		groups = groups,
	}
	self.__index = self
	return setmetatable(c, self)
end

function Config:find_by_group(group_name)
	local cmds = {}

	for _, cmd in ipairs(self.commands) do
		if cmd.groups ~= nil then
			if vim.tbl_contains(cmd.groups, group_name) then
				table.insert(cmds, cmd)
			end
		end
	end
	return cmds
end

function M.get_project_config()
	if cached_config ~= nil then
		return cached_config
	end

	local config_path = path.join(M.get_project_root(), ".projectlaunch.json")
	local ok, config = pcall(read_json_file, config_path)

	if ok then
		cached_config = Config:new(config)

		return cached_config
	else
		return nil
	end
end

local function get_nodejs_config(project_files)
	if not vim.tbl_contains(project_files, "package.json") then
		return
	end

	local packagejson_path = path.join(M.get_project_root(), "package.json")
	local ok, packagejson = pcall(read_json_file, packagejson_path)

	local runner = "npm"
	-- if they have a yarn.lock file they probably want to run using yarn instead of npm
	if vim.tbl_contains(project_files, "yarn.lock") then
		runner = "yarn"
	end

	if ok and packagejson.scripts ~= nil then
		local config = { commands = {} }

		for name, _ in pairs(packagejson.scripts) do
			table.insert(config.commands, { name = name, cmd = runner .. " run " .. name, groups = {} })
		end

		return Config:new(config)
	else
		return nil
	end
end

-- for languages/ecosystems that have a standard way to specify lists of commands
-- they can be added here, along with a language specific parser. The format is
-- { string, function } where the the string is the name to show these commands
-- is the 'heading' these commands will show under in the prompt menu.
local ecosystem_specific_getters = {
	{ "package.json", get_nodejs_config },
}

function M.get_ecosystem_configs()
	if cached_ecosystem_specific_configs ~= nil then
		return cached_ecosystem_specific_configs
	end
	cached_ecosystem_specific_configs = {}

	local project_root_dir_list = vim.fn.readdir(M.get_project_root())

	for _, eco in ipairs(ecosystem_specific_getters) do
		local name, getter = eco[1], eco[2]

		local config = getter(project_root_dir_list)

		if config ~= nil and #config.commands > 0 then
			cached_ecosystem_specific_configs[name] = config
		end
	end

	return cached_ecosystem_specific_configs
end

return M
