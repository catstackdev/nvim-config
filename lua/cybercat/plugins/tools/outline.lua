-- There are also some related plugins like `aerial.nvim` found below
--
-- { "stevearc/aerial.nvim", opts = {} }, // like
--
return {
	"hedyhli/outline.nvim",
	lazy = true,
	cmd = { "Outline", "OutlineOpen" },
	keys = {
		{ "<leader>oo", "<cmd>Outline<CR>", desc = "Toggle outline" },
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
		},
		outline_items = {
			show_symbol_details = true, -- show symbol type (function, class, etc.)
		},
		auto_close = false, -- keep outline open when switching buffers
		highlight_hovered_item = true, -- highlights symbol under cursor
		preview_window = {
			auto_preview = true, -- show preview of symbol definition
			live = true,
		},
		show_guides = true, -- tree guides for nested symbols
		keymaps = {
			close = { "<Esc>", "q" },
			goto_location = "<CR>",
			peek_location = "o",
			hover_symbol = "K",
			toggle_preview = "p",
			rename_symbol = "r",
		},
	},
}
