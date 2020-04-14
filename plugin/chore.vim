"-----------------------------------------------"
" File:     plugin/chore.vim
" Author:   Jason Long <jasonlongball@gmail.com>
" Version:  v0.0.1
"-----------------------------------------------"

if exists('g:ChoreLoaded') || &compatible || v:version < 700
  finish
endif
let g:ChoreLoaded = 1

if !exists('g:chore_keywords')
  let g:chore_keywords = ['TODO', 'FIXME', 'BUG']
endif

if !exists('g:chore_jump_type')
  let g:chore_jump_type = 1
endif

if !exists('g:chore_root_patterns')
  let g:chore_root_patterns = ['.git', '.git/', '_darcs/', '.hg/', '.bzr/', '.svn/']
endif

if !exists('g:chore_priority')
  let g:chore_priority = ['rg', 'ag', 'ack', 'ack-grep']
endif

if !exists('g:chore_executable_arguments')
  let g:chore_executable_arguments = {}
endif

if !get(g:, 'chore_force_init', 1)
  call chore#init()
endif

command! -bang ChoreOpen call chore#open()
