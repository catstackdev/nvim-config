-- NOTE: s and iw(past with copied) s is like past
-- s + G
-- select with v + s
return {
	"gbprod/substitute.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local substitute = require("substitute")

		substitute.setup()

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		vim.keymap.set("n", "s", substitute.operator, { desc = "Substitute with motion" })
		vim.keymap.set("n", "ss", substitute.line, { desc = "Substitute line" })
		vim.keymap.set("n", "S", substitute.eol, { desc = "Substitute to end of line" })
		vim.keymap.set("x", "s", substitute.visual, { desc = "Substitute in visual mode" })
		-- keymap.set("n", "<leader>r", substitute.operator, { desc = "Substitute with motion" })
		-- keymap.set("n", "<leader>rr", substitute.line, { desc = "Substitute line" })
		-- keymap.set("n", "<leader>R", substitute.eol, { desc = "Substitute to end of line" })
		-- keymap.set("x", "<leader>r", substitute.visual, { desc = "Substitute in visual mode" })
	end,
}
