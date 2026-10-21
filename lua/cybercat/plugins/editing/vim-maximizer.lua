-- The runner output is hidden while a split is maximized, so its title strip
-- doesn't stay on screen, and brought back when the split is restored.
local runnerHidden = false

local function toggleSplitMaximize()
  local runner = require("cybercat.utils.runner")
  if runner.isFocused() then
    runner.toggleMaximize() -- a real fullscreen float, covers everything
    return
  end
  if runnerHidden then
    runnerHidden = false
    if vim.t.maximizer_sizes then
      vim.cmd("MaximizerToggle")
    end
    runner.open()
    return
  end
  if runner.isVisible() then
    runner.close()
    runnerHidden = true
  end
  vim.cmd("MaximizerToggle")
end

return {
  "szw/vim-maximizer",
  keys = {
    { "<leader>sm", toggleSplitMaximize, desc = "Maximize/minimize a split" },
  },
}
