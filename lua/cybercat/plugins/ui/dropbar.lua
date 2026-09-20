return {
	"Bekaboo/dropbar.nvim",
	event = "BufReadPost",
	-- optional, but required for fuzzy finder support
	dependencies = {
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		require("dropbar").setup({
			bar = {
				-- padding = { left = 1, right = 1 },
				pick = {
					-- home row first so pick-mode selections stay on the fastest keys to reach
					pivots = "asdfghjklqwertyuiopzxcvbnm",
				},
			},
			menu = {
				preview = true,
				scrollbar = { enable = false, background = false },
			},
			-- icons = {
			-- 	ui = {
			-- 		bar = { separator = " › ", extends = "…" },
			-- 		menu = { separator = " ", indicator = " " },
			-- 	},
			-- },
		})

		local dropbar_api = require("dropbar.api")
		vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
		vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
		vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
	end,
}
