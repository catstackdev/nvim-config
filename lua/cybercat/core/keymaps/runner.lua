-- Run the current file in its language's runner (see cybercat.utils.runner)
-- http/rest buffers override <leader>rr/<leader>rl locally (plugins/tools/rest.lua)
local keymap = vim.keymap
local runner = require("cybercat.utils.runner")

keymap.set("n", "<leader>rr", runner.runFile, { desc = "Run: current file" })
keymap.set("n", "<leader>rt", runner.testFile, { desc = "Run: test crate/project" })
keymap.set("n", "<leader>rl", runner.runLast, { desc = "Run: last command again" })
keymap.set("n", "<leader>ro", runner.open, { desc = "Run: reopen output" })
keymap.set("n", "<leader>rq", runner.close, { desc = "Run: close output" })
