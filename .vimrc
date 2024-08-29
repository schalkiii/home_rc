" 语言设置
let $LANG="zh_CN.UTF-8" 
" 这行被注释掉了，可以设置环境变量 LANG 为简体中文 UTF-8 编码
set langmenu=zh_cn.utf-8
" 设置 Vim 菜单语言为简体中文 UTF-8
set encoding=utf-8
" 被注释掉的设置编码为 UTF-8
set fileencoding=utf-8
set fileencodings=utf-8,ucs-bom,gbk,gb2312,cp936


" 重新加载 Vim 的菜单配置，这两行常用于定制菜单项
source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim

" 高亮设置
hi CursorLine cterm=none ctermbg=DarkMagenta ctermfg=White
hi CursorColumn cterm=none ctermbg=DarkMagenta ctermfg=White
hi LineNr cterm=bold ctermfg=DarkGrey ctermbg=NONE
highlight Comment ctermfg=cyan
highlight Search term=reverse ctermbg=4 ctermfg=7
" 以上设置定制了光标行/列、行号、注释和搜索结果的高亮效果

" 常规设置
set nocompatible
" 禁用兼容模式，启用 Vim 的扩展功能
set history=30
" 设置命令历史记录为 30 条

" 文件类型检测与缩进设置
filetype on
filetype plugin indent on
" 启用文件类型检测、插件和缩进设置


set bg=dark
" 设置背景为深色模式

" 编辑与文件保存相关配置
set fdm=marker
" 设置折叠方法为基于标记
set autowrite
" 在切换缓冲区或执行某些命令时自动保存文件
set nobackup
" 不生成备份文件

" 命令行与搜索设置
set wildmenu
" 启用命令行的自动补全菜单
set ignorecase
"搜索时忽略大小写
set smartcase
"如果搜索包含大写字母，则区分大小写

"缩进与制表符设置
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
" 使用空格替代 Tab，一个 Tab 相当于 4 个空格

" 其他设置
set backspace=indent,eol,start
" 使回退键更符合预期，允许删除缩进、行尾符等
set whichwrap+=<,>,h,l
" 允许光标在行首和行尾进行左右移动
set hlsearch
" 高亮搜索结果
set incsearch
" 增量搜索，实时显示搜索结果
set showmatch
" 显示匹配的括号
set showmode
" 显示当前模式
" set mouse=a
" 启用鼠标支持

set scrolloff=0
" 滚动时光标与上下边缘之间至少保留 5 行
set sidescroll=1
" 水平滚动时每次移动 1 列

set novisualbell
" 禁用可视提示
set noerrorbells
" 禁用错误提示音

set number
" 显示行号

" 自动缩进与智能缩进
set autoindent
set smartindent

if has("gui_running")
    " GUI 模式下的配置
    set guifont=Monospace\ 12
    "颜色主题与界面配置
    colorscheme evening
    "设置 Vim 的配色方案为 evening

    " 窗口大小与字体设置
    set columns=200
    set lines=30
    " 设置 Vim 窗口宽度为 320 列，高度为 80 行
else
    " 终端模式设置，避免退出 Vim 后终端不显示问题
    set t_ti= t_te=

endif


" 使用鼠标设置可能导致终端行为异常，可以根据需要注释掉
" set mouse=a

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
