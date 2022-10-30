# projectlaunch.nvim

This is a [Neovim](https://neovim.io/) plugin for running commands in your project. Have a bunch of commands you need to run to boot a site and kick off some build processes? Make a command group for them and start them all at once!

It will also try searching for commands in:

* `package.json` "scripts" object for NodeJS projects
* `Makefile`

I'm open to PRs adding support for more languages/ecosystem specific command registries.

_This currently requires a fairly new version of Neovim 0.7.0 for the Lua autocmd API._

https://user-images.githubusercontent.com/3468630/159603708-0045b827-4c51-42d6-afbe-28362f391989.mp4

## Configuration

Your project's configuration should be specified in a file (default filename is `.projectlaunch.json`) at the root of your project, it will specify any commands that can be run. If you're familiar with Typescript this is an interface that would describe it.

```Typescript
interface ProjectLaunchConfig {
    commands: {
        // a name for the command
        name: string;
        // the actual command that should be opened in a terminal
        cmd: string;
        // a list of group names this command belongs to
        groups?: string[];
        // a directory to run the command from (defaults to the project root)
        cwd?: string;
    }[]
}
```

```json
{
    "commands": [
        { "name": "Start", "cmd": "npm run dev", "groups": ["dev"] },
        { "name": "Build frontend", "cmd": "npm run build-frontend:dev", "groups": ["dev"] },
        { "name": "Build server", "cmd": "npm run build-server:dev", "groups": ["dev"] },
        { "name": "Lint frontend", "cmd": "npm run lint-frontend:dev", "groups": ["lint", "test"] },
        { "name": "Lint server", "cmd": "npm run lint-server:dev", "groups": ["lint", "test"] },
        { "name": "Test", "cmd": "npm test", "groups": ["test"] }
    ]
}
```

### Example configuration

```lua

-- optionally override defaults
local projectlaunch = require('projectlaunch')

projectlaunch.setup({
    -- set a default width for split windows
    split_default_width = 80 
    -- if opening the split terminal should move focus to the split's window
    split_focus_on_open = false,
    -- the filename of configuration file which under root directory.
    config_path = ".projectlaunch.json",
})

-- open the main menu
vim.keymap.set('n', "<leader>ll", projectlaunch.toggle_main_menu, {noremap = true, expr = false, buffer = false})

-- open the floating window terminal viewer
vim.keymap.set('n', "<leader>lf", projectlaunch.toggle_float, {noremap = true, expr = false, buffer = false})

-- open the split window terminal viewer
vim.keymap.set('n', "<leader>ls", projectlaunch.toggle_split, {noremap = true, expr = false, buffer = false})

-- show the next or previous terminals in the open viewer
vim.keymap.set('n', "<leader>ln", projectlaunch.show_next, {noremap = true, expr = false, buffer = false})
vim.keymap.set('n', "<leader>lm", projectlaunch.show_prev, {noremap = true, expr = false, buffer = false})

-- restart the command running in the currently open split terminal
vim.keymap.set('n', "<leader>lr", projectlaunch.restart_command_in_split, {noremap = true, expr = false, buffer = false})

-- add custom commands programmatically. you can write your own lua code to add a list of commands
-- from a tool you use that projectlaunch.nvim doesn't support. or type part of a long command that
-- you need to use occasionally, then use 'e' in the prompt menu to edit and add the rest, like for
-- running specific parts of test suites, put everything but the test suite name in here then edit later
projectlaunch.add_custom_command("npm test")
```

### Hotkeys

In all floating windows `<esc>` closes the window (terminal windows will keep running in the background).

Main Menu

* `p` - open the command/group selection window ("Prompt menu")
* Commands that run on the job under the cursor
	* `f` - show the terminal output in a floating window
	* `s` - show the terminal output in a split window
	* `R` - restart command
	* `X` - kill running command (if command has stopped already `X` removes it from the list)

Prompt menu

* `<CR>` - run the command or group under the cursor
* `c` - enter a command manually (will show under a "Custom" heading). These commands aren't saved, use this when you just want to run a one off command.
* `e` - edit the command (edits in-place for custom commands created with `c`, creates a new custom if any other command source is used). Pressing `R` over an edited command in the main menu will restart it using the new command.

Terminals

* `(` - view the previous command's terminal output
* `)` - view the next command's terminal output

### Highlights

Commands in the main menu are highlighted using the following highlight groups:

```vim
" highlights for commands that are currently running
hi def link ProjectLaunchRunning Normal
" highlights for commands that have exited
hi def link ProjectLaunchExited Comment
```

### Goals

Eventually I want this to...
* look for your project root. Right now it assumes `cwd` is the root of your project.
* support more alternative command sources
* have tests!
