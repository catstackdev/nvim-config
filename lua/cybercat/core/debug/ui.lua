-- dap-ui layout, panel behaviour, signs, and auto open/close.
local M = {}

local PANEL_FILETYPES = { "dapui_scopes", "dapui_watches", "dapui_stacks", "dapui_breakpoints", "dap-repl" }

---@return boolean
local function is_dapui_open()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
		if filetype:find("^dapui_") or filetype == "dap-repl" then
			return true
		end
	end
	return false
end

--- Rebuild the dap-ui windows at their configured sizes, keeping the cursor
--- where it was. No-op while the UI is closed.
function M.reset_layout()
	if not is_dapui_open() then
		return
	end
	vim.schedule(function()
		local current_win = vim.api.nvim_get_current_win()
		require("dapui").open({ reset = true })
		if vim.api.nvim_win_is_valid(current_win) then
			vim.api.nvim_set_current_win(current_win)
		end
	end)
end

--- Each nvim-tree open/close steals width from a neighbour and gives it back to
--- only one window, so the panels drift on every toggle. Rebuild after it moves.
local function keep_layout_when_tree_toggles()
	local ok, tree_api = pcall(require, "nvim-tree.api")
	if not ok then
		return
	end
	tree_api.events.subscribe(tree_api.events.Event.TreeOpen, M.reset_layout)
	tree_api.events.subscribe(tree_api.events.Event.TreeClose, M.reset_layout)
end

function M.setup()
	local dap = require("dap")
	local dapui = require("dapui")

	dapui.setup({
		floating = { border = "rounded" },
		-- Order matters: dap-ui opens layouts in this order, so the bottom REPL
		-- goes first to span the full width under the right sidebar. The REPL is
		-- also where the program's own output appears (Delve sends stdout as DAP
		-- output events).
		-- Layout sizes below 1 are a share of the screen (columns for the
		-- sidebar, lines for the bottom), so the layout fits any terminal size.
		-- Breakpoints have no panel: the gutter signs already show them.
		layouts = {
			{
				elements = { { id = "repl", size = 1 } },
				size = 0.25,
				position = "bottom",
			},
			{
				elements = {
					{ id = "scopes", size = 0.5 },
					{ id = "watches", size = 0.25 },
					{ id = "stacks", size = 0.25 },
				},
				size = 0.3,
				position = "right",
			},
		},
	})

	-- Wrap long values instead of letting them run off the panel edge.
	vim.api.nvim_create_autocmd("FileType", {
		pattern = PANEL_FILETYPES,
		callback = function()
			vim.wo.wrap = true
			vim.wo.linebreak = true
		end,
	})

	-- A resized terminal (tmux split, new window size) re-fits the panels.
	vim.api.nvim_create_autocmd("VimResized", { callback = M.reset_layout })

	require("nvim-dap-virtual-text").setup({ enabled = true })

	dap.listeners.after.event_initialized["dapui_config"] = dapui.open
	dap.listeners.before.event_terminated["dapui_config"] = dapui.close
	dap.listeners.before.event_exited["dapui_config"] = dapui.close

	keep_layout_when_tree_toggles()

	vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "", linehl = "", numhl = "" })
	vim.fn.sign_define("DapStopped", { text = "→", texthl = "", linehl = "debugPC", numhl = "" })
end

return M
