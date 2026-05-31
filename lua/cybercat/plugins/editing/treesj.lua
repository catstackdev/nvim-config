return {
	"Wansmer/treesj",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	keys = {
		{ "<leader>tj", "<cmd>TSJToggle<cr>", desc = "Treesj: toggle split/join" },
		{ "<leader>tJ", "<cmd>TSJJoin<cr>",   desc = "Treesj: join node" },
		{ "<leader>tS", "<cmd>TSJSplit<cr>",  desc = "Treesj: split node" },
	},
	opts = {
		use_default_keymaps = false, -- defaults <leader>m/j/s collide with snacks search prefix
		max_join_length = 240,
	},
}
