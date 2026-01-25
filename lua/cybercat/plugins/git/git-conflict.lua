return {
	"akinsho/git-conflict.nvim",
	version = "*",
	event = "VeryLazy",
	config = function()
		require("git-conflict").setup({
			default_mappings = {
				ours = "co", -- Choose ours (current branch)
				theirs = "ct", -- Choose theirs (incoming branch)
				none = "c0", -- Choose none (delete both)
				both = "cb", -- Choose both
				next = "]x", -- Next conflict
				prev = "[x", -- Previous conflict
			},
			disable_diagnostics = false,
			list_opener = "copen",
		})
	end,
}
