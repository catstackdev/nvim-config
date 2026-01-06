return {
	"vuki656/package-info.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	ft = "json", -- Lazy load on package.json
	config = function()
		require("package-info").setup({
			-- colors = {
			-- up_to_date = "#3C4048",
			-- outdated = "#d19a66", -- Orange instead of red (less aggressive)
			-- },
			icons = {
				enable = true,
				style = {
					up_to_date = "✓",
					outdated = "⚠",
				},
			},
			autostart = true,
			hide_up_to_date = false, -- Set to true to only show outdated
			hide_unstable_versions = true, -- Hide alpha/beta/rc versions
		})

		-- Keymaps for package management (only in package.json)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "json",
			callback = function()
				local bufname = vim.api.nvim_buf_get_name(0)
				if bufname:match("package%.json$") then
					local opts = { buffer = true, silent = true }

					-- Show/hide dependency versions
					vim.keymap.set(
						"n",
						"<leader>ns",
						require("package-info").show,
						vim.tbl_extend("force", opts, { desc = "Show dependency versions" })
					)
					vim.keymap.set(
						"n",
						"<leader>nh",
						require("package-info").hide,
						vim.tbl_extend("force", opts, { desc = "Hide dependency versions" })
					)

					-- Update packages
					vim.keymap.set(
						"n",
						"<leader>nu",
						require("package-info").update,
						vim.tbl_extend("force", opts, { desc = "Update dependency" })
					)
					vim.keymap.set(
						"n",
						"<leader>nd",
						require("package-info").delete,
						vim.tbl_extend("force", opts, { desc = "Delete dependency" })
					)
					vim.keymap.set(
						"n",
						"<leader>ni",
						require("package-info").install,
						vim.tbl_extend("force", opts, { desc = "Install dependency" })
					)
					vim.keymap.set(
						"n",
						"<leader>nc",
						require("package-info").change_version,
						vim.tbl_extend("force", opts, { desc = "Change dependency version" })
					)
				end
			end,
		})
	end,
}
