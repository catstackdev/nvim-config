-- g c c
-- g b c
return {
	"numToStr/Comment.nvim",
	event = { "BufReadPre", "BufNewFile" },
	-- commentstring context is handled by ts-comments.nvim (see editing/ts-comments.lua);
	-- Comment.nvim just reads vim.bo.commentstring, so no pre_hook is needed.
	config = function()
		require("Comment").setup({})
	end,
	-- ✨ This 'keys' section is what you were missing
	-- keys = {
	--   -- Toggle comment on the current line
	--   { "gcc", mode = "n", desc = "Comment toggle current line" },
	--   -- Toggle comment for the selected lines in Visual mode
	--   { "gc",  mode = "v", desc = "Comment toggle visual lines" },
	--   -- Toggle block comment on the current line
	--   { "gbc", mode = "n", desc = "Block comment current line" },
	--   -- Toggle block comment for the selected lines in Visual mode
	--   { "gb",  mode = "v", desc = "Block comment visual lines" },
	-- },
}
