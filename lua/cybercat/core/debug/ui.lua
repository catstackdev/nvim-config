-- dap-ui layout, panel behaviour, signs, and auto open/close.
local M = {}

local PANEL_FILETYPES = { "dapui_scopes", "dapui_watches", "dapui_stacks", "dapui_breakpoints", "dap-repl" }

-- Indexes into the `layouts` list given to dapui.setup below.
local REPL_LAYOUT = 1
local SIDEBAR_LAYOUT = 2

--- A dap-ui layout that is open right now, or nil when none is.
---@return integer?
local function open_layout()
	local found
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
		if filetype:find("^dapui_") then
			return SIDEBAR_LAYOUT
		elseif filetype == "dap-repl" then
			found = REPL_LAYOUT
		end
	end
	return found
end

--- Rebuild the dap-ui windows at their configured sizes, keeping the cursor
--- where it was. No-op while the UI is closed, and never opens a layout that
--- was hidden (opening one layout resets the sizes of all the open ones).
function M.reset_layout()
	local layout = open_layout()
	if not layout then
		return
	end
	vim.schedule(function()
		local current_win = vim.api.nvim_get_current_win()
		require("dapui").open({ layout = layout, reset = true })
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

local MIN_VALUE_WIDTH = 10
local EDGE_MARGIN = 3
local FALLBACK_PANEL_WIDTH = 40

--- Width of the variable panel as it is on screen right now.
---@return integer
local function variable_panel_width()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
		if filetype == "dapui_scopes" or filetype == "dapui_watches" then
			return vim.api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff
		end
	end
	return FALLBACK_PANEL_WIDTH
end

--- "Unable to evaluate expression: could not find symbol value for x" is what a
--- watch shows whenever x is not in scope at the current line. Keep the reason,
--- drop the boilerplate; any other error keeps its full text.
---@param line string
---@return string
local function shorten_error(line)
	local reason = line:match("^Unable to evaluate expression: (.*)$")
	if not reason then
		return line
	end
	if reason:find("could not find symbol value for", 1, true) then
		return "⚠ not in scope here"
	end
	return "⚠ " .. reason
end

--- Delve prints a struct's whole type as its value ("struct { pkg/path.name string; ...").
--- dap-ui can only cut by lines, so cut each value line to what fits in the panel
--- (from where the value starts to the right edge); the struct's fields are still
--- listed under it, and <leader>de shows the full value.
local function shorten_long_values()
	local util = require("dapui.util")
	local format_value = util.format_value
	util.format_value = function(value_start, value)
		-- Stay a few columns short of the edge: a row that reaches it makes dap-ui
		-- (expand_lines) float a copy of the row over itself when the cursor is on it.
		local room = math.max(variable_panel_width() - value_start - EDGE_MARGIN, MIN_VALUE_WIDTH)
		local lines = format_value(value_start, value)
		for i, line in ipairs(lines) do
			lines[i] = shorten_error(line)
			line = lines[i]
			-- only struct/pointer dumps ("{...}"); never error messages or plain values
			if line:find("{", 1, true) and vim.fn.strdisplaywidth(line) > room then
				lines[i] = vim.fn.strcharpart(line, 0, room - 1) .. "…"
			end
		end
		return lines
	end
end

---@param name string
---@param attribute "fg"|"bg"
---@param fallback string
---@return string
local function colour_of(name, attribute, fallback)
	local colour = vim.api.nvim_get_hl(0, { name = name, link = false })[attribute]
	return colour and string.format("#%06x", colour) or fallback
end

--- The line the program is paused on gets a full-line background (not only the
--- arrow), taken from the colorscheme's "added line" colour so it fits any theme.
local function define_signs()
	vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = colour_of("DiffAdd", "bg", "#2e4a2e") })
	vim.api.nvim_set_hl(0, "DapStoppedArrow", { fg = colour_of("DiagnosticOk", "fg", "#98c379"), bold = true })
	vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "", linehl = "", numhl = "" })
	vim.fn.sign_define("DapBreakpointCondition", { text = "🟡", texthl = "", linehl = "", numhl = "" })
	vim.fn.sign_define("DapLogPoint", { text = "📝", texthl = "", linehl = "", numhl = "" })
	vim.fn.sign_define("DapBreakpointRejected", { text = "⭕", texthl = "", linehl = "", numhl = "" })
	vim.fn.sign_define(
		"DapStopped",
		{ text = "→", texthl = "DapStoppedArrow", linehl = "DapStoppedLine", numhl = "" }
	)
end

function M.setup()
	local dap = require("dap")
	local dapui = require("dapui")
	shorten_long_values()

	dapui.setup({
		floating = { border = "rounded" },
		-- Off: it floats a copy of any full-width row over itself while the cursor is
		-- on it, which looks like overflow. Long rows are cut or wrapped instead.
		expand_lines = false,
		-- Go type names can be hundreds of characters (anonymous structs, *testing.T);
		-- cut them so the value stays visible. Use <leader>de for the full text.
		render = { max_type_length = 25 },
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

	-- The REPL wraps (its text is prose). The variable panels do not: wrapping
	-- turns one big struct into a wall of lines, so keep one row per variable
	-- (scroll sideways with zl/zh, or read the full value with <leader>de).
	vim.api.nvim_create_autocmd("FileType", {
		pattern = PANEL_FILETYPES,
		callback = function(event)
			-- Watches hold error messages, which read better wrapped.
			local wraps = event.match == "dap-repl" or event.match == "dapui_watches"
			vim.wo.wrap = wraps
			vim.wo.linebreak = wraps
		end,
	})

	-- A resized terminal (tmux split, new window size) re-fits the panels.
	vim.api.nvim_create_autocmd("VimResized", { callback = M.reset_layout })

	require("nvim-dap-virtual-text").setup({ enabled = true })

	-- Only the sidebar opens by itself; <leader>dr shows the REPL when wanted.
	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open({ layout = SIDEBAR_LAYOUT })
	end
	dap.listeners.before.event_terminated["dapui_config"] = dapui.close
	dap.listeners.before.event_exited["dapui_config"] = dapui.close

	keep_layout_when_tree_toggles()

	define_signs()
	-- A colorscheme change clears custom highlight groups; define them again.
	vim.api.nvim_create_autocmd("ColorScheme", { callback = define_signs })
end

return M
