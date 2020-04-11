"-----------------------------------------------"
" File:     chore.vim
" Author:   Jason Long <jasonlongball@gmail.com>
" Version:  v0.0.1
"-----------------------------------------------"

let g:ChoreTest = chore#executable()

if exists('g:ChoreLoaded') || &compatible || v:version < 700
  finish
endif
let g:ChoreLoaded = 1

call chore#init()
