-- LSP Inlay Hints customization
-- 
-- ⚠️  WARNING: This file is NOT automatically loaded!
-- 
-- Inlay hints must be configured AFTER the colorscheme loads, otherwise they
-- get overridden. Currently configured in:
--   1. lua/cybercat/plugins/colorscheme.lua:43-48 (after colorscheme loads)
--   2. lua/cybercat/core/autocmds.lua:17-28 (ColorScheme autocmd)
--
-- This file provides alternative styles you can manually apply.
-- To use: Uncomment the require() call in colorscheme.lua or autocmds.lua

local M = {}

function M.setup()
	local colors = require("cybercat.core.ui.colors")

	-- Default inlay hint style (subtle, italic, comment-like)
	vim.api.nvim_set_hl(0, "LspInlayHint", {
		fg = colors["cybercat_color09"] or "#6c7086", -- Fallback to gray
		bg = "NONE", -- Transparent background
		italic = true,
	})

	-- You can also create variants for different hint types:
	-- Parameter hints (e.g., "name:", "age:")
	vim.api.nvim_set_hl(0, "LspInlayHintParameter", {
		link = "LspInlayHint", -- Link to main style
	})

	-- Type hints (e.g., ": string", ": number")
	vim.api.nvim_set_hl(0, "LspInlayHintType", {
		link = "LspInlayHint", -- Link to main style
	})
end

-- Alternative styles you can try:
function M.style_dimmed()
	vim.api.nvim_set_hl(0, "LspInlayHint", {
		fg = "#4a4a4a",
		bg = "NONE",
		italic = true,
	})
end

function M.style_colored()
	local colors = require("cybercat.core.ui.colors")
	vim.api.nvim_set_hl(0, "LspInlayHint", {
		fg = colors["cybercat_color03"], -- Cyan color
		bg = "NONE",
		italic = true,
	})
end

function M.style_subtle_bg()
	local colors = require("cybercat.core.ui.colors")
	vim.api.nvim_set_hl(0, "LspInlayHint", {
		fg = colors["cybercat_color09"],
		bg = colors["cybercat_color13"], -- Very subtle background
		italic = true,
	})
end

function M.style_bold()
	local colors = require("cybercat.core.ui.colors")
	vim.api.nvim_set_hl(0, "LspInlayHint", {
		fg = colors["cybercat_color09"],
		bg = "NONE",
		bold = true, -- Make it bold instead of italic
	})
end

return M
