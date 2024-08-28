"Plug 'godlygeek/tabular'

"let $LANG="zh_CN.UTF-8"
set langmenu=zh_cn.utf-8
"set encoding=utf8

colorscheme evening

source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim

hi CursorLine cterm=none ctermbg=DarkMagenta ctermfg=White
hi CursorColumn cterm=none ctermbg=DarkMagenta ctermfg=White
hi LineNr cterm=bold ctermfg=DarkGrey ctermbg=NONE
highlight Comment ctermfg=cyan
highlight Search term=reverse ctermbg=4 ctermfg=7

set nocompatible
set history=30

filetype on
filetype plugin indent on

set columns=320
set lines=80

set bg=dark
"set guifont=Monospace:h18
set guifont=Monospace
set fdm=marker
set autowrite
set nobackup

set wildmenu
set ignorecase
set smartcase
set ruler
set wrap
set cindent
set expandtab
set nobackup
set noswapfile
set tabstop=4
set softtabstop=4
set shiftwidth=4
set backspace=indent,eol,start
set whichwrap+=<,>,h,l         
set hlsearch
set incsearch
set showmatch
set showmode
set mouse=a
set shortmess=atI
set report=0
set lsp=0
set novisualbell
set noerrorbells
set number

set autoindent
set smartindent
set scrolloff=5
set sidescroll=1

syntax on

let b:match_words='\<begin\>:\<end\>' 

imap <F2>  //--------Modified by Qi.Shao on<Esc>:r !date <CR><CR><Esc>kJ$a------v<Esc>o 
map  <F2> o//--------Modified by Qi.Shao on<Esc>:r !date <CR><CR><Esc>kJ$a------v<Esc>j 

function GetCurFilePath()
    let cur_dir=getcwd()
    let cur_file_name=getreg('%')
    let dir_filename=cur_dir."".cur_file_name
    echo dir_filename."         done"
    call setreg('+',dir_filename)
endfunction

nnoremap <silent> <F9> : call GetCurFilePath()<cr>
