return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeoutlen = 300
	end,
	opts = function()
		return {
			preset = "modern",
			delay = 200,
			icons = { mappings = true },
			win = { border = "rounded", title_pos = "center" },
			spec = require("cybercat.core.whichkey-groups"),
		}
	end,
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
}
