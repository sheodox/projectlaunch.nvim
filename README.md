# projectlaunch.nvim

This is a [Neovim](https://neovim.io/) plugin for running commands in your project. Have a bunch of commands you need to run to boot a site and kick off some build processes? Make a command group for them and start them all at once!

https://user-images.githubusercontent.com/3468630/159603708-0045b827-4c51-42d6-afbe-28362f391989.mp4

## Configuration

Your project's configuration should be specified in a `.projectlaunch.json` file at the root of your project, it will specify any commands that can be run. If you're familiar with Typescript this is an interface that would describe it.

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
        { "name": "Lint frontend", "cmd": "npm run lint-server:dev", "groups": ["lint", "test"] },
        { "name": "Lint server", "cmd": "npm run build-server:dev", "groups": ["lint", "test"] },
        { "name": "Test", "cmd": "npm test", "groups": ["test"] }
    ]
}
```

### Example configuration

```lua

-- open the main menu
vim.keymap.set('n', "<leader>ll", require('projectlaunch').toggle_menu, {noremap = true, expr = false, buffer = false})
-- open the floating window terminal viewer
vim.keymap.set('n', "<leader>lf", require('projectlaunch').toggle_float, {noremap = true, expr = false, buffer = false})
-- open the split window terminal viewer
vim.keymap.set('n', "<leader>ls", require('projectlaunch').toggle_split, {noremap = true, expr = false, buffer = false})
-- show the next or previous terminals in the open viewer
vim.keymap.set('n', "<leader>ln", require('projectlaunch').show_next, {noremap = true, expr = false, buffer = false})
vim.keymap.set('n', "<leader>lm", require('projectlaunch').show_prev, {noremap = true, expr = false, buffer = false})
```

### Hotkeys

In all floating windows `<esc>` closes the window (terminal windows will keep running in the background).

Main Menu

* `p` - open the command/group selection window ("Prompt menu")
* Commands that run on the job under the cursor
	* `f` - show the terminal output in a floating window
	* `s` - show the terminal output in a split window
	* `R` - restart command
	* `X` - kill running command

Prompt menu

* `<CR>` - run the command or group under the cursor

Terminals

* `(` - view the previous command's terminal output
* `)` - view the previous command' terminal output

### Goals

Eventually I want this to...
* be able to read `package.json` scripts (or other language/ecosystem specific command lists) and offer those as options to run.
* look for your project root. Right now it assumes `cwd` is the root of your project.
