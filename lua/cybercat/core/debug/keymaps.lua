-- Debug keymaps: everything lives under <leader>d + one letter.
local M = {}

--- Keep the word/selection in the Watches panel, re-evaluated at every step.
--- dap-ui needs a nio task for this.
local function add_watch()
	require("nio").run(function()
		require("dapui").elements.watches.add()
	end)
end

function M.setup()
	local dap = require("dap")
	local dapui = require("dapui")

	local function map(modes, lhs, rhs, desc)
		vim.keymap.set(modes, lhs, rhs, { desc = "Debug: " .. desc })
	end

	map("n", "<leader>db", dap.toggle_breakpoint, "Toggle breakpoint")
	map("n", "<leader>dc", dap.continue, "Start/Continue")
	map("n", "<leader>dn", dap.step_over, "Next line (step over)")
	map("n", "<leader>di", dap.step_into, "Step into")
	map("n", "<leader>do", dap.step_out, "Step out")
	map("n", "<leader>dx", dap.terminate, "Stop")
	map("n", "<leader>dt", dapui.toggle, "Toggle UI")
	-- layout 2 is the sidebar (variables, watches, stack); layout 1 the REPL
	map("n", "<leader>ds", function()
		dapui.toggle({ layout = 2 })
	end, "Show/hide side panels")
	map("n", "<leader>dr", function()
		dapui.toggle({ layout = 1 })
	end, "Show/hide REPL")
	map("n", "<leader>d=", require("cybercat.core.debug.ui").reset_layout, "Reset panel sizes")
	map("n", "<leader>dz", require("cybercat.core.debug.resize").start, "Resize mode (then h/j/k/l)")
	map({ "n", "v" }, "<leader>de", require("cybercat.core.debug.eval_float").show, "Eval word/selection")
	map({ "n", "v" }, "<leader>dE", dapui.eval, "Eval word/selection (expandable)")
	map({ "n", "v" }, "<leader>dw", add_watch, "Add word/selection to Watches")
end

return M
