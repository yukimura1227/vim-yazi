let s:temp_dir = fnamemodify(tempname(), ':h')
let s:selection_file = s:temp_dir . '/vim_yazi_selection_files.txt'

function! vim_yazi#CheckYaziAvailable()
  if !executable(g:yazi_executable)
    echohl ErrorMsg
    echo "Error: yazi is not installed or not found in PATH"
    echohl None
    return 0
  endif
  return 1
endfunction

function! vim_yazi#CreateFloatingWindow() abort
  if !has('nvim')
    return 0
  endif

  let width = float2nr(&columns * 0.9)
  let height = float2nr(&lines * 0.9)
  let row = float2nr((&lines - height) / 2)
  let col = float2nr((&columns - width) / 2)

  let opts = {
    \ 'relative': 'editor',
    \ 'width': width,
    \ 'height': height,
    \ 'row': row,
    \ 'col': col,
    \ 'style': 'minimal',
    \ 'border': 'rounded'
  \ }

  let buf = nvim_create_buf(v:false, v:true)
  let win = nvim_open_win(buf, v:true, opts)

  return win
endfunction

function! vim_yazi#LaunchYazi(path)
  if !vim_yazi#CheckYaziAvailable()
    return
  endif

  let initial_path = empty(a:path) ? getcwd() : a:path
  let yazi_cmd = g:yazi_executable . ' --chooser-file=' . shellescape(s:selection_file)
  let yazi_cmd .= ' ' . shellescape(initial_path)
  let yazi_cmd = 'sh -c "' . yazi_cmd . '"'

  if has('nvim')
    let win = vim_yazi#CreateFloatingWindow()
    call termopen(yazi_cmd, {
      \ 'on_exit': {job_id, exit_code, event -> vim_yazi#OnYaziExit(win, exit_code)}
      \ })
    startinsert
  elseif has('terminal')
    " using vim terminal
    let term_buf = term_start(yazi_cmd, {
      \ 'exit_cb': function('vim_yazi#OnYaziExit'),
      \ 'term_finish': 'close',
      \ 'term_rows': winheight('%'),
      \ 'term_cols': winwidth('%'),
      \ 'curwin': 1,
    \ })
  else
    execute '!' . yazi_cmd
    call vim_yazi#OpenSelectedFiles()
  endif
endfunction

function! vim_yazi#YaziOpen(path)
  let path = empty(a:path) ? expand('%:p') : a:path
  call vim_yazi#LaunchYazi(path)
endfunction

function! vim_yazi#OpenSelectedFiles()
  if !filereadable(s:selection_file)
    return
  endif

  let selected_files = []
  for line in readfile(s:selection_file)
    let line = trim(line)
    if !empty(line) && filereadable(line)
      call add(selected_files, line)
    endif
  endfor

  call delete(s:selection_file)

  if empty(selected_files)
    return
  endif

  if g:yazi_open_multiple && len(selected_files) > 1
    for file in selected_files
      execute 'tabedit ' . fnameescape(file)
    endfor
    echo "Opened " . len(selected_files) . " files"
  else
    execute 'tabedit ' . fnameescape(selected_files[0])
  endif
endfunction

" Callback function on Vim close
function! vim_yazi#OnYaziExit(job, status)
  call vim_yazi#OpenSelectedFiles()
endfunction

function! vim_yazi#SuppressNetrw()
  if exists('#FileExplorer')
    autocmd! FileExplorer *
  endif
endfunction

" replace netrw
function! vim_yazi#YaziHijackNetrw(path)
  if !isdirectory(a:path)
    return
  endif
  silent! bdelete
  " NOTE: avoid E242: Can't split a window while closing another
  call timer_start(0, { -> vim_yazi#LaunchYazi(a:path) })
endfunction

