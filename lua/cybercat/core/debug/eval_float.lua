-- <leader>de: show the value of the word under the cursor (or the visual
-- selection) in a bordered, padded float. Unlike dap-ui's own hover, this one
-- keeps its size, so it can have real padding.
local M = {}

local PADDING = " "
local MAX_HEIGHT = 20

---@type integer?
local current_win

---@return string expression  visual selection if in visual mode, else the word under the cursor
local function current_expr()
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" then
		local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
		return vim.trim(table.concat(lines, " "))
	end
	local expr = vim.fn.expand("<cexpr>")
	return expr ~= "" and expr or vim.fn.expand("<cword>")
end

local function leave_visual_mode()
	if vim.fn.mode():match("[vV]") then
		vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	end
end

local function close()
	if current_win and vim.api.nvim_win_is_valid(current_win) then
		vim.api.nvim_win_close(current_win, true)
	end
	current_win = nil
end

---@param text string
---@return string[] lines  text with horizontal padding and a blank line above and below
local function padded_lines(text)
	local lines = {}
	for line in vim.gsplit(text, "\n", { plain = true }) do
		lines[#lines + 1] = PADDING .. line .. PADDING
	end
	return lines
end

---@param lines string[]
---@param min_width integer  the title's width, so the title is never cropped
---@return integer width, integer height
local function content_size(lines, min_width)
	local max_width = math.floor(vim.o.columns * 0.8)
	local width = min_width
	for _, line in ipairs(lines) do
		width = math.max(width, vim.fn.strdisplaywidth(line))
	end
	width = math.min(width, max_width)

	local height = 0
	for _, line in ipairs(lines) do
		height = height + math.max(1, math.ceil(vim.fn.strdisplaywidth(line) / width))
	end
	return width, math.min(height, MAX_HEIGHT)
end

---@param expr string
---@param text string
---@param value_type string?
local function open(expr, text, value_type)
	close()
	local title = " " .. vim.fn.strcharpart(expr, 0, 40) .. (value_type and (" : " .. value_type) or "") .. " "
	local lines = padded_lines(text)
	local width, height = content_size(lines, vim.fn.strdisplaywidth(title))

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"

	current_win = vim.api.nvim_open_win(buf, false, {
		relative = "cursor",
		row = 1,
		col = 0,
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = title,
		title_pos = "left",
	})
	vim.wo[current_win].wrap = true

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave" }, {
		once = true,
		callback = close,
	})
end

--- The expression under the cursor / in the selection (any visual mode); leaves visual mode.
---@return string
function M.take_expr()
	local expr = current_expr()
	leave_visual_mode()
	return expr
end

function M.show()
	local session = require("dap").session()
	if not session then
		vim.notify("No active debug session", vim.log.levels.WARN)
		return
	end
	local expr = current_expr()
	leave_visual_mode()
	if expr == "" then
		return
	end

	local frame = session.current_frame
	session:request(
		"evaluate",
		{ expression = expr, frameId = frame and frame.id, context = "hover" },
		function(err, response)
			vim.schedule(function()
				if err or not response then
					open(expr, err and err.message or "no result", nil)
				else
					open(expr, response.result, response.type)
				end
			end)
		end
	)
end

return M
