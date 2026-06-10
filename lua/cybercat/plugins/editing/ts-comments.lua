-- ts-comments.nvim: lighter replacement for nvim-ts-context-commentstring.
-- It sets `vim.bo.commentstring` based on treesitter cursor context so that
-- Comment.nvim's gcc / gbc (and Neovim 0.10+ native gc) produce the right
-- comment style inside mixed-language buffers (JSX/TSX/Vue/Svelte/etc).
return {
	"folke/ts-comments.nvim",
	event = "VeryLazy",
	opts = {
		-- ts-comments ships with no entry for wgsl/glsl; register them so the
		-- built-in `gc` / `gcc` (Neovim 0.10+) resolves a commentstring instead
		-- of falling back to `vim.filetype.get_option`, which on these filetypes
		-- can recurse through the override and blow the Lua stack.
		lang = {
			wgsl = "// %s",
			glsl = "// %s",
		},
	},
}
