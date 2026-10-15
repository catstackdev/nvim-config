-- Debug keymaps: everything lives under <leader>d + one letter.
local M = {}

--- Keep the word/selection in the Watches panel, re-evaluated at every step.
--- dap-ui needs a nio task for this.
local function add_watch()
	-- Read the selection here, not inside dap-ui: its own reader only understands
	-- charwise `v` and falls back to the word under the cursor for `V` / <C-v>.
	local expr = require("cybercat.core.debug.eval_float").take_expr()
	if expr == "" then
		return
	end
	require("nio").run(function()
		require("dapui").elements.watches.add(expr)
	end)
end

--- Remove every expression from the Watches panel (dap-ui keeps them between sessions).
local function clear_watches()
	require("nio").run(function()
		local watches = require("dapui").elements.watches
		for index = #watches.get(), 1, -1 do
			watches.remove(index)
		end
	end)
end

--- Stop the session, close the panels and wipe the watches, so the next
--- <leader>dc starts clean.
local function stop_session()
	require("dap").terminate({
		on_done = function()
			vim.schedule(function()
				require("dapui").close()
				clear_watches()
			end)
		end,
	})
end

function M.setup()
	local dap = require("dap")
	local dapui = require("dapui")

	local function map(modes, lhs, rhs, desc)
		vim.keymap.set(modes, lhs, rhs, { desc = "Debug: " .. desc })
	end

	map("n", "<leader>db", dap.toggle_breakpoint, "Toggle breakpoint")
	map("n", "<leader>dB", dap.clear_breakpoints, "Clear ALL breakpoints")
	map("n", "<leader>dc", function()
		-- A Go test file can't be built as a program, so skip the menu and debug the test.
		if not dap.session() and vim.api.nvim_buf_get_name(0):match("_test%.go$") then
			require("dap-go").debug_test()
		else
			dap.continue()
		end
	end, "Start/Continue (test file: debug nearest test)")
	map("n", "<leader>dn", dap.step_over, "Next line (step over)")
	map("n", "<leader>di", dap.step_into, "Step into")
	map("n", "<leader>do", dap.step_out, "Step out")
	map("n", "<leader>dx", stop_session, "Stop (and clear watches)")
	map("n", "<leader>dR", dap.restart, "Restart (run again from the top)")
	map("n", "<leader>dg", dap.run_to_cursor, "Go (run) to cursor line")
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
