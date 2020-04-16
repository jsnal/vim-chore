"-----------------------------------------------"
" File:     autoload/chore/default.vim
" Author:   Jason Long <jasonlongball@gmail.com>
"-----------------------------------------------"

function! chore#default#search(executable, search_pattern, location) abort
  let l:output = system(a:executable . ' "' . a:search_pattern . '" "' . a:location . '"')
  call chore#finalize_search(l:output)
endfunction
