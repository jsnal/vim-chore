"-----------------------------------------------"
" File:     chore.vim
" Author:   Jason Long <jasonlongball@gmail.com>
" Version:  v0.0.1
"-----------------------------------------------"

if exists('g:ChoreLoaded') || &compatible || v:version < 700
  finish
endif
let g:ChoreLoaded = 1

if !get(g:, 'chore_force_init', 1)
  call chore#init()
endif

command! -bang ChoreOpen call chore#open()
