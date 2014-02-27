set nocompatible

filetype off
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'scrooloose/nerdtree'
Bundle 'syntastic' 
Bundle 'kien/ctrlp.vim'
Bundle 'Valloric/YouCompleteMe'
Bundle 'bling/vim-airline'
Bundle 'tpope/vim-fireplace'
Bundle 'tpope/vim-classpath'
Bundle 'guns/vim-clojure-static'
Bundle 'kovisoft/slimv'

Bundle 'tpope/vim-fireplace'
Bundle 'tpope/vim-classpath'
Bundle 'guns/vim-clojure-static'

filetype indent plugin on

set encoding=utf-8
" use patched fonts
let g:airline_powerline_fonts = 1

set ofu=syntaxcomplete#Complete


" Appearance
" syntax highlight 
syntax on

"color sceheme
colorscheme Tomorrow-Night

" do not wrap
set nowrap

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
set autoindent

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
  set undodir=~/.vim/.undo, ~/tmp,/tmp
endif
set directory=~/.vim/.tmp

"draw line bellow cursor
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
vnoremap / /\v
nnoremap / /\v

" Nerdtree
autocmd VimEnter * NERDTree | wincmd p
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

let NERDTreeChDirMode=0
let NERDTreeQuitOnOpen=1
let NERDTreeMouseMode=2
let NERDTreeMinimalUI=1
" show hidden files
let NERDTreeShowHidden=1
let NERDTreeIgnore=['swo$','\.swp$','\.git','\.hg','\.svn','\.bzr']
let NERDTreeKeepTreeInNewTab=1
let g:nerdtree_tabs_open_on_gui_startup=0

" ctrlp
 set runtimepath^=~/.vim/bundle/ctrlp.vim

" mappings
let mapleader = ","
