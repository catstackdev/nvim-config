-- Core plugins that are essential for the editor functionality
-- Telescope, Treesitter, Which-key, Harpoon

return {
  require("cybercat.plugins.core.telescope"),
  require("cybercat.plugins.core.telescope-undo"),
  require("cybercat.plugins.core.nvim-treesitter"),
  require("cybercat.plugins.core.nvim-treesitter-context"),
  require("cybercat.plugins.core.which-key"),
  require("cybercat.plugins.core.harpoon"),
}
