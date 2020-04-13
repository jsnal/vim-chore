if !exists('g:chore_keywords')
  let g:chore_keywords = ['TODO', 'FIXME', 'BUG']
endif

function! chore#open() abort
  let l:search_pattern = join(g:chore_keywords, '|')

  let l:executable = chore#executable()
  if empty(l:executable)
    call chore#executable_error()
    return
  endif

  " TODO: Make chore#find_directory() a bufvar
  call chore#search(l:executable, l:search_pattern, chore#find_directory())
endfunction

function! chore#search(executable, search_pattern, location) abort
  let l:output = system(a:executable . ' "' . a:search_pattern . '" "' . a:location . '"')
  " echo a:executable . ' "' . a:search_pattern . '" "' . a:location . '"'
  " echo l:output

  " Quick and dirty need to finalize the output
  execute 'cgetexpr l:output'
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

" This part of the source code is heavily inspired by the vim plugin vim-rooter.
" It strips out all of the changing directory functionality that comes with
" vim-rooter and just returns the raw output of the plugin.
"
" https://github.com/airblade/vim-rooter/blob/master/plugin/rooter.vim#L80-L126
if !exists('g:chore_root_patterns')
  let g:chore_root_patterns = ['.git', '.git/', '_darcs/', '.hg/', '.bzr/', '.svn/']
endif

function! chore#is_directory(pattern) abort
  return a:pattern[-1:] == '/'
endfunction

function! chore#find_ancestor(pattern) abort
  let fd_dir = isdirectory(s:fd) ? s:fd : fnamemodify(s:fd, ':h')
  let fd_dir_escaped = escape(fd_dir, ' ')

  if chore#is_directory(a:pattern)
    let match = finddir(a:pattern, fd_dir_escaped.';')
  else
    let [_suffixesadd, &suffixesadd] = [&suffixesadd, '']
    let match = findfile(a:pattern, fd_dir_escaped.';')
    let &suffixesadd = _suffixesadd
  endif

  if empty(match)
    return ''
  endif

  if chore#is_directory(a:pattern)
    if stridx(fnamemodify(fd_dir, ':p'), fnamemodify(match, ':p')) == 0
      return fnamemodify(match, ':p:h')
    else
      return fnamemodify(match, ':p:h:h')
    endif
  else
    return fnamemodify(match, ':p:h')
  endif
endfunction

function! chore#find_directory() abort
  let s:fd = expand('%:p')

  if empty(s:fd)
    let s:fd = getcwd()
  endif

  for pattern in g:chore_root_patterns
    let result = chore#find_ancestor(pattern)
    if !empty(result)
      return result
    endif
  endfor
  return ''
endfunction

if !exists('g:chore_priority')
  let g:chore_priority = ['rg', 'ag', 'ack', 'ack-grep']
endif

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
      let s:executables['rg'] .= ' --no-config'
    endif
    if match(l:rg_help, '--max-columns') != -1
      let s:executables['rg'] .= ' --max-columns 4096'
    endif
  endif

  if executable('ag')
    let l:ag_help=system('ag --help')
    if match(l:ag_help, '--vimgrep') != -1
      let s:executables['ag'] .= '--vimgrep'
    else
      let s:executables['ag'] .= '--column'
    endif
    if match(l:ag_help, '--width') != -1
      let s:executables['ag'] .= ' --width 4096'
    endif
  endif

  let s:init_done = 1
endfunction

function! chore#executables() abort
  return copy(s:executables)
endfunction

function! chore#executable() abort
  let l:valid_executables = keys(s:executables)
  let l:executables = filter(g:chore_priority, 'index(l:valid_executables, v:val) != -1')

  for l:executable in l:executables
    if executable(l:executable)
      let l:custom_args = get(g:, 'chore_executable_arguments', {})
      let l:type = exists('v:t_dict') ? v:t_dict : 4

      if type(l:custom_args) == l:type && has_key(l:custom_args, l:executable)
        return l:executable . ' ' . l:custom_args[l:executable]
      else
        return l:executable . ' ' . s:executables[l:executable]
      endif
    endif
  endfor
  return ''
endfunction

call chore#init()
