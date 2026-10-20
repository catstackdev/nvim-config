-- Run the current file in its language's runner (see cybercat.utils.runner)
-- http/rest buffers override <leader>rr/<leader>rl locally (plugins/tools/rest.lua)
local keymap = vim.keymap
local runner = require("cybercat.utils.runner")

keymap.set("n", "<leader>rr", runner.runFile, { desc = "Run: current file" })
keymap.set("n", "<leader>rt", runner.testFile, { desc = "Run: test crate/project" })
keymap.set("n", "<leader>rl", runner.runLast, { desc = "Run: last command again" })
keymap.set("n", "<leader>ro", runner.open, { desc = "Run: reopen output" })
keymap.set("n", "<leader>rq", runner.close, { desc = "Run: close output" })

-- neotest has no Rust adapter (neotest-rust is archived), so in Rust buffers the
-- <leader>te* test keys go through the runner instead; other languages stay on neotest.
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("RunnerRustTestKeys", { clear = true }),
	pattern = "rust",
	desc = "Runner: te* test keys for Rust buffers",
	callback = function(event)
		local function map(lhs, rhs, desc)
			keymap.set("n", lhs, rhs, { buffer = event.buf, desc = desc })
		end
		map("<leader>tet", runner.testNearest, "Run: nearest test (cargo)")
		map("<leader>tef", runner.testInFile, "Run: tests in file (cargo)")
		map("<leader>tea", runner.testFile, "Run: all tests in crate (cargo)")
	end,
})
