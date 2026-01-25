-- g c c
-- g b c
return {
	"numToStr/Comment.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	config = function()
		local comment = require("Comment")
		local ts_context_commentstring = require("ts_context_commentstring.integrations.comment_nvim")

		comment.setup({
			pre_hook = ts_context_commentstring.create_pre_hook(),
		})
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
