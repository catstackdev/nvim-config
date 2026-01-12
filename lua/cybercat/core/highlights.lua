local colors = require("cybercat.core.colors")

local bg_colors = {
	colors["cybercat_color04"],
	colors["cybercat_color02"],
	colors["cybercat_color03"],
	colors["cybercat_color01"],
	colors["cybercat_color05"],
	colors["cybercat_color08"],
}

local fg_transparent = colors["cybercat_color13"]
local fg_solid = colors["cybercat_color26"]

local fg = fg_transparent or fg_solid

for i, bg in ipairs(bg_colors) do
	vim.api.nvim_set_hl(0, "@markup.heading." .. i .. ".markdown", {
		fg = fg,
		bg = bg,
		bold = true,
	})
end

-- NOTE: LSP Inlay Hints are configured in colorscheme.lua and autocmds.lua
-- They must be set AFTER the colorscheme loads, otherwise they get overridden
-- See:
--   - lua/cybercat/plugins/colorscheme.lua (after vim.cmd("colorscheme"))
--   - lua/cybercat/core/autocmds.lua (ColorScheme autocmd)
