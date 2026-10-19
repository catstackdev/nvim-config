-- Go: nvim-dap-go drives `dlv` from PATH (brew install delve) and registers the
-- adapter plus launch/test configurations itself.
local M = {}

function M.setup()
	if vim.fn.executable("dlv") ~= 1 then
		vim.notify("dlv not found! Run: brew install delve", vim.log.levels.WARN)
		return
	end

	require("dap-go").setup()

	-- The first launch of a cold dlv can take longer than nvim-dap's default retry
	-- window (14 x 250ms) to start listening, which surfaces as ECONNRESET /
	-- ECONNREFUSED. Keep retrying for ~10s instead.
	local dap = require("dap")
	dap.set_log_level("DEBUG") -- connection details land in ~/.cache/nvim/dap.log
	local dap_go_adapter = dap.adapters.go
	dap.adapters.go = function(callback, config)
		dap_go_adapter(function(adapter)
			adapter.options = vim.tbl_extend("force", adapter.options or {}, { max_retries = 40 })
			callback(adapter)
		end, config)
	end

	-- Stepping past the end of main is handled by step_guard.lua. This only catches
	-- the remaining way in (step out of main): the top frame is then runtime.main.
	-- Do NOT match other runtime frames: dlv also stops on runtime goroutines
	-- (gopark, goexit, ...) in the middle of a perfectly healthy session.
	require("dap").listeners.after.stackTrace["cybercat_go_end_of_main"] = function(_, err, response)
		local top = not err and response and response.stackFrames and response.stackFrames[1]
		if top and top.name == "runtime.main" then
			vim.schedule(function()
				require("dap").terminate()
			end)
		end
	end

	vim.keymap.set("n", "<leader>dT", function()
		require("dap-go").debug_test()
	end, { desc = "Debug: Go test under cursor" })
	vim.keymap.set("n", "<leader>dL", function()
		require("dap-go").debug_last_test()
	end, { desc = "Debug: Go last test" })
end

return M
