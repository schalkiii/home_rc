" ──────────────────────────────────────────────
" Encoding & Language
" ──────────────────────────────────────────────
let $LANG="zh_CN.UTF-8"
set langmenu=zh_cn.utf-8
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,ucs-bom,gbk,gb2312,cp936
source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim

" ──────────────────────────────────────────────
" Highlighting
" ──────────────────────────────────────────────
hi CursorLine cterm=none ctermbg=DarkMagenta ctermfg=White
hi CursorColumn cterm=none ctermbg=DarkMagenta ctermfg=White
hi LineNr cterm=bold ctermfg=DarkGrey ctermbg=NONE
highlight Comment ctermfg=cyan
highlight Search term=reverse ctermbg=4 ctermfg=7

" ──────────────────────────────────────────────
" General Settings
" ──────────────────────────────────────────────
set nocompatible
set history=1000
set hidden
set nobackup
set noswapfile
set autowrite
set timeoutlen=1000

" ──────────────────────────────────────────────
" Filetype Detection
" ──────────────────────────────────────────────
filetype on
filetype plugin indent on

" ──────────────────────────────────────────────
" Appearance
" ──────────────────────────────────────────────
set bg=dark
set ruler
set number
set showmode
set showmatch
set novisualbell
set noerrorbells
set scrolloff=5
set sidescroll=1

" ──────────────────────────────────────────────
" Indentation
" ──────────────────────────────────────────────
set autoindent
set smartindent
set cindent
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" ──────────────────────────────────────────────
" Folding
" ──────────────────────────────────────────────
set fdm=marker

" ──────────────────────────────────────────────
" Search
" ──────────────────────────────────────────────
set hlsearch
set incsearch
set ignorecase
set smartcase
set wildmenu

" ──────────────────────────────────────────────
" Editing Behavior
" ──────────────────────────────────────────────
set backspace=indent,eol,start
set whichwrap+=<,>,h,l
set splitright
set splitbelow

" ──────────────────────────────────────────────
" GUI vs Terminal
" ──────────────────────────────────────────────
if has("gui_running")
    set guifont=Monospace\ 12
    colorscheme evening
    set columns=200
    set lines=60
else
    colorscheme default
    set t_ti=
    set t_te=
endif

syntax on

" ──────────────────────────────────────────────
" Filetype-Specific Matching
" ──────────────────────────────────────────────
let b:match_words='\<begin\>:\<end\>'

" ──────────────────────────────────────────────
" Key Mappings
" ──────────────────────────────────────────────

" F2: Insert modification comment with timestamp
"   Insert mode: places cursor after comment for immediate typing
"   Normal mode: opens new line below, inserts comment
imap <F2>  //--------Modified by Qi.Shao on<Esc>:r !date <CR><CR><Esc>kJ$a------v<Esc>o
map  <F2> o//--------Modified by Qi.Shao on<Esc>:r !date <CR><CR><Esc>kJ$a------v<Esc>j

" F9: Copy current file path to clipboard
function GetCurFilePath()
    let cur_dir=getcwd()
    let cur_file_name=getreg('%')
    let dir_filename=cur_dir."/".cur_file_name
    echo dir_filename."         done"
    call setreg('+',dir_filename)
endfunction
nnoremap <silent> <F9> :call GetCurFilePath()<cr>

" Ctrl+N: Open NERDTree
" Ctrl+T: Toggle NERDTree
" Ctrl+F: Find current file in NERDTree
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>