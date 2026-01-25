-- LSP import management keymaps
local keymap = vim.keymap

-- Quick fix import (generic LSP quickfix)
keymap.set("n", "<leader>qf", function()
  vim.lsp.buf.code_action({
    context = { only = { "quickfix" } },
    apply = true,
  })
end, { desc = "Apply Quick Fix (Auto Import)" })

-- Load import utility module
local ok, imports = pcall(require, "cybercat.utils.import")

if not ok then
  vim.notify("cybercat.utils.import module not found - import keymaps disabled", vim.log.levels.WARN)
  return
end

-- Individual import actions
keymap.set("n", "<leader>ai", imports.add_missing_imports, {
  desc = "Add missing imports",
})

keymap.set("n", "<leader>ri", imports.remove_unused_imports, {
  desc = "Remove unused imports",
})

keymap.set("n", "<leader>oi", imports.organize_imports, {
  desc = "Organize imports",
})

-- Combined actions
keymap.set("n", "<leader>fi", imports.fix_all_imports, {
  desc = "Fix all imports (add + remove + organize)",
})

keymap.set("n", "<leader>fa", imports.fix_all, {
  desc = "Fix all (imports + code issues)",
})

-- Debugging & stats
keymap.set("n", "<leader>ad", imports.debug_code_actions, {
  desc = "Debug code actions",
})

keymap.set("n", "<leader>is", imports.import_stats, {
  desc = "Show import statistics",
})
