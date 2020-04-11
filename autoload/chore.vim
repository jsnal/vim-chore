let g:ChorePriority = ['rg', 'ag', 'ack', 'ack-grep']

let s:executables={
      \   'rg': '--vimgrep --no-heading',
      \   'ag': '',
      \   'ack': '--column --noheading',
      \   'ack-grep': '--column --noheading'
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

function! vim#executables() abort
endfunction
