return { -- highlight occurences of current word
	"RRethy/vim-illuminate",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		delay = 200,
		under_cursor = true,
		min_count_to_highlight = 1,
		providers = { "lsp", "treesitter", "regex" },
		filetypes_denylist = {
			"dashboard",
			"alpha",
			"neo-tree",
			"NvimTree",
			"lazy",
			"mason",
			"TelescopePrompt",
			"harpoon",
			"dirbuf",
			"dirvish",
			"fugitive",
		},
	},
	config = function(_, opts)
		require("illuminate").configure(opts)
	end,
}
