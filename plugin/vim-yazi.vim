" vim-yazi - Yazi file manager integration for Vim
" Author: yukimura1227
" Version: 1.0
" Description: Launch yazi file manager from vim and open selected files

if exists('g:loaded_yazi')
  finish
endif
let g:loaded_yazi = 1

""""""""""""""""""""""""""""""""""""""""
" Default Configs
""""""""""""""""""""""""""""""""""""""""
if !exists('g:yazi_executable')
  let g:yazi_executable = 'yazi'
endif

if !exists('g:yazi_open_multiple')
  let g:yazi_open_multiple = 1
endif

let s:temp_dir = fnamemodify(tempname(), ':h')
let s:selection_file = s:temp_dir . '/vim_yazi_selection_files.txt'

function! s:CheckYaziAvailable()
  if !executable(g:yazi_executable)
    echohl ErrorMsg
    echo "Error: yazi is not installed or not found in PATH"
    echohl None
    return 0
  endif
  return 1
endfunction

function! s:OpenSelectedFiles()
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

function! s:LaunchYazi(path)
  if !s:CheckYaziAvailable()
    return
  endif

  let initial_path = empty(a:path) ? getcwd() : a:path
  if !isdirectory(initial_path)
    " using parent directory
    let initial_path = fnamemodify(initial_path, ':h')
  endif
  let yazi_cmd = g:yazi_executable . ' --chooser-file=' . shellescape(s:selection_file)
  let yazi_cmd .= ' ' . shellescape(initial_path)
  let yazi_cmd = 'sh -c "' . yazi_cmd . '"'

  if has('terminal')
    " using vim terminal
    let term_buf = term_start(yazi_cmd, {
      \ 'close_cb': function('s:OnYaziTermClose'),
      \ 'term_finish': 'close'
    \ })
  else
    execute '!' . yazi_cmd
    call s:OpenSelectedFiles()
  endif
endfunction

" Callback function on Vim close
function! s:OnYaziTermClose(channel)
  call s:OpenSelectedFiles()
endfunction

function! s:yazi_open(...)
  let path = a:0 > 0 ? a:1 : expand('%:p:h')
  call s:LaunchYazi(path)
endfunction

""""""""""""""""""""""""""""""""""""""""
" Define commands
""""""""""""""""""""""""""""""""""""""""
command! -nargs=? -complete=dir Yazi call s:yazi_open(<q-args>)

""""""""""""""""""""""""""""""""""""""""
" Default KeyMap
""""""""""""""""""""""""""""""""""""""""
if !exists('g:yazi_no_mappings') || !g:yazi_no_mappings
  nnoremap <silent> <leader>y :Yazi<CR>
endif
