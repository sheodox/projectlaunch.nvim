if exists('g:loaded_projectlaunch') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

lua require('projectlaunch')

" highlights for commands that are currently running
hi def link ProjectLaunchRunning Normal
" highlights for commands that have exited
hi def link ProjectLaunchExited Comment

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_projectlaunch = 1
