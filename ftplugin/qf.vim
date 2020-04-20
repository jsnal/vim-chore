if g:chore_qf_settings
  setlocal nolist
  setlocal nowrap
  setlocal number
  if exists('+relativenumber')
    setlocal norelativenumber
  endif

  nnoremap <buffer> <silent> dd :call chore#delete_qf_entry()<CR>
endif
