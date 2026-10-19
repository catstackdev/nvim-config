-- Step over, but never off the end of a Go program: stepping past main's closing
-- brace lands in runtime/proc.go, which nvim-dap then opens (polluting the window
-- and the jumplist). On that line, end the session instead of stepping.
local M = {}

---@return boolean
local function at_end_of_go_main()
	local session = require("dap").session()
	local frame = session and session.current_frame
	local path = frame and frame.source and frame.source.path
	if not (frame and path and frame.name == "main.main") then
		return false
	end
	local bufnr = vim.fn.bufadd(path)
	vim.fn.bufload(bufnr)
	local text = vim.api.nvim_buf_get_lines(bufnr, frame.line - 1, frame.line, false)[1] or ""
	return text:match("^}%s*$") ~= nil
end

function M.step_over()
	if at_end_of_go_main() then
		vim.notify("End of main: ending the debug session", vim.log.levels.INFO)
		return require("dap").terminate()
	end
	require("dap").step_over()
end

return M
