-- Plugin Template with Keymaps
-- Use this for plugins that are mainly keyboard-driven

return {
	"author/plugin-name",
	keys = {
		-- Basic keymap
		{ "<leader>x", "<cmd>Command<CR>", desc = "Description" },
		
		-- With mode specification
		{ "<leader>y", "<cmd>Command<CR>", desc = "Description", mode = "n" },
		
		-- Visual mode
		{ "<leader>z", "<cmd>Command<CR>", desc = "Description", mode = "v" },
		
		-- Multiple modes
		{ "<leader>a", "<cmd>Command<CR>", desc = "Description", mode = { "n", "v" } },
		
		-- With function
		{
			"<leader>b",
			function()
				require("plugin-name").action()
			end,
			desc = "Description",
		},
	},
	opts = {},
}
