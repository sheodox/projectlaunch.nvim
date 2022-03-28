local M = {}
local util = require("projectlaunch.util")
local config_utils = require("projectlaunch.config_utils")

-- https://www.gnu.org/software/make/manual/html_node/Makefile-Names.html
local makefile_file_names = { "GNUmakefile", "makefile", "Makefile" }
local function has_makefile(project_files)
	for _, file in ipairs(makefile_file_names) do
		if vim.tbl_contains(project_files, file) then
			return true
		end
	end
end

function M.get_config(project_files)
	if not has_makefile(project_files) then
		return
	end

	if vim.fn.executable("make") == 0 then
		util.log("Makefile found but make isn't installed")
		return
	end

	local make_db_dump_blocks = vim.split(vim.fn.system("make -qpRr"), "\n\n")
	local make_targets = {}

	for _, value in ipairs(make_db_dump_blocks) do
		-- make will have a lot of comments in the output like "# Not a target:", ignore those blocks
		-- as they are not targets
		local target = vim.trim(vim.split(value, ":")[1])
		-- target has to start with a lowercase letter
		if target:match("^%w[^$#\\/\t=]") then
			table.insert(make_targets, target)
		end
	end

	if #make_targets == 0 then
		return
	end

	local config = { commands = {
		{ cmd = "make" },
	} }
	for _, target in ipairs(make_targets) do
		table.insert(config.commands, { cmd = "make " .. target })
	end

	return config_utils.Config:new(config)
end

return M
