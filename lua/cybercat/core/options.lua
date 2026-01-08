vim.cmd("let g:netrw_liststyle = 3")

vim.o.sessionoptions = vim.o.sessionoptions .. ",localoptions"
vim.g.python3_host_prog = vim.fn.expand("~/.venv/neovim/bin/python")

local opt = vim.opt

if vim.g.neovim_mode == "skitty" then
	vim.wo.number = false
	vim.wo.relativenumber = false
else
	vim.wo.number = true
	vim.wo.relativenumber = true
end

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

opt.wrap = false

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

opt.cursorline = true

-- turn on termguicolors for tokyonight colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false

opt.spelllang = "en_us"
opt.spell = true

-- Reason: You lose undo history when you close files. This is a game-changer for safety.
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo"

opt.scrolloff = 2 -- Keep 2 lines visible above/below cursor
opt.sidescrolloff = 2 -- Keep 2 columns visible left/right
