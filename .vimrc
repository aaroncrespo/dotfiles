" vim: set tabstop=8 softtabstop=2 shiftwidth=2 expandtab nowrap:

scriptencoding utf-8  " this file is in utf-8

set nocompatible " Don't emulate vi's limitations. This is also required for Vundle
filetype off     " Required for Vundle. This is re-enabled further down.

set shell=/bin/bash  " Vundle's commands only work in bash
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
"brew install vim --enable-rubyinterp --enable-pythoninterp --enable-python3interp --enable-gui=no --enable-perlinterp
Plugin 'scrooloose/nerdtree' " Tree file explorer
Plugin 'wincent/Command-T'   " Fuzzy file finder.
Plugin 'bling/vim-airline'
Plugin 'vim-scripts/TagHighlight'  " Enhanced syntax highlighting by parsing
                                   " ctags.
Plugin 'Valloric/YouCompleteMe'    " Autocompletion for many languages, most
                                  " notably C/C++/Objective-C via libclang.
Plugin 'kovisoft/slimv'


call vundle#end()         " Finish Plugins
filetype indent plugin on " Required for Vundle.

" Terminal
if (&term =~ "xterm") && (&termencoding == "")
  set termencoding=utf-8
endif

" use patched fonts
let g:airline_powerline_fonts = 1

"set ofu=syntaxcomplete#Complete

" Appearance
" syntax highlight
syntax on

"color sceheme
colorscheme Tomorrow-Night

" do not wrap
set nowrap

" wrap movement
set whichwrap+=<,>,h,l,[,]

" 256 color support
set t_Co=256

" line numbers always
set number
set relativenumber

" if term supported allow mouse
set mouse=a

"hide mouse in gui while typing
set mousehide

" current mode in status line
set showmode

" highlight search results
set hlsearch

" highlight matching parens for .1s
set showmatch
set matchtime=1

" Editing Functionality
" auto indent
" set autoindent

" copy previous indent when auto indent
set copyindent

" show matches as typed
set incsearch

" ignore case in search
set ignorecase

" Vim
" stop middle click paste
nnoremap <MiddleMouse> <Nop>
nnoremap <2-MiddleMouse> <Nop>
nnoremap <3-MiddleMouse> <Nop>
nnoremap <4-MiddleMouse> <Nop>
inoremap <MiddleMouse> <Nop>
inoremap <2-MiddleMouse> <Nop>
inoremap <3-MiddleMouse> <Nop>
inoremap <4-MiddleMouse> <Nop>

" ; acts like :
noremap ; :

" cmd history length
set history=1000

" undo history
set undolevels=1000

" persist history
if v:version >= 730
  set undofile
endif

" swap
set directory^=$HOME/.vim/tmp//

" draw line bellow cursor
set cursorline

" no bell
set visualbell
set noerrorbells

" no tabs only spaces
set expandtab
set shiftwidth=2

" 2 space tabs
set tabstop=2

" for backspacing
set softtabstop=2
set backspace=indent,eol,start

" shift to indentation levels
set shiftround

" insert \v before any searched string, basically replacing vim's wonky re
" " syntax with regular re syntax
"vnoremap / /\v
"nnoremap / /\v

"
" Plugins
"
" Nerdtree
autocmd VimEnter * NERDTree
autocmd VimEnter * wincmd p
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

let NERDTreeChDirMode=0
let NERDTreeQuitOnOpen=1
let NERDTreeMouseMode=2
let NERDTreeMinimalUI=1
" show hidden files
let NERDTreeShowHidden=1
let NERDTreeIgnore=['swo$','\.swp$','\.git','\.hg','\.svn','\.bzr', '\.DS_Store', '\.swp$']
let NERDTreeKeepTreeInNewTab=1
let g:nerdtree_tabs_open_on_gui_startup=0

" ctrlp
 set runtimepath^=~/.vim/bundle/ctrlp.vim

" mappings
let mapleader = ","

" YCM
let g:ycm_seed_identifiers_with_syntax = 1
let g:ycm_add_preview_to_completeopt = 1
let g:ycm_min_num_of_chars_for_completion = 2

"
" Syntax
"
autocmd FileType css,scss setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Misc
set cinwords=if,else,while,do,for,switch,case

