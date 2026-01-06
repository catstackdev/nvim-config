local M = {}
local config = require("chat.config")

function M.setup()
	vim.api.nvim_create_user_command("ChatToggle", function()
		require("chat.ui.manager").toggle()
	end, { desc = "Toggle chat UI" })

	vim.api.nvim_create_user_command("ChatNew", function()
		require("chat.core.sessions").create()
	end, { desc = "Create new chat session" })

	vim.api.nvim_create_user_command("ChatSend", function()
		require("chat.ui.input").send()
	end, { desc = "Send current message" })

	vim.api.nvim_create_user_command("ChatInterrupt", function()
		require("chat.core.api.client").cancel()
	end, { desc = "Interrupt current request" })

	vim.api.nvim_create_user_command("ChatExport", function(opts)
		local format = opts.args or "markdown"
		require("chat.core.sessions").export(nil, format)
	end, {
		nargs = "?",
		desc = "Export chat session",
		complete = function()
			return { "markdown", "json" }
		end,
	})
end

return M
