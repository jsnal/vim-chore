let g:ChoreCaseSensitive = 0
let g:ChoreKeywords = ['TODO', 'FIXME', 'BUG']

function! chore#open() abort
  let l:search_pattern = join(g:ChoreKeywords, '|')

  let l:executable = chore#executable()
  if empty(l:executable)
    call chore#executable_error()
    return
  endif

  call chore#search(l:executable, l:search_pattern, getcwd())
endfunction

function! chore#search(executable, search_pattern, location) abort
  let l:output = system(a:executable . ' "' . a:search_pattern . '"')
  echo l:output
endfunction

function! chore#executable_error() abort
  call chore#error(
        \ 'Unable find valid executable. Install rg, ag, ack or ack-grep'
        \ )
endfunction

function! chore#error(message) abort
  call inputsave()
  echohl ErrorMsg
  unsilent call input(a:message . ': Press ENTER to continue')
  echohl NONE
  call inputrestore()
  unsilent echo
  redraw!
endfunction

let g:ChorePriority = ['rg', 'ag', 'ack', 'ack-grep']

let s:executables = {
      \   'rg': '--vimgrep --no-heading',
      \   'ag': '',
      \   'ack': '--column --with-filename --noheading',
      \   'ack-grep': '--column --with-filename --noheading'
      \ }

let s:init_done = 0

function! chore#init() abort
  if s:init_done
    return
  endif

  if executable('rg')
    let l:rg_help = system('rg --help')
    if match(l:rg_help, '--no-config') != -1
      let s:executables['rg'].=' --no-config'
    endif
    if match(l:rg_help, '--max-columns') != -1
      let s:executables['rg'].=' --max-columns 4096'
    endif
  endif

  if executable('ag')
    let l:ag_help=system('ag --help')
    if match(l:ag_help, '--vimgrep') != -1
      let s:executables['ag'].='--vimgrep'
    else
      let s:executables['ag'].='--column'
    endif
    if match(l:ag_help, '--width') != -1
      let s:executables['ag'].=' --width 4096'
    endif
  endif

  let s:init_done = 1
endfunction

function! chore#executables() abort
  return copy(s:executables)
endfunction

function! chore#executable() abort
  let l:valid_executables = keys(s:executables)
  let l:executables = filter(g:ChorePriority, 'index(l:valid_executables, v:val) != -1')

  for l:executable in l:executables
    if executable(l:executable)
      return l:executable . ' ' . s:executables[l:executable]
    endif
  endfor
  return ''
endfunction
