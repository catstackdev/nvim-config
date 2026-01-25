return {
	"nvim-treesitter/nvim-treesitter-context",
	enabled = false,
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		enable = true,
		max_lines = 4,
		trim_scope = "outer",
		mode = "cursor",
		separator = "─",
	},
	config = function(_, opts)
		require("treesitter-context").setup(opts)
		vim.keymap.set("n", "gC", function()
			require("treesitter-context").go_to_context(vim.v.count1)
		end, { silent = true, desc = "Go to context" })
	end,
}
