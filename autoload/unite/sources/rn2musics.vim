scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#rn2musics#define()
  return s:source
endfunction


let s:source = {
      \   'name' : 'rn2musics',
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
    let musics = radiko#get_rn2_musics()

    let times = map(copy(musics), 'v:val.time')
    let max_timestr_len = max(map(copy(times), 'len(v:val)'))
    let format = '[%-' . max_timestr_len . 's] %s - %s'

    return map(musics, '{
                \   "word": printf(format, v:val.time, v:val.title, v:val.artist),
                \   "action__station_id": "RN2"
                \ }')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
