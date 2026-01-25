-- Hurl.nvim plugin configuration
-- HTTP testing with .hurl files
-- Uses shared utilities from cybercat.utils.http

return {
	"jellydn/hurl.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	ft = "hurl",
	opts = {
		debug = false,
		show_notification = true,
		mode = "split",
		formatters = {
			json = { "jq" },
			html = { "prettier", "--parser", "html" },
		},
		env_file = {
			"hurl.env",
			"test/api/hurl.env",
			".env",
		},
		auto_close = false,
		split_position = "right",
		split_size = "50%",
	},
	keys = function()
		local http = require("cybercat.utils.http")
		
		return {
			-- Run requests (shows response body)
			{ 
				"<leader>hr", 
				function() http.run_hurl_file() end,
				desc = "Hurl: Run File", 
				ft = "hurl" 
			},
			{ 
				"<leader>ha", 
				function() http.run_hurl_at_cursor() end,
				desc = "Hurl: Run Request at Cursor", 
				ft = "hurl" 
			},
			
			-- Test mode (shows pass/fail summary)
			{ 
				"<leader>ht", 
				function() http.test_hurl_file(false) end,
				desc = "Hurl: Test File", 
				ft = "hurl" 
			},
			{ 
				"<leader>hT", 
				function() http.test_hurl_file(true) end,
				desc = "Hurl: Test Verbose", 
				ft = "hurl" 
			},
			
			-- Other commands
			{ 
				"<leader>hv", 
				"<cmd>HurlVerbose<CR>", 
				desc = "Hurl: Toggle Verbose", 
				ft = "hurl" 
			},
			{ 
				"<leader>he", 
				"<cmd>HurlManageVariable<CR>", 
				desc = "Hurl: Manage Variables", 
				ft = "hurl" 
			},
		}
	end,
	config = function(_, opts)
		require("hurl").setup(opts)
		
		-- Setup HTTP utilities (terminal keymaps, etc.)
		require("cybercat.utils.http").setup()
	end,
}
