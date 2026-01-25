return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",

		-- Adapters for your stack
		"nvim-neotest/neotest-jest",
		"marilari88/neotest-vitest",
	},
	event = "VeryLazy",
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-jest")({
					jestCommand = "npm test --",
					jestConfigFile = "jest.config.js",
					env = { CI = true },
					cwd = function()
						return vim.fn.getcwd()
					end,
				}),
				require("neotest-vitest")({
					-- Filter directories for Vitest
					filter_dir = function(name)
						return name ~= "node_modules"
					end,
				}),
			},

			-- UI configuration
			status = { virtual_text = true },
			output = { open_on_run = true },
			quickfix = {
				open = false,
			},

			-- Floating window for test output
			floating = {
				border = "rounded",
				max_height = 0.8,
				max_width = 0.9,
			},

			-- Icons
			icons = {
				running = "",
				passed = "",
				failed = "",
				skipped = "",
				unknown = "",
			},
		})
	end,

	keys = {
		-- Run tests
		{
			"<leader>tet",
			function()
				require("neotest").run.run()
			end,
			desc = "Run nearest test",
		},
		{
			"<leader>tef",
			function()
				require("neotest").run.run(vim.fn.expand("%"))
			end,
			desc = "Run test file",
		},
		{
			"<leader>tea",
			function()
				require("neotest").run.run(vim.fn.getcwd())
			end,
			desc = "Run all tests",
		},
		{
			"<leader>ted",
			function()
				require("neotest").run.run({ strategy = "dap" })
			end,
			desc = "Debug nearest test",
		},

		-- Test output
		{
			"<leader>teo",
			function()
				require("neotest").output.open({ enter = true })
			end,
			desc = "Show test output",
		},
		{
			"<leader>teO",
			function()
				require("neotest").output_panel.toggle()
			end,
			desc = "Toggle output panel",
		},

		-- Test summary
		{
			"<leader>tes",
			function()
				require("neotest").summary.toggle()
			end,
			desc = "Toggle test summary",
		},

		-- Navigation
		{
			"[t",
			function()
				require("neotest").jump.prev({ status = "failed" })
			end,
			desc = "Previous failed test",
		},
		{
			"]t",
			function()
				require("neotest").jump.next({ status = "failed" })
			end,
			desc = "Next failed test",
		},

		-- Watch mode
		{
			"<leader>tew",
			function()
				require("neotest").watch.toggle(vim.fn.expand("%"))
			end,
			desc = "Toggle watch mode",
		},

		-- Stop tests
		{
			"<leader>teS",
			function()
				require("neotest").run.stop()
			end,
			desc = "Stop test",
		},
	},
}
