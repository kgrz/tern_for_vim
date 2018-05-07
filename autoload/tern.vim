if !has('python3')
  echo 'tern requires python support'
  finish
endif

let s:plug = expand("<sfile>:p:h:h")
let s:script = s:plug . '/script/tern.py'
execute 'py3file ' . fnameescape(s:script)

if !exists('g:tern#command')
  let g:tern#command = ["node", expand('<sfile>:h') . '/../node_modules/tern/bin/tern', '--no-port-file']
endif

if !exists('g:tern#arguments')
  let g:tern#arguments = []
endif

function! tern#PreviewInfo(info)
  pclose
  new +setlocal\ previewwindow|setlocal\ buftype=nofile|setlocal\ noswapfile|setlocal\ wrap
  exe "normal z" . &previewheight . "\<cr>"
  call append(0, type(a:info)==type("") ? split(a:info, "\n") : a:info)
  wincmd p
endfunction

function! tern#Complete(findstart, complWord)
  if a:findstart
    python3 tern_ensureCompletionCached()
    return b:ternLastCompletionPos['start']
  elseif b:ternLastCompletionPos['end'] - b:ternLastCompletionPos['start'] == len(a:complWord)
    return b:ternLastCompletion
  else
    let rest = []
    for entry in b:ternLastCompletion
      if entry["word"] =~ '^\V'. escape(a:complWord, '\')
        call add(rest, entry)
      endif
    endfor
    return rest
  endif
endfunction

function! tern#LookupType()
  python3 tern_lookupType()
  return ''
endfunction

function! tern#LookupArgumentHints()
  if g:tern_show_argument_hints == 'no'
    return
  endif
  let fname = get(matchlist(getline('.')[:col('.')-2],'\([a-zA-Z0-9_]*\)([^()]*$'),1)
  let pos   = match(getline('.')[:col('.')-2],'[a-zA-Z0-9_]*([^()]*$')
  if pos >= 0
    python3 tern_lookupArgumentHints(vim.eval('fname'),int(vim.eval('pos')))
  endif
  return ''
endfunction

if !exists('g:tern_show_argument_hints')
  let g:tern_show_argument_hints = 'no'
endif

if !exists('g:tern_show_signature_in_pum')
  let g:tern_show_signature_in_pum = 0
endif

if !exists('g:tern_set_omni_function')
  let g:tern_set_omni_function = 1
endif

if !exists('g:tern_map_keys')
  let g:tern_map_keys = 0
endif

if !exists('g:tern_map_prefix')
  let g:tern_map_prefix = '<LocalLeader>'
endif

if !exists('g:tern_request_timeout')
  let g:tern_request_timeout = 1
endif

if !exists('g:tern_request_query')
  let g:tern_request_query = {}
endif

if !exists('g:tern_show_loc_after_rename')
  let g:tern_show_loc_after_rename = 1
endif

if !exists('g:tern_show_loc_after_refs')
  let g:tern_show_loc_after_refs = 1
endif

function! tern#Enable()
  if stridx(&buftype, "nofile") > -1 || stridx(&buftype, "nowrite") > -1
    return
  endif

  let b:ternProjectDir = ''
  let b:ternLastCompletion = []
  let b:ternLastCompletionPos = {'row': -1, 'start': 0, 'end': 0}
  if !exists('b:ternBufferSentAt')
    let b:ternBufferSentAt = undotree()['seq_cur']
  endif
  let b:ternInsertActive = 0
  if g:tern_set_omni_function
    setlocal omnifunc=tern#Complete
  endif
  augroup TernAutoCmd
    autocmd! * <buffer>
    autocmd BufLeave <buffer> :py3 tern_sendBufferIfDirty()

    if g:tern_show_argument_hints == 'on_move'
      autocmd CursorMoved,CursorMovedI <buffer> call tern#LookupArgumentHints()
    elseif g:tern_show_argument_hints == 'on_hold'
      autocmd CursorHold,CursorHoldI <buffer> call tern#LookupArgumentHints()
    endif
    autocmd InsertEnter <buffer> let b:ternInsertActive = 1
    autocmd InsertLeave <buffer> let b:ternInsertActive = 0
  augroup END
endfunction

augroup TernShutDown
  autocmd VimLeavePre * call tern#Shutdown()
augroup END

function! tern#Disable()
  augroup TernAutoCmd
    autocmd! * <buffer>
  augroup END
endfunction

function! tern#Shutdown()
  py3 tern_killServers()
endfunction
