if exists('g:enable_managenvimsessions') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions

set cpo&vim " reset them to defaults

highlight SessionsWindow ctermbg=234 guibg=#1d1d1d ctermfg=10 guifg=#f9f9f9

" command to run plugin
command! ManageNvimSessions lua require("manage-nvim-sessions").mns()
command! MakeSession lua require("manage-nvim-sessions").ms()
command! UpdateSession lua require("manage-nvim-sessions").us()
command! DeleteSession lua require("manage-nvim-sessions").ds()
command! CurrentSession lua require("manage-nvim-sessions").cs()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:enable_managenvimsessions = 1
if exists('g:enable_mns_on_start') && g:enable_mns_on_start
	au VimEnter * nested :ManageNvimSessions
endif
