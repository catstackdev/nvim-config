return {
	-- The correct repository path
	"David-Kunz/gen.nvim",

	cmd = "Gen",

	keys = {
		-- Default mapping to open the main Gen window (normal/visual mode)
		{ "<leader>gG", "<cmd>Gen<cr>", mode = { "n", "v" }, desc = "Gemini: Start Generation" },
	},

	config = function()
		require("gen").setup({
			default_model = "gemini-2.5-flash",
			-- The plugin automatically detects GEMINI_API_KEY
		})

		-- Mapping for general prompt input
		vim.keymap.set("n", "<leader>GM", function()
			local prompt = vim.fn.input("Gemini Prompt: ")
			if prompt == "" then
				return
			end
			-- Execute the 'Gen' command with the user's prompt
			vim.api.nvim_exec("Gen " .. prompt, false)
		end, { desc = "Gemini: Prompt & Generate" })

		-- 🚀 NEW KEYMAP: Generate Commit Message using Gemini
		vim.keymap.set("n", "<leader>gcm", function()
			-- Get git diff file list
			local diff_names = vim.fn.system("git diff --cached --name-status")

			if vim.v.shell_error ~= 0 or diff_names == "" then
				vim.notify("No staged changes", vim.log.levels.WARN, { title = "Git Error" })
				return
			end

			-- Get full diff for more context
			local full_diff = vim.fn.system("git diff --cached")

			-- Build the detailed prompt (using the optimized structure)
			local prompt = string.format(
				[[You are an expert Git commit message writer following the Conventional Commit specification.
			
FULL DIFF:
%s

Generate the commit message now. Your output MUST be ONLY the commit message text.
Format: type(scope): concise summary (max 50 chars), followed by a blank line, then a body with bullet points (wrapped at 72 chars) explaining the WHAT and WHY.
]],
				full_diff
			)

			-- Execute the 'Gen' command with the generated prompt
			vim.api.nvim_exec("Gen " .. prompt, false)
		end, { desc = "Gemini: Generate commit message for staged changes" })
	end,
}
