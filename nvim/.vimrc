" Set leader key
let mapleader = " "        " Set Space as the leader key
let maplocalleader = " "   " Also set local leader to Space

" Mouse functionality
set mouse=a

" Theme
colorscheme slate

" Transparency background
highlight Normal guibg=NONE ctermbg=NONE
highlight NormalNC guibg=NONE ctermbg=NONE
highlight EndOfBuffer guibg=NONE ctermbg=NONE

" Background of visual mode
highlight Visual guibg=#3e4451 guifg=#ffffff  " Background grey and text white

" Change the color of the mode indicator (ModeMsg)
highlight ModeMsg guibg=#3b4252 guifg=#d8dee9  " Dark background and light text (grey colors)

" Numbers
set number          " Show absolute line numbers
set relativenumber  " Show relative line numbers

" Toggle line numbers with <leader>n
nnoremap <leader>n :set number! relativenumber!<CR>

