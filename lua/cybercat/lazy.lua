local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

vim.o.termguicolors = true
require("lazy").setup(
	{
		-- Core plugins (telescope, treesitter, which-key, harpoon)
		{ import = "cybercat.plugins.core" },
		
		-- UI plugins (statusline, dashboard, notifications, etc.)
		{ import = "cybercat.plugins.ui" },
		
		-- Editing plugins (surround, autopairs, comment, motion)
		{ import = "cybercat.plugins.editing" },
		
		-- Git plugins
		{ import = "cybercat.plugins.git" },
		
		-- AI plugins (copilot, codeium, claude, avante)
		{ import = "cybercat.plugins.ai" },
		
		-- Language-specific plugins (markdown, package-info, kubectl)
		{ import = "cybercat.plugins.languages" },
		
		-- Tools (HTTP, testing, debugging, search/replace)
		{ import = "cybercat.plugins.tools" },
		
		-- LSP & Mason (keep untouched)
		{ import = "cybercat.plugins.lsp" },
		
		-- Colorschemes
		{ import = "cybercat.plugins.colorscheme" },
		
		-- Legacy plugins (for compatibility during migration)
		{ import = "cybercat.plugins" },
	},
	{
		-- install = {
		--   colorscheme = { "nightfly" },
		-- },
		checker = {
			enabled = true,
			notify = false,
		},

		performance = {
			rtp = {
				-- disable some rtp plugins
				disabled_plugins = {
					"gzip",
					-- "matchit",
					-- "matchparen",
					-- "netrwPlugin",
					"tarPlugin",
					"tohtml",
					-- "tutor",
					"zipPlugin",
				},
			},
		},
		change_detection = {
			notify = false,
		},
	}
)
