return {
	-- Smooth scrolling
	{
		"karb94/neoscroll.nvim",
		event = "BufWinEnter",
		opts = {
			easing = "circular", -- smoother than the default linear
		},
		config = function(_, opts)
			require("neoscroll").setup(opts)
		end,
	},

	-- Persistent scrollbar / scroll indicators
	{
		"dstein64/nvim-scrollview",
		event = "BufWinEnter",
		opts = {
			excluded_filetypes = { "nerdtree", "NvimTree", "help", "toggleterm" },
			current_only = false, -- show scrollbar for all windows
			signs_on_startup = { "diagnostics", "search", "marks", "spell" },
			hide_on_cursor_intersect = true,
			winblend = 30, -- translucent scrollbar in terminals without termguicolors
		},
		config = function(_, opts)
			require("scrollview").setup(opts)
		end,
	},
}
