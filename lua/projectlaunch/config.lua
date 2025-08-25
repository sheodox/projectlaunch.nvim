local M = {}
local api = vim.api
local util = require("projectlaunch.util")
local path = require("projectlaunch.path")
local options = require("projectlaunch.options")
local config_utils = require("projectlaunch.config_utils")
local alt_configs = {
	nodejs = require("projectlaunch.alternate_configs.nodejs"),
	makefile = require("projectlaunch.alternate_configs.makefile"),
	cargo = require("projectlaunch.alternate_configs.cargo"),
}

local cached_config = nil
local cached_ecosystem_specific_configs = nil

local function get_config_path()
	return path.join(config_utils.get_project_root(), options.get().config_path)
end

function M.get_project_config()
	if cached_config ~= nil then
		return cached_config
	end

	local config_path = get_config_path()
	local ok, config = pcall(config_utils.read_json_file, config_path)

	if ok then
		cached_config = config_utils.Config:new(config)
	else
		cached_config = config_utils.Config:new()
	end

	return cached_config
end

function M.add_custom_command(cmd)
	assert(cmd ~= nil and cmd ~= "", "can't add a blank command")

	local config = M.get_project_config()
	config:add_custom(cmd)
end

-- for languages/ecosystems that have a standard way to specify lists of commands
-- they can be added here, along with a language specific parser. The format is
-- { string, function } where the the string is the name to show these commands
-- is the 'heading' these commands will show under in the launch menu.
local ecosystem_specific_getters = {
	{ "package.json", alt_configs.nodejs.get_config },
	{ "Makefile", alt_configs.makefile.get_config },
	{ alt_configs.cargo.name, alt_configs.cargo.get_config },
}

function M.get_ecosystem_configs()
	if cached_ecosystem_specific_configs ~= nil then
		return cached_ecosystem_specific_configs
	end
	cached_ecosystem_specific_configs = {}

	local project_root_dir_list = vim.fn.readdir(config_utils.get_project_root())

	for _, eco in ipairs(ecosystem_specific_getters) do
		local name, getter = eco[1], eco[2]

		local config = getter(project_root_dir_list)

		if config ~= nil and #config.commands > 0 then
			cached_ecosystem_specific_configs[name] = config
		end
	end

	return cached_ecosystem_specific_configs
end

function M.has_commands()
	local has_project_config = M.get_project_config():has_things()
	local has_ecosystem_config = false

	for eco_name, eco_cfg in pairs(M.get_ecosystem_configs()) do
		if eco_cfg:has_things() then
			has_ecosystem_config = true
		end
	end

	return has_project_config or has_ecosystem_config
end

function M.reload_config()
	cached_config = nil
	cached_ecosystem_specific_configs = nil
	M.get_project_config()
	M.get_ecosystem_configs()
end

local function reload_config()
	if options.get().auto_reload_config then
		M.reload_config()
	end
end

-- reload config when reload a saved session
api.nvim_create_autocmd("SessionLoadPost", {
	group = util.augroup,
	callback = reload_config,
})

-- reload config when updated custom config
api.nvim_create_autocmd("BufWritePost", {
	group = util.augroup,
	pattern = "*.json",
	callback = reload_config,
})

-- validate config file exists and approximates format
--
-- File validation is purposely very loose so it is typo resistant.
-- Loose validation prevents the overwriting of user commands.
local function file_approximates_format()
	local approximates_expected_format = nil

	local file_readable = vim.fn.filereadable(get_config_path())

	if file_readable == 0 then
		vim.notify("Config doesn't exist", vim.log.levels.WARN)
	else
		local lines = vim.fn.readfile(get_config_path())
		local content = table.concat(lines, "\n")

		local has_commands = string.find(content, 'commands"')
		local has_curly_brace = string.find(content, "{")
		local has_name = string.find(content, '"name"')
		local has_cmd = string.find(content, '"cmd"')

		if has_commands and has_curly_brace and has_name and has_cmd then
			approximates_expected_format = 1
		end
	end

	return approximates_expected_format
end

local function create_default_launch_JSON()
	local default_config = {
		commands = {
			{
				name = "default",
				cmd = "echo hello world",
			},
		},
	}

	local default_json = vim.fn.json_encode(default_config)

	vim.notify("Writing default launch JSON", vim.log.levels.INFO)
	vim.fn.writefile({ default_json }, get_config_path())
end

local function open_launch_file()
	if not file_approximates_format() then
		create_default_launch_JSON()
	end

	vim.cmd.edit(get_config_path())
end

function M.edit_config()
	open_launch_file()
end

return M
