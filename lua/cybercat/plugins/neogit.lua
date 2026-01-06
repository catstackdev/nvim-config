return {
	"NeogitOrg/neogit",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"sindrets/diffview.nvim", -- Better diff view
	},
	enabled = false,
	keys = {
		{ "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit" },
		{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff View" },
	},
	config = true,
}
