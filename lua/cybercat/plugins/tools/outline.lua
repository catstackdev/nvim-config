-- There are also some related plugins like `aerial.nvim` found below
--
-- { "stevearc/aerial.nvim", opts = {} }, // like
--
return {
	"hedyhli/outline.nvim",
	lazy = true,
	cmd = { "Outline", "OutlineOpen" },
	keys = {
		{ "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
	},
	opts = {
		symbol_folding = {
			autofold_depth = false, -- unfold all by default
		},
		outline_window = {
			width = 20,
			position = "right", -- optional: "left" or "right"
			show_numbers = false, -- show line numbers in outline
			show_relative_numbers = false,
			show_symbol_kind = true, -- show symbol type (function, class, etc.)
		},
		auto_close = false, -- keep outline open when switching buffers
		highlight_hovered_item = true, -- highlights symbol under cursor
		preview = true, -- optional: show preview of symbol definition
		show_guides = true, -- tree guides for nested symbols
		keymaps = {
			close = "q",
			goto_location = "<CR>",
			focus_location = "o",
			hover_symbol = "K",
			toggle_preview = "p",
			rename_symbol = "r",
		},
		on_hover = function(symbol)
			if not symbol then
				vim.notify("No symbol under cursor", vim.log.levels.WARN)
				return
			end
			vim.lsp.buf.hover()
		end,
	},
}
