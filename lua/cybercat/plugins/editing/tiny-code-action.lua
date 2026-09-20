-- return {
-- 	"rachartier/tiny-code-action.nvim",
-- 	dependencies = {
-- 		"folke/snacks.nvim",
-- 	},
-- 	event = "LspAttach",
-- 	opts = {
-- 		backend = "vim", -- native vim.diff preview, no external tool required
-- 		picker = "snacks", -- match the picker already used elsewhere in this config
-- 	},
-- }
return {
	"rachartier/tiny-code-action.nvim",
	dependencies = {
		-- optional picker via telescope
		{ "nvim-telescope/telescope.nvim" },
		-- optional picker via fzf-lua
		{ "ibhagwan/fzf-lua" },
		-- .. or via snacks
		{
			"folke/snacks.nvim",
			opts = {
				terminal = {},
			},
		},
	},
	event = "LspAttach",
	opts = {},
}
