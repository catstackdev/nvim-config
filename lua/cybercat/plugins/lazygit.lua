return {
  "kdheepak/lazygit.nvim",
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- setting the keybinding for LazyGit with 'keys' is recommended in
  -- order to load the plugin when the command is run for the first time
  keys = {
    { "<leader>lg", "<cmd>LazyGit<cr>", desc = "Open lazy git" },
  },
  config = function()
    -- Set up environment for lazygit to use correct editor
    vim.g.lazygit_floating_window_scaling_factor = 0.9
    
    -- Make sure NVIM var is set so nvim-remote works
    if vim.fn.has('nvim') == 1 then
      vim.env.NVIM = vim.v.servername
    end
  end,
}
