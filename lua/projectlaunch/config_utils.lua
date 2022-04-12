local M = {}

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

function M.read_json_file(p)
	local json_text = vim.fn.readfile(p)
	return vim.fn.json_decode(json_text)
end

local Config = {}
M.Config = Config

function Config:new(cfg)
	if cfg == nil then
		cfg = { commands = {} }
	end

	-- if no name specified, use the command (used by alternate sources)
	for _, command in ipairs(cfg.commands) do
		if command.name == nil then
			command.name = command.cmd
		end
	end

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
		custom = {},
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

function Config:add_custom(cmd)
	if cmd ~= "" and cmd ~= nil then
		table.insert(self.custom, { name = cmd, cmd = cmd })
	end
end

function Config:has_things()
	return #self.commands > 0 or #self.custom > 0
end

function Config:update_custom(custom_index, new_cmd)
	if new_cmd == "" or new_cmd == nil then
		return
	end

	self.custom[custom_index].name = new_cmd
	self.custom[custom_index].cmd = new_cmd
end

return M
