-- Git keymaps
local keymap = vim.keymap

-- Git commit with AI auto-generate (use terminal git commit which works)
keymap.set("n", "<leader>gc", function()
  -- Close lazygit if open
  vim.cmd("q")
  -- Run git commit in terminal which triggers auto-generate
  vim.cmd("terminal git commit")
  vim.cmd("startinsert")
end, { desc = "Git commit with AI (terminal)" })
