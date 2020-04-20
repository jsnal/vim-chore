"-----------------------------------------------"
" File:     autoload/chore.vim
" Author:   Jason Long <jasonlongball@gmail.com>
"-----------------------------------------------"

let s:async_support = 0
if (v:version >= 800 || has('patch-7.4.1829')) && (!has('nvim'))
  if has('job') && has('channel')
    let s:async_support = 1
  endif
endif

function! chore#open() abort
  let l:search_pattern = join(g:chore_keywords, '|')
  " TODO: Make s:find_directory() a bufvar
  let l:root_dir = s:find_directory()

  let l:executable = chore#executable()
  if empty(l:executable)
    call s:executable_error()
    return
  endif

  if s:async_support == 1
    call chore#async#search(l:executable, l:search_pattern, l:root_dir)
  else
    call chore#default#search(l:executable, l:search_pattern, l:root_dir)
  endif
endfunction

function! s:set_title(title) abort
  if has('patch-7.4.2200')
    call setqflist([], 'a', {'title' : a:title})
  elseif a:type ==# 'qf'
    let w:quickfix_title = a:title
  endif
endfunction

" 0 - Chore will push to the qf list but hide it from the user
" 1 - (default) Chore will push to the qf list and open/focus the qf list.
" 2 - Chore will push to the qf list and open/focus the qf list and jump to it.
function! s:jump_type() abort
  if g:chore_jump_type != 0 && g:chore_jump_type != 1 && g:chore_jump_type != 2
    let g:chore_jump_type = 1
  endif
  return g:chore_jump_type
endfunction

function! chore#finalize_search(output) abort
  execute 'cgetexpr a:output'
  if g:chore_jump_type == 1 || g:chore_jump_type == 2
    cope
    if g:chore_jump_type == 2
      cfirst
    endif
  elseif g:chore_jump_type != 0
    call chore#error(
          \ 'Unable to push results to list. Check g:chore_jump_type'
          \ )
  endif
  call s:set_title('Chores')
endfunction

function! s:executable_error() abort
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
function! s:is_directory(pattern) abort
  return a:pattern[-1:] == '/'
endfunction

function! s:find_ancestor(pattern) abort
  let fd_dir = isdirectory(s:fd) ? s:fd : fnamemodify(s:fd, ':h')
  let fd_dir_escaped = escape(fd_dir, ' ')

  if s:is_directory(a:pattern)
    let match = finddir(a:pattern, fd_dir_escaped.';')
  else
    let [_suffixesadd, &suffixesadd] = [&suffixesadd, '']
    let match = findfile(a:pattern, fd_dir_escaped.';')
    let &suffixesadd = _suffixesadd
  endif

  if empty(match)
    return ''
  endif

  if s:is_directory(a:pattern)
    if stridx(fnamemodify(fd_dir, ':p'), fnamemodify(match, ':p')) == 0
      return fnamemodify(match, ':p:h')
    else
      return fnamemodify(match, ':p:h:h')
    endif
  else
    return fnamemodify(match, ':p:h')
  endif
endfunction

function! chore#delete_qf_entry() abort
  let l:lineid = winline() - 1
  let l:qfall = getqflist()
  call remove(l:qfall, l:lineid)
  call setqflist(l:qfall, 'r')
  " TODO: Find a way of moving to the qf entry above the one deleted
endfunction

function! s:find_directory() abort
  let s:fd = expand('%:p')

  if empty(s:fd)
    let s:fd = getcwd()
  endif

  for pattern in g:chore_root_patterns
    let result = s:find_ancestor(pattern)
    if !empty(result)
      return result
    endif
  endfor
  return ''
endfunction

let s:executables = {
      \   'rg': '--vimgrep --no-heading --word-regexp',
      \   'ag': '--word-regexp',
      \   'ack': '--column --with-filename --noheading --word-regexp',
      \   'ack-grep': '--column --with-filename --noheading --word-regexp'
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
      let s:executables['ag'] .= ' --vimgrep'
    else
      let s:executables['ag'] .= ' --column'
    endif
    if match(l:ag_help, '--width') != -1
      let s:executables['ag'] .= ' --width 4096'
    endif
  endif

  let l:executable = chore#executable()
  if !empty(l:executable)
    let &grepprg=l:executable
    let &grepformat='%f:%l:%m'
  endif

  let s:init_done = 1
endfunction

function! s:executables() abort
  return copy(s:executables)
endfunction

function! chore#executable() abort
  let l:valid_executables = keys(s:executables)
  let l:executables = filter(g:chore_priority, 'index(l:valid_executables, v:val) != -1')

  for l:executable in l:executables
    if executable(l:executable)
      let l:custom_args = g:chore_executable_arguments
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
