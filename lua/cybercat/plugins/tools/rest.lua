-- REST.nvim plugin configuration
-- HTTP testing with .http/.rest files
-- Lightweight alternative to Postman/Insomnia

return {
	"rest-nvim/rest.nvim",
	ft = { "http", "rest" },
	dependencies = {
		{
			"nvim-treesitter/nvim-treesitter",
			opts = function(_, opts)
				opts.ensure_installed = opts.ensure_installed or {}
				table.insert(opts.ensure_installed, "http")
			end,
		},
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("rest-nvim").setup({
			request = {
				set_content_type = true,
			},
			response = {
				hooks = {
					decode_url_segments = true,
					format_json = true,
				},
				highlight = {
					enabled = true,
					timeout = 150,
				},
			},
			env_file = ".env.local",
			env_dir = vim.fn.getcwd(),
			custom_dynamic_variables = {
				timestamp = function()
					return os.date("%Y-%m-%dT%H:%M:%S")
				end,
			},
			extensions = {
				telescope = true,
			},
		})

		-- Keybindings for .http/.rest files
		local map = vim.keymap.set

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "http", "rest" },
			callback = function()
				local buf_opts = { buffer = true, silent = true }
				
				map("n", "<leader>rr", "<cmd>Rest run<CR>", 
					vim.tbl_extend("force", buf_opts, { desc = "Rest: Run Request" }))
				map("n", "<leader>rl", "<cmd>Rest last<CR>", 
					vim.tbl_extend("force", buf_opts, { desc = "Rest: Run Last" }))
				map("n", "<leader>ro", "<cmd>Rest open<CR>", 
					vim.tbl_extend("force", buf_opts, { desc = "Rest: Open Result" }))
				map("n", "<leader>re", "<cmd>Rest env select<CR>", 
					vim.tbl_extend("force", buf_opts, { desc = "Rest: Select Env" }))
				map("n", "<leader>rc", "<cmd>Rest copy<CR>", 
					vim.tbl_extend("force", buf_opts, { desc = "Rest: Copy cURL" }))
				map("n", "<leader>rL", "<cmd>Rest logs<CR>", 
					vim.tbl_extend("force", buf_opts, { desc = "Rest: Show Logs" }))
				map("n", "<leader>rt", "<cmd>Rest toggle_view<CR>", 
					vim.tbl_extend("force", buf_opts, { desc = "Rest: Toggle View" }))
			end,
		})

		-- Global keymaps
		map("n", "<leader>rf", "<cmd>Telescope rest select_env<CR>", { desc = "Rest: Find Requests" })

		-- Custom keymaps for REST result window (avoid H/L conflicts)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "rest_nvim_result",
			callback = function()
				local buf = vim.api.nvim_get_current_buf()
				
				-- Unmap H and L to avoid conflicts with window navigation
				pcall(vim.keymap.del, "n", "H", { buffer = buf })
				pcall(vim.keymap.del, "n", "L", { buffer = buf })
				
				-- Add helpful keymaps for result window
				map("n", "q", "<cmd>close<CR>", { buffer = buf, desc = "Close result" })
				map("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, desc = "Close result" })
				map("n", "<Tab>", "<cmd>Rest run last<CR>", { buffer = buf, desc = "Re-run last" })
			end,
		})
		
		-- Setup HTTP utilities (shared with Hurl)
		require("cybercat.utils.http").setup()
	end,
}
