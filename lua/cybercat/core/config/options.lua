-- ============================================================================
-- Vim Options Configuration
-- ============================================================================
-- Merged from options.lua + options2.lua for better organization
-- ============================================================================

local opt = vim.opt

-- ============================================================================
-- Leader Key
-- ============================================================================

vim.g.mapleader = " "

-- ============================================================================
-- Provider Configuration
-- ============================================================================

-- Python host program (pyenv-compatible)
-- NOTE: To fix "neovim module not found" error, run:
--   pip install pynvim
-- Or disable Python provider by uncommenting the line below:
-- vim.g.loaded_python3_provider = 0

local pyenv_python = vim.fn.expand("~/.pyenv/shims/python")
if vim.fn.executable(pyenv_python) == 1 then
	vim.g.python3_host_prog = pyenv_python
else
	vim.g.python3_host_prog = vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
end

-- Disable unused providers to reduce warnings
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- ============================================================================
-- UI & Appearance
-- ============================================================================

opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.cursorline = true
opt.conceallevel = 0

-- Line numbers (mode-specific configuration below)
opt.number = true
opt.relativenumber = true

-- ============================================================================
-- Tabs & Indentation
-- ============================================================================

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- ============================================================================
-- Search Settings
-- ============================================================================

opt.ignorecase = true
opt.smartcase = true

-- ============================================================================
-- Text Editing
-- ============================================================================

opt.wrap = false
opt.textwidth = 80
-- opt.colorcolumn = "80"

-- ============================================================================
-- Scrolling
-- ============================================================================

opt.scrolloff = 2
opt.sidescrolloff = 2

-- ============================================================================
-- Clipboard & Backspace
-- ============================================================================

opt.clipboard:append("unnamedplus")
opt.backspace = "indent,eol,start"

-- ============================================================================
-- Windows & Splits
-- ============================================================================

opt.splitright = true
opt.splitbelow = true

-- ============================================================================
-- File Handling
-- ============================================================================

opt.swapfile = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- ============================================================================
-- Spell Checking
-- ============================================================================

opt.spelllang = "en_us"
opt.spell = true

-- ============================================================================
-- Timeouts & Updates
-- ============================================================================

opt.timeout = true
opt.timeoutlen = 1000
opt.updatetime = 200

-- ============================================================================
-- Session Options
-- ============================================================================

opt.sessionoptions = {
	"buffers",
	"curdir",
	"tabpages",
	"winsize",
	"help",
	"globals",
	"skiprtp",
	"folds",
	"localoptions",
}

-- ============================================================================
-- Misc Settings
-- ============================================================================

vim.cmd("let g:netrw_liststyle = 3")
vim.g.snacks_animate = false

-- ============================================================================
-- Mode-Specific Configuration
-- ============================================================================

if vim.g.neovim_mode == "skitty" then
	-- Skitty Mode: Minimal UI for writing
	vim.wo.number = false
	vim.wo.relativenumber = false

	opt.laststatus = 2
	opt.statusline = "%m"
	opt.signcolumn = "no"
	opt.textwidth = 25
	opt.linebreak = false
	opt.wrap = false
	-- opt.colorcolumn = ""

	local colors = require("cybercat.core.ui.colors")
	vim.cmd(string.format([[highlight WinBar1 guifg=%s]], colors["linkarzu_color03"]))
	-- Winbar disabled (uncomment to enable)
	-- opt.winbar = '%#WinBar1# %{luaeval(\'vim.fn.fnamemodify(vim.fn.expand("%:t"), ":r")\')}%*%=%#WinBar1# linkarzu.com %*'
else
	-- Default Mode: Full development environment
	opt.relativenumber = true
	opt.textwidth = 80
	opt.wrap = true
	-- opt.colorcolumn = "80"

	-- ============================================================================
	-- Winbar Configuration
	-- ============================================================================

	local function shorten_path(path)
		local shorten_if_more_than = 6
		local prefix = ""
		if path:sub(1, 2) == "~/" then
			prefix = "~/"
			path = path:sub(3)
		elseif path:sub(1, 1) == "/" then
			prefix = "/"
			path = path:sub(2)
		end

		local parts = {}
		for part in string.gmatch(path, "[^/]+") do
			table.insert(parts, part)
		end

		if #parts > shorten_if_more_than then
			local first = parts[1]
			local last_four = table.concat({
				parts[#parts - 3],
				parts[#parts - 2],
				parts[#parts - 1],
				parts[#parts],
			}, "/")
			return prefix .. first .. "/../" .. last_four
		end

		return prefix .. table.concat(parts, "/")
	end

	local function get_winbar_path()
		local full_path = vim.fn.expand("%:p:h")
		return full_path:gsub(vim.fn.expand("$HOME"), "~")
	end

	local function get_buffer_count()
		return vim.fn.len(vim.fn.getbufinfo({ buflisted = 1 }))
	end

	local function update_winbar()
		local home_replaced = get_winbar_path()
		local buffer_count = get_buffer_count()
		local display_path = shorten_path(home_replaced)
		opt.winbar = "%#WinBar1#%m "
			.. "%#WinBar2#("
			.. buffer_count
			.. ") "
			.. "%#WinBar3#"
			.. vim.fn.expand("%:t")
			.. "%*%=%#WinBar1#"
			.. display_path
	end

	-- Winbar disabled (uncomment to enable)
	-- vim.api.nvim_create_autocmd({ "BufEnter", "ModeChanged" }, {
	-- 	callback = function(args)
	-- 		local old_mode = args.event == "ModeChanged" and vim.v.event.old_mode or ""
	-- 		local new_mode = args.event == "ModeChanged" and vim.v.event.new_mode or ""
	-- 		if args.event == "ModeChanged" then
	-- 			local buf_ft = vim.bo.filetype
	-- 			if buf_ft == "snacks_terminal" or old_mode:match("^t") or new_mode:match("^n") then
	-- 				update_winbar()
	-- 			end
	-- 		else
	-- 			update_winbar()
	-- 		end
	-- 	end,
	-- })
end

-- ============================================================================
-- Auto-Update Plugins on Startup
-- ============================================================================

local function augroup(name)
	return vim.api.nvim_create_augroup("cybercat_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("VimEnter", {
	group = augroup("autoupdate"),
	callback = function()
		if require("lazy.status").has_updates then
			require("lazy").update({ show = false })
		end
	end,
})

-- ============================================================================
-- Cursor Configuration
-- ============================================================================

opt.guicursor = {
	"n-v-c-sm:block-Cursor",
	"i-ci-ve:ver25-lCursor",
	"r-cr:hor20-CursorIM",
}

-- ============================================================================
-- Neovide Configuration
-- ============================================================================

if vim.g.neovide then
	-- Font
	vim.o.guifont = "JetBrainsMono Nerd Font:h15"

	-- Performance
	vim.g.neovide_refresh_rate = 120
	vim.g.neovide_scroll_animation_length = 0

	-- Cursor animations
	vim.g.neovide_cursor_animation_length = 0.18
	vim.g.neovide_cursor_short_animation_length = 0.15
	vim.g.neovide_position_animation_length = 0.20
	vim.g.neovide_cursor_trail_size = 7
	vim.g.neovide_cursor_vfx_mode = "sonicboom"

	-- macOS: Use right alt key as meta
	vim.g.neovide_input_macos_option_key_is_meta = "only_right"

	-- Keymaps for macOS
	vim.keymap.set("n", "<D-s>", ":w<CR>")
	vim.keymap.set("v", "<D-c>", '"+y')
	vim.keymap.set("n", "<D-v>", '"+P')
	vim.keymap.set("v", "<D-v>", '"+P')
	vim.keymap.set("c", "<D-v>", "<C-R>+")
	vim.keymap.set("i", "<D-v>", '<ESC>l"+Pli')

	vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = true })
end
