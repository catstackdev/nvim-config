local M = {}
local config = require("chat.config")

function M.setup()
	local group = vim.api.nvim_create_augroup("ChatUI", { clear = true })

	-- Save history on exit
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			if config.options.persist_history then
				require("chat.core.history.manager").save()
			end
		end,
	})

	-- Auto-focus input when sidebar opens
	vim.api.nvim_create_autocmd("User", {
		pattern = "ChatUIOpened",
		group = group,
		callback = function()
			require("chat.ui.input").show()
		end,
	})

	-- Syntax highlighting for chat buffers
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "chat",
		group = group,
		callback = function()
			require("chat.ui.highlights").apply_buffer_highlights()
		end,
	})
end

return M
