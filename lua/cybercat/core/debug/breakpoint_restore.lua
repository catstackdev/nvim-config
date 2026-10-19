-- Restore saved breakpoints (persistent-breakpoints.nvim keeps them per working
-- directory) in two situations the plugin's own loader gets wrong:
--   * a file that is not open when a debug session starts: its breakpoints would
--     never reach the debugger, so load every saved file before the session starts;
--   * a buffer that is listed but not loaded (e.g. from a restored session): setting
--     a breakpoint there puts it on line 1, and that line 1 then gets saved back.
local M = {}

--- Breakpoints the plugin saved for a file. Entries the debugger rejected ("breakpoint
--- already exists", the line-1 damage described above) are dropped.
---@param path string
---@return table[]
local function saved_for(path)
	local saved = require("persistent-breakpoints.inmemory").bps or {}
	local by_line = {}
	for _, bp in ipairs(saved[path] or {}) do
		if not (bp.state and bp.state.verified == false) then
			by_line[bp.line] = bp
		end
	end
	return vim.tbl_values(by_line)
end

---@param bufnr integer  must be loaded
function M.restore_buffer(bufnr)
	if not vim.api.nvim_buf_is_loaded(bufnr) then
		return
	end
	local breakpoints = require("dap.breakpoints")
	if #(breakpoints.get(bufnr)[bufnr] or {}) > 0 then
		return -- already has breakpoints: this session set them, don't double up
	end
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	for _, bp in ipairs(saved_for(vim.api.nvim_buf_get_name(bufnr))) do
		if bp.line <= line_count then
			breakpoints.set({
				condition = bp.condition,
				log_message = bp.logMessage,
				hit_condition = bp.hitCondition,
			}, bufnr, bp.line)
		end
	end
end

--- Load (without showing) every file that has saved breakpoints, then restore them.
function M.restore_all()
	for path in pairs(require("persistent-breakpoints.inmemory").bps or {}) do
		if vim.fn.filereadable(path) == 1 then
			local bufnr = vim.fn.bufadd(path)
			vim.fn.bufload(bufnr)
			M.restore_buffer(bufnr)
		end
	end
	require("cybercat.core.debug.breakpoint_labels").refresh()
end

function M.setup()
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = vim.api.nvim_create_augroup("cybercat_breakpoint_restore", { clear = true }),
		callback = function(args)
			M.restore_buffer(args.buf)
			require("cybercat.core.debug.breakpoint_labels").refresh_soon()
		end,
	})
	-- runs right before a session starts, so the debugger gets every file's breakpoints
	require("dap").listeners.on_config["cybercat_breakpoint_restore"] = function(config)
		M.restore_all()
		return config
	end
end

return M
