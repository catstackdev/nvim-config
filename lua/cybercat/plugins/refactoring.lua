return {
	"ThePrimeagen/refactoring.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		-- Extract function (visual mode)
		{
			"<leader>re",
			":Refactor extract ",
			mode = "x",
			desc = "Extract function",
		},
		-- Extract function to file (visual mode)
		{
			"<leader>ref",
			":Refactor extract_to_file ",
			mode = "x",
			desc = "Extract function to file",
		},
		-- Extract variable (visual mode)
		{
			"<leader>rev",
			":Refactor extract_var ",
			mode = "x",
			desc = "Extract variable",
		},
		-- Inline variable (normal + visual mode)
		-- Changed from <leader>ri to avoid conflict with "remove imports"
		{
			"<leader>riv",
			":Refactor inline_var",
			mode = { "n", "x" },
			desc = "Inline variable",
		},
		-- Inline function (normal mode)
		{
			"<leader>rI",
			":Refactor inline_func",
			mode = "n",
			desc = "Inline function",
		},
		-- Extract block (normal mode)
		{
			"<leader>reb",
			":Refactor extract_block",
			mode = "n",
			desc = "Extract block",
		},
		-- Extract block to file (normal mode)
		{
			"<leader>rebf",
			":Refactor extract_block_to_file",
			mode = "n",
			desc = "Extract block to file",
		},
	},
	opts = {
		prompt_func_return_type = {
			go = false,
			java = false,
			cpp = false,
			c = false,
			h = false,
			hpp = false,
			cxx = false,
		},
		prompt_func_param_type = {
			go = false,
			java = false,
			cpp = false,
			c = false,
			h = false,
			hpp = false,
			cxx = false,
		},
		printf_statements = {},
		print_var_statements = {},
		show_success_message = true, -- Changed to true - useful feedback
	},
}
