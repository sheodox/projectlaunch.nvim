local M = {}

local function get_default_options()
  return {
    split_default_width = 80,
    split_focus_on_open = false,
    config_path = ".projectlaunch.json",
    auto_reload_config = true,
    max_menu_width = 50,
    max_menu_height = 30,
  }
end

local options = get_default_options()

function M.override(opts)
  options = vim.tbl_deep_extend("force", get_default_options(), opts or {})
end

function M.get()
  return options
end

return M
