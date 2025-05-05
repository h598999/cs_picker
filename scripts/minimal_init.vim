set rtp+=.
set rtp+=/home/jonas/.local/share/nvim/lazy/plenary.nvim
set rtp+=/home/jonas/.local/share/nvim/lazy/telescope.nvim

runtime! plugin/plenary.vim
runtime! plugin/telescope.lua

let g:telescope_test_delay = 100
