-- ============================================================================
-- Snacks.nvim - Modular Configuration
-- ============================================================================
-- NOTE: If you experience an issue in which you cannot select a file with the
-- snacks picker when you're in insert mode, only in normal mode, and you use
-- the bullets.vim plugin, that's the cause, go to that file to see how to
-- resolve it
-- https://github.com/folke/snacks.nvim/issues/812
-- ============================================================================

local keymaps = require("cybercat.plugins.snacks.keymaps")
local opts = require("cybercat.plugins.snacks.opts")

return {
	{
		"folke/snacks.nvim",
		keys = keymaps.setup(),
		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					-- Commented out debug utilities (uncomment if needed)
					-- Setup some globals for debugging (lazy-loaded)
					-- _G.dd = function(...)
					-- 	Snacks.debug.inspect(...)
					-- end
					-- _G.bt = function()
					-- 	Snacks.debug.backtrace()
					-- end

					-- Override print to use snacks for `:=` command
					-- if vim.fn.has("nvim-0.11") == 1 then
					-- 	vim._print = function(_, ...)
					-- 		dd(...)
					-- 	end
					-- else
					-- 	vim.print = _G.dd
					-- end

					-- Commented out toggle mappings (uncomment if needed)
					-- Create some toggle mappings
					-- Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
					-- Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
					-- Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
					-- Snacks.toggle.diagnostics():map("<leader>ud")
					-- Snacks.toggle.line_number():map("<leader>ul")
					-- Snacks.toggle
					-- 	.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
					-- 	:map("<leader>uc")
					-- Snacks.toggle.treesitter():map("<leader>uT")
					-- Snacks.toggle
					-- 	.option("background", { off = "light", on = "dark", name = "Dark Background" })
					-- 	:map("<leader>ub")
					-- Snacks.toggle.inlay_hints():map("<leader>uh")
					-- Snacks.toggle.indent():map("<leader>ug")
					-- Snacks.toggle.dim():map("<leader>uD")
				end,
			})
		end,
		---@type snacks.Config
		opts = opts.setup(),
	},
}
