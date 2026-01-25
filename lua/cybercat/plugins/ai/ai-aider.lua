return {
	"joshuavial/aider.nvim",
	opts = {
		auto_manage_context = true, -- automatically manage buffer context
		default_bindings = false, -- disable default keybindings (use custom below)
		debug = false, -- enable debug logging
		border = {
			style = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
			color = "#fab387",
		},
		-- Aider CLI arguments (synced with ~/.aider.conf.yml)
		aider_args = {
			"--model",
			"ollama/qwen2.5-coder:7b",
			"--no-auto-commits", -- Never auto-commit (manual control only)
			"--dirty-commits", -- Allow commits with dirty working tree
		},
	},

	config = function(_, opts)
		require("aider").setup(opts)

		-- Only use commands that actually exist in the plugin!
		local keymap = vim.keymap.set
		local opts_silent = { noremap = true, silent = true }

		-- Aider window management (ONLY THESE COMMANDS EXIST)
		keymap("n", "<leader>ado", ":AiderOpen<CR>", vim.tbl_extend("force", opts_silent, { desc = "Aider: Open" }))
		keymap(
			"n",
			"<leader>adm",
			":AiderAddModifiedFiles<CR>",
			vim.tbl_extend("force", opts_silent, { desc = "Aider: Add modified files" })
		)

		-- Auto-resize Aider window (35% of screen width, positioned right like outline)
		vim.api.nvim_create_autocmd("WinEnter", {
			pattern = "*",
			callback = function()
				local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
				if buf_ft == "AiderConsole" then -- Plugin uses "AiderConsole" not "aider"
					-- Set width dynamically (35% of terminal width, similar to outline)
					local width = math.floor(vim.o.columns * 0.35)
					vim.cmd("vertical resize " .. width)
					vim.cmd("wincmd L") -- move to right
				end
			end,
		})
	end,
}
