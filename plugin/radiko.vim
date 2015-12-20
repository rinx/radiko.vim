" radiko.vim
" Version: 0.0.1
" Author: Rintaro Okamura
" License: MIT

if exists('g:loaded_radiko')
  finish
endif
let g:loaded_radiko = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=1 RadikoPlay call radiko#play(<f-args>)
command! RadikoStop call radiko#stop()
command! RadikoUpdateStations call radiko#update_stations()

augroup Radiko
    autocmd!
    autocmd Radiko VimLeave * call radiko#stop()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo

