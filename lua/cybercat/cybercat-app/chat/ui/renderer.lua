local config = require("cybercat.cybercat-app.chat.config")
local state = require("cybercat.cybercat-app.chat.ui.sidebar").state

local M = {}

function M.render(lines)
	vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
end

return M
