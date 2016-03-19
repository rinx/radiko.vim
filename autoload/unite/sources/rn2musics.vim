scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#rn2musics#define()
  return s:source
endfunction


let s:source = {
      \   'name' : 'rn2musics',
      \ }

function! s:source.gather_candidates(args, context)
    let musics = radiko#get_rn2_musics()

    let times = map(copy(musics), 'v:val.time')
    let max_timestr_len = max(map(copy(times), 'len(v:val)'))
    let format = '[%-' . max_timestr_len . 's] %s - %s'

    return map(musics, '{
                \   "word": printf(format, v:val.time, v:val.title, v:val.artist)
                \ }')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
