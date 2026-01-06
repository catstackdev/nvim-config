local M = {}

function M.setup()
	vim.api.nvim_set_hl(0, "ChatSidebarTitle", { fg = "#00ffff", bold = true })
	vim.api.nvim_set_hl(0, "ChatSidebarLine", { fg = "#ffffff" })
end

return M
