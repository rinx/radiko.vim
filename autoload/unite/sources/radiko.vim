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

function! s:source.async_gather_candidates(args, context)
    let stations = radiko#get_stations()

    let ids = map(copy(stations), 'v:val["id"]')
    let max_id_len = max(map(copy(ids), 'len(v:val)'))

    let label = radiko#is_playing() ? g:radiko#unite_nowplaying_labels[self.__counter] : ''
    let label_len = len(label) > 0 ? len(label) + 1 : 0
    if self.__counter == len(g:radiko#unite_nowplaying_labels) - 1
      let self.__counter = 0
    else
      let self.__counter += 1
    endif

    let format = '%-' . label_len . 's %-' . max_id_len . 's - %s'

    let a:context.source.unite__cached_candidates = []
    return map(stations, '{
                \   "word": printf(format, radiko#get_playing_station_id() == v:val["id"] ? label : "", v:val["id"], v:val["name"]),
                \   "action__station_id": v:val["id"]
                \ }')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
