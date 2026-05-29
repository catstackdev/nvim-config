---@diagnostic disable: undefined-global
-- Shared helper for shader preview ftplugins (glsl, wgsl).
-- Opens a minimal terminal split, returns focus to caller, auto-closes on exit.

local M = {}

function M.launch(cmd)
	local origin = vim.api.nvim_get_current_win()

	vim.cmd("botright 4split | terminal " .. cmd)

	local term_win = vim.api.nvim_get_current_win()
	local term_buf = vim.api.nvim_get_current_buf()

	local function close_preview()
		if vim.api.nvim_win_is_valid(term_win) then
			vim.api.nvim_win_close(term_win, true)
		end
		if vim.api.nvim_buf_is_valid(term_buf) then
			vim.cmd("bdelete! " .. term_buf)
		end
	end

	vim.api.nvim_create_autocmd("TermClose", {
		buffer = term_buf,
		once = true,
		callback = vim.schedule_wrap(function()
			close_preview()
		end),
	})

	if vim.api.nvim_win_is_valid(origin) then
		vim.api.nvim_set_current_win(origin)
	end
end

return M
