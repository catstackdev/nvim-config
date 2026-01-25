-- Navigation and scrolling keymaps
local keymap = vim.keymap

-- Scroll by 35% of the window height and keep the cursor centered
local scroll_percentage = 0.35
keymap.set("n", "<C-d>", function()
  local lines = math.floor(vim.api.nvim_win_get_height(0) * scroll_percentage)
  vim.cmd("normal! " .. lines .. "jzz")
end, { noremap = true, silent = true })

keymap.set("n", "<C-u>", function()
  local lines = math.floor(vim.api.nvim_win_get_height(0) * scroll_percentage)
  vim.cmd("normal! " .. lines .. "kzz")
end, { noremap = true, silent = true })

-- Noice plugin keymaps
keymap.set({ "n", "v", "i" }, "<M-h>", function()
  require("noice").cmd("all")
end, { desc = "[P]Noice History" })

keymap.set({ "n", "v", "i" }, "<M-d>", function()
  require("noice").cmd("dismiss")
end, { desc = "Dismiss All" })

-- Copy the current line and all diagnostics on that line to system clipboard
vim.keymap.set("n", "yd", function()
  local pos = vim.api.nvim_win_get_cursor(0)
  local line_num = pos[1] - 1
  local line_text = vim.api.nvim_buf_get_lines(0, line_num, line_num + 1, false)[1]
  local diagnostics = vim.diagnostic.get(0, { lnum = line_num })
  if #diagnostics == 0 then
    vim.notify("No diagnostic found on this line", vim.log.levels.WARN)
    return
  end
  local message_lines = {}
  for _, d in ipairs(diagnostics) do
    for msg_line in d.message:gmatch("[^\n]+") do
      table.insert(message_lines, msg_line)
    end
  end
  local formatted = {}
  table.insert(formatted, "Line:\n" .. line_text .. "\n")
  table.insert(formatted, "Diagnostic on that line:\n" .. table.concat(message_lines, "\n"))
  vim.fn.setreg("+", table.concat(formatted, "\n\n"))
  vim.notify("Line and diagnostic copied to clipboard", vim.log.levels.INFO)
end, { desc = "[P]Yank line and diagnostic to system clipboard" })

-- When searching for stuff, search results show in the middle
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")
