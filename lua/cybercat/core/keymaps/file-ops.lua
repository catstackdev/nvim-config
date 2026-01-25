-- File save and quit operations
local keymap = vim.keymap

-- Save operations
keymap.set("n", "<leader>wa", "<cmd>wall<CR>", { desc = "Save all files in this root dir" })
keymap.set("n", "<leader>wf", "<cmd>w<CR>", { desc = "Save only this file" })

-- Quit operations
keymap.set("n", "<leader>qf", "<cmd>q<CR>", { desc = "Quit only this file" })
keymap.set("n", "<leader>qa", "<cmd>qall<CR>", { desc = "Quit all, exit all" })
keymap.set("n", "<leader>q!", "<cmd>qall!<CR>", { desc = "Quit all no save, exit all no save" })

-- Combined save and quit
keymap.set("n", "<leader>wqa", "<cmd>wall<CR>:qall<CR>", { desc = "Save all files and quit" })
