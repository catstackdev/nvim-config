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
		{ import = "cybercat.plugins" },
		{ import = "cybercat.plugins.lsp" },
		{ import = "cybercat.plugins.colorscheme" },
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
