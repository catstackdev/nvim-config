return {
	"folke/tokyonight.nvim",
	priority = 1000,
	config = function()
		local highlight_utils = require("cybercat.core.highlights.utils")
		
		local bg = "#011628"
		local bg_dark = "#011423"
		local bg_highlight = "#143652"
		local bg_search = "#0A64AC"
		local bg_visual = "#275378"
		local fg = "#CBE0F0"
		local fg_dark = "#B4D0E9"
		local fg_gutter = "#627E97"
		local border = "#547998"

		vim.o.termguicolors = true

		require("tokyonight").setup({
			style = "night",
			transparent = true,
			on_colors = function(colors)
				colors.bg = bg
				colors.bg_dark = bg_dark
				colors.bg_float = bg_dark
				colors.bg_highlight = bg_highlight
				colors.bg_popup = bg_dark
				colors.bg_search = bg_search
				colors.bg_sidebar = bg_dark
				colors.bg_statusline = bg_dark
				colors.bg_visual = bg_visual
				colors.border = border
				colors.fg = fg
				colors.fg_dark = fg_dark
				colors.fg_float = fg
				colors.fg_gutter = fg_gutter
				colors.fg_sidebar = fg_dark
			end,
		})

		vim.cmd("colorscheme tokyonight")

		-- Setup LSP Inlay Hints highlight (must be after colorscheme)
		vim.api.nvim_set_hl(0, "LspInlayHint", {
			fg = "#627E97", -- fg_gutter color (subtle gray)
			bg = "NONE",
			italic = true,
		})

		-- Setup transparency for various plugin windows
		highlight_utils.setup_transparency_autocmd("NvimTree", highlight_utils.get_nvimtree_groups())
		highlight_utils.setup_transparency_autocmd("neo-tree", highlight_utils.get_neotree_groups())
		highlight_utils.setup_transparency_autocmd("mini.files", highlight_utils.get_minifiles_groups())
		highlight_utils.setup_transparency_autocmd("mason", highlight_utils.get_mason_groups())
		highlight_utils.setup_transparency_autocmd("lazy", highlight_utils.get_lazy_groups())

		-- Setup event-based transparency for Telescope and WhichKey
		highlight_utils.setup_event_autocmd(
			{ "VimEnter", "ColorScheme" },
			vim.list_extend(highlight_utils.get_telescope_groups(), highlight_utils.get_whichkey_groups())
		)
	end,
}