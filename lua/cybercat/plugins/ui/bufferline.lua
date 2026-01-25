-- NOTE: space + t + o -- create new tap
return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  -- opts = {
  -- options = {
  --   mode = "tabs",
  --   separator_style = "slant",
  -- },
  -- },
  -- config = function()
  --   local bufferline = require("bufferline")
  --   bufferline.setup({
  --     -- options = {
  --     --   -- style_preset = bufferline.style_preset.no_italic, or you can combine these e.g.
  --     --   style_preset = {
  --     --     bufferline.style_preset.no_italic,
  --     --     bufferline.style_preset.no_bold,
  --     --   },
  --     -- },
  --   })
  -- end,
  diagnostics = "nvim_lsp",
  -- diagnostics_indicator = function(count, level)
  --   local icon = level:match("error") and " " or ""
  --   return " " .. icon .. count
  -- end,
  diagnostics_indicator = function(count, level, diagnostics_dict, context)
    local s = " "
    for e, n in pairs(diagnostics_dict) do
      local sym = e == "error" and " " or (e == "warning" and " " or "")
      s = s .. n .. sym
    end
    return s
  end,

  -- groups = {
  --   options = {
  --     toggle_hidden_on_enter = true, -- when you re-enter a hidden group this options re-opens that group so the buffer is visible
  --   },
  --   items = {
  --     {
  --       name = "Tests", -- Mandatory
  --       highlight = { underline = true, sp = "blue" }, -- Optional
  --       priority = 2, -- determines where it will appear relative to other groups (Optional)
  --       icon = "", -- Optional
  --       matcher = function(buf) -- Mandatory
  --         return buf.filename:match("%_test") or buf.filename:match("%_spec")
  --       end,
  --     },
  --     {
  --       name = "Docs",
  --       highlight = { undercurl = true, sp = "green" },
  --       auto_close = false, -- whether or not close this group if it doesn't contain the current buffer
  --       matcher = function(buf)
  --         return buf.filename:match("%.md") or buf.filename:match("%.txt")
  --       end,
  --       separator = { -- Optional
  --         style = require("bufferline.groups").separator.tab,
  --       },
  --     },
  --   },
  -- },
}
