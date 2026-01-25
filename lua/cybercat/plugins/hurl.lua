return {
	"jellydn/hurl.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	ft = "hurl",
	opts = {
		-- Show debugging info
		debug = false,
		-- Show notification on run
		show_notification = true,
		-- Show response in popup or split
		mode = "split",
		-- Formatters for response body
		formatters = {
			json = { "jq" },
			html = {
				"prettier",
				"--parser",
				"html",
			},
		},
		-- Auto-find variables file
		env_file = {
			"hurl.env",
			"test/api/hurl.env",
			".env",
		},
		-- Disable test mode by default (show responses instead)
		auto_close = false,
		-- Split window configuration
		split_position = "right",
		split_size = "50%",
	},
	keys = {
		-- Run requests (shows last response body only)
		{ "<leader>hr", "<cmd>HurlRunner<CR>", desc = "Hurl: Run File (show last response)", ft = "hurl" },
		{ "<leader>ha", "<cmd>HurlRunnerAt<CR>", desc = "Hurl: Run Request at Cursor", ft = "hurl" },
		
		-- Test mode (shows pass/fail summary for ALL tests)
		{ "<leader>ht", function()
			vim.cmd("split | terminal hurl --test " .. vim.fn.expand("%"))
		end, desc = "Hurl: Test File (show all results)", ft = "hurl" },
		
		-- Test with verbose (shows ALL requests and responses)
		{ "<leader>hT", function()
			vim.cmd("split | terminal hurl --test --very-verbose " .. vim.fn.expand("%"))
		end, desc = "Hurl: Test Verbose (show all details)", ft = "hurl" },
		
		-- Verbose mode (shows full HTTP details)
		{ "<leader>hv", "<cmd>HurlVerbose<CR>", desc = "Hurl: Toggle Verbose", ft = "hurl" },
		{ "<leader>hV", function()
			vim.cmd("split | terminal hurl --verbose " .. vim.fn.expand("%"))
		end, desc = "Hurl: Run Verbose (non-test mode)", ft = "hurl" },
		
		-- Other commands
		{ "<leader>he", "<cmd>HurlManageVariable<CR>", desc = "Hurl: Manage Variables", ft = "hurl" },
	},
	config = function(_, opts)
		require("hurl").setup(opts)
		
		-- Add autocmd to close terminal with 'q' for hurl test output
		vim.api.nvim_create_autocmd("TermOpen", {
			pattern = "term://*hurl*",
			callback = function()
				vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, desc = "Close hurl test output" })
			end,
		})
		
		-- Auto-format .hurl files on save
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*.hurl",
			callback = function()
				-- You can add hurl formatting here if needed
			end,
		})
	end,
}
