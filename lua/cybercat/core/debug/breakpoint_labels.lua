-- Show each breakpoint's condition / log message as virtual text at the end of
-- its line (e.g. "if i == 10", "log: x = {x}"), so you can see what you set.
local M = {}

local NS = vim.api.nvim_create_namespace("cybercat_breakpoint_labels")

---@param bp table  entry from dap.breakpoints.get()
---@return string?
local function label_of(bp)
	if bp.condition and bp.condition ~= "" then
		return "  if " .. bp.condition
	elseif bp.logMessage and bp.logMessage ~= "" then
		return "  log: " .. bp.logMessage
	elseif bp.hitCondition and bp.hitCondition ~= "" then
		return "  hit " .. bp.hitCondition
	end
end

function M.refresh()
	local by_buffer = require("dap.breakpoints").get()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
			for _, bp in ipairs(by_buffer[bufnr] or {}) do
				local label = label_of(bp)
				if label and bp.line <= vim.api.nvim_buf_line_count(bufnr) then
					vim.api.nvim_buf_set_extmark(bufnr, NS, bp.line - 1, 0, {
						virt_text = { { label, "DiagnosticVirtualTextWarn" } },
						virt_text_pos = "eol",
					})
				end
			end
		end
	end
end

--- Refresh once the current key's work (a prompt, a toggle) has landed.
function M.refresh_soon()
	vim.defer_fn(M.refresh, 50)
end

function M.setup()
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
		callback = M.refresh_soon,
	})
end

return M
