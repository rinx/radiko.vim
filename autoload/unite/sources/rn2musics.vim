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

function! s:get_str_disp_len(str)
    let stdlen = len(a:str)
    let mltlen = len(substitute(a:str, '.', 'x', 'g'))
    if stdlen != mltlen
        return stdlen - ((stdlen - mltlen) / 2)
    else
        return stdlen
    endif
endfunction

function! s:name_formatter(max_timestr_len, max_title_len, title)
    let stdlen = len(a:title)
    let mltlen = len(substitute(a:title, '.', 'x', 'g'))
    if stdlen != mltlen
        let ret_len = ((stdlen - mltlen) / 2) + a:max_title_len
    else
        let ret_len = a:max_title_len
    endif
    return '%-3s[%-' . a:max_timestr_len . 's] ' . '%-' . ret_len . 's - %s'
endfunction

function! s:isthissong(current_music_id, music_id)
    if a:current_music_id == a:music_id
        return '->'
    else
        return ''
    endif
endfunction

function! s:source.action_table.play.func(candidate)
  call radiko#play(a:candidate.action__station_id)
endfunction

function! s:source.async_gather_candidates(args, context)
    let musics = radiko#get_rn2_musics()

    let times = map(copy(musics), 'v:val.time')
    let max_timestr_len = max(map(copy(times), 'len(v:val)'))
    let titles = map(copy(musics), 'v:val.title')
    let max_title_len = max(map(copy(titles), 's:get_str_disp_len(v:val)'))

    let ltime = localtime()
    let ctime = str2nr(strftime("%H", ltime), 10) * 3600 +
                \ str2nr(strftime("%M", ltime), 10) * 60 +
                \ str2nr(strftime("%S", ltime))
    let current_music_num = radiko#get_rn2_musics_by_time(musics, ctime)
    let current_music_id = musics[current_music_num - 1].id

    let a:context.source.unite__cached_candidates = []
    return map(musics, '{
                \   "word": printf(s:name_formatter(max_timestr_len, max_title_len, v:val.title), s:isthissong(current_music_id, v:val.id), v:val.time, v:val.title, v:val.artist),
                \   "action__station_id": "RN2"
                \ }')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
