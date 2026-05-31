-- ts-comments.nvim: lighter replacement for nvim-ts-context-commentstring.
-- It sets `vim.bo.commentstring` based on treesitter cursor context so that
-- Comment.nvim's gcc / gbc (and Neovim 0.10+ native gc) produce the right
-- comment style inside mixed-language buffers (JSX/TSX/Vue/Svelte/etc).
return {
	"folke/ts-comments.nvim",
	event = "VeryLazy",
	opts = {},
}
