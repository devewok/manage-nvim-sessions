if exists('g:enable_load_nvim_sessions') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions

set cpo&vim " reset them to defaults

highlight CustomFloatingWindow ctermbg=234 guibg=#1d1d1d ctermfg=10 guifg=white

" command to run plugin
command! LoadNvimSessions lua require("load-nvim-sessions").lns()
command! MakeSession lua require("load-nvim-sessions").ms()
command! UpdateSession lua require("load-nvim-sessions").us()
command! DeleteSession lua require("load-nvim-sessions").ds()
command! CurrentSession lua require("load-nvim-sessions").cs()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:enable_load_nvim_sessions = 1
if exists('g:enable_lns_on_start') && g:enable_lns_on_start
	au VimEnter * nested :LoadNvimSessions
endif
