-- Plugin management keymaps
local keymap = vim.keymap

-- Lazy.nvim
keymap.set("n", "<leader>lzo", "<cmd>Lazy<CR>", { desc = "Open Lazy" })
keymap.set("n", "<leader>lzu", "<cmd>Lazy update<CR>", { desc = "Update Lazy" })

-- Mason
keymap.set("n", "<leader>mn", "<cmd>Mason<CR>", { desc = "Update Lazy" })

-- LSP Info
keymap.set("n", "<leader>lp", "<cmd>LspInfo<CR>", { desc = "open LspInfo" })

-- kubectl toggle
keymap.set("n", "<leader>uk", '<cmd>lua require("kubectl").toggle()<cr>', { noremap = true, silent = true })
