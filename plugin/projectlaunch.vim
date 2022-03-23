if exists('g:loaded_projectlaunch') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

lua require('projectlaunch')

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_projectlaunch = 1
