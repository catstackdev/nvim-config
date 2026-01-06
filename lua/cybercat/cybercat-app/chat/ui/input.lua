local M = {}
local state = {
	buf = nil,
	win = nil,
	ns = vim.api.nvim_create_namespace("chat_input"),
	history = {},
	history_index = 0,
}

local config = require("chat.config")
local utils = require("chat.core.utils")
local manager = require("chat.ui.manager")

function M.init()
	-- Create input buffer
	state.buf = vim.api.nvim_create_buf(false, true)

	-- Configure buffer
	vim.api.nvim_buf_set_name(state.buf, "chat-ui://input")
	vim.api.nvim_buf_set_option(state.buf, "filetype", "chat_input")
	vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
	vim.api.nvim_buf_set_option(state.buf, "modifiable", true)

	-- Set keymaps
	vim.api.nvim_buf_set_keymap(
		state.buf,
		"n",
		config.options.mappings.send,
		'<Cmd>lua require("chat.ui.input").send()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		state.buf,
		"i",
		config.options.mappings.send,
		'<Cmd>lua require("chat.ui.input").send()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		state.buf,
		"i",
		config.options.mappings.history_complete,
		'<Cmd>lua require("chat.ui.input").complete_history()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		state.buf,
		"i",
		"<Up>",
		'<Cmd>lua require("chat.ui.input").history_prev()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		state.buf,
		"i",
		"<Down>",
		'<Cmd>lua require("chat.ui.input").history_next()<CR>',
		{ silent = true }
	)
end

function M.show()
	if not manager.is_active() then
		return
	end

	local sidebar = require("chat.ui.sidebar")
	if not sidebar.win then
		return
	end

	local win_height = 1 -- Single line input
	local win_width = vim.api.nvim_win_get_width(sidebar.win) - 4 -- Account for borders

	state.win = vim.api.nvim_open_win(state.buf, true, {
		relative = "win",
		win = sidebar.win,
		width = win_width,
		height = win_height,
		col = 2,
		row = vim.api.nvim_win_get_height(sidebar.win) - win_height - 1,
		style = "minimal",
		border = "none",
		focusable = true,
	})

	-- Set prompt
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { "> " })
	vim.api.nvim_win_set_cursor(state.win, { 1, 2 })
	vim.cmd("startinsert!")
end

function M.send()
	local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
	local input = table.concat(lines, "\n"):gsub("^>%s*", "")

	if #input > 0 then
		table.insert(state.history, 1, input)
		state.history_index = 0
		manager.send_message(input)
		vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { "> " })
		vim.api.nvim_win_set_cursor(state.win, { 1, 2 })
	end
end

function M.complete_history()
	-- Implement completion using telescope/fzf
end

function M.history_prev()
	if #state.history == 0 then
		return
	end
	state.history_index = math.min(state.history_index + 1, #state.history)
	M._set_history_input()
end

function M.history_next()
	if #state.history == 0 then
		return
	end
	state.history_index = math.max(state.history_index - 1, 0)
	M._set_history_input()
end

function M._set_history_input()
	local text = state.history_index > 0 and state.history[state.history_index] or ""
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { "> " .. text })
	vim.api.nvim_win_set_cursor(state.win, { 1, #text + 3 })
end

return M
