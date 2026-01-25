return {
	"danymat/neogen",
	enabled = false,
	dependencies = "nvim-treesitter/nvim-treesitter",
	config = function()
		require("neogen").setup({
			enabled = true,
			languages = {
				javascript = { template = { annotation_convention = "jsdoc" } },
				typescript = { template = { annotation_convention = "tsdoc" } },
				tsx = { template = { annotation_convention = "tsdoc" } },
				jsx = { template = { annotation_convention = "jsdoc" } },
			},
		})

		-- 🔥 Auto-generate docstring when typing `/**<CR>` like in VSCode
		vim.api.nvim_create_autocmd("InsertCharPre", {
			pattern = { "*.js", "*.ts", "*.jsx", "*.tsx" },
			callback = function(ev)
				local line = vim.api.nvim_get_current_line()
				local col = vim.api.nvim_win_get_cursor(0)[2]
				local before = line:sub(1, col)
				if before:match("%/%*%*$") then
					vim.schedule(function()
						require("neogen").generate()
					end)
				end
			end,
		})
	end,
}
