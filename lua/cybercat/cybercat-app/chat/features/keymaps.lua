-- keymaps.lua
local M = {}
local config = require("cybercat.cybercat-app.chat.config")
local sidebar = require("cybercat.cybercat-app.chat.ui.sidebar")

function M.set_sidebar_keymaps(buf)
	local opts = { silent = true, noremap = true }

	vim.keymap.set("n", config.options.mappings.open or "<leader>cs", function()
		sidebar.open()
	end, { desc = "Open Chat Sidebar" })

	vim.keymap.set("n", config.options.mappings.scroll_up or "<C-u>", function()
		sidebar.scroll(-5)
	end, vim.tbl_extend("force", opts, { buffer = buf }))

	vim.keymap.set("n", config.options.mappings.scroll_down or "<C-d>", function()
		sidebar.scroll(5)
	end, vim.tbl_extend("force", opts, { buffer = buf }))

	vim.keymap.set("n", config.options.mappings.close or "q", function()
		sidebar.close()
	end, vim.tbl_extend("force", opts, { buffer = buf }))

	-- Move to sidebar with Ctrl-l
	-- vim.keymap.set("n", "<C-l>", function()
	-- 	print("[keymap] sidebar win id:", win, "is_valid:", vim.api.nvim_win_is_valid(win))
	-- 	if sidebar.state and sidebar.get_state().win and vim.api.nvim_win_is_valid(sidebar.state.win) then
	-- 		vim.api.nvim_set_current_win(sidebar.state.win)
	-- 	else
	-- 		vim.notify("Sidebar is not open", vim.log.levels.INFO)
	-- 	end
	-- end, { desc = "Focus Chat Sidebar (only if open)" })

	-- vim.keymap.set("n", "<C-l>", function()
	-- 	if sidebar.state and sidebar.state.win and vim.api.nvim_win_is_valid(sidebar.state.win) then
	-- 		vim.api.nvim_set_current_win(sidebar.state.win)
	-- 	else
	-- 		sidebar.open()
	-- 		vim.schedule(function()
	-- 			if sidebar.state and sidebar.state.win then
	-- 				vim.api.nvim_set_current_win(sidebar.state.win)
	-- 			end
	-- 		end)
	-- 	end
	-- end, { desc = "Focus or Open Chat Sidebar" })

	-- Go back (to left split) with Ctrl-h
	vim.keymap.set("n", config.options.mappings.back or "<C-h>", "<C-w>h", { desc = "Go Left" })
end

return M
