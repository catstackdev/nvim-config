return {
	"nvim-treesitter/playground",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("nvim-treesitter.configs").setup({
			playground = {
				enable = true,
				updatetime = 25,
			},
		})
	end,
}
