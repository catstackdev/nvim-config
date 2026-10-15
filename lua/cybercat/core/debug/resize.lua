-- Resize mode: press the key once, then tap h/j/k/l as often as you like.
-- The window's border follows the key: h moves a border left, l right, k up,
-- j down. So for a panel on the right/bottom edge of the screen (the dap-ui
-- sidebar and REPL), h/k make it bigger; for the others, l/j do.
local M = {}

local STEP = 2
local HELP = "-- RESIZE --  h j k l: move the border   = equalize   q/Esc: done"

---@param win integer
---@return boolean
local function touches_right_edge(win)
	local col = vim.api.nvim_win_get_position(win)[2]
	return col + vim.api.nvim_win_get_width(win) >= vim.o.columns - 1
end

---@param win integer
---@return boolean
local function touches_bottom_edge(win)
	local row = vim.api.nvim_win_get_position(win)[1]
	local bottom_rows = vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0)
	return row + vim.api.nvim_win_get_height(win) >= vim.o.lines - bottom_rows - 1
end

--- Change a size, in the direction that moves the border the way the key points.
---@param win integer
---@param key string
local function move_border(win, key)
	if key == "h" or key == "l" then
		local grows = (key == "h") == touches_right_edge(win)
		vim.api.nvim_win_set_width(win, math.max(1, vim.api.nvim_win_get_width(win) + (grows and STEP or -STEP)))
	elseif key == "k" or key == "j" then
		local grows = (key == "k") == touches_bottom_edge(win)
		vim.api.nvim_win_set_height(win, math.max(1, vim.api.nvim_win_get_height(win) + (grows and STEP or -STEP)))
	end
end

function M.start()
	local win = vim.api.nvim_get_current_win()
	while true do
		vim.api.nvim_echo({ { HELP, "ModeMsg" } }, false, {})
		vim.cmd("redraw")
		local ok, key = pcall(vim.fn.getcharstr)
		if not ok or key == "q" or key == vim.keycode("<Esc>") or key == vim.keycode("<CR>") then
			break
		elseif key == "=" then
			vim.cmd("wincmd =")
		elseif vim.api.nvim_win_is_valid(win) then
			move_border(win, key)
		end
	end
	vim.api.nvim_echo({ { "" } }, false, {})
	vim.cmd("redraw")
end

return M
