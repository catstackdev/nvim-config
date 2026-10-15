-- Go: nvim-dap-go drives `dlv` from PATH (brew install delve) and registers the
-- adapter plus launch/test configurations itself.
local M = {}

function M.setup()
	if vim.fn.executable("dlv") ~= 1 then
		vim.notify("dlv not found! Run: brew install delve", vim.log.levels.WARN)
		return
	end

	require("dap-go").setup()
	vim.keymap.set("n", "<leader>dT", function()
		require("dap-go").debug_test()
	end, { desc = "Debug: Go test under cursor" })
	vim.keymap.set("n", "<leader>dL", function()
		require("dap-go").debug_last_test()
	end, { desc = "Debug: Go last test" })
end

return M
