-- Which-key group names and icons for the <leader> prefixes.
-- Add a line here when a new <leader>x prefix appears; per-key labels come from each keymap's `desc`.
-- Keep prefixes free of a standalone mapping (e.g. a bare <leader>d next to <leader>d*): Vim waits for
-- 'timeoutlen' before firing it.

-- Neovim runs LuaJIT, which has no "\u{...}" escapes, so build glyphs from codepoints.
---@param codepoint integer Nerd Font codepoint
---@param color string which-key color name
---@return wk.Icon
local function icon(codepoint, color)
	return { icon = vim.fn.nr2char(codepoint) .. " ", color = color }
end

---@type wk.Spec
return {
	{ "<leader>a", group = "imports / autosave", icon = icon(0xf0c7, "green") },
	{ "<leader>c", group = "claude / file", icon = icon(0xf06a9, "orange") },
	{ "<leader>d", group = "debug", icon = icon(0xf188, "red") },
	{ "<leader>e", group = "explorer", icon = icon(0xf07b, "azure") },
	{ "<leader>f", group = "find / fix", icon = icon(0xf002, "green") },
	{ "<leader>g", group = "git", icon = icon(0xf1d3, "orange") },
	{ "<leader>h", group = "harpoon", icon = icon(0xf0c1, "azure") },
	{ "<leader>i", group = "image / inspect / imports", icon = icon(0xf03e, "purple") },
	{ "<leader>j", group = "jupyter / jqx", icon = icon(0xf121, "purple") },
	{ "<leader>l", group = "lazy / lsp / preview", icon = icon(0xf0e7, "yellow") },
	{ "<leader>m", group = "markdown", icon = icon(0xf48a, "azure") },
	{ "<leader>n", group = "npm / notifications", icon = icon(0xf487, "green") },
	{ "<leader>o", group = "organize / outline", icon = icon(0xf03a, "azure") },
	{ "<leader>q", group = "quit / quickfix", icon = icon(0xf00d, "red") },
	-- r mixes three areas: run (rr rl rR rt rx ro rq), refactor (re* ri* rI), lsp (rn rN rs)
	{ "<leader>r", group = "run / refactor / rename", icon = icon(0xf04b, "green") },
	{ "<leader>R", group = "http requests", icon = icon(0xf0ac, "cyan") },
	{ "<leader>s", group = "search / splits / speak", icon = icon(0xf0db, "cyan") },
	{ "<leader>t", group = "tabs / test / treesj", icon = icon(0xf0c3, "yellow") },
	{ "<leader>u", group = "ui / undo", icon = icon(0xf1fc, "purple") },
	{ "<leader>w", group = "write / session", icon = icon(0xf017, "azure") },
	{ "<leader>x", group = "trouble / diagnostics", icon = icon(0xf071, "red") },
}
