return {
	-- Smooth scrolling
	{
		"karb94/neoscroll.nvim",
		event = "BufWinEnter",
		opts = {
			mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
			hide_cursor = true,
			stop_eof = true,
			respect_scrolloff = false,
			cursor_scrolls_alone = true,
			duration_multiplier = 1.0,
			easing = "circular", -- smoother than linear
			performance_mode = false,
			ignored_events = { "WinScrolled", "CursorMoved" },
			pre_hook = function(info)
				-- Optional: highlight word under cursor or do something before scroll
			end,
			post_hook = function(info)
				-- Optional: run a function after scroll
			end,
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
			current_only = false, -- Show scrollbar for all windows
			scrollbars = {
				search = "Search",
				error = "DiagnosticError",
				warning = "DiagnosticWarn",
				info = "DiagnosticInfo",
				hint = "DiagnosticHint",
				git = "GitSignsAdd", -- show git marks (requires gitsigns.nvim)
				marks = "Identifier", -- show vim marks
			},
			signs = true, -- show signs in the scrollbar (LSP, Git)
			offset = 1, -- offset from the right for scrollbar
		},
		config = function(_, opts)
			require("scrollview").setup(opts)
		end,
	},
}
