local M = {}
local config = require("config")
local util = require("util")
local InteractiveMenu = require("interactive_menu")
local term = require("term")

local main_menu = nil
local max_menu_width = 50
local max_menu_text_width = 50
local max_menu_height = 30

function M.launch_group(group)
	local cfg = config.get_project_config()
	local cmds = cfg:find_by_group(group)

	for _, cmd in ipairs(cmds) do
		M.launch_command(cmd)
	end
end

function M.launch_command(cmd)
	term.spawn_term(cmd, {
		on_exit = M.render_menu,
	})
end

local function prompt_launch()
	local cfg = config.get_project_config()
	local ecosystem_cfg = config.get_ecosystem_configs()
	local prompt_menu = nil

	if cfg == nil and not util.table_has_items(ecosystem_cfg) then
		util.log(
			"No .projectlaunch.json file or supported ecosystem specific configuration files were found at "
				.. config.get_project_root()
		)
		return
	end

	local lines = {}

	if cfg ~= nil then
		if #cfg.commands < 0 then
			util.log("No commands found in .projectlaunch.json")
		else
			if #cfg.groups > 0 then
				table.insert(lines, { nil, "Groups" })

				for _, group in ipairs(cfg.groups) do
					table.insert(lines, { { group = group }, "  " .. group })
				end
			end

			if #cfg.commands > 0 then
				table.insert(lines, { nil, "Commands" })

				for _, command in ipairs(cfg.commands) do
					table.insert(lines, { { command = command }, "  " .. command.name })
				end
			end
		end
	end

	for ecosystem_name, ecosystem_config in pairs(ecosystem_cfg) do
		table.insert(lines, { nil, ecosystem_name })

		for _, command in ipairs(ecosystem_config.commands) do
			table.insert(lines, { { command = command }, "  " .. command.name })
		end
	end

	local function spawn(data)
		if data.group then
			M.launch_group(data.group)
		else
			M.launch_command(data.command)
		end

		-- show the status of the newly spawned commands
		M.toggle_main_menu()
	end

	prompt_menu = InteractiveMenu:new({
		header_lines = { "What do you want to launch?" },
		body_lines = lines,
		max_height = max_menu_height,
		max_width = max_menu_width,
		keymaps = {
			["<cr>"] = { handler = spawn, destroy = true },
			m = { handler = M.toggle_main_menu, destroy = true },
		},
	})
	prompt_menu:render()
end

local function show_in_float(data)
	term.show_float(data.index)
end

local function show_in_split(data)
	term.show_split(data.index)
end

local function restart_job(data)
	-- restarting a job will briefly close the menu (new window opened to create a terminal
	-- will close the menu because of the BufLeave autocmd, keep track of the cursor so
	-- we can reopen the menu in the same place they were)
	local menu_cursor_position = vim.api.nvim_win_get_cursor(0)
	term.restart_job(data.job)
	util.log("Restarted '" .. data.job.name .. "'")

	--  spawning the new job requires creating a new window (can't open a terminal in a dirty buffer)
	--  so we need to manually reopen the main menu
	M.toggle_main_menu()
	vim.api.nvim_win_set_cursor(0, menu_cursor_position)
end

local function kill_job(data)
	data.job:kill()
	util.log("Killed '" .. data.job.name .. "'")
end

function M.render_menu()
	-- status code updates come through here (on_exit callback), but if the
	-- menu isn't showing right now there's nothing we can update
	if main_menu == nil then
		return
	end

	local status_lines = {}

	for job_index, job in ipairs(term.jobs) do
		local status = "running"
		if not job.running then
			status = "exit code " .. tostring(job.exit_code)
		end

		local row_data = {
			index = job_index,
			job = job,
		}
		table.insert(status_lines, { row_data, job.name .. "  -  (" .. tostring(status) .. ")" })
	end

	if #term.jobs == 0 then
		table.insert(status_lines, { nil, util.center(" --  Nothing is running, press p -- ", max_menu_text_width) })
	end

	main_menu:render_body(status_lines)
end

function M.toggle_main_menu()
	if main_menu ~= nil then
		main_menu:destroy()
	else
		main_menu = InteractiveMenu:new({
			header_lines = { "ProjectLaunch.nvim" },
			body_lines = {},
			max_height = max_menu_height,
			max_width = max_menu_width,
			on_destroy = function()
				main_menu = nil
			end,
			keymaps = {
				p = { handler = prompt_launch, with_row = false, destroy = true },
				f = { handler = show_in_float, destroy = true },
				s = { handler = show_in_split, destroy = true },
				R = { handler = restart_job },
				X = { handler = kill_job },
			},
		})
		main_menu:render()

		M.render_menu()
	end
end

return M
