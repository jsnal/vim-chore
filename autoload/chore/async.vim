"-----------------------------------------------"
" File:     autoload/chore/async.vim
" Author:   Jason Long <jasonlongball@gmail.com>
"-----------------------------------------------"

let s:jobs = {}

function! s:info_from_channel(channel)
  let l:channel_id = ch_info(a:channel)['id']
  if has_key(s:jobs, l:channel_id)
    return s:jobs[l:channel_id]
  endif
endfunction

function! chore#async#search(executable, search_pattern, location) abort
  " call ferret#private#async#cancel()
  " call ferret#private#autocmd('FerretAsyncStart')
  let l:command = a:executable . ' "' . a:search_pattern . '" "' . a:location . '"'
  let l:job = job_start(l:command, {
        \   'in_io': 'null',
        \   'err_cb': '',
        \   'out_cb': 'chore#async#out_cb',
        \   'close_cb': 'chore#async#close_cb',
        \   'err_mode': 'raw',
        \   'out_mode': 'raw'
        \ })
  let l:channel = job_getchannel(l:job)
  let l:channel_id = ch_info(l:channel)['id']
  let s:jobs[l:channel_id] = {
        \   'channel_id': l:channel_id,
        \   'job': l:job,
        \   'errors': [],
        \   'output': [],
        \   'pending_error': '',
        \   'pending_output': '',
        \   'pending_error_length': 0,
        \   'pending_output_length': 0,
        \   'result_count': 0,
        \   'window': win_getid()
        \ }
endfunction

function! chore#async#out_cb(channel, msg) abort
  let l:info = s:info_from_channel(a:channel)
  call add(l:info.output, a:msg)
  " let l:info.output = a:msg
endfunction

function! chore#async#close_cb(channel) abort
  let l:info = s:info_from_channel(a:channel)
  let g:test = l:info
  " echo l:info.output
endfunction
