"-----------------------------------------------"
" File:     autoload/chore/async.vim
" Author:   Jason Long <jasonlongball@gmail.com>
"-----------------------------------------------"

let s:jobs = {}

function! s:job_from_channel(channel) abort
  let l:channel_id = ch_info(a:channel)['id']
  if has_key(s:jobs, l:channel_id)
    return s:jobs[l:channel_id]
  endif
endfunction

function! chore#async#search(executable, search_pattern, location) abort
  let l:command = a:executable . ' "' . a:search_pattern . '" "' . a:location . '"'
  let l:job = job_start(l:command, {
        \   'in_io': 'null',
        \   'err_cb': 'chore#async#err_cb',
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

function! chore#async#err_cb(channel, msg) abort
  let l:job = s:job_from_channel(a:channel)
  let l:type = exists('v:t_dict') ? v:t_dict : 4
  if type(l:job) == l:type
    let l:lines=split(a:msg, '\n', 1)
    let l:count=len(l:lines)
    for l:i in range(l:count)
      let l:line=l:lines[l:i]
      if l:i != l:count - 1 && l:line != ''
        call add(l:job.errors, l:line)
      endif
    endfor
  endif
endfunction

function! chore#async#out_cb(channel, msg) abort
  let l:job = s:job_from_channel(a:channel)
  let l:type = exists('v:t_dict') ? v:t_dict : 4
  if type(l:job) == l:type
    let l:lines=split(a:msg, '\n', 1)
    let l:count=len(l:lines)
    for l:i in range(l:count)
      let l:line=l:lines[l:i]
      if l:i != l:count - 1 && l:line != ''
        call add(l:job.output, l:line)
      endif
    endfor
  endif
endfunction

function! chore#async#close_cb(channel) abort
  let l:job = s:job_from_channel(a:channel)
  let l:type = exists('v:t_dict') ? v:t_dict : 4
  if type(l:job) == l:type
    call remove(s:jobs, l:job.channel_id)
    call chore#finalize_search(l:job.output)
  endif
endfunction
