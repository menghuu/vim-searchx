let s:AcceptReason = {}
let s:AcceptReason.Marker = 1
let s:AcceptReason.Return = 2

let s:Direction = {}
let s:Direction.Prev = 0
let s:Direction.Next = 1

let s:state = {}
let s:state.direction = s:Direction.Next
let s:state.firstview = v:null
let s:state.matches = { 'matches': [], 'current': v:null }
let s:state.accept_reason = s:AcceptReason.Marker

"
" searchx#run
"
function! searchx#run(...) abort
  let s:state.direction = get(a:000, 0, s:detect_direction())
  let s:state.firstview = winsaveview()
  let s:state.accept_reason = s:AcceptReason.Return
  let v:hlsearch = v:true

  augroup searchx-run
    autocmd!
    autocmd CmdlineChanged * call s:on_input()
  augroup END
  let l:return = input('/')
  augroup searchx-run
    autocmd!
  augroup END

  call s:clear()
  if l:return ==# ''
    return winrestview(s:state.firstview)
  elseif index([s:AcceptReason.Marker], s:state.accept_reason) >= 0
    call s:markpos(s:state.firstview)
    call feedkeys("\<Cmd>let v:hlsearch = v:false\<CR>", 'n')
  else
    call s:markpos(s:state.firstview)
    call feedkeys("\<Cmd>let v:hlsearch = v:true\<CR>", 'n')
  endif
endfunction

"
" searchx#clear
"
function! searchx#clear() abort
  call s:clear()
endfunction

"
" searchx#next
"
function searchx#next() abort
  call s:goto('zn')
endfunction

"
" searchx#prev
"
function searchx#prev() abort
  call s:goto('bn')
endfunction

"
" s:detect_direction
"
function! s:detect_direction() abort
  let l:curpos = getcurpos()[1:2]
  let l:above = l:curpos[0] - line('w0')
  let l:below = line('w$') - l:curpos[0]
  return l:above > l:below ? s:Direction.Prev : s:Direction.Next
endfunction

"
" s:markpos
"
function! s:markpos(firstview) abort
  let l:finalview = winsaveview()
  call winrestview(a:firstview)
  normal! m`
  call winrestview(l:finalview)
  call cursor(l:finalview.lnum, l:finalview.col)
endfunction

"
" s:goto
"
function! s:goto(dir) abort
  if getreg('/') ==# ''
    return
  endif

  let l:pos = searchpos(getreg('/'), a:dir)
  if l:pos[0] != 0
    call cursor(l:pos[0], l:pos[1])
    let s:state.matches = s:find_matches(getreg('/'), l:pos)
    let l:is_cmdline = mode(1) ==# 'c'
    call s:refresh({ 'marker': l:is_cmdline, 'incsearch': l:is_cmdline })
    if !l:is_cmdline
      call feedkeys("\<Cmd>let v:hlsearch = v:true\<CR>", 'n')
    endif
  endif
endfunction


"
" on_input
"
function! s:on_input() abort
  try
    let l:input = g:searchx.convert(getcmdline())
    if getreg('/') ==# l:input
      return
    endif

    " Check marker.
    if strlen(l:input) > 0
      let l:index = index(g:searchx.markers, l:input[strlen(l:input) - 1])
      if l:index >= 0
        for l:match in s:state.matches.matches
          if l:match.marker ==# g:searchx.markers[l:index]
            call cursor(l:match.lnum, l:match.col)
            let s:state.accept_reason = s:AcceptReason.Marker
            call feedkeys("\<CR>", 'n')
            return
          endif
        endfor
      endif
    endif

    " Update view state.
    if strlen(getreg('/')) > strlen(l:input)
      call winrestview(s:state.firstview)
    endif
    let s:state.matches = s:find_matches(l:input, [s:state.firstview.lnum, s:state.firstview.col])
    call setreg('/', l:input)
    call s:refresh({ 'marker': v:true })

    " Search for out-of-window match via native `searchpos`.
    if empty(s:state.matches.matches) && s:state.matches.current is v:null
      if s:state.direction == s:Direction.Next
        call searchx#next()
      else
        call searchx#prev()
      endif
    else
      " Move to current match.
      if s:state.matches.current isnot v:null
        call cursor(s:state.matches.current.lnum, s:state.matches.current.col)
      endif
    endif
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfunction

"
" refresh
"
function s:refresh(...) abort
  call s:clear()

  let l:option = get(a:000, 0, {})
  for l:match in s:state.matches.matches
    if s:state.matches.current is l:match && get(l:option, 'incsearch', v:true)
      call searchx#highlight#set_incsearch(l:match)
    else
      if get(l:option, 'marker', v:true)
        call searchx#highlight#set_marker(l:match)
      endif
    endif
  endfor
  let v:hlsearch = len(s:state.matches.matches) > 0

  redraw
endfunction

"
" clear
"
function s:clear() abort
  call searchx#highlight#clear()
  let v:hlsearch = v:false
endfunction

"
" find_matches
"
function! s:find_matches(input, curpos) abort
  let l:lnum_s = line('w0')
  let l:lnum_e = line('w$')
  let l:texts = getbufline('%', l:lnum_s, l:lnum_e)
  let l:next = v:null
  let l:prev = v:null
  let l:matches = []
  for l:i in range(0, len(l:texts) - 1)
    let l:text = l:texts[l:i]
    let l:off = 0
    while l:off < strlen(l:text)
      let l:m = matchstrpos(l:text, a:input, l:off, 1)
      if l:m[0] ==# ''
        break
      endif
      
      let l:match = {
      \   'id': len(l:matches) + 1,
      \   'lnum': l:lnum_s + l:i,
      \   'col': l:m[1] + 1,
      \   'end_col': l:m[2] + 1,
      \   'marker': get(g:searchx.markers, len(l:matches), v:null),
      \ }
      if empty(l:next) && (a:curpos[0] < l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] <= l:match.col)
        let l:next = l:match
      endif
      if a:curpos[0] > l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] >= l:match.col
        let l:prev = l:match
      endif
      call add(l:matches, l:match)
      let l:off = l:match.end_col
    endwhile
  endfor
  let l:next = empty(l:next) ? l:prev : l:next
  let l:prev = empty(l:prev) ? l:next : l:prev
  let l:current = s:state.direction == s:Direction.Next ? l:next : l:prev
  return { 'matches': l:matches, 'current': l:current }
endfunction

