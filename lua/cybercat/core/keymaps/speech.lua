-- Speak selected text (or the current line) aloud via macOS `say`, and stop it
local keymap = vim.keymap

local function speak(text)
	vim.fn.jobstart({ "say", text }, { detach = true })
end

-- A Lua-function mapping runs like <Cmd>, so it fires without leaving Visual
-- mode first: the current selection is still live, so yank it directly
-- instead of "gv" (which would reselect the previous, now-stale, selection).
keymap.set("v", "<leader>sp", function()
	vim.cmd('normal! "zy')
	speak(vim.fn.getreg("z"))
end, { desc = "Speak selected text" })

keymap.set("n", "<leader>sp", function()
	speak(vim.fn.getline("."))
end, { desc = "Speak current line" })

keymap.set("n", "<leader>sP", function()
	speak(table.concat(vim.fn.getline(1, "$"), "\n"))
end, { desc = "Speak entire buffer" })

keymap.set("n", "<leader>sS", function()
	vim.fn.jobstart({ "killall", "say" })
end, { desc = "Stop speaking" })
