# vim-searchx

The extended search motion.

- Jump to the specific match via marker (like easymotion)
- Move cursor during searching
- Input converter
- Improved jumplist management


### Settings

```vim
" Overwrite / and ?.
nnoremap ? <Cmd>call searchx#start({ 'dir': 0 })<CR>
nnoremap / <Cmd>call searchx#start({ 'dir': 1 })<CR>
xnoremap ? <Cmd>call searchx#start({ 'dir': 0 })<CR>
xnoremap / <Cmd>call searchx#start({ 'dir': 1 })<CR>
cnoremap ; <Cmd>call searchx#select()<CR>
" repeat/continue latest search which is done by calling function `searchx#start`
nnoremap <leader>/ <Cmd>call searchx#start({ 'repeat': ['dir', 'convert', 'input', 'save_state_when'] })<CR>
xnoremap <leader>/ <Cmd>call searchx#start({ 'repeat': ['dir', 'convert', 'input', 'save_state_when'] })<CR>

" Move to next/prev match.
nnoremap N <Cmd>call searchx#prev_dir()<CR>
nnoremap n <Cmd>call searchx#next_dir()<CR>
xnoremap N <Cmd>call searchx#prev_dir()<CR>
xnoremap n <Cmd>call searchx#next_dir()<CR>
nnoremap <C-k> <Cmd>call searchx#prev()<CR>
nnoremap <C-j> <Cmd>call searchx#next()<CR>
xnoremap <C-k> <Cmd>call searchx#prev()<CR>
xnoremap <C-j> <Cmd>call searchx#next()<CR>
cnoremap <C-k> <Cmd>call searchx#prev()<CR>
cnoremap <C-j> <Cmd>call searchx#next()<CR>

" Clear highlights
nnoremap <C-l> <Cmd>call searchx#clear()<CR>

let g:searchx = {}

" Auto jump if the recent input matches to any marker.
let g:searchx.auto_accept = v:true

" The scrolloff value for moving to next/prev.
let g:searchx.scrolloff = &scrolloff

" To enable scrolling animation.
let g:searchx.scrolltime = 500

" To enable auto nohlsearch after cursor is moved
let g:searchx.nohlsearch = {}
let g:searchx.nohlsearch.jump = v:true

" Marker characters.
let g:searchx.markers = split('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '.\zs')

" Save state when search result is accepted
" The state is used to repeat/continue latest search which is done by calling function `searchx#start`
let g:searchx.save_state_when = 'accepted'

" Convert search pattern.
function g:searchx.convert(input) abort
  if a:input !~# '\k'
    return '\V' .. a:input
  endif
  return a:input[0] .. substitute(a:input[1:], '\\\@<! ', '.\\{-}', 'g')
endfunction
```


### Side note

I was develop similar plugins before for experimenting and thrown them away.

I don't know if to maintein it, but this plugin is more convenient than the followings.

- [vim-seak](https://github.com/hrsh7th/vim-seak)
- [vim-foolish-move](https://github.com/hrsh7th/vim-foolish-move)
- [vim-feeling-move](https://github.com/hrsh7th/vim-feeling-move)
- [vim-aim](https://github.com/hrsh7th/vim-aim)
- [vim-insert-point](https://github.com/hrsh7th/vim-insert-point)

