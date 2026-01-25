-- return {}
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
		-- Helper function to check if environment files exist
		local function check_env_files()
			local cwd = vim.fn.getcwd()
			local env_files = {
				cwd .. "/.env.local",
				cwd .. "/.env.dev",
				cwd .. "/.env.prod",
			}

			local missing_files = {}
			for _, file in ipairs(env_files) do
				if vim.fn.filereadable(file) == 0 then
					table.insert(missing_files, file)
				end
			end

			return missing_files
		end

		-- Helper function to create example env files
		local function create_example_env_files()
			local cwd = vim.fn.getcwd()
			local env_configs = {
				[".env.local"] = "# Local Development Environment\nbaseUrl=http://localhost:3000\napiKey=local-dev-key\n",
				[".env.dev"] = "# Development Environment\nbaseUrl=https://dev-api.example.com\napiKey=dev-api-key-here\n",
				[".env.prod"] = "# Production Environment\nbaseUrl=https://api.example.com\napiKey=prod-api-key-here\n",
			}

			for filename, content in pairs(env_configs) do
				local filepath = cwd .. "/" .. filename
				if vim.fn.filereadable(filepath) == 0 then
					local file = io.open(filepath, "w")
					if file then
						file:write(content)
						file:close()
						vim.notify("Created: " .. filename, vim.log.levels.INFO)
					end
				end
			end
		end

		-- Show help box if env files don't exist
		local function show_env_help()
			local missing = check_env_files()
			if #missing > 0 then
				local help_lines = {
					"",
					"REST.nvim Environment Setup",
					"─────────────────────────────────────",
					"",
					"Missing environment files:",
				}

				for _, file in ipairs(missing) do
					table.insert(help_lines, "  • " .. vim.fn.fnamemodify(file, ":t"))
				end

				table.insert(help_lines, "")
				table.insert(help_lines, "Quick Setup:")
				table.insert(help_lines, "  1. Run :RestCreateEnvFiles")
				table.insert(help_lines, "  2. Edit env files with your API details")
				table.insert(help_lines, "  3. Use snippets: 'get', 'post', 'getauth', etc.")
				table.insert(help_lines, "")
				table.insert(help_lines, "Available keymaps:")
				table.insert(help_lines, "  <leader>rr - Run request under cursor")
				table.insert(help_lines, "  <leader>re - Select environment")
				table.insert(help_lines, "")

				vim.notify(table.concat(help_lines, "\n"), vim.log.levels.WARN)
			end
		end

		-- Create user command
		vim.api.nvim_create_user_command("RestCreateEnvFiles", create_example_env_files, {})

		-- Check for env files when opening http files
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "http", "rest" },
			callback = function()
				vim.defer_fn(show_env_help, 500)
			end,
		})

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

		-- Keybindings
		local map = vim.keymap.set

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "http", "rest" },
			callback = function()
				map("n", "<leader>rr", "<cmd>Rest run<CR>", { desc = "Rest: Run Request", buffer = true })
				map("n", "<leader>rl", "<cmd>Rest last<CR>", { desc = "Rest: Run Last Request", buffer = true })
				map("n", "<leader>ro", "<cmd>Rest open<CR>", { desc = "Rest: Open Result Pane", buffer = true })
				map("n", "<leader>re", "<cmd>Rest env select<CR>", { desc = "Rest: Select Environment", buffer = true })
				map("n", "<leader>rc", "<cmd>Rest copy<CR>", { desc = "Rest: Copy as cURL", buffer = true })
				map("n", "<leader>rL", "<cmd>Rest logs<CR>", { desc = "Rest: Show Logs", buffer = true })
				map("n", "<leader>rt", "<cmd>Rest toggle_view<CR>", { desc = "Rest: Toggle View", buffer = true })
			end,
		})

		-- Global keymaps (not filetype-specific)
		map("n", "<leader>rf", "<cmd>Telescope rest select_env<CR>", { desc = "Rest: Find Requests" })
		map("n", "<leader>rN", "<cmd>RestCreateEnvFiles<CR>", { desc = "Rest: Create Environment Files" })

		-- Custom keymaps for REST result window (avoid H/L conflicts)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "rest_nvim_result",
			callback = function()
				local buf = vim.api.nvim_get_current_buf()
				-- Unmap H and L if they're set by the plugin
				pcall(vim.keymap.del, "n", "H", { buffer = buf })
				pcall(vim.keymap.del, "n", "L", { buffer = buf })
				
				-- Add alternative navigation keymaps
				map("n", "<Tab>", "<cmd>Rest run last<CR>", { desc = "Rest: Run Last Request", buffer = buf })
				map("n", "q", "<cmd>close<CR>", { desc = "Close result window", buffer = buf })
				map("n", "<Esc>", "<cmd>close<CR>", { desc = "Close result window", buffer = buf })
				map("n", "<leader>rc", "<cmd>Rest copy<CR>", { desc = "Rest: Copy as cURL", buffer = buf })
			end,
		})
	end,
}
