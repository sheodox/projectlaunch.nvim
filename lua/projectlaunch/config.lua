local M = {}
local api = vim.api
local util = require("projectlaunch.util")
local path = require("projectlaunch.path")
local options = require("projectlaunch.options")
local config_utils = require("projectlaunch.config_utils")
local alt_configs = {
	nodejs = require("projectlaunch.alternate_configs.nodejs"),
	makefile = require("projectlaunch.alternate_configs.makefile"),
}

local cached_config = nil
local cached_ecosystem_specific_configs = nil

function M.get_project_config()
	if cached_config ~= nil then
		return cached_config
	end

	local config_path = path.join(config_utils.get_project_root(), options.get().config_path)
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
-- is the 'heading' these commands will show under in the prompt menu.
local ecosystem_specific_getters = {
	{ "package.json", alt_configs.nodejs.get_config },
	{ "Makefile", alt_configs.makefile.get_config },
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

return M
