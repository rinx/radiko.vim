" Load vital modules
let s:V = vital#of('radiko')
let s:VP = s:V.import('Process')
let s:PM = s:V.import('ProcessManager')
let s:SF = s:V.import('System.Filepath')
let s:CACHE = s:V.import('System.Cache')
let s:HTTP = s:V.import('Web.HTTP')
let s:JSON = s:V.import('Web.JSON')
let s:XML = s:V.import('Web.XML')
let s:L = s:V.import('Data.List')

" config
let g:radiko#radiko_playerpath = get(g:, 'radiko#radiko_playerpath', 'apps/js/flash')
let g:radiko#radiko_playername = get(g:, 'radiko#radiko_playername', 'myplayer-release.swf')
let g:radiko#play_command = get(g:, 'radiko#play_command',
            \ "rtmpdump -v -r 'rtmpe://f-radiko.smartstream.ne.jp' --app '%%STA_ID%%/_definst_' --playpath 'simul-stream.stream' -W 'http://radiko.jp/"
            \ . g:radiko#radiko_playerpath . "/" . g:radiko#radiko_playername
            \ . "' -C  S:'' -C S:'' -C S:'' -C S:%%AUTH_TOKEN%% --live --quiet | mplayer - -really-quiet")
let g:radiko#cache_dir = get(g:, 'radiko#cache_dir', expand("~/.cache/radiko-vim"))
let g:radiko#cache_file = get(g:, 'radiko#cache_file', 'stations.cache')

let s:stations_cache = s:CACHE.new('file', {'cache_dir': g:radiko#cache_dir})
let g:radiko#now_playing = ''
let g:radiko#now_playing_id = ''

let g:radiko#cache_rn2 = get(g:, 'radiko#cache_rn2', 'rn2_music.cache')
let g:radiko#cache_rn2_time = get(g:, 'radiko#cache_rn2_time', 3600)

let g:radiko#unite_nowplaying_labels = get(g:, 'radiko#unite_nowplaying_labels', [
            \ '   N',
            \ '  No',
            \ ' Now',
            \ 'Now ',
            \ 'ow P',
            \ 'w Pl',
            \ ' Pla',
            \ 'Play',
            \ 'layi',
            \ 'ayin',
            \ 'ying',
            \ 'ing ',
            \ 'ng  ',
            \ 'g   ',
            \ ])

" Player
function! radiko#play(staid)
    if executable('mplayer')
        if s:PM.is_available()
            let [authtoken, auth2_fms] = radiko#auth()
            let play_command = radiko#gen_play_command(authtoken, a:staid)
            call radiko#stop()
            call writefile([play_command], g:radiko#cache_dir . '/player.sh')
            call s:PM.touch('radiko_play', 'sh ' . g:radiko#cache_dir . '/player.sh')
            let stations = radiko#get_stations()
            let nowsta = filter(copy(stations), 'v:val.id == "' . a:staid . '"')
            echo 'Playing ' . nowsta[0].name . '.'
            let g:radiko#now_playing = nowsta[0].name
            let g:radiko#now_playing_id = nowsta[0].id
        else
            echo 'Error: vimproc is unavailable.'
        endif
    else
        echo 'Error: Please install mplayer to listen streaming music.'
    endif
endfunction
function! radiko#gen_play_command(authtoken, staid)
    let play_command = substitute(
                \ substitute(g:radiko#play_command, '%%STA_ID%%', a:staid, ''),
                \ '%%AUTH_TOKEN%%', a:authtoken, '')
    return play_command
endfunction

function! radiko#is_playing(...)
    " Process status
    let status = 'dead'
    try
        let status = s:PM.status('radiko_play')
    catch
    endtry

    if status == 'inactive' || status == 'active'
        return 1
    else
        return 0
    endif
endfunction

function! radiko#stop()
    if radiko#is_playing()
        return s:PM.kill('radiko_play')
    endif
endfunction

function! radiko#get_playing_station()
    if radiko#is_playing()
        return g:radiko#now_playing
    else
        let g:radiko#now_playing = ''
        return 0
    endif
endfunction

function! radiko#get_playing_station_id()
    if radiko#is_playing()
        return g:radiko#now_playing_id
    else
        let g:radiko#now_playing_id = ''
        return 0
    endif
endfunction

function! radiko#get_playing_rn2_music()
    let musics = radiko#get_rn2_musics()
    let ltime = localtime()
    let ctime = str2nr(strftime("%H", ltime), 10) * 3600 +
                \ str2nr(strftime("%M", ltime), 10) * 60 +
                \ str2nr(strftime("%S", ltime))
    let i = radiko#get_rn2_musics_by_time(musics, ctime)
    return [musics[i-1].title, musics[i-1].artist]
endfunction

function! radiko#get_next_rn2_music()
    let musics = radiko#get_rn2_musics()
    let ltime = localtime()
    let ctime = str2nr(strftime("%H", ltime), 10) * 3600 +
                \ str2nr(strftime("%M", ltime), 10) * 60 +
                \ str2nr(strftime("%S", ltime))
    let i = radiko#get_rn2_musics_by_time(musics, ctime)
    return [musics[i].title, musics[i].artist]
endfunction

function! radiko#get_rn2_musics_by_time(musics, ttime)
    let mlistlen = len(a:musics)
    let mtime = 0
    let i = -1
    while mtime < a:ttime
        let i += 1
        if i >= mlistlen
            return i-1
        endif
        let t = map(split(a:musics[i].time, ':'), 'str2nr(v:val)')
        let mtime = t[0] * 3600 + t[1] * 60 + t[2]
    endwhile
    return i
endfunction


function! radiko#update_stations()
    let stations = radiko#fetch_stations()
    call s:stations_cache.set(g:radiko#cache_file, stations)
endfunction
function! radiko#fetch_stations()
    let [authtoken, auth2_fms] = radiko#auth()
    let area_id = matchstr(auth2_fms, '\(\d\|\a\)*\ze,')
    let data = s:XML.parseURL('http://radiko.jp/v2/station/list/' . area_id . '.xml')
    let raw_stations = data.childNodes('station')
    let stations = map(raw_stations, '{
                \ "id": v:val.childNode("id").value(),
                \ "name": v:val.childNode("name").value(),
                \ "channel_xml": "http://radiko.jp/v2/station/stream/" . v:val.childNode("id").value(). ".xml"
                \ }')
    return stations
endfunction

function! radiko#get_stations()
    if s:stations_cache.has(g:radiko#cache_file)
        return s:stations_cache.get(g:radiko#cache_file)
    else
        call radiko#update_stations()
        return s:stations_cache.get(g:radiko#cache_file)
    endif
endfunction

function! radiko#update_rn2_music()
    let musics = radiko#fetch_rn2_music()
    call s:stations_cache.set(g:radiko#cache_rn2, musics)
endfunction
function! radiko#fetch_rn2_music()
    let musics = s:JSON.decode(s:HTTP.get('http://www.radionikkei.jp/rn2/json/json.php').content)
    return musics
endfunction

function! radiko#get_rn2_musics()
    if s:stations_cache.has(g:radiko#cache_rn2)
        let lasttime = getftime(g:radiko#cache_dir . '/' . g:radiko#cache_rn2)
        if (localtime() - lasttime) > g:radiko#cache_rn2_time
            call radiko#update_rn2_music()
        endif
        return s:stations_cache.get(g:radiko#cache_rn2)
    else
        call radiko#update_rn2_music()
        return s:stations_cache.get(g:radiko#cache_rn2)
    endif
endfunction

function! radiko#auth()
    if !filereadable(g:radiko#cache_dir . '/' . g:radiko#radiko_playername)
        call radiko#get_swf(g:radiko#radiko_playerpath, g:radiko#radiko_playername)
    endif
    if !filereadable(g:radiko#cache_dir . '/authkey.png')
        call radiko#extract_authkey(g:radiko#radiko_playername)
    endif

    let [authtoken, offset, length] = radiko#auth_auth1_fms()

    let partialkey = radiko#extract_partialkey(offset, length)

    " HTTP request to get auth2_fms
    let auth2_fms = s:HTTP.request('get', 'https://radiko.jp/v2/api/auth2_fms',
                \ {
                \   "data": "\r\n",
                \   "headers": {
                \     "pragma": "no-cache",
                \     "X-Radiko-App": "pc_ts",
                \     "X-Radiko-App-Version": "4.0.0",
                \     "X-Radiko-User": "test-stream",
                \     "X-Radiko-Device": "pc",
                \     "X-Radiko-AuthToken": authtoken,
                \     "X-Radiko-Partialkey": substitute(partialkey, '==.*$', '==', '')
                \   },
                \   "client": ["wget"]
                \ }).content
    return [authtoken, auth2_fms]
endfunction
function! radiko#auth_auth1_fms()
    " HTTP request to get auth1_fms
    let auth1_fms = s:HTTP.parseHeader(
                \ s:HTTP.request('get', 'https://radiko.jp/v2/api/auth1_fms',
                \ {
                \   "data": "\r\n",
                \   "headers": {
                \     "pragma": "no-cache",
                \     "X-Radiko-App": "pc_ts",
                \     "X-Radiko-App-Version": "4.0.0",
                \     "X-Radiko-User": "test-stream",
                \     "X-Radiko-Device": "pc"
                \   },
                \   "client": ["wget"]
                \ }).header)

    let authtoken = auth1_fms['X-Radiko-AuthToken']
    let offset    = auth1_fms['X-Radiko-KeyOffset']
    let length    = auth1_fms['X-Radiko-KeyLength']
    return [authtoken, offset, length]
endfunction
function! radiko#get_swf(playerpath, playername)
    if s:PM.is_available()
        if executable('wget')
            let cmd = 'wget http://radiko.jp/' . a:playerpath . '/' . a:playername . ' -O ' . g:radiko#cache_dir . '/' . a:playername
            let out = s:VP.system(cmd,
                        \ {
                        \   "use_vimproc": 1,
                        \   "input": "",
                        \   "timeout": 0,
                        \   "background": 0
                        \ }
                        \)
            return 0
        else
            echo 'Error: wget does not exist.'
            return 1
        endif
    else
        echo 'Error: vimproc is unavailable.'
        return 2
    endif
endfunction
function! radiko#extract_authkey(playername)
    if s:PM.is_available()
        if executable('swfextract')
            let cmd = 'swfextract -b 12 ' . g:radiko#cache_dir . '/' . a:playername . ' -o ' . g:radiko#cache_dir . '/authkey.png'
            let out = s:VP.system(cmd,
                        \ {
                        \   "use_vimproc": 1,
                        \   "input": "",
                        \   "timeout": 0,
                        \   "background": 0
                        \ }
                        \)
            return 0
        else
            echo 'Error: swfextract does not exist.'
            return 1
        endif
    else
        echo 'Error: vimproc is unavailable.'
        return 2
    endif
endfunction
function! radiko#extract_partialkey(offset, length)
    if s:PM.is_available()
        if executable('dd') && executable('base64')
            let cmd = 'dd if=' . g:radiko#cache_dir . '/authkey.png bs=1 skip=' . a:offset . ' count=' . a:length . ' 2> /dev/null | base64'
            let out = s:VP.system(cmd,
                        \ {
                        \   "use_vimproc": 1,
                        \   "input": "",
                        \   "timeout": 0,
                        \   "background": 0
                        \ }
                        \)
            return out
        else
            echo 'Error: dd or base64 cannot be used.'
        endif
    else
        echo 'Error: vimproc is unavailable.'
    endif
endfunction



