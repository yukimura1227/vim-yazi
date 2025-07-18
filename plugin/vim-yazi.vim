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

if !exists('g:yazi_no_mappings')
  let g:yazi_no_mappings = 0
endif

if exists('g:yazi_replace_netrw') && g:yazi_replace_netrw
  augroup YaziReplaceNetrw
    autocmd!
    autocmd VimEnter * silent! call vim_yazi#SuppressNetrw()
    autocmd BufEnter * ++nested call vim_yazi#YaziHijackNetrw(expand('%:p'))
  augroup END
endif

""""""""""""""""""""""""""""""""""""""""
" Define commands
""""""""""""""""""""""""""""""""""""""""
command! -nargs=? -complete=dir Yazi call vim_yazi#YaziOpen(<q-args>)
command! -nargs=0 YaziCwd Yazi .

""""""""""""""""""""""""""""""""""""""""
" Default KeyMap
""""""""""""""""""""""""""""""""""""""""
if !exists('g:yazi_no_mappings') || !g:yazi_no_mappings
  nnoremap <silent> <leader>y :Yazi<CR>
endif
