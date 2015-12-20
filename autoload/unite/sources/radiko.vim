scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#radiko#define()
  return s:source
endfunction


let s:source = {
      \   'name' : 'radiko',
      \   'hooks' : {},
      \   'action_table' : {
      \     'play' : {
      \       'description' : 'Play this station',
      \     }
      \   },
      \   'default_action' : 'play',
      \   '__counter' : 0
      \ }

function! s:source.action_table.play.func(candidate)
  call radiko#play(a:candidate.action__station_id)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
