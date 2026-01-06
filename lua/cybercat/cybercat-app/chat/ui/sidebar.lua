local M = {}
local state = {
	sidebar_win = nil,
	sidebar_buf = nil,
	input_win = nil,
	input_buf = nil,
	ns = vim.api.nvim_create_namespace("chat_ui"),
}

local config = require("cybercat.cybercat-app.chat.config")

-- local keymap =  require("cybercat.cybercat-app.chat.features.keymaps")
-- local utils = require("chat.core.utils")
-- local renderer = require("chat.ui.renderer")
-- local highlights = require("chat.ui.highlights")

-- Initialize or return existing buffer
function M.get_buf()
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		return state.buf
	end
	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(state.buf, "sidebar://tree")
	vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(state.buf, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
	vim.api.nvim_buf_set_option(state.buf, "filetype", config.options.filetype)
	vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
	return state.buf
end

function M.init()
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		return state.buf
	end
	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(state.buf, "chat-ui://sidebar")
	vim.api.nvim_buf_set_option(state.buf, "filetype", "chat")
	vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
	vim.api.nvim_buf_set_option(state.buf, "undolevels", -1)
	vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
	return state.buf
end
-- function M.open()
-- 	local buf = M.init()
-- 	if state.win and vim.api.nvim_win_is_valid(state.win) then
-- 		return buf
-- 	end
--
-- 	local ui = vim.api.nvim_list_uis()[1]
--
-- 	local width = math.min(config.options.width, math.floor(ui.width * 0.6))
--
-- 	state.win = vim.api.nvim_open_win(buf, true, {
-- 		relative = "editor",
-- 		width = width,
-- 		height = ui.height - 5,
-- 		col = config.options.position == "right" and (ui.width - width) or 0,
-- 		row = 2,
-- 		style = "minimal",
-- 		border = config.options.border,
-- 		title = config.options.show_title and config.options.title or "",
-- 		title_pos = "left",
-- 		noautocmd = true,
-- 	})
--
-- 	-- 🛠 Set winhl **after** opening the window
-- 	vim.api.nvim_win_set_option(
-- 		state.win,
-- 		"winhl",
-- 		table.concat({
-- 			"Normal:" .. config.options.hl.normal,
-- 			"NormalFloat:" .. config.options.hl.normal,
-- 			"FloatBorder:" .. config.options.hl.border,
-- 			"Title:" .. config.options.hl.title,
-- 		}, ",")
-- 	)
--
-- 	vim.api.nvim_win_set_option(state.win, "wrap", true)
-- 	vim.api.nvim_win_set_option(state.win, "cursorline", true)
--
-- 	-- Return buffer so keymaps can be set
-- 	print("[sidebar] Opened win id:", state.win)
-- 	return buf
-- end
function M.open()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_set_current_win(state.win)
		return
	end
	local buf = M.get_buf()
	if config.options.position == "left" then
		vim.cmd("topleft vertical " .. config.options.width .. " split")
	else
		vim.cmd("botright vertical " .. config.options.width .. " split")
	end

	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)

	-- Window options
	vim.api.nvim_win_set_option(win, "number", false)
	vim.api.nvim_win_set_option(win, "relativenumber", false)
	vim.api.nvim_win_set_option(win, "cursorline", true)
	vim.api.nvim_win_set_option(win, "wrap", false)

	state.win = win

	-- Focus window
	vim.api.nvim_set_current_win(win)
end

-- function M.open()
-- 	if state.win and vim.api.nvim_win_is_valid(state.win) then
-- 		return
-- 	end
--
-- 	local ui = vim.api.nvim_list_uis()[1]
-- 	local width = math.min(config.options.width, math.floor(ui.width * 0.6))
--
-- 	local opts = {
-- 		relative = "editor",
-- 		width = width,
-- 		height = ui.height - 5,
-- 		col = config.options.position == "right" and (ui.width - width) or 0,
-- 		row = 2,
-- 		style = "minimal",
-- 		border = config.options.border,
-- 		title = config.options.show_title and config.options.title or "",
-- 		title_pos = "left",
-- 		noautocmd = true,
-- 		winhl = table.concat({
-- 			"Normal:" .. config.options.hl.normal,
-- 			"NormalFloat:" .. config.options.hl.normal,
-- 			"FloatBorder:" .. config.options.hl.border,
-- 			"Title:" .. config.options.hl.title,
-- 		}, ","),
-- 	}
--
-- 	state.win = vim.api.nvim_open_win(state.buf, true, opts)
--
-- 	-- Window options
-- 	vim.api.nvim_win_set_option(state.win, "winblend", config.options.winblend)
-- 	vim.api.nvim_win_set_option(state.win, "wrap", true)
-- 	vim.api.nvim_win_set_option(state.win, "cursorline", true)
-- 	vim.api.nvim_win_set_option(state.win, "number", false)
-- 	vim.api.nvim_win_set_option(state.win, "relativenumber", false)
-- 	vim.api.nvim_win_set_option(state.win, "conceallevel", 2)
--
-- 	-- Trigger redraw
-- 	-- renderer.redraw()
-- end

function M.close()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end
	state.win = nil
end

function M.scroll(lines)
	if not state.win then
		return
	end
	local current = vim.api.nvim_win_get_cursor(state.win)
	vim.api.nvim_win_set_cursor(state.win, { math.max(1, current[1] + lines), current[2] })
end

function M.clear_extmarks()
	for _, mark in pairs(state.extmarks) do
		vim.api.nvim_buf_del_extmark(state.buf, state.ns, mark)
	end
	state.extmarks = {}
end

function M.get_state()
	return state
end

return M
