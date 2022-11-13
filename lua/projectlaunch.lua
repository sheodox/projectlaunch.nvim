local M = {}

local term = require("projectlaunch.term")
local main_menu = require("projectlaunch.main_menu")
local config = require("projectlaunch.config")
local options = require("projectlaunch.options")

-- show/hide the main menu, all things can start from here
M.toggle_main_menu = main_menu.toggle_main_menu

-- show/hide terminals in a floating window or split window
M.toggle_float = term.toggle_float
M.toggle_split = term.toggle_split

M.restart_command_in_split = term.restart_job_in_split

-- show the next or previous terminal in the open float or split window
M.show_prev = term.show_prev
M.show_next = term.show_next

M.setup = function(opts)
	options.override(opts)
end

M.add_custom_command = config.add_custom_command

return M
