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

function! s:source.gather_candidates(args, context)
    let stations = radiko#get_stations()

    return map(stations, '{
                \   "word": v:val["name"],
                \   "action__station_id": v:val["id"]
                \ }')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
